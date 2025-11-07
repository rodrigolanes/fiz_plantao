import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Stream do estado de autenticação
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Usuário atual
  static User? get currentUser => _supabase.auth.currentUser;

  // Verificar se está logado
  static bool get isLoggedIn => currentUser != null;

  // Obter userId (UUID do Supabase)
  static String? get userId => currentUser?.id;

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
      }

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro ao fazer login: $e';
    }
  }

  // Cadastro com email e senha
  static Future<AuthResponse?> cadastrar(String email, String senha) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: senha,
      );

      // Salvar userId no Hive para cache
      if (response.user != null) {
        final box = await Hive.openBox('config');
        await box.put('userId', response.user!.id);
        await box.put('userEmail', response.user!.email);
      }

      // Nota: Supabase envia email de confirmação automaticamente
      // se configurado em Authentication > Email Templates

      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
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
    } catch (e) {
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
        }
        return response;
      }
    } catch (e) {
      throw 'Erro ao fazer login com Google: $e';
    }
  }

  // Redefinir senha
  static Future<void> redefinirSenha(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
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
