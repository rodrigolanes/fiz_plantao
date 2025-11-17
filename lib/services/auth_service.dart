import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/config_helper.dart';
import '../models/local.dart';
import '../models/plantao.dart';
import 'google_sign_in_service.dart';
import 'log_service.dart';

// Interface abstrata para Supabase Auth
abstract class ISupabaseAuth {
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;
  Future<AuthResponse> signInWithPassword({required String email, required String password});
  Future<AuthResponse> signUp({required String email, required String password, String? emailRedirectTo});
  Future<void> signOut();
  Future<bool> signInWithOAuth(OAuthProvider provider, {String? redirectTo, Map<String, String>? queryParams});
  Future<AuthResponse> signInWithIdToken(
      {required OAuthProvider provider, required String idToken, String? accessToken});
  Future<void> refreshSession();
  Future<void> resend({required OtpType type, required String email, String? emailRedirectTo});
  Future<void> resetPasswordForEmail(String email, {String? redirectTo});
}

// Interface abstrata para GoogleSignIn
abstract class IGoogleSignIn {
  Future<GoogleSignInAccount?> signIn();
  Future<void> signOut();
}

// Interface abstrata para Hive config box
abstract class IHiveConfig {
  Future<void> put(String key, dynamic value);
  dynamic get(String key);
  Future<void> clear();
}

// Implementações concretas que delegam para os clients originais
class SupabaseAuthImpl implements ISupabaseAuth {
  final SupabaseClient _client;

  SupabaseAuthImpl([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Future<AuthResponse> signInWithPassword({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email, password: password);

  @override
  Future<AuthResponse> signUp({required String email, required String password, String? emailRedirectTo}) =>
      _client.auth.signUp(email: email, password: password, emailRedirectTo: emailRedirectTo);

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<bool> signInWithOAuth(OAuthProvider provider, {String? redirectTo, Map<String, String>? queryParams}) =>
      _client.auth.signInWithOAuth(provider, redirectTo: redirectTo, queryParams: queryParams);

  @override
  Future<AuthResponse> signInWithIdToken(
          {required OAuthProvider provider, required String idToken, String? accessToken}) =>
      _client.auth.signInWithIdToken(provider: provider, idToken: idToken, accessToken: accessToken);

  @override
  Future<void> refreshSession() => _client.auth.refreshSession();

  @override
  Future<void> resend({required OtpType type, required String email, String? emailRedirectTo}) =>
      _client.auth.resend(type: type, email: email, emailRedirectTo: emailRedirectTo);

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) =>
      _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
}

class GoogleSignInImpl implements IGoogleSignIn {
  final GoogleSignIn _googleSignIn;

  GoogleSignInImpl([GoogleSignIn? googleSignIn]) : _googleSignIn = googleSignIn ?? GoogleSignInService.instance;

  @override
  Future<GoogleSignInAccount?> signIn() => _googleSignIn.signIn();

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}

class HiveConfigImpl implements IHiveConfig {
  Box? _box;

  Future<Box> _getBox() async {
    _box ??= await Hive.openBox('config');
    return _box!;
  }

  @override
  Future<void> put(String key, dynamic value) async {
    final box = await _getBox();
    await box.put(key, value);
  }

  @override
  dynamic get(String key) {
    if (_box == null || !_box!.isOpen) {
      return null;
    }
    return _box!.get(key);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}

class AuthService {
  final ISupabaseAuth _supabase;
  final IGoogleSignIn _googleSignIn;
  final IHiveConfig _hiveConfig;

  // Construtor com dependências injetáveis
  AuthService({
    ISupabaseAuth? supabase,
    IGoogleSignIn? googleSignIn,
    IHiveConfig? hiveConfig,
  })  : _supabase = supabase ?? SupabaseAuthImpl(),
        _googleSignIn = googleSignIn ?? GoogleSignInImpl(),
        _hiveConfig = hiveConfig ?? HiveConfigImpl();

  // Instância singleton para uso em produção
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService();

  // Método para substituir a instância (útil em testes)
  static void setInstance(AuthService service) {
    _instance = service;
  }

  // Stream do estado de autenticação
  Stream<AuthState> get authStateChanges => _supabase.onAuthStateChange;

  // Getters estáticos para compatibilidade retroativa - REMOVIDOS (conflito de nomes)

  // Usuário atual
  User? get currentUser => _supabase.currentUser;

  // Verificar se está logado
  bool get isLoggedIn => currentUser != null;

  // Override de userId para testes (quando definido, tem precedência)
  String? _overrideUserId;

  // Obter userId (UUID do Supabase) com suporte a override em testes
  String? get currentUserId => _overrideUserId ?? currentUser?.id;

  // Setter exposto para testes: permite definir um userId fake durante o teste
  // Em produção, não utilizar este setter.
  set testUserId(String? value) {
    _overrideUserId = value;
  }

  // Limpar override (útil em suites de teste)
  void clearTestOverride() {
    _overrideUserId = null;
  }

  // Login com email e senha
  Future<AuthResponse?> login(String email, String senha) async {
    try {
      final response = await _supabase.signInWithPassword(
        email: email,
        password: senha,
      );

      // Salvar userId no Hive para cache
      if (response.user != null) {
        await _hiveConfig.put('userId', response.user!.id);
        await _hiveConfig.put('userEmail', response.user!.email);
        LogService.auth('Login realizado: ${response.user!.email}');
      }

      return response;
    } on AuthException catch (e) {
      LogService.auth('Erro de autenticação no login', e);
      throw _handleAuthException(e);
    } catch (e) {
      LogService.auth('Erro inesperado no login', e);
      throw 'Erro ao fazer login: $e';
    }
  }

  // Cadastro com email e senha
  Future<AuthResponse?> cadastrar(String email, String senha) async {
    try {
      final response = await _supabase.signUp(
        email: email,
        password: senha,
        emailRedirectTo: kIsWeb ? 'http://localhost:3000' : 'br.com.rodrigolanes.fizplantao://login-callback/',
      );

      // Salvar userId no Hive para cache
      if (response.user != null) {
        await _hiveConfig.put('userId', response.user!.id);
        await _hiveConfig.put('userEmail', response.user!.email);
        LogService.auth('Cadastro realizado: ${response.user!.email}');
      }

      // Nota: Supabase envia email de confirmação automaticamente
      // se configurado em Authentication > Email Templates

      return response;
    } on AuthException catch (e) {
      LogService.auth('Erro de autenticação no cadastro', e);
      throw _handleAuthException(e);
    } catch (e) {
      LogService.auth('Erro inesperado no cadastro', e);
      throw 'Erro ao cadastrar: $e';
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.signOut();
      await _googleSignIn.signOut();

      // Limpar TODOS os dados locais do Hive
      await _limparDadosLocais();

      LogService.auth('Logout realizado e dados locais limpos');
    } catch (e) {
      LogService.auth('Erro ao fazer logout', e);
      throw 'Erro ao fazer logout: $e';
    }
  }

  // Limpar todos os dados locais do usuário
  Future<void> _limparDadosLocais() async {
    try {
      // Limpar box de configurações
      await _hiveConfig.clear();

      // Limpar box de plantões
      final plantoesBox = await Hive.openBox<Plantao>('plantoes');
      await plantoesBox.clear();

      // Limpar box de locais
      final locaisBox = await Hive.openBox<Local>('locais');
      await locaisBox.clear();

      LogService.auth('Dados locais limpos: config, plantões e locais');
    } catch (e) {
      LogService.auth('Erro ao limpar dados locais', e);
      // Não propagar erro para não bloquear o logout
    }
  }

  // Login com Google
  Future<AuthResponse?> loginComGoogle() async {
    // Verificar se integração com Google está habilitada
    if (!_isGoogleIntegrationEnabled()) {
      throw 'Login com Google está desabilitado. Configure enableGoogleIntegrations = true no SupabaseConfig.';
    }

    try {
      if (kIsWeb) {
        // Web retorna bool (redirect/popup). Sessão chega via onAuthStateChange.
        await _supabase.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? 'http://localhost:3000' : null,
          queryParams: {
            'access_type': 'offline',
            'prompt': 'consent',
          },
        );
        return null;
      } else {
        // Debug: imprimir escopos configurados
        GoogleSignInService.printScopes();

        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          LogService.auth('Login com Google cancelado pelo usuário');
          return null; // cancelado
        }

        LogService.auth('Login com Google concluído para: ${googleUser.email}');

        final googleAuth = await googleUser.authentication;
        LogService.auth(
            'Token info - idToken: ${googleAuth.idToken != null ? "presente" : "AUSENTE"}, accessToken: ${googleAuth.accessToken != null ? "presente" : "ausente"}');

        if (googleAuth.idToken == null) {
          LogService.auth('ERRO: idToken está nulo após autenticação');
          throw 'Token Google ausente';
        }

        final response = await _supabase.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
        );

        if (response.user != null) {
          await _hiveConfig.put('userId', response.user!.id);
          await _hiveConfig.put('userEmail', response.user!.email);
          LogService.auth('Login com Google realizado: ${response.user!.email}');
        }
        return response;
      }
    } on AuthException catch (e) {
      // Se o email já existe, retornar erro específico
      if (e.message.toLowerCase().contains('email') && e.message.toLowerCase().contains('already')) {
        LogService.auth('Tentativa de login com Google - email já cadastrado', e);
        throw 'Este email já possui uma conta. Faça login com email/senha primeiro e vincule o Google nas configurações.';
      }
      LogService.auth('Erro de autenticação com Google', e);
      throw _handleAuthException(e);
    } catch (e) {
      LogService.auth('Erro inesperado no login com Google', e);
      throw 'Erro ao fazer login com Google: $e';
    }
  }

  // Vincular conta Google à conta atual
  Future<void> linkGoogleAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw 'Nenhum usuário logado';

      // Verificar se já tem Google vinculado
      final identities = user.identities;
      if (identities != null && identities.any((i) => i.provider == 'google')) {
        throw 'Conta Google já vinculada';
      }

      // NOTA: O Supabase Flutter ainda não tem suporte completo para linkIdentity em mobile
      // Por enquanto, vamos informar ao usuário que ele pode fazer login com Google diretamente
      throw 'Vincular contas não está disponível no momento. Você pode fazer logout e entrar com Google para acessar com ambos os métodos.';

      // TODO: Quando o Supabase Flutter adicionar suporte completo, usar:
      // if (kIsWeb) {
      //   await _supabase.auth.linkIdentity(OAuthProvider.google);
      // } else {
      //   final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      //   if (googleUser == null) return;
      //   final googleAuth = await googleUser.authentication;
      //   if (googleAuth.idToken == null) throw 'Token Google ausente';
      //   // Usar API REST diretamente para linkIdentity
      // }
    } on AuthException catch (e) {
      LogService.auth('Erro ao vincular conta Google', e);
      throw _handleAuthException(e);
    } catch (e) {
      LogService.auth('Erro inesperado ao vincular conta', e);
      rethrow;
    }
  }

  // Obter lista de identidades vinculadas
  List<String> getLinkedProviders() {
    final user = currentUser;
    if (user == null) return [];

    final identities = user.identities;
    if (identities == null || identities.isEmpty) {
      // Se não tem identities, provavelmente é email/password
      return ['email'];
    }

    return identities.map((i) => i.provider).toList();
  }

  // Redefinir senha
  Future<void> redefinirSenha(String email) async {
    try {
      await _supabase.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? 'http://localhost:3000' : 'br.com.rodrigolanes.fizplantao://login-callback/',
      );
      LogService.auth('Email de redefinição de senha enviado: $email');
    } on AuthException catch (e) {
      LogService.auth('Erro ao redefinir senha', e);
      throw _handleAuthException(e);
    } catch (e) {
      LogService.auth('Erro inesperado ao redefinir senha', e);
      throw 'Erro ao redefinir senha: $e';
    }
  }

  // Verificar se o email foi verificado
  bool get emailVerificado {
    final user = currentUser;
    if (user == null) return false;

    // No Supabase, verificamos se emailConfirmedAt não é null
    return user.emailConfirmedAt != null;
  }

  // Recarregar dados do usuário (para atualizar status de verificação)
  Future<void> recarregarUsuario() async {
    try {
      // Supabase atualiza automaticamente o usuário
      // Mas podemos forçar uma atualização fazendo refresh
      await _supabase.refreshSession();
    } catch (e) {
      // Ignorar erros de refresh silenciosamente
    }
  }

  // Enviar email de verificação
  Future<void> enviarEmailVerificacao() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw 'Nenhum usuário logado';
      }
      if (user.emailConfirmedAt != null) {
        throw 'Email já verificado';
      }

      // Reenviar email de confirmação
      await _supabase.resend(
        type: OtpType.signup,
        email: user.email!,
        emailRedirectTo: kIsWeb ? 'http://localhost:3000' : 'br.com.rodrigolanes.fizplantao://login-callback/',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro ao enviar email de verificação: $e';
    }
  }

  // Tratar exceções do Supabase Auth
  String _handleAuthException(AuthException e) {
    // Supabase usa mensagens de erro em inglês por padrão
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials') || message.contains('invalid email or password')) {
      return 'Email ou senha incorretos.';
    } else if (message.contains('user not found')) {
      return 'Usuário não encontrado.';
    } else if (message.contains('email already registered') || message.contains('user already registered')) {
      return 'Este email já está em uso.';
    } else if (message.contains('invalid email')) {
      return 'Email inválido.';
    } else if (message.contains('password') && message.contains('short')) {
      return 'Senha muito fraca. Use no mínimo 6 caracteres.';
    } else if (message.contains('email not confirmed')) {
      return 'Email não confirmado. Verifique sua caixa de entrada.';
    } else if (message.contains('too many requests')) {
      return 'Muitas tentativas. Tente novamente mais tarde.';
    } else {
      return 'Erro ao autenticar: ${e.message}';
    }
  }

  /// Verificar se integração com Google está habilitada
  bool _isGoogleIntegrationEnabled() {
    return ConfigHelper.isGoogleIntegrationEnabled;
  }

  // Obter userId do cache (para uso offline)
  Future<String?> getCachedUserId() async {
    return _hiveConfig.get('userId');
  }

  // Obter email do cache
  Future<String?> getCachedEmail() async {
    return _hiveConfig.get('userEmail');
  }

}
