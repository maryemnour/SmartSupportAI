-- ================================================================
--  Smart Support AI — Migration 001
--  Run this in Supabase SQL Editor AFTER the MASTER_SQL.sql
--  Adds: bot_capabilities column, bookings table
-- ================================================================

-- ── 1. Add bot_capabilities JSONB column to companies ────────
ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS bot_capabilities JSONB DEFAULT '{
    "can_book_rooms": false,
    "can_check_availability": true,
    "can_show_pricing": true,
    "can_cancel_booking": false,
    "can_modify_booking": false,
    "can_collect_contact_info": true,
    "can_handle_complaints": true,
    "can_suggest_upsells": false,
    "can_concierge_services": false,
    "ai_fallback_enabled": true
  }'::jsonb;

-- ── 2. Create bookings table ─────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bookings (
  id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id      UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  session_id      UUID        REFERENCES public.chat_sessions(id) ON DELETE SET NULL,
  guest_name      TEXT        NOT NULL,
  guest_email     TEXT,
  guest_phone     TEXT,
  room_type       TEXT,
  check_in_date   DATE,
  check_out_date  DATE,
  guests_count    INT         DEFAULT 1,
  special_requests TEXT,
  status          TEXT        DEFAULT 'pending'
                  CHECK (status IN ('pending','confirmed','cancelled','completed')),
  total_price     NUMERIC(10,2),
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bookings_company  ON public.bookings(company_id);
CREATE INDEX IF NOT EXISTS idx_bookings_session  ON public.bookings(session_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status   ON public.bookings(status);

CREATE TRIGGER set_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── 3. RLS for bookings ──────────────────────────────────────
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "b_read"   ON public.bookings FOR SELECT
  USING (company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid()));
CREATE POLICY "b_insert" ON public.bookings FOR INSERT
  WITH CHECK (true);
CREATE POLICY "b_update" ON public.bookings FOR UPDATE
  USING (company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid()));
CREATE POLICY "b_delete" ON public.bookings FOR DELETE
  USING (company_id IN (SELECT company_id FROM public.users WHERE id = auth.uid()));

-- ── 4. Grant permissions ─────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.bookings TO authenticated;
GRANT INSERT ON public.bookings TO anon;
