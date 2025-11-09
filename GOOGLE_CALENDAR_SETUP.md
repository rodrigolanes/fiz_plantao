# Configuração Google Calendar - Fiz Plantão

## 🎯 Objetivo
Configurar autenticação Google para permitir sincronização com Google Calendar no Android.

## 📝 Pré-requisitos
- Conta Google/Firebase
- Android Studio ou keytool instalado

---

## 🔧 Passo a Passo Completo

### 1️⃣ Gerar SHA-1 Fingerprint

Execute no terminal (na pasta raiz do projeto):

```powershell
# Opção 1: Via Gradle
cd android
./gradlew signingReport

# Opção 2: Via keytool (debug keystore)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

📋 Copie o **SHA-1** que aparece (formato: `AA:BB:CC:DD:EE:...`)

---

### 2️⃣ Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Selecione seu projeto ou crie um novo:
   - Nome: **Fiz Plantão**
   - Plano: Gratuito (Spark)

3. No Dashboard do projeto, clique em **Adicionar app** → Ícone do Android

4. Preencha o formulário:
   ```
   Package name: br.com.rodrigolanes.fizplantao
   App nickname: Fiz Plantão (opcional)
   SHA-1: [Cole o SHA-1 copiado no passo 1]
   ```

5. Clique em **Registrar app**

---

### 3️⃣ Baixar google-services.json

1. No Firebase Console, após registrar o app, clique em **Baixar google-services.json**
2. Copie o arquivo baixado para:
   ```
   android/app/google-services.json
   ```

**⚠️ IMPORTANTE:** 
- O arquivo DEVE estar em `android/app/` (não `android/`)
- NÃO commite este arquivo (já está no .gitignore)

---

### 4️⃣ Google Cloud Console - Habilitar APIs

1. Acesse: https://console.cloud.google.com/
2. Selecione o projeto do Firebase (mesmo nome)
3. Vá em **APIs & Services** → **Library**
4. Busque e habilite:
   - ✅ **Google Calendar API**
   - ✅ **Google Sign-In API** (já deve estar habilitada)

---

### 5️⃣ Configurar OAuth Consent Screen

1. No Google Cloud Console, vá em **APIs & Services** → **OAuth consent screen**
2. Escolha **External** (para testes) ou **Internal** (se tiver Google Workspace)
3. Preencha:
   ```
   App name: Fiz Plantão
   User support email: [seu email]
   Developer contact: [seu email]
   ```
4. Clique em **Save and Continue**
5. Em **Scopes**, clique em **Add or Remove Scopes**:
   - Adicione: `https://www.googleapis.com/auth/calendar`
   - Adicione: `https://www.googleapis.com/auth/calendar.events`
6. Salve e continue
7. Em **Test users** (se External), adicione seu email de teste

---

### 6️⃣ Criar OAuth 2.0 Client IDs

1. No Google Cloud Console, vá em **APIs & Services** → **Credentials**
2. Clique em **+ Create Credentials** → **OAuth client ID**

#### 6.1 Android Client (para o app mobile)
```
Application type: Android
Name: Fiz Plantão Android
Package name: br.com.rodrigolanes.fizplantao
SHA-1: [Cole o SHA-1 do passo 1]
```
Clique em **Create**

#### 6.2 Web Client (para o Flutter)
```
Application type: Web application
Name: Fiz Plantão Web Client
Authorized redirect URIs: (deixe vazio por enquanto)
```
Clique em **Create**

📋 **Copie o Web Client ID** (formato: `123456789-abc.apps.googleusercontent.com`)

---

### 7️⃣ Atualizar Código com Web Client ID

Abra `lib/config/supabase_config.dart` e atualize:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://seu-projeto.supabase.co';
  static const String supabaseAnonKey = 'sua-anon-key';
  
  // Adicione esta linha com seu Web Client ID:
  static const String googleWebClientId = 'SEU-WEB-CLIENT-ID.apps.googleusercontent.com';
}
```

---

## ✅ Verificar Configuração

### Estrutura de arquivos esperada:
```
android/
├── app/
│   ├── google-services.json  ← DEVE EXISTIR
│   └── build.gradle.kts       ← Configurado com plugin
└── build.gradle.kts           ← Configurado com classpath
```

### Testar:
```powershell
flutter clean
flutter pub get
cd android
./gradlew app:assembleDebug
```

Se compilar sem erros, está OK! 🎉

---

## 🐛 Troubleshooting

### Erro 12500 - Sign in failed
**Causa:** SHA-1 não configurado ou incorreto
**Solução:** 
1. Verifique se o SHA-1 no Firebase Console é o mesmo do comando keytool
2. Aguarde 5-10 minutos após adicionar SHA-1 (propagação)

### google-services.json not found
**Causa:** Arquivo no lugar errado ou não existe
**Solução:** Certifique-se que está em `android/app/google-services.json`

### API not enabled
**Causa:** Google Calendar API não habilitada
**Solução:** Habilite no Google Cloud Console → APIs & Services → Library

### OAuth consent screen not configured
**Causa:** Tela de consentimento não configurada
**Solução:** Configure no Google Cloud Console (passo 5)

---

## 📚 Referências

- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Google Calendar API](https://developers.google.com/calendar/api/guides/overview)

---

**Última atualização:** Novembro 2025
