-- ================================================================
--  Smart Support AI — Migration 002
--  Run this in Supabase SQL Editor AFTER MASTER_SQL.sql and MIGRATION_001.sql
--  Plugs: anon could SELECT api_key from any company via RLS policy
--         `co_read USING (true)` combined with table-level SELECT grant.
--  Fix: revoke table-level SELECT from anon; grant SELECT on all columns
--       EXCEPT api_key. Authenticated users keep full access.
-- ================================================================

-- ── 1. Tighten companies column access for anon ──────────────
-- Widget/chat/hotel pages legitimately need to read public company
-- metadata (name, colors, welcome message, bot_capabilities), but
-- must NOT be able to read api_key belonging to other tenants.
REVOKE SELECT ON public.companies FROM anon;

GRANT SELECT (
  id,
  name,
  slug,
  logo_url,
  primary_color,
  welcome_message,
  support_email,
  whatsapp_number,
  plan,
  is_active,
  bot_capabilities,
  created_at,
  updated_at
) ON public.companies TO anon;

-- Notes:
-- * api_key is deliberately omitted. Anon cannot SELECT it.
-- * The widget already knows its own api_key (passed via data-key
--   attribute), so it never needs to read api_key back — it only
--   needs to USE api_key as a filter to find the matching company.
-- * PostgREST/Supabase clients must therefore stop using
--   .select('*') from anon contexts and list columns explicitly.
--   widget.js has been updated accordingly.

-- ── 2. Sanity check ──────────────────────────────────────────
-- Anon is still granted INSERT on chat_sessions / messages /
-- unknown_questions / ratings / bookings (from MASTER_SQL and
-- MIGRATION_001) — those are unaffected.
-- RLS policies on companies are unchanged; only the column-level
-- GRANT is tightened.

-- ── 3. Verify (uncomment to test) ────────────────────────────
-- SET ROLE anon;
-- SELECT api_key FROM public.companies LIMIT 1;   -- should ERROR: permission denied for column api_key
-- SELECT id, name FROM public.companies LIMIT 1;  -- should succeed
-- RESET ROLE;
