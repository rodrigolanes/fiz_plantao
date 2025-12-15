-- Migration: Adicionar suporte para duração de 6 horas
-- Data: 2025-12-15
-- Descrição: Atualiza o constraint de duracao na tabela plantoes para incluir 'seisHoras'

-- Remover constraint antigo
ALTER TABLE plantoes 
DROP CONSTRAINT IF EXISTS plantoes_duracao_check;

-- Adicionar novo constraint com 'seisHoras' incluído
ALTER TABLE plantoes 
ADD CONSTRAINT plantoes_duracao_check 
CHECK (duracao IN ('dozeHoras', 'vinteQuatroHoras', 'seisHoras'));

-- Comentário para documentação
COMMENT ON COLUMN plantoes.duracao IS 'Duração do plantão: seisHoras (6h), dozeHoras (12h) ou vinteQuatroHoras (24h)';
