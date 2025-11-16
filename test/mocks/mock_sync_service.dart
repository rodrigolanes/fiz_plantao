/// Mock do SyncService para testes
/// Evita chamadas ao Supabase durante execução de testes unitários
class MockSyncService {
  /// Sincronização mock - não faz nada
  static Future<void> syncAll() async {
    // Mock: retorna sucesso sem executar operações reais
    return Future.value();
  }

  /// Upload mock - não faz nada
  static Future<void> uploadLocalData() async {
    return Future.value();
  }

  /// Download mock - não faz nada
  static Future<void> downloadRemoteData() async {
    return Future.value();
  }
}
