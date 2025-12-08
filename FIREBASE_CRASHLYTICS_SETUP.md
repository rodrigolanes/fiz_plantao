# Firebase Crashlytics - Guia de Configuração

## Visão Geral

O Firebase Crashlytics está configurado no **Fiz Plantão** para capturar e reportar erros em produção automaticamente. Isso permite diagnosticar problemas reportados por usuários com stack traces completos e informações de contexto.

## ✅ O que já está configurado

### 1. Dependências (pubspec.yaml)
```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_crashlytics: ^4.2.0
```

### 2. Inicialização (main.dart)
- ✅ Firebase inicializado antes do app
- ✅ Captura automática de erros Flutter (`FlutterError.onError`)
- ✅ Captura de erros assíncronos não tratados (`PlatformDispatcher.onError`)
- ✅ Zona protegida (`runZonedGuarded`) para capturar todos os erros

### 3. Instrumentação (DatabaseService)
Métodos críticos instrumentados com try-catch + Crashlytics:
- ✅ `savePlantao()` - Erros ao salvar plantão
- ✅ `updatePlantao()` - Erros ao atualizar plantão
- ✅ `deletePlantao()` - Erros ao deletar plantão (causa do bug reportado)

Cada erro registrado inclui:
- **Reason**: Descrição do erro
- **Information**: Contexto adicional (userId, plantaoId, localNome)
- **Stack trace**: Completo para debugging

### 4. CI/CD
- ✅ `google-services.json` configurado nos workflows
- ✅ Símbolos de debug enviados automaticamente durante o build
- ✅ Firebase conectado ao projeto via `GOOGLE_SERVICES_JSON` secret

## 🔍 Como usar o Crashlytics

### Acessar o Console

1. Acesse: [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto "Fiz Plantão"
3. Vá em **Crashlytics** no menu lateral
4. Visualize crashes agrupados por tipo

### Interpretar um Crash

Cada crash mostra:

**Informações Básicas:**
- Quantidade de usuários afetados
- Número de ocorrências
- Primeira e última ocorrência

**Stack Trace:**
- Caminho completo do erro (arquivo:linha)
- Método onde ocorreu
- Chain de chamadas

**Contexto Personalizado:**
- `userId`: ID do usuário que teve o erro
- `plantaoId`: ID do plantão (quando aplicável)
- `localNome`: Nome do local (quando aplicável)

**Device Info:**
- Modelo do dispositivo
- Versão do Android
- RAM/Storage disponível
- Versão do app

### Exemplo de Crash: Erro ao Deletar Plantão

```
Reason: Erro ao deletar plantão ID: abc123xyz
Information:
  - userId: user_456
  - plantaoId: abc123xyz

Stack Trace:
#0 DatabaseService.deletePlantao (database_service.dart:260)
#1 _ListaPlantoesScreenState._deletePlantao (lista_plantoes_screen.dart:85)
...
```

## 🛠️ Debugging com Crashlytics

### Forçar um Crash (Teste)

Para testar se está funcionando:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Forçar crash
FirebaseCrashlytics.instance.crash();

// Ou registrar erro não-fatal
try {
  throw Exception('Erro de teste');
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
}
```

### Logs Personalizados

Adicionar breadcrumbs para rastrear ações:

```dart
FirebaseCrashlytics.instance.log('Usuário clicou em salvar plantão');
```

### Identificar Usuário

Já configurado automaticamente nos métodos do DatabaseService:

```dart
FirebaseCrashlytics.instance.setUserIdentifier(userId);
```

### Custom Keys

Adicionar mais contexto:

```dart
FirebaseCrashlytics.instance.setCustomKey('plantao_local', 'Hospital XYZ');
FirebaseCrashlytics.instance.setCustomKey('is_synced', true);
```

## 📊 Monitoramento

### Alertas

Configure alertas no Firebase Console:
1. Crashlytics → Settings → Email Alerts
2. Ative "New issues" e "Regressed issues"
3. Configure threshold (ex: notificar se > 5 crashes/hora)

### Velocidade do Crash

- **Fatal crashes**: Aparecem em ~5 minutos
- **Non-fatal errors**: Batch enviado a cada 30 minutos ou quando app fecha

### Versões

Crashlytics rastreia por versão do app:
- Veja crashes específicos de `1.8.3` vs `1.9.0`
- Identifique regressões após deploy

## 🔒 Privacidade

### Dados Coletados

- ❌ **NÃO coleta**: Dados de plantões, valores, nomes de locais (apenas em contexto de erro)
- ✅ **Coleta**: Stack traces, device info, versão do app, userId (hash)

### LGPD/GDPR

- Crashlytics é GDPR compliant
- Dados anonimizados após 180 dias
- Usuários podem solicitar exclusão via Firebase Console

## 🚀 Próximos Passos

### Melhorias Futuras

1. **Performance Monitoring**
   - Adicionar Firebase Performance para rastrear lentidão
   - Monitorar tempo de sync, save, delete

2. **Analytics Integration**
   - Correlacionar crashes com eventos de Analytics
   - Ver jornada do usuário antes do crash

3. **Alertas Avançados**
   - Integrar com Slack/Discord para notificações
   - Dashboard customizado com métricas

## 📚 Referências

- [Firebase Crashlytics Docs](https://firebase.google.com/docs/crashlytics)
- [Flutter Crashlytics Plugin](https://pub.dev/packages/firebase_crashlytics)
- [Best Practices](https://firebase.google.com/docs/crashlytics/best-practices)

## 🆘 Troubleshooting

### Crashes não aparecem no console

1. Verificar `google-services.json` está correto
2. Confirmar que app está em modo release (`flutter build`)
3. Aguardar até 5 minutos para aparecer
4. Verificar conexão com internet do dispositivo

### Símbolos não desobfuscados

1. Confirmar que `mappingFile` está no upload do Play Store
2. Verificar que build foi feito com `--release`
3. Re-upload dos símbolos se necessário

### Erros não capturados

1. Confirmar que método tem `try-catch`
2. Verificar que `rethrow` está presente (para UI tratar também)
3. Checar se `FlutterError.onError` está configurado

---

**Última atualização:** Dezembro 2024  
**Versão mínima do app com Crashlytics:** 1.9.0
