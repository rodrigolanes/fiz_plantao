            # Configuração Google OAuth - Fiz Plantão

## SHA-1 Fingerprints

### 1. Debug Keystore (desenvolvimento local)
```
SHA-1: BA:BC:1A:37:9A:84:C8:CA:13:4E:8A:8A:9C:4C:B8:32:4E:05:20:EF
```
**Uso:** Builds locais com `flutter run` ou debug APKs

---

### 2. Upload Keystore (sua keystore de assinatura)
```
SHA-1: 4A:41:3D:6E:3C:BE:84:20:A8:4B:DC:90:F9:2B:3F:12:18:48:32:3E
SHA-256: 64:D4:53:17:81:1F:6A:74:70:FC:97:46:6B:E8:37:BF:D0:DC:76:04:EF:92:F4:D6:AA:07:11:DD:39:9A:41:41
```
**Arquivo:** `android/upload-keystore.jks`  
**Alias:** `upload`  
**Uso:** Gerar AAB/APK de release localmente

---

### 3. App Signing Key (Google Play gerenciado) ⚠️ **IMPORTANTE**
```
SHA-1: 7D:CF:C6:99:A4:0B:99:26:E4:94:33:94:AE:75:71:3B:7D:30:9B:8D
```
**Fonte:** Google Play Console → Release → Setup → App Integrity → "App signing key certificate"  
**Uso:** Apps baixados da Play Store (Internal, Closed, Open Testing, Production)

---

## OAuth 2.0 Clients no Google Cloud Console

### Web Application (para autenticação web)
- **Client ID:** `[SEU_WEB_CLIENT_ID].apps.googleusercontent.com`
- **Uso:** Usado como `serverClientId` no código Android

### Android Application
**DEVE conter TODOS os 3 SHA-1 acima:**

1. ✅ Debug: `BA:BC:1A:37...` (desenvolvimento)
2. ✅ Upload: `4A:41:3D:6E...` (builds locais release)  
3. ⚠️ **App Signing: `7D:CF:C6:99...`** ← **ESTE É CRÍTICO PARA PLAY STORE**

**Package name:** `br.com.rodrigolanes.fizplantao`

---

## Por que preciso de 3 SHA-1?

### Fluxo de Assinatura do Android:

1. **Debug local** → usa keystore de debug do Android SDK → SHA-1: `BA:BC:1A:37...`

2. **Release local** → você assina com `upload-keystore.jks` → SHA-1: `4A:41:3D:6E...`

3. **Play Store** → Google re-assina o AAB com chave própria → SHA-1: `7D:CF:C6:99...`

Quando o usuário baixa da Play Store, o app vem assinado com a chave **#3** (Google Play App Signing), não com sua upload keystore!

---

## Como Verificar sua Configuração Atual

### Google Cloud Console
1. Acesse: https://console.cloud.google.com/apis/credentials
2. Encontre o OAuth Client ID do tipo "Android"
3. Verifique quantos SHA-1 estão cadastrados
4. Compare com os 3 fingerprints acima

### Se estiver faltando o App Signing SHA-1:
1. Clique em "Edit" no OAuth Client Android
2. Adicione o fingerprint: `7D:CF:C6:99:A4:0B:99:26:E4:94:33:94:AE:75:71:3B:7D:30:9B:8D`
3. Salve
4. **Aguarde até 30 minutos** para propagação

---

## Solução de Problemas

### "sign_in_failed" na Play Store mas funciona localmente
**Causa:** Falta o SHA-1 da App Signing Key no OAuth Client  
**Solução:** Adicionar SHA-1 `7D:CF:C6:99...` conforme instruções acima

### Como obter SHA-1 da App Signing Key
1. Play Console → Seu App → Release → Setup → App integrity
2. Seção "App signing key certificate"
3. Copiar SHA-1 fingerprint

### Tempo de propagação
Após adicionar/modificar OAuth Client, pode levar até 30 minutos para as mudanças se propagarem nos servidores do Google.

---

## Resumo Rápido

| Ambiente | SHA-1 | Status |
|----------|-------|--------|
| Debug local | `BA:BC:1A:37...` | ✅ Deve estar cadastrado |
| Release local | `4A:41:3D:6E...` | ✅ Deve estar cadastrado |
| Play Store | `7D:CF:C6:99...` | ⚠️ **VERIFICAR SE ESTÁ CADASTRADO** |

---

**Última atualização:** 7 de novembro de 2025
