import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream do estado de autenticação
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  static User? get currentUser => _auth.currentUser;

  // Verificar se está logado
  static bool get isLoggedIn => currentUser != null;

  // Obter userId
  static String? get userId => currentUser?.uid;

  // Login com email e senha
  static Future<UserCredential?> login(String email, String senha) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Salvar userId no Hive para cache
      if (credential.user != null) {
        final box = await Hive.openBox('config');
        await box.put('userId', credential.user!.uid);
        await box.put('userEmail', credential.user!.email);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Cadastro com email e senha
  static Future<UserCredential?> cadastrar(String email, String senha) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Salvar userId no Hive para cache
      if (credential.user != null) {
        final box = await Hive.openBox('config');
        await box.put('userId', credential.user!.uid);
        await box.put('userEmail', credential.user!.email);

        // Enviar email de verificação automaticamente
        await credential.user!.sendEmailVerification();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Logout
  static Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();

    // Limpar cache do Hive
    final box = await Hive.openBox('config');
    await box.delete('userId');
    await box.delete('userEmail');
  }

  // Login com Google
  static Future<UserCredential?> loginComGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // O usuário cancelou o login
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Salvar userId no Hive para cache
      if (userCredential.user != null) {
        final box = await Hive.openBox('config');
        await box.put('userId', userCredential.user!.uid);
        await box.put('userEmail', userCredential.user!.email);
      }

      return userCredential;
    } catch (e) {
      throw 'Erro ao fazer login com Google: $e';
    }
  }

  // Redefinir senha
  static Future<void> redefinirSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Verificar se o email foi verificado
  static bool get emailVerificado {
    return currentUser?.emailVerified ?? false;
  }

  // Recarregar dados do usuário (para atualizar status de verificação)
  static Future<void> recarregarUsuario() async {
    await currentUser?.reload();
  }

  // Enviar email de verificação
  static Future<void> enviarEmailVerificacao() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw 'Nenhum usuário logado';
      }
      if (user.emailVerified) {
        throw 'Email já verificado';
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Tratar exceções do Firebase Auth
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      case 'email-already-in-use':
        return 'Este email já está em uso.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'weak-password':
        return 'Senha muito fraca. Use no mínimo 6 caracteres.';
      case 'user-disabled':
        return 'Usuário desabilitado.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      default:
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
