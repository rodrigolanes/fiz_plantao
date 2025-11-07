-- ============================================
-- MIGRAÇÃO FIREBASE → SUPABASE AUTH
-- ============================================
-- Este script RECRIA as tabelas locais e plantoes
-- com user_id do tipo UUID (compatível com auth.users)
-- 
-- ATENÇÃO: Isso vai DELETAR todos os dados existentes!
-- Faça backup antes de executar.
-- ============================================

-- 1. Dropar tabelas antigas (CASCADE para deletar dependências)
DROP TABLE IF EXISTS plantoes CASCADE;
DROP TABLE IF EXISTS locais CASCADE;

-- 2. Criar tabela de locais com UUID
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

-- 3. Criar tabela de plantões com UUID
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

-- 4. Habilitar RLS nas tabelas
ALTER TABLE locais ENABLE ROW LEVEL SECURITY;
ALTER TABLE plantoes ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas RLS para locais
CREATE POLICY "Usuários podem ver seus próprios locais"
  ON locais FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir seus próprios locais"
  ON locais FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar seus próprios locais"
  ON locais FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem deletar seus próprios locais"
  ON locais FOR DELETE
  USING (auth.uid() = user_id);

-- 6. Criar políticas RLS para plantoes
CREATE POLICY "Usuários podem ver seus próprios plantões"
  ON plantoes FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Usuários podem inserir seus próprios plantões"
  ON plantoes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem atualizar seus próprios plantões"
  ON plantoes FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Usuários podem deletar seus próprios plantões"
  ON plantoes FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================
-- MIGRAÇÃO COMPLETA!
-- ============================================
-- Próximos passos:
-- 1. Execute este script no SQL Editor do Supabase
-- 2. Faça logout/login no app
-- 3. Os dados locais (Hive) serão sincronizados automaticamente
-- ============================================
