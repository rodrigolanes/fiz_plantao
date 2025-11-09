-- Migration: Add calendar event IDs to plantoes table
-- Data: 2025-11-08
-- Descrição: Adiciona campos para armazenar IDs dos eventos do Google Calendar

-- Adicionar coluna calendar_event_id (ID do evento do plantão no Google Calendar)
ALTER TABLE plantoes 
ADD COLUMN IF NOT EXISTS calendar_event_id TEXT;

-- Adicionar coluna calendar_payment_event_id (ID do evento de pagamento - obsoleto mas mantido para compatibilidade)
ALTER TABLE plantoes 
ADD COLUMN IF NOT EXISTS calendar_payment_event_id TEXT;

-- Comentários nas colunas
COMMENT ON COLUMN plantoes.calendar_event_id IS 'ID do evento do plantão no Google Calendar';
COMMENT ON COLUMN plantoes.calendar_payment_event_id IS 'ID do evento de pagamento no Google Calendar (obsoleto - eventos de pagamento agora são agrupados por data)';

-- Criar índice para busca por calendar_event_id (útil para sincronização)
CREATE INDEX IF NOT EXISTS idx_plantoes_calendar_event_id ON plantoes(calendar_event_id) WHERE calendar_event_id IS NOT NULL;
