import 'package:fizplantao/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_helpers.dart';
import '../mocks/mock_interfaces.dart';

void main() {
  late MockISupabaseAuth mockSupabase;
  late MockIGoogleSignIn mockGoogleSignIn;
  late MockIHiveConfig mockHiveConfig;
  late AuthService authService;

  setUpAll(() async {
    // Inicializar Hive para testes
    await TestHelpers.initHiveForTest();
    TestHelpers.registerHiveAdapters();
  });

  setUp(() {
    mockSupabase = MockISupabaseAuth();
    mockGoogleSignIn = MockIGoogleSignIn();
    mockHiveConfig = MockIHiveConfig();

    authService = AuthService(
      supabase: mockSupabase,
      googleSignIn: mockGoogleSignIn,
      hiveConfig: mockHiveConfig,
    );
  });

  tearDown(() async {
    // Fechar boxes abertos durante os testes
    try {
      if (Hive.isBoxOpen('plantoes')) await Hive.box('plantoes').close();
      if (Hive.isBoxOpen('locais')) await Hive.box('locais').close();
    } catch (_) {}
  });

  group('AuthService', () {
    group('login', () {
      test('deve fazer login com sucesso e cachear userId', () async {
        // Arrange
        final email = 'test@example.com';
        final senha = 'password123';
        final userId = 'test-user-123';

        when(mockSupabase.signInWithPassword(
          email: email,
          password: senha,
        )).thenAnswer((_) async => FakeAuthResponse(user: FakeUser(userId: userId)));

        // Act
        final response = await authService.login(email, senha);

        // Assert
        expect(response, isNotNull);
        verify(mockHiveConfig.put('userId', userId)).called(1);
        verify(mockHiveConfig.put('userEmail', 'fake@example.com')).called(1);
      });

      test('deve lançar exceção quando credenciais inválidas', () async {
        // Arrange
        final email = 'test@example.com';
        final senha = 'wrongpassword';

        when(mockSupabase.signInWithPassword(
          email: email,
          password: senha,
        )).thenThrow(AuthException('Invalid login credentials'));

        // Act & Assert
        expect(
          () => authService.login(email, senha),
          throwsA(isA<String>()),
        );
      });
    });

    group('cadastrar', () {
      test('deve cadastrar usuário com sucesso', () async {
        // Arrange
        final email = 'newuser@example.com';
        final senha = 'password123';
        final userId = 'new-user-456';

        when(mockSupabase.signUp(
          email: email,
          password: senha,
          emailRedirectTo: argThat(isNotNull, named: 'emailRedirectTo'),
        )).thenAnswer((_) async => FakeAuthResponse(user: FakeUser(userId: userId)));

        // Act
        final response = await authService.cadastrar(email, senha);

        // Assert
        expect(response, isNotNull);
        verify(mockHiveConfig.put('userId', userId)).called(1);
        verify(mockHiveConfig.put('userEmail', 'fake@example.com')).called(1);
      });

      test('deve lançar exceção quando email já existe', () async {
        // Arrange
        final email = 'existing@example.com';
        final senha = 'password123';

        when(mockSupabase.signUp(
          email: email,
          password: senha,
          emailRedirectTo: argThat(isNotNull, named: 'emailRedirectTo'),
        )).thenThrow(AuthException('User already registered'));

        // Act & Assert
        expect(
          () => authService.cadastrar(email, senha),
          throwsA(isA<String>()),
        );
      });
    });

    group('logout', () {
      test('deve fazer logout e limpar dados locais', () async {
        // Arrange
        when(mockSupabase.signOut()).thenAnswer((_) async {});
        when(mockGoogleSignIn.signOut()).thenAnswer((_) async {});
        when(mockHiveConfig.clear()).thenAnswer((_) async {});

        // Act
        await authService.logout();

        // Assert
        verify(mockSupabase.signOut()).called(1);
        verify(mockGoogleSignIn.signOut()).called(1);
        verify(mockHiveConfig.clear()).called(1);
      });
    });

    group('userId getter', () {
      test('deve retornar userId do usuário atual', () {
        // Arrange
        when(mockSupabase.currentUser).thenReturn(FakeUser());

        // Act
        final userId = authService.currentUserId;

        // Assert
        expect(userId, isNotNull);
      });

      test('deve retornar null quando não há usuário logado', () {
        // Arrange
        when(mockSupabase.currentUser).thenReturn(null);

        // Act
        final userId = authService.currentUserId;

        // Assert
        expect(userId, isNull);
      });

      test('deve retornar override userId quando definido (para testes)', () {
        // Arrange
        authService.testUserId = 'override-user-id';

        // Act
        final userId = authService.currentUserId;

        // Assert
        expect(userId, equals('override-user-id'));

        // Cleanup
        authService.clearTestOverride();
      });
    });

    group('emailVerificado', () {
      test('deve retornar false quando email não está verificado', () {
        // Arrange
        when(mockSupabase.currentUser).thenReturn(FakeUser());

        // Act
        final verificado = authService.emailVerificado;

        // Assert
        expect(verificado, isFalse); // FakeUser tem emailConfirmedAt null
      });

      test('deve retornar false quando não há usuário', () {
        // Arrange
        when(mockSupabase.currentUser).thenReturn(null);

        // Act
        final verificado = authService.emailVerificado;

        // Assert
        expect(verificado, isFalse);
      });
    });

    group('getCachedUserId', () {
      test('deve retornar userId do cache', () async {
        // Arrange
        when(mockHiveConfig.get('userId')).thenReturn('cached-user-id');

        // Act
        final userId = await authService.getCachedUserId();

        // Assert
        expect(userId, equals('cached-user-id'));
      });
    });
  });
}
