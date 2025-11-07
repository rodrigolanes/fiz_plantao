# Configuração do Supabase

Este documento descreve como configurar o Supabase para o Fiz Plantão.

## 1. Criar Projeto no Supabase

1. Acesse https://supabase.com
2. Crie um novo projeto
3. Anote a **URL do projeto** e a **anon/public key**

## 2. Configurar Autenticação

### Email/Senha

1. No Dashboard do Supabase, vá em **Authentication > Providers**
2. **Email** já vem habilitado por padrão
3. Configure opcionalmente:
   - **Enable email confirmations**: Requer confirmação de email antes do login
   - **Secure email change**: Requer confirmação para alterar email

### Google Sign-In (Opcional)

1. **Criar credenciais no Google Cloud Console:**
   - Acesse https://console.cloud.google.com
   - Crie um novo projeto (ou use existente)
   - Vá em **APIs & Services > Credentials**
   - Clique em **Create Credentials > OAuth 2.0 Client ID**
   - Tipo: **Web application**
   - **Authorized redirect URIs**: Adicione a URL do Supabase:
     ```
     https://fizplantao.supabase.co/auth/v1/callback
     ```
     (Substitua `fizplantao` pelo ID do seu projeto)
   - Copie o **Client ID** e **Client Secret**

2. **Configurar no Supabase:**
   - Vá em **Authentication > Providers > Google**
   - Habilite o provider
   - Cole o **Client ID** e **Client Secret**
   - Salve

## 3. Criar Tabelas no Banco de Dados

Execute os seguintes scripts SQL no **SQL Editor** do Supabase:

### 3.1 Tabela `locais`

```sql
-- Deletar tabela antiga (se existir) para recriar com UUID
DROP TABLE IF EXISTS plantoes CASCADE;
DROP TABLE IF EXISTS locais CASCADE;

-- Criar tabela de locais
CREATE TABLE locais (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  apelido TEXT NOT NULL,
  nome TEXT NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ativo BOOLEAN NOT NULL DEFAULT TRUE
);

-- Índices para performance
CREATE INDEX idx_locais_user_id ON locais(user_id);
CREATE INDEX idx_locais_ativo ON locais(ativo);
CREATE INDEX idx_locais_atualizado_em ON locais(atualizado_em);

-- Comentários
COMMENT ON TABLE locais IS 'Locais de trabalho cadastrados pelo usuário';
COMMENT ON COLUMN locais.id IS 'ID único do local (UUID)';
COMMENT ON COLUMN locais.user_id IS 'ID do usuário proprietário (referência para auth.users)';
COMMENT ON COLUMN locais.apelido IS 'Nome curto/apelido do local';
COMMENT ON COLUMN locais.nome IS 'Nome completo do local';
COMMENT ON COLUMN locais.ativo IS 'Flag de soft delete (true = ativo, false = deletado)';
```

### 3.2 Tabela `plantoes`

```sql
-- Criar tabela de plantões
CREATE TABLE plantoes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  local_id UUID NOT NULL REFERENCES locais(id) ON DELETE RESTRICT,
  data_hora TIMESTAMPTZ NOT NULL,
  duracao TEXT NOT NULL CHECK (duracao IN ('dozeHoras', 'vinteQuatroHoras')),
  valor DECIMAL(10, 2) NOT NULL,
  previsao_pagamento TIMESTAMPTZ NOT NULL,
  criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ativo BOOLEAN NOT NULL DEFAULT TRUE
);

-- Índices para performance
CREATE INDEX idx_plantoes_user_id ON plantoes(user_id);
CREATE INDEX idx_plantoes_local_id ON plantoes(local_id);
CREATE INDEX idx_plantoes_ativo ON plantoes(ativo);
CREATE INDEX idx_plantoes_data_hora ON plantoes(data_hora);
CREATE INDEX idx_plantoes_previsao_pagamento ON plantoes(previsao_pagamento);
CREATE INDEX idx_plantoes_atualizado_em ON plantoes(atualizado_em);

-- Comentários
COMMENT ON TABLE plantoes IS 'Plantões realizados pelo usuário';
COMMENT ON COLUMN plantoes.id IS 'ID único do plantão (UUID)';
COMMENT ON COLUMN plantoes.user_id IS 'ID do usuário proprietário (referência para auth.users)';
COMMENT ON COLUMN plantoes.local_id IS 'ID do local onde o plantão foi realizado';
COMMENT ON COLUMN plantoes.duracao IS 'Duração do plantão (dozeHoras ou vinteQuatroHoras)';
COMMENT ON COLUMN plantoes.valor IS 'Valor pago pelo plantão em reais';
COMMENT ON COLUMN plantoes.previsao_pagamento IS 'Data prevista para receber o pagamento';
COMMENT ON COLUMN plantoes.ativo IS 'Flag de soft delete (true = ativo, false = deletado)';
```

### 3.3 Row Level Security (RLS)

```sql
-- Habilitar RLS nas tabelas
ALTER TABLE locais ENABLE ROW LEVEL SECURITY;
ALTER TABLE plantoes ENABLE ROW LEVEL SECURITY;

-- Políticas para tabela locais
-- Usuários autenticados podem ver apenas seus próprios locais
CREATE POLICY "Usuários podem ver seus próprios locais"
  ON locais FOR SELECT
  USING (auth.uid() = user_id);

-- Usuários autenticados podem inserir seus próprios locais
CREATE POLICY "Usuários podem inserir seus próprios locais"
  ON locais FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Usuários autenticados podem atualizar seus próprios locais
CREATE POLICY "Usuários podem atualizar seus próprios locais"
  ON locais FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Usuários autenticados podem deletar seus próprios locais
CREATE POLICY "Usuários podem deletar seus próprios locais"
  ON locais FOR DELETE
  USING (auth.uid() = user_id);

-- Políticas para tabela plantoes
-- Usuários autenticados podem ver apenas seus próprios plantões
CREATE POLICY "Usuários podem ver seus próprios plantões"
  ON plantoes FOR SELECT
  USING (auth.uid() = user_id);

-- Usuários autenticados podem inserir seus próprios plantões
CREATE POLICY "Usuários podem inserir seus próprios plantões"
  ON plantoes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Usuários autenticados podem atualizar seus próprios plantões
CREATE POLICY "Usuários podem atualizar seus próprios plantões"
  ON plantoes FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Usuários autenticados podem deletar seus próprios plantões
CREATE POLICY "Usuários podem deletar seus próprios plantões"
  ON plantoes FOR DELETE
  USING (auth.uid() = user_id);
```

## 4. Habilitar Realtime (Opcional)

Para receber atualizações em tempo real quando dados mudam:

1. Vá em **Database > Replication**
2. Habilite replicação para as tabelas:
   - `locais`
   - `plantoes`

## 5. Configurar a Aplicação

### 5.1 Criar arquivo de configuração

Crie o arquivo `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://SEU_PROJETO.supabase.co';
  static const String supabaseAnonKey = 'SUA_ANON_KEY_AQUI';
}
```

### 5.2 Adicionar ao .gitignore

```
# Supabase credentials
lib/config/supabase_config.dart
```

## 6. Estrutura Final

### Tabelas

- **locais**: Locais de trabalho com UUID user_id
- **plantoes**: Plantões realizados com UUID user_id e local_id

### Foreign Keys

- `plantoes.user_id` → `auth.users(id)` (CASCADE)
- `plantoes.local_id` → `locais(id)` (RESTRICT)
- `locais.user_id` → `auth.users(id)` (CASCADE)

### Índices

- Performance otimizada para queries por user_id, ativo, data_hora, atualizado_em

### Segurança

- RLS habilitado em todas as tabelas
- Cada usuário só acessa seus próprios dados
- Policies usando `auth.uid()` para isolar dados por usuário

## 7. Migração de Dados Existentes

Se você já tem dados no Firebase:

1. **Backup**: Exporte dados do Firebase/Hive antes de qualquer operação
2. **Limpar dados locais**: Delete boxes do Hive ou faça logout/login para re-sincronizar
3. **Primeira sincronização**: Após login, todos os dados locais serão enviados para o Supabase

**IMPORTANTE**: Como mudamos de TEXT (Firebase) para UUID (Supabase), os IDs de usuário mudarão. Isso significa que:
- Você precisará fazer logout e login novamente
- Os dados locais do Hive serão re-sincronizados com novos UUIDs
- Dados antigos do Firebase não serão migrados automaticamente

## Troubleshooting

### Erro: "Invalid JWT"

- Verifique se o `supabaseAnonKey` está correto
- Verifique se o `supabaseUrl` está correto

### Erro: "Row level security policy violation"

- Verifique se as policies RLS foram criadas corretamente
- Verifique se o usuário está autenticado (`auth.uid()` não pode ser null)

### Dados não sincronizam

- Verifique a conexão com internet
- Verifique no console do Supabase se há erros nas tabelas
- Verifique logs do app para erros de sincronização

### Google Sign-In não funciona

- Verifique se o Client ID e Client Secret estão corretos
- Verifique se a Redirect URI está correta no Google Cloud Console
- Verifique se o provider Google está habilitado no Supabase

---

**Última atualização:** Novembro 2025
