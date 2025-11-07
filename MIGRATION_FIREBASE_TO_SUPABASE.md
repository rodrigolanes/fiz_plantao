# Migração Firebase → Supabase Auth

## Data: Novembro 2025

### Motivação

Simplificar a stack tecnológica eliminando a dependência do Firebase e centralizando autenticação e banco de dados no Supabase.

## Mudanças Realizadas

### 1. Código

#### ✅ lib/services/auth_service.dart
- **Substituído:** `FirebaseAuth` → `Supabase.auth`
- **Alterado user ID:** `user.uid` (TEXT) → `user.id` (UUID)
- **Métodos atualizados:**
  - `login()`: `signInWithPassword()`
  - `cadastrar()`: `signUp()`
  - `logout()`: `signOut()`
  - `loginComGoogle()`: `signInWithIdToken()` com `OAuthProvider.google`
  - `redefinirSenha()`: `resetPasswordForEmail()`
  - `emailVerificado`: `user.emailConfirmedAt != null`
  - `enviarEmailVerificacao()`: `resend(type: OtpType.signup)`
- **Tratamento de erros:** `FirebaseAuthException` → `AuthException`

#### ✅ lib/services/sync_service.dart
- **Substituído:** `FirebaseAuth.instance.currentUser` → `Supabase.instance.auth.currentUser`
- **Alterado:** `user.uid` → `user.id`
- **Removido:** Import `firebase_auth`

#### ✅ lib/main.dart
- **Removido:** `Firebase.initializeApp()`
- **Removido:** Imports `firebase_core` e `firebase_options`
- **Mantido:** `Supabase.initialize()` apenas

#### ✅ pubspec.yaml
- **Removidas dependências:**
  - `firebase_core: ^3.6.0`
  - `firebase_auth: ^5.3.1`
  - `cloud_firestore: ^5.4.4`
- **Mantidas:**
  - `supabase_flutter: ^2.8.0`
  - `google_sign_in: ^6.2.2` (necessária para Google Auth via Supabase)

#### ✅ lib/firebase_options.dart
- **Deletado:** Arquivo não é mais necessário

### 2. Banco de Dados Supabase

#### ✅ Alteração de Schema

**Antes (Firebase):**
```sql
user_id TEXT  -- IDs gerados pelo Firebase Auth (strings longas)
```

**Agora (Supabase):**
```sql
user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
```

#### ✅ Foreign Keys Adicionadas
- `locais.user_id` → `auth.users(id)` CASCADE
- `plantoes.user_id` → `auth.users(id)` CASCADE
- `plantoes.local_id` → `locais(id)` RESTRICT

#### ✅ RLS Policies Atualizadas
Agora usam `auth.uid()` (função nativa do Supabase) ao invés de comparação manual com user_id TEXT.

### 3. Documentação

#### ✅ SUPABASE_SETUP.md
Criado guia completo com:
- Configuração de autenticação Email/Senha
- Configuração de Google Sign-In
- Scripts SQL para criação de tabelas com UUID
- Políticas RLS
- Troubleshooting

#### ✅ supabase_migration.sql
Script SQL pronto para executar que:
- Dropa tabelas antigas (TEXT user_id)
- Recria tabelas com UUID user_id
- Adiciona foreign keys para auth.users
- Configura RLS policies

## Como Executar a Migração

### Passo 1: Backup (IMPORTANTE!)
```bash
# Faça backup dos dados locais do Hive antes de qualquer coisa
# Em caso de problemas, você pode restaurar
```

### Passo 2: Executar SQL no Supabase
1. Acesse https://fizplantao.supabase.co
2. Vá em **SQL Editor**
3. Cole o conteúdo de `supabase_migration.sql`
4. Execute o script
5. Verifique se as tabelas foram criadas com sucesso

### Passo 3: Atualizar Dependências
```bash
flutter pub get
```

### Passo 4: Testar Localmente
```bash
# Deletar dados locais para forçar nova sincronização
# OU apenas fazer logout/login

flutter run -d edge  # ou chrome, android, etc.
```

### Passo 5: Teste de Autenticação
1. **Cadastro:** Criar nova conta com email/senha
2. **Login:** Fazer login com a conta criada
3. **Verificar UUID:** Dados devem aparecer no Supabase Table Editor com UUID correto
4. **Sincronização:** Criar local/plantão e verificar sync
5. **Google Sign-In:** Se configurado, testar login com Google

### Passo 6: Commit e Deploy
```bash
git add .
git commit -m "Migrar autenticação Firebase → Supabase Auth"
git push origin develop
```

## Impactos e Considerações

### ✅ Vantagens
- **Stack simplificada:** Apenas Supabase (Auth + Database)
- **Menos dependências:** 3 packages a menos
- **Melhor integração:** user_id UUID nativo, foreign keys funcionam
- **RLS nativo:** Políticas de segurança mais robustas
- **Custo:** Supabase tem tier gratuito generoso

### ⚠️ Breaking Changes
- **User IDs mudaram:** TEXT (Firebase) → UUID (Supabase)
- **Dados antigos:** Não há migração automática de contas Firebase para Supabase
- **Usuários precisam:** Fazer logout e login novamente após deploy
- **Google Sign-In:** Requer configuração no Supabase Dashboard

### 🔄 Dados do Hive
Os dados locais no Hive **não precisam** ser deletados:
- Ao fazer login novamente, `SyncService` sincroniza tudo
- Novo `user_id` (UUID) será salvo no cache
- Dados são re-enviados para Supabase com novo UUID

### 🔐 Segurança
- **RLS habilitado:** Cada usuário só vê seus dados (`auth.uid() = user_id`)
- **Foreign keys:** Cascata garante deleção de dados órfãos
- **Supabase Auth:** Sistema robusto com suporte a MFA, OAuth, etc.

## Configuração Opcional: Google Sign-In

Para habilitar login com Google no Supabase:

### 1. Google Cloud Console
1. Acesse https://console.cloud.google.com
2. Crie OAuth 2.0 Client ID (Web Application)
3. Adicione Redirect URI:
   ```
   https://fizplantao.supabase.co/auth/v1/callback
   ```
4. Copie Client ID e Client Secret

### 2. Supabase Dashboard
1. Vá em **Authentication > Providers > Google**
2. Habilite o provider
3. Cole Client ID e Client Secret
4. Salve

## Troubleshooting

### Erro de compilação após migração
```bash
flutter clean
flutter pub get
flutter run
```

### "User not authenticated" após atualizar
- Fazer logout e login novamente
- User ID mudou de TEXT para UUID

### Dados não aparecem no Supabase
- Verificar RLS policies
- Verificar que usuário está autenticado
- Verificar logs de sincronização no console

### Google Sign-In não funciona
- Verificar configuração no Supabase Dashboard
- Verificar Redirect URI no Google Cloud Console
- Testar com conta Google diferente

## Próximos Passos

- [ ] Executar `supabase_migration.sql` no SQL Editor
- [ ] Testar cadastro + login com email/senha
- [ ] Testar sincronização de dados
- [ ] Configurar Google Sign-In (opcional)
- [ ] Atualizar versão no `pubspec.yaml` para `1.2.0+8`
- [ ] Fazer commit e push para `develop`
- [ ] Testar em produção

## Versão

- **Antes:** v1.1.0+7 (Firebase Auth + Supabase Database)
- **Depois:** v1.2.0+8 (Supabase Auth + Supabase Database)

---

**Data da migração:** 07 de Novembro de 2025
**Tempo estimado:** ~30 minutos
**Complexidade:** Média
