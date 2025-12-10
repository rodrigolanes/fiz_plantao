# Tratamento de Realtime Errors - Fiz Plantão

## O Erro

```
flutter_error_exception: RealtimeSubscribeException(status: RealtimeSubscribeStatus.channelError, details: null)
```

Este erro ocorre quando o app tenta se conectar aos **Supabase Realtime listeners** e falha. As causas podem ser:

1. **Realtime desabilitado** no Supabase (Project Settings → Add-ons)
2. **RLS (Row Level Security) misconfigured** - app não tem permissão SELECT
3. **Problema de conectividade** - timeout, conexão perdida
4. **Servidor Supabase indisponível** temporariamente

## Solução Implementada

### 1. Error Handlers nos Listeners (sync_service.dart)

```dart
_supabase.from('locais').stream(primaryKey: ['id']).eq('user_id', user.id).listen(
  _handleRemoteLocaisChange,
  onError: (error, stackTrace) {
    LogService.sync('Erro no Realtime listener de Locais', error);
    // Não rethrow - continua funcionando offline
  },
);
```

**Benefício:** O app continua funcionando offline mesmo se Realtime falhar.

### 2. Timeouts em Operações de Sync

```dart
await _downloadRemoteChanges(userId).timeout(
  const Duration(seconds: 20),
  onTimeout: () => throw Exception('Timeout ao baixar mudanças remotas'),
);
```

**Benefício:** Não trava o app em conexões lentas/instáveis.

### 3. Novo Método: syncWithRetry()

```dart
await SyncService.instance.syncWithRetry(maxAttempts: 3);
```

**Como usar em screens:**
```dart
// Após operação crítica (save/delete)
try {
  await DatabaseService.instance.savePlantao(plantao);
  // Tentar sincronizar com retry
  await SyncService.instance.syncWithRetry();
} catch (e) {
  // Mostrar erro ao usuário
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Erro: ${e.toString()}')),
  );
}
```

**Backoff exponencial:** 2s → 4s → 8s entre tentativas.

## Checklist para Produção

- [x] Adicionar error handlers nos Realtime listeners
- [x] Adicionar timeouts nas operações de sync
- [x] Adicionar método de retry com backoff
- [ ] **Verificar RLS no Supabase:**
  - [ ] Tabela `locais`: Habilitar RLS
  - [ ] Tabela `plantoes`: Habilitar RLS
  - [ ] Policy SELECT: `auth.uid() = user_id`
  - [ ] Policy INSERT/UPDATE/DELETE: `auth.uid() = user_id`

## Verificar RLS (Supabase Console)

1. Go to: **Authentication → Policies**
2. Para tabela `locais` e `plantoes`:
   - SELECT: ✅ Habilitado
   - INSERT: ✅ Habilitado
   - UPDATE: ✅ Habilitado
   - DELETE: ✅ Habilitado
   - Todas com `WHERE auth.uid() = user_id`

## Verificar Realtime (Supabase Console)

1. Go to: **Project Settings → Add-ons**
2. **Realtime**: Deve estar "Enabled"
3. Se desabilitado, clicar em "Enable"

## Comportamento Esperado Agora

1. **Se Realtime falha:** App continua funcionando offline ✅
2. **Se sync timeout:** Operação é abortada, não trava ✅
3. **Se operação falha:** Retry automático com backoff ✅
4. **Logs detalhados:** `LogService.sync()` registra todos os erros ✅

## Debug

Para ver logs de sincronização:
```bash
flutter run -v  # Verbose mode
# Procurar por: "Sincronização" ou "Realtime listener"
```

Ou no Firebase Crashlytics:
- Se houver erro crítico, será registrado automaticamente
- Ver em: Firebase Console → Crashlytics

## Próximos Passos (Opcional)

1. **Notificação ao usuário:** Mostrar banner "Offline mode" quando Realtime falhar
2. **Polling fallback:** Sincronizar a cada 5 minutos se Realtime estiver inativo por 30min
3. **Métricas:** Rastrear quantas vezes Realtime falha
