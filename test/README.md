# Testes - Fiz Plantão

## Estrutura de Testes

```
test/
├── helpers/           # Utilitários para configuração de testes
│   └── test_helpers.dart
├── mocks/            # Mocks de serviços externos
│   └── mock_sync_service.dart
├── models/           # Testes de modelos de dados
│   ├── local_test.dart
│   └── plantao_test.dart
└── services/         # Testes de serviços
    └── database_service_test.dart
```

## Mocks Disponíveis

### MockSyncService

Mock do `SyncService` que evita chamadas reais ao Supabase durante testes unitários.

**Uso:**
```dart
import '../mocks/mock_sync_service.dart';

// Todos os métodos retornam Future<void> sem executar operações
await MockSyncService.syncAll();
await MockSyncService.uploadLocalData();
await MockSyncService.downloadRemoteData();
```

## Helpers de Teste

### TestHelpers

Classe com métodos utilitários para configurar ambiente de teste.

**Configuração completa do ambiente:**
```dart
import '../helpers/test_helpers.dart';

setUp(() async {
  // Configura Hive, AuthService e desabilita Calendar sync
  await TestHelpers.setupTestEnvironment(userId: 'test-user-123');
});
```

**Métodos disponíveis:**

- `initHiveForTest()` - Inicializa Hive em diretório temporário
- `registerHiveAdapters()` - Registra adapters do Hive
- `setupAuthMock(userId)` - Configura mock do AuthService
- `setupTestEnvironment(userId)` - Setup completo (recomendado)
- `cleanupTestEnvironment(env)` - Limpa ambiente após testes

## Padrões de Teste

### Setup e Teardown

```dart
setUpAll(() async {
  // Inicialização única para todos os testes do grupo
  TestWidgetsFlutterBinding.ensureInitialized();
  hiveTempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(hiveTempDir.path);
});

setUp(() async {
  // Configuração antes de cada teste
  await TestHelpers.setupTestEnvironment(userId: userId);
});

tearDown(() async {
  // Limpeza após cada teste
  await locaisBox.clear();
  await plantoesBox.clear();
});

tearDownAll(() async {
  // Limpeza final
  if (hiveTempDir.existsSync()) {
    await hiveTempDir.delete(recursive: true);
  }
});
```

### Desabilitando Sincronização

O Calendar sync é automaticamente desabilitado pelo `TestHelpers.setupTestEnvironment()`.

Para desabilitar manualmente:
```dart
if (!Hive.isBoxOpen('settings')) {
  await Hive.openBox('settings');
}
await Hive.box('settings').put('calendar_sync_enabled', false);
```

## Boas Práticas

1. **Isolamento**: Cada teste deve ser independente
2. **Limpeza**: Sempre limpar dados entre testes
3. **Mocks**: Usar mocks para dependências externas (Supabase, Google Calendar)
4. **Diretórios temporários**: Usar `Directory.systemTemp` para Hive
5. **Naming**: Nomes descritivos que explicam o que está sendo testado

## Executando Testes

```bash
# Todos os testes
flutter test

# Teste específico
flutter test test/services/database_service_test.dart

# Com output detalhado
flutter test --reporter expanded

# Com coverage
flutter test --coverage
```

## Troubleshooting

### MissingPluginException

Se aparecer erro de plugin não encontrado:
- ✅ Certifique-se de usar `TestHelpers.setupTestEnvironment()`
- ✅ Calendar sync deve estar desabilitado
- ✅ Erros do Supabase são esperados e capturados pelo `.catchError()`

### Erro de Hive Adapter

Se aparecer erro de adapter não registrado:
- ✅ Registre adapters no `setUpAll()`
- ✅ Use `Hive.isAdapterRegistered(typeId)` antes de registrar

### Erro de Box não aberto

- ✅ Abra boxes necessários no `setUp()`
- ✅ Verifique se `Hive.init()` foi chamado
