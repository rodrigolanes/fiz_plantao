# 🚀 Guia de Configuração - Supabase + GitHub Actions

Este guia contém todos os passos necessários para configurar o Supabase e os secrets do GitHub Actions para o projeto **Fiz Plantão**.

---

## 📋 Índice

1. [Configurar Supabase](#1-configurar-supabase)
2. [Configurar Autenticação Google](#2-configurar-autenticação-google)
3. [Configurar o Projeto Local](#3-configurar-o-projeto-local)
4. [Configurar GitHub Actions Secrets](#4-configurar-github-actions-secrets)
5. [Testar a Configuração](#5-testar-a-configuração)

---

## 1. 🗄️ Configurar Supabase

### 1.1 Criar Conta e Projeto

1. Acesse [supabase.com](https://supabase.com)
2. Clique em **"Start your project"** e faça login (GitHub recomendado)
3. Clique em **"New Project"**
4. Preencha:
   - **Name:** `fiz-plantao` (ou outro nome de sua escolha)
   - **Database Password:** Gere uma senha forte e **SALVE EM LOCAL SEGURO**
   - **Region:** `South America (São Paulo)` (mais próxima do Brasil)
   - **Pricing Plan:** Free
5. Clique em **"Create new project"**
6. Aguarde 2-3 minutos para provisionamento

### 1.2 Obter Credenciais

Após o projeto ser criado:

1. No menu lateral, vá em **Settings** (ícone de engrenagem)
2. Clique em **API**
3. Anote as seguintes informações:

```
📝 Anote aqui:
──────────────────────────────────────
Project URL: https://____________.supabase.co
anon public key: eyJhbGci____________ (começa com eyJ)
service_role key: eyJhbGci____________ (NUNCA commite!)
──────────────────────────────────────
```

⚠️ **IMPORTANTE:** 
- `anon public` = Vai no código (seguro expor)
- `service_role` = NUNCA commitar, só em secrets

### 1.3 Criar Tabelas no Banco de Dados

1. No menu lateral do Supabase, clique em **SQL Editor**
2. Clique em **"New query"**
3. Copie **TODO** o conteúdo do arquivo `supabase_migration.sql` (na raiz do projeto)
4. Cole no editor SQL
5. Clique em **"Run"** (ou pressione `Ctrl+Enter`)
6. Aguarde a execução (deve aparecer "Success. No rows returned")

✅ **Verificar se funcionou:**
- Vá em **Table Editor** no menu lateral
- Você deve ver 2 tabelas: `locais` e `plantoes`
- Clique em cada uma para verificar as colunas

---

## 2. 🔐 Configurar Autenticação Google

### 2.1 Criar Projeto no Google Cloud Console

1. Acesse [console.cloud.google.com](https://console.cloud.google.com)
2. Crie um novo projeto ou selecione um existente
3. Nome sugerido: `Fiz Plantão`

### 2.2 Habilitar Google Sign-In API

1. No menu lateral, vá em **APIs & Services** > **Library**
2. Busque por **"Google Sign-In"** ou **"Google+ API"**
3. Clique em **"Enable"**

### 2.3 Configurar OAuth Consent Screen

Se você NÃO encontrou o menu indicado, siga estas orientações detalhadas (a Google muda a UI com frequência):

#### 2.3.1 Confirmar que um projeto está selecionado
No topo da página do Google Cloud Console verifique se há um nome de projeto. Se aparecer "Select a project" você precisa escolher o projeto criado (ex: `Fiz Plantão`).

#### 2.3.2 Caminhos possíveis na interface
Existem três variações atuais da navegação:
1. Menu lateral direto: **APIs & Services** > **OAuth consent screen**
2. Se não aparecer, clique em **More products** (ou "+ Enable APIs and Services") e depois em **APIs & Services**.
3. Se você veio a partir do Firebase Console: Clique em **Project Settings** (ícone engrenagem) > aba **Integrations** > botão **Manage in Google Cloud Console** (ou link para "Google Cloud Platform") e então siga o caminho da opção 1.

#### 2.3.3 Primeira vez vs já configurado
- Se for a PRIMEIRA vez, você verá a tela pedindo para escolher o tipo do User Type.
- Se você JÁ configurou antes, verá diretamente o resumo do consent screen. Nesse caso procure um botão **Edit App** (ou "Editar") no topo para alterar.
- Se aparece um botão **Configure consent screen** dentro de **APIs & Services > Credentials**, clique nele — esse atalho substitui o menu direto em alguns layouts.

#### 2.3.4 Selecionar o tipo
Escolha **External** (permite qualquer usuário com conta Google). Clique em **Create** ou **Save and Continue** conforme a UI.

#### 2.3.5 Preencher informações básicas
- App name: `Fiz Plantão`
- User support email: seu email
- Developer contact information: seu email
Clique em **Save and Continue**.

#### 2.3.6 Scopes
Na página de Scopes:
- Clique em **Add or Remove Scopes**
- Marque os básicos (se não vierem marcados):
  - `.../auth/userinfo.email`
  - `.../auth/userinfo.profile`
  - `openid`
- Salve e Continue.

#### 2.3.7 Test Users (opcional no modo External)
Se ainda estiver em modo de testes (status: Testing), adicione seu email em **Test users** para conseguir usar antes de publicar. Depois clique em **Save and Continue**.

#### 2.3.8 Revisar e publicar (opcional)
Na última etapa revise. Você pode deixar em modo Testing (suficiente para desenvolvimento). Para liberar para qualquer usuário futuramente, clique em **Publish App** quando estiver pronto.

#### 2.3.9 Caso o menu realmente não apareça
Verifique:
- Permissões: precisa estar como Owner ou Editor do projeto.
- URL direta: acesse `https://console.cloud.google.com/apis/credentials/consent?project=SEU_PROJECT_ID`
- Limpar cache do navegador ou usar janela anônima.
- Garantir que não está logado em conta corporativa com restrições.

> Depois de concluído, prossiga para criar o OAuth Client (próxima seção). Se algo ainda não aparecer, me informe exatamente qual tela você vê que eu adapto novamente.

### 2.4 Criar OAuth Client ID

1. Vá em **APIs & Services** > **Credentials**
2. Clique em **"Create Credentials"** > **"OAuth client ID"**
3. Escolha **"Web application"**
4. Preencha:
   - **Name:** `Fiz Plantão Web`
   - **Authorized JavaScript origins:**
     ```
     https://SEU_PROJETO_ID.supabase.co
     ```
   - **Authorized redirect URIs:**
     ```
     https://SEU_PROJETO_ID.supabase.co/auth/v1/callback
     ```
   ⚠️ **Substitua `SEU_PROJETO_ID`** pelo ID do seu projeto Supabase!

5. Clique em **"Create"**
6. **Anote o Client ID e Client Secret:**

```
📝 Anote aqui:
──────────────────────────────────────
Google Client ID: ____________.apps.googleusercontent.com
Google Client Secret: GOCSPX-____________
──────────────────────────────────────
```

### 2.5 Configurar Google no Supabase

1. Volte ao Supabase
2. Vá em **Authentication** > **Providers**
3. Clique em **"Google"**
4. Ative o toggle **"Enable Sign in with Google"**
5. Cole:
   - **Client ID:** (do passo anterior)
   - **Client Secret:** (do passo anterior)
6. Clique em **"Save"**

### 2.5.1 Verificar Callback no Supabase

O Supabase já expõe a rota de callback padrão `/auth/v1/callback`. Não é necessário adicionar outra. O fluxo Web usará exatamente esse endpoint.

### 2.5.2 Diferença entre Web e Mobile

- Web: usa `signInWithOAuth(Provider.google)` que abre uma nova janela e redireciona para `https://SEU_PROJETO_ID.supabase.co/auth/v1/callback`.
- Mobile (Android/iOS): usa o plugin `google_sign_in` para obter `idToken` e `accessToken` localmente e depois troca por sessão via `supabase.auth.signInWithIdToken`.

### 2.5.3 Erros Comuns

| Sintoma | Causa Provável | Correção |
|--------|-----------------|----------|
| 404 no login Google (Web) | Redirect URI não cadastrado | Confirmar URI exata no OAuth Web: `https://SEU_PROJETO_ID.supabase.co/auth/v1/callback` |
| Popup fecha sem login | Consent Screen incompleto | Publicar/Salvar Consent Screen e adicionar escopos básicos |
| Token ausente (mobile) | Falta SHA-1 no OAuth Android | Adicionar SHA-1 do keystore de release/debug no Google Cloud |
| "access denied" | Provider Google não ativado no Supabase | Ativar em Authentication > Providers |
| Loop de login | Cookies bloqueados no navegador | Permitir third-party cookies ou usar outro navegador |

### 2.5.4 Checklist Pós Configuração

```
☑ Consent Screen em modo Testing ou Published
☑ OAuth Client Web com redirect callback correto
☑ OAuth Client Android com package + SHA-1
☑ Provider Google ativado no Supabase
☑ Fluxo Web abre popup sem 404
☑ Fluxo Mobile retorna user com id/email
```

### 2.6 Configurar Google Sign-In para Android

1. No Google Cloud Console, crie outro **OAuth client ID**
2. Desta vez escolha **"Android"**
3. Preencha:
   - **Name:** `Fiz Plantão Android`
   - **Package name:** `br.com.rodrigolanes.fizplantao`
   - **SHA-1 certificate fingerprint:** 
     
     Execute no terminal (raiz do projeto):
     ```bash
     keytool -list -v -keystore android\upload-keystore.jks -alias upload
     ```
     Digite a senha do keystore quando solicitado.
     Copie o valor de **SHA1** que aparece.

4. Clique em **"Create"**

---

## 3. 💻 Configurar o Projeto Local

### 3.1 Editar `supabase_config.dart`

1. Abra o arquivo `lib/config/supabase_config.dart`
2. Substitua os valores:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://SEU_PROJETO_ID.supabase.co';
  static const String supabaseAnonKey = 'SUA_ANON_KEY_AQUI';
}
```

### 3.2 Instalar Dependências

Execute no terminal:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3.3 Testar Localmente

```bash
flutter run
```

**O que testar:**
- [ ] Tela de login aparece
- [ ] Consegue criar conta com email/senha
- [ ] Recebe email de verificação
- [ ] Consegue fazer login com Google (web)
- [ ] Dados locais (Hive) são preservados

---

## 4. 🔒 Configurar GitHub Actions Secrets

Os secrets são necessários para o **deploy automático** quando você fizer push para `develop`.

### 4.1 Acessar Secrets do Repositório

1. Acesse seu repositório no GitHub: `https://github.com/rodrigolanes/fiz_plantao`
2. Clique em **Settings** (aba superior)
3. No menu lateral, clique em **Secrets and variables** > **Actions**
4. Clique em **"New repository secret"** para cada item abaixo

### 4.2 Lista de Secrets Necessários

#### 🔑 Secrets de Assinatura Android (já devem existir)

| Nome do Secret | Descrição | Como obter |
|----------------|-----------|------------|
| `KEYSTORE_BASE64` | Keystore em base64 | `[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\upload-keystore.jks")) > keystore.txt` |
| `KEYSTORE_PASSWORD` | Senha do keystore | Valor de `storePassword` em `android/key.properties` |
| `KEY_PASSWORD` | Senha da chave | Valor de `keyPassword` em `android/key.properties` |
| `KEY_ALIAS` | Alias da chave | `upload` (ou valor em `android/key.properties`) |

#### 📦 Secret de Deploy Google Play (já deve existir)

| Nome do Secret | Descrição | Como obter |
|----------------|-----------|------------|
| `SERVICE_ACCOUNT_JSON` | Service Account da Play Store | Já configurado anteriormente |

#### 🌐 Secrets do Supabase (novos)

Estes secrets são usados para gerar automaticamente o arquivo `lib/config/supabase_config.dart` durante o workflow:

| Nome do Secret | Descrição | Como obter |
|----------------|-----------|------------|
| `SUPABASE_URL` | URL do projeto Supabase | Settings > API > Project URL |
| `SUPABASE_ANON_KEY` | Chave pública (anon) | Settings > API > anon public key |
| `GOOGLE_WEB_CLIENT_ID` | Web Client ID do Google OAuth | Google Cloud Console > Credentials > Web application Client ID |

> NÃO adicionar `service_role` aqui. Ela nunca deve ficar exposta em builds mobile.

### 4.3 Verificar Secrets Configurados

No final, você deve ter estes secrets:

```
✅ KEYSTORE_BASE64
✅ KEYSTORE_PASSWORD
✅ KEY_PASSWORD
✅ KEY_ALIAS
✅ SERVICE_ACCOUNT_JSON
✅ SUPABASE_URL
✅ SUPABASE_ANON_KEY
✅ GOOGLE_WEB_CLIENT_ID
```

> ✨ **Nota:** O projeto não usa mais Firebase. O `google-services.json` não é necessário e o arquivo `supabase_config.dart` é gerado dinamicamente pelo CI.

---

## 5. ✅ Testar a Configuração

### 5.1 Testar Localmente

```bash
# Limpar build anterior
flutter clean

# Instalar dependências
flutter pub get

# Rodar no emulador/device
flutter run --release
```

**Checklist de testes:**
- [ ] App abre sem erros
- [ ] Tela de login aparece
- [ ] Consegue criar conta
- [ ] Consegue fazer login com Google
- [ ] Cadastra um local
- [ ] Cadastra um plantão
- [ ] Dados aparecem na lista
- [ ] Faz logout e login novamente
- [ ] Dados continuam salvos

### 5.2 Testar CI/CD (GitHub Actions)

```bash
# Incrementar versão (OBRIGATÓRIO)
# Edite pubspec.yaml: version: 1.2.0+8 → 1.2.1+9

# Commitar mudanças
git add .
git commit -m "chore: Configurar Supabase e atualizar docs"

# Push para develop (aciona deploy automático)
git push origin develop
```

**Verificar:**
1. Vá em `https://github.com/rodrigolanes/fiz_plantao/actions`
2. Deve aparecer um workflow rodando
3. Aguarde ~5-10 minutos
4. Se sucesso ✅, o APK foi enviado para Google Play (internal track)

### 5.3 Solução de Problemas Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| `Invalid JWT` | Supabase anon key errado | Verifique `supabase_config.dart` |
| `Failed to authenticate` | Google Client ID errado | Verifique configuração OAuth |
| `Table not found` | SQL não foi executado | Execute `supabase_migration.sql` no SQL Editor |
| `Build failed` no GitHub | Secret faltando | Verifique todos os secrets no passo 4 |
| `Row Level Security` error | Usuário não tem permissão | Verifique se as políticas RLS foram criadas |

---

## 📞 Suporte

Se encontrar problemas:

1. **Logs do app:** `flutter run --verbose`
2. **Logs do Supabase:** SQL Editor > Query history
3. **Logs do GitHub Actions:** Actions > Workflow específico > Build step

**Contato:** rodrigolanes@gmail.com

---

## 📚 Documentação Oficial

- [Supabase Docs](https://supabase.com/docs)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [GitHub Actions](https://docs.github.com/en/actions)

---

**✅ Configuração completa!** Agora o app está pronto para produção com autenticação e sincronização na nuvem.
