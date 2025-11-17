import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fizplantao/models/local.dart';
import 'package:fizplantao/models/plantao.dart';
import 'package:fizplantao/services/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../helpers/mock_generators.mocks.dart';
import '../mocks/mock_interfaces.dart';

void main() {
  late MockISupabaseClient mockSupabase;
  late MockIConnectivity mockConnectivity;
  late MockIHiveRepository mockHiveRepo;
  late MockBox<Local> mockLocaisBox;
  late MockBox<Plantao> mockPlantoesBox;
  late SyncService syncService;

  setUp(() {
    mockSupabase = MockISupabaseClient();
    mockConnectivity = MockIConnectivity();
    mockHiveRepo = MockIHiveRepository();
    mockLocaisBox = MockBox<Local>();
    mockPlantoesBox = MockBox<Plantao>();

    syncService = SyncService(
      supabase: mockSupabase,
      connectivity: mockConnectivity,
      hiveRepo: mockHiveRepo,
    );
  });

  group('SyncService', () {
    group('Conectividade', () {
      test('deve verificar conectividade antes de sincronizar', () async {
        // Arrange
        when(mockHiveRepo.locaisBox).thenReturn(mockLocaisBox);
        when(mockHiveRepo.plantoesBox).thenReturn(mockPlantoesBox);
        when(mockLocaisBox.values).thenReturn([]);
        when(mockPlantoesBox.values).thenReturn([]);
        when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final mockUser = FakeUser(userId: 'user123', email: 'test@example.com');
        final mockAuth = FakeGoTrueClient(mockUser);
        when(mockSupabase.auth).thenReturn(mockAuth);

        when(mockSupabase.from('locais')).thenAnswer((_) => FakeSupabaseQueryBuilder());
        when(mockSupabase.from('plantoes')).thenAnswer((_) => FakeSupabaseQueryBuilder());

        // Act
        await syncService.syncAll();

        // Assert
        verify(mockConnectivity.checkConnectivity()).called(1);
        expect(syncService.lastSyncTime, isNotNull);
      });

      test('deve lançar exceção quando não houver conectividade', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.none]);

        // Act & Assert
        expect(
          () => syncService.syncAll(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Sincronização concorrente', () {
      test('não deve sincronizar se já estiver sincronizando', () async {
        // Arrange
        when(mockHiveRepo.locaisBox).thenReturn(mockLocaisBox);
        when(mockHiveRepo.plantoesBox).thenReturn(mockPlantoesBox);
        when(mockLocaisBox.values).thenReturn([]);
        when(mockPlantoesBox.values).thenReturn([]);

        final mockUser = FakeUser(userId: 'user123', email: 'test@example.com');
        final mockAuth = FakeGoTrueClient(mockUser);
        when(mockSupabase.auth).thenReturn(mockAuth);
        when(mockSupabase.from('locais')).thenAnswer((_) => FakeSupabaseQueryBuilder());
        when(mockSupabase.from('plantoes')).thenAnswer((_) => FakeSupabaseQueryBuilder());

        when(mockConnectivity.checkConnectivity()).thenAnswer(
          (_) async => Future.delayed(const Duration(milliseconds: 100), () => [ConnectivityResult.wifi]),
        );

        // Act
        final sync1Future = syncService.syncAll();
        final sync2Future = syncService.syncAll();

        await Future.wait([sync1Future, sync2Future]);

        // Assert
        verify(mockConnectivity.checkConnectivity()).called(1);
      });
    });

    group('Estado de sincronização', () {
      test('deve atualizar lastSyncTime após sincronização bem-sucedida', () async {
        // Arrange
        when(mockHiveRepo.locaisBox).thenReturn(mockLocaisBox);
        when(mockHiveRepo.plantoesBox).thenReturn(mockPlantoesBox);
        when(mockLocaisBox.values).thenReturn([]);
        when(mockPlantoesBox.values).thenReturn([]);
        when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final mockUser = FakeUser(userId: 'user123', email: 'test@example.com');
        final mockAuth = FakeGoTrueClient(mockUser);
        when(mockSupabase.auth).thenReturn(mockAuth);
        when(mockSupabase.from('locais')).thenAnswer((_) => FakeSupabaseQueryBuilder());
        when(mockSupabase.from('plantoes')).thenAnswer((_) => FakeSupabaseQueryBuilder());

        expect(syncService.lastSyncTime, isNull);

        // Act
        await syncService.syncAll();

        // Assert
        expect(syncService.lastSyncTime, isNotNull);
        expect(syncService.lastSyncTime!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      });

      test('não deve atualizar lastSyncTime se sincronização falhar', () async {
        // Arrange
        when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.none]);

        expect(syncService.lastSyncTime, isNull);

        // Act
        try {
          await syncService.syncAll();
        } catch (_) {
          // Esperado
        }

        // Assert
        expect(syncService.lastSyncTime, isNull);
      });
    });

    group('Hive Repository', () {
      test('deve acessar boxes do Hive através do repository', () async {
        // Arrange
        when(mockHiveRepo.locaisBox).thenReturn(mockLocaisBox);
        when(mockHiveRepo.plantoesBox).thenReturn(mockPlantoesBox);
        when(mockLocaisBox.values).thenReturn([]);
        when(mockPlantoesBox.values).thenReturn([]);
        when(mockConnectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);

        final mockUser = FakeUser(userId: 'user123', email: 'test@example.com');
        final mockAuth = FakeGoTrueClient(mockUser);
        when(mockSupabase.auth).thenReturn(mockAuth);
        when(mockSupabase.from('locais')).thenAnswer((_) => FakeSupabaseQueryBuilder());
        when(mockSupabase.from('plantoes')).thenAnswer((_) => FakeSupabaseQueryBuilder());

        // Act
        await syncService.syncAll();

        // Assert
        verify(mockHiveRepo.locaisBox).called(greaterThan(0));
        verify(mockHiveRepo.plantoesBox).called(greaterThan(0));
      });
    });
  });
}
