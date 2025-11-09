import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' show CalendarApi;
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'log_service.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      CalendarApi.calendarScope, // Acesso ao Google Calendar
    ],
    // Web Client ID é necessário no Android para obter idToken
    serverClientId: kIsWeb ? null : SupabaseConfig.googleWebClientId,
  );

  // Stream do estado de autenticação
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Usuário atual
  static User? get currentUser => _supabase.auth.currentUser;

  // Verificar se está logado
  static bool get isLoggedIn => currentUser != null;

  // Override de userId para testes (quando definido, tem precedência)
  static String? _overrideUserId;

  // Obter userId (UUID do Supabase) com suporte a override em testes
  static String? get userId => _overrideUserId ?? currentUser?.id;

  // Setter exposto para testes: permite definir um userId fake durante o teste
  // Em produção, não utilizar este setter.
  static set userId(String? value) {
    _overrideUserId = value;
  }

  // Limpar override (útil em suites de teste)
  static void clearTestOverride() {
    _overrideUserId = null;
  }

  // Login com email e senha
  static Future<AuthResponse?> login(String email, String senha) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      // Salvar userId no Hive para cache
      if (response.user != null) {
        final box = await Hive.openBox('config');
        await box.put('userId', response.user!.id);
        await box.put('userEmail', response.user!.email);
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
  static Future<AuthResponse?> cadastrar(String email, String senha) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: senha,
        emailRedirectTo: kIsWeb ? 'http://localhost:3000' : 'br.com.rodrigolanes.fizplantao://login-callback/',
      );

      // Salvar userId no Hive para cache
      if (response.user != null) {
        final box = await Hive.openBox('config');
        await box.put('userId', response.user!.id);
        await box.put('userEmail', response.user!.email);
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
  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      await _googleSignIn.signOut();

      // Limpar cache do Hive
      final box = await Hive.openBox('config');
      await box.delete('userId');
      await box.delete('userEmail');
      LogService.auth('Logout realizado');
    } catch (e) {
      LogService.auth('Erro ao fazer logout', e);
      throw 'Erro ao fazer logout: $e';
    }
  }

  // Login com Google
  static Future<AuthResponse?> loginComGoogle() async {
    try {
      if (kIsWeb) {
        // Web retorna bool (redirect/popup). Sessão chega via onAuthStateChange.
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? 'http://localhost:3000' : null,
          queryParams: {
            'access_type': 'offline',
            'prompt': 'consent',
          },
        );
        return null;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null; // cancelado

        final googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null) throw 'Token Google ausente';

        final response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
        );

        if (response.user != null) {
          final box = await Hive.openBox('config');
          await box.put('userId', response.user!.id);
          await box.put('userEmail', response.user!.email);
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
  static Future<void> linkGoogleAccount() async {
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
  static List<String> getLinkedProviders() {
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
  static Future<void> redefinirSenha(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
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
  static bool get emailVerificado {
    final user = currentUser;
    if (user == null) return false;

    // No Supabase, verificamos se emailConfirmedAt não é null
    return user.emailConfirmedAt != null;
  }

  // Recarregar dados do usuário (para atualizar status de verificação)
  static Future<void> recarregarUsuario() async {
    try {
      // Supabase atualiza automaticamente o usuário
      // Mas podemos forçar uma atualização fazendo refresh
      await _supabase.auth.refreshSession();
    } catch (e) {
      // Ignorar erros de refresh silenciosamente
    }
  }

  // Enviar email de verificação
  static Future<void> enviarEmailVerificacao() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw 'Nenhum usuário logado';
      }
      if (user.emailConfirmedAt != null) {
        throw 'Email já verificado';
      }

      // Reenviar email de confirmação
      await _supabase.auth.resend(
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
  static String _handleAuthException(AuthException e) {
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

  // Obter userId do cache (para uso offline)
  static Future<String?> getCachedUserId() async {
    final box = await Hive.openBox('config');
    return box.get('userId');
  }

  // Obter email do cache
  static Future<String?> getCachedEmail() async {
    final box = await Hive.openBox('config');
    return box.get('userEmail');
  }
}
