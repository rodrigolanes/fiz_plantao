import 'dart:io';

import 'package:fizplantao/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../mocks/mock_sync_service.dart';

/// Helpers para configuração de testes
class TestHelpers {
  /// Inicializa ambiente de teste com Hive
  static Future<Directory> initHiveForTest() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final hiveTempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(hiveTempDir.path);

    return hiveTempDir;
  }

  /// Registra adapters do Hive se ainda não registrados
  static void registerHiveAdapters() {
    // Importações dinâmicas para evitar erros se adapters já registrados
    try {
      if (!Hive.isAdapterRegistered(0)) {
        // Local adapter
        final localAdapter = _getAdapter('LocalAdapter');
        if (localAdapter != null) Hive.registerAdapter(localAdapter);
      }
      if (!Hive.isAdapterRegistered(1)) {
        // Plantao adapter
        final plantaoAdapter = _getAdapter('PlantaoAdapter');
        if (plantaoAdapter != null) Hive.registerAdapter(plantaoAdapter);
      }
      if (!Hive.isAdapterRegistered(2)) {
        // Duracao adapter
        final duracaoAdapter = _getAdapter('DuracaoAdapter');
        if (duracaoAdapter != null) Hive.registerAdapter(duracaoAdapter);
      }
    } catch (_) {
      // Adapters já registrados, ignora
    }
  }

  static dynamic _getAdapter(String adapterName) {
    // Placeholder - adapters devem ser registrados manualmente nos testes
    return null;
  }

  /// Configura mock do AuthService
  static void setupAuthMock(String userId) {
    AuthService.userId = userId;
  }

  /// Configura ambiente de teste completo
  static Future<TestEnvironment> setupTestEnvironment({
    required String userId,
  }) async {
    final hiveTempDir = await initHiveForTest();

    setupAuthMock(userId);

    // Desabilita Calendar sync
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }
    await Hive.box('settings').put('calendar_sync_enabled', false);

    return TestEnvironment(
      hiveTempDir: hiveTempDir,
      syncService: MockSyncService(),
    );
  }

  /// Limpa ambiente de teste
  static Future<void> cleanupTestEnvironment(TestEnvironment env) async {
    try {
      if (env.hiveTempDir.existsSync()) {
        await env.hiveTempDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignora erros de cleanup
    }
  }
}

/// Ambiente de teste configurado
class TestEnvironment {
  final Directory hiveTempDir;
  final MockSyncService syncService;

  TestEnvironment({
    required this.hiveTempDir,
    required this.syncService,
  });
}
