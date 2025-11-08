-- ============================================
-- MIGRAÇÃO: Adicionar campo 'pago' em plantões
-- Data: 8 de novembro de 2025
-- Versão: 1.3.0
-- ============================================

-- Adicionar coluna 'pago' na tabela plantoes
ALTER TABLE plantoes 
ADD COLUMN IF NOT EXISTS pago BOOLEAN NOT NULL DEFAULT FALSE;

-- Comentário
COMMENT ON COLUMN plantoes.pago IS 'Indica se o plantão foi pago (true) ou não (false)';

-- Criar índice para consultas por status de pagamento
CREATE INDEX IF NOT EXISTS idx_plantoes_pago ON plantoes(pago);

-- Atualizar RLS policies se necessário (já existem, não precisa alterar)
-- As policies existentes permitem que usuários vejam/editem apenas seus próprios dados
