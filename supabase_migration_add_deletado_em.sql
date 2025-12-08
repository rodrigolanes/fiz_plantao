-- Migration: Add deletado_em column to locais and plantoes tables
-- Purpose: Support multi-device sync with explicit delete timestamps
-- Date: 2025-01-XX

-- Add deletado_em column to locais table
ALTER TABLE locais
ADD COLUMN deletado_em TIMESTAMPTZ;

-- Add comment explaining the column
COMMENT ON COLUMN locais.deletado_em IS 'Timestamp when the local was soft-deleted (ativo=false). Used for multi-device sync conflict resolution.';

-- Add deletado_em column to plantoes table
ALTER TABLE plantoes
ADD COLUMN deletado_em TIMESTAMPTZ;

-- Add comment explaining the column
COMMENT ON COLUMN plantoes.deletado_em IS 'Timestamp when the plantao was soft-deleted (ativo=false). Used for multi-device sync conflict resolution.';

-- Create index for better query performance on deleted records
CREATE INDEX idx_locais_deletado_em ON locais(deletado_em) WHERE deletado_em IS NOT NULL;
CREATE INDEX idx_plantoes_deletado_em ON plantoes(deletado_em) WHERE deletado_em IS NOT NULL;

-- Optional: Update existing soft-deleted records to set deletado_em = atualizado_em
-- This provides a reasonable timestamp for records that were deleted before this migration
UPDATE locais
SET deletado_em = atualizado_em
WHERE ativo = false AND deletado_em IS NULL;

UPDATE plantoes
SET deletado_em = atualizado_em
WHERE ativo = false AND deletado_em IS NULL;
