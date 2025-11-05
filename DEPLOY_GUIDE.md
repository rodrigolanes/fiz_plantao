# Guia de Deploy Automatizado - Google Play

Este guia detalha como configurar o deploy automatizado do **Fiz Plantão** no Google Play Console usando GitHub Actions.

## 📋 Pré-requisitos

- Conta Google Play Console configurada
- Repositório no GitHub
- App já criado no Google Play Console
- Flutter SDK instalado localmente

## 🔐 Parte 1: Criar Keystore de Assinatura

### 1.1 Gerar Keystore

Execute no terminal (na pasta do projeto):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Responda as perguntas:**

- Senha do keystore: escolha uma senha forte (min 6 caracteres)
- Senha da chave: pode ser a mesma do keystore
- Nome, organização, etc.: preencha conforme solicitado

**⚠️ IMPORTANTE:**

- Guarde o arquivo `upload-keystore.jks` em local seguro
- Anote as senhas - você precisará delas
- **NUNCA** commite o arquivo `.jks` no git

### 1.2 Converter Keystore para Base64

Para usar no GitHub Actions, converta para Base64:

**Windows (PowerShell):**

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

**Linux/Mac:**

```bash
base64 upload-keystore.jks | pbcopy  # Mac
base64 upload-keystore.jks | xclip   # Linux
```

O conteúdo Base64 foi copiado para a área de transferência.

### 1.3 Criar key.properties Local

Copie o arquivo exemplo:

```bash
cp android/key.properties.example android/key.properties
```

Edite `android/key.properties` com suas credenciais:

```properties
storePassword=SUA_SENHA_KEYSTORE
keyPassword=SUA_SENHA_CHAVE
keyAlias=upload
storeFile=../upload-keystore.jks
```

**⚠️ IMPORTANTE:** O arquivo `key.properties` já está no `.gitignore` - não será commitado.

## 🔑 Parte 2: Configurar Service Account do Google Play

### 2.1 Criar Service Account

1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Selecione/crie um projeto vinculado ao Google Play Console
3. Menu → **IAM & Admin** → **Service Accounts**
4. Clique **+ CREATE SERVICE ACCOUNT**
5. Preencha:
   - Nome: `github-actions-deploy`
   - Descrição: `Deploy automatizado via GitHub Actions`
6. Clique **CREATE AND CONTINUE**
7. Não adicione papéis aqui, clique **DONE**

### 2.2 Criar Chave JSON

1. Clique no service account recém-criado
2. Aba **KEYS** → **ADD KEY** → **Create new key**
3. Tipo: **JSON**
4. Clique **CREATE** - arquivo JSON será baixado
5. **Guarde este arquivo em local seguro**

### 2.3 Vincular ao Google Play Console

1. Acesse [Google Play Console](https://play.google.com/console)
2. Menu → **Usuários e permissões**
3. Aba **Service accounts**
4. Clique **Grant access** no service account criado
5. Configurar permissões:
   - ✅ **Releases** → Gerenciar releases de produção
   - ✅ **Releases** → Gerenciar releases de teste (internal/closed/open)
   - Outros conforme necessidade
6. Salvar

## 🔧 Parte 3: Configurar Secrets no GitHub

Acesse: `https://github.com/rodrigolanes/fiz_plantao/settings/secrets/actions`

Adicione os seguintes secrets clicando em **New repository secret**:

### 3.1 KEYSTORE_BASE64

- **Nome:** `KEYSTORE_BASE64`
- **Valor:** Cole o conteúdo Base64 copiado no passo 1.2

### 3.2 KEYSTORE_PASSWORD

- **Nome:** `KEYSTORE_PASSWORD`
- **Valor:** Senha do keystore (escolhida no passo 1.1)

### 3.3 KEY_PASSWORD

- **Nome:** `KEY_PASSWORD`
- **Valor:** Senha da chave (escolhida no passo 1.1)

### 3.4 KEY_ALIAS

- **Nome:** `KEY_ALIAS`
- **Valor:** `upload` (ou alias que você usou)

### 3.5 SERVICE_ACCOUNT_JSON

- **Nome:** `SERVICE_ACCOUNT_JSON`
- **Valor:** Cole **todo o conteúdo** do arquivo JSON baixado no passo 2.2

## 🚀 Parte 4: Workflows Configurados

### 4.1 Deploy Internal Testing (Branch `develop`)

Arquivo: `.github/workflows/deploy-internal.yml`

**Trigger:** Push para branch `develop`

**Faz:**

1. Checkout do código
2. Setup Java 17 e Flutter 3.24.0
3. Decodifica keystore e cria `key.properties`
4. Instala dependências (`flutter pub get`)
5. Build do AppBundle assinado
6. Upload para track **internal** do Google Play

**Como usar:**

```bash
git checkout develop
git add .
git commit -m "Nova funcionalidade"
git push origin develop
```

### 4.2 Deploy Production (Tag `v*`)

Arquivo: `.github/workflows/deploy-production.yml`

**Trigger:** Push de tag começando com `v` (ex: `v1.0.0`)

**Faz:**

1. Checkout do código
2. Setup Java 17 e Flutter 3.24.0
3. Decodifica keystore e cria `key.properties`
4. Instala dependências (`flutter pub get`)
5. Build do AppBundle assinado
6. Upload para track **production** do Google Play

**Como usar:**

```bash
# 1. Atualizar versão no pubspec.yaml
# version: 1.0.1+2

# 2. Commit e push
git add pubspec.yaml
git commit -m "Bump version 1.0.1"
git push origin main

# 3. Criar tag
git tag v1.0.1
git push origin v1.0.1
```

## 📝 Checklist de Deploy

### Antes do Primeiro Deploy

- [ ] Keystore criado e convertido para Base64
- [ ] `key.properties` configurado localmente
- [ ] Service Account criado no Google Cloud
- [ ] Service Account vinculado ao Google Play Console
- [ ] Todos os 5 secrets configurados no GitHub
- [ ] App já criado manualmente no Google Play Console (primeiro upload manual)
- [ ] Branch `develop` criada no repositório

### Para Cada Deploy Internal

- [ ] Testar funcionalidades localmente
- [ ] Atualizar README se necessário
- [ ] Commit e push para `develop`
- [ ] Aguardar workflow completar
- [ ] Verificar no Google Play Console → Internal testing

### Para Cada Deploy Production

- [ ] Incrementar versão no `pubspec.yaml`
- [ ] Atualizar CHANGELOG (opcional)
- [ ] Commit e push para `main`
- [ ] Criar e push tag `v*`
- [ ] Aguardar workflow completar
- [ ] Verificar no Google Play Console → Production

## 🐛 Troubleshooting

### Erro: "Keystore was tampered with"

- Verifique se copiou todo o Base64 sem quebras de linha
- Recrie o secret `KEYSTORE_BASE64`

### Erro: "The apk must be signed with the same certificates"

- Você mudou o keystore após primeiro upload
- Use o keystore original ou crie novo app no Play Console

### Erro: "Service account not found"

- Verifique se service account tem permissões no Play Console
- Confirme que JSON está completo no secret

### Erro: "Version code X has already been used"

- Incremente `versionCode` no `pubspec.yaml`
- Formato: `version: X.Y.Z+CODE` (ex: `1.0.1+2`)

### Workflow não dispara

- Verifique nome da branch (`develop` ou tag `v*`)
- Confirme que workflow está em `.github/workflows/`
- Veja aba "Actions" no GitHub para logs

## 📚 Referências

- [Flutter - Build and release Android app](https://docs.flutter.dev/deployment/android)
- [Google Play Console - Service Account](https://support.google.com/googleplay/android-developer/answer/9845334)
- [GitHub Actions - Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## 🔒 Segurança

**NUNCA commite:**

- ❌ `upload-keystore.jks`
- ❌ `key.properties`
- ❌ Service account JSON
- ❌ Senhas em texto plano

**Arquivo `.gitignore` já inclui:**

```
*.jks
*.keystore
key.properties
*-keystore.jks
```

---

**Versão do Guia:** 1.0  
**Última atualização:** Novembro 2025
