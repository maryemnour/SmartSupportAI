-- ================================================================
--  Smart Support AI -- Migration 004
--  Run this in Supabase SQL Editor AFTER MIGRATION_003.sql
--  Generifies the bookings table from hotel-specific columns to
--  industry-agnostic ones, matching the platform's horizontal SaaS
--  positioning (any service business: clinics, salons, restaurants,
--  agencies, hotels, etc.).
--
--  Column renames (data preserved where possible):
--    room_type      -> service_type
--    check_in_date  -> start_date
--    check_out_date -> end_date
--    guests_count   -> party_size
-- ================================================================

-- 1. Rename existing columns (preserves any rows already booked).
ALTER TABLE public.bookings
  RENAME COLUMN room_type TO service_type;

ALTER TABLE public.bookings
  RENAME COLUMN check_in_date TO start_date;

ALTER TABLE public.bookings
  RENAME COLUMN check_out_date TO end_date;

ALTER TABLE public.bookings
  RENAME COLUMN guests_count TO party_size;

-- 2. Update column comments so the schema documents the new semantics.
COMMENT ON COLUMN public.bookings.service_type IS
  'Free-form label of the booked service (e.g. "haircut", "consultation", "dinner table", "double room", "interpreter session"). Each tenant defines its own vocabulary.';
COMMENT ON COLUMN public.bookings.start_date IS
  'When the booked service begins. For point-in-time services (dinner, appointment) end_date may be NULL.';
COMMENT ON COLUMN public.bookings.end_date IS
  'When the booked service ends. NULL for single-day or point-in-time services.';
COMMENT ON COLUMN public.bookings.party_size IS
  'Number of people the booking covers (guests, attendees, patients, diners, etc.).';

-- 3. Loosen the end_date semantics: it must no longer be required to be after start_date,
--    because some services (single appointment, single-day reservation) only have a start.
--    If a CHECK constraint was previously added enforcing end_date > start_date, drop it.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'bookings'
      AND constraint_type = 'CHECK'
      AND constraint_name LIKE '%end_after_start%'
  ) THEN
    EXECUTE 'ALTER TABLE public.bookings DROP CONSTRAINT IF EXISTS bookings_end_after_start_check';
  END IF;
END $$;

-- 4. Make end_date and party_size nullable / sensible defaults.
ALTER TABLE public.bookings
  ALTER COLUMN end_date DROP NOT NULL;

-- party_size already had DEFAULT 1, keep it.

-- Notes:
-- * The hotel demo (`website/hotel.html`) is just one demo deployment;
--   it can keep using the same table -- a "double room" is just a
--   service_type value, two dates remain start_date/end_date.
-- * Any application code referring to room_type/check_in_date/etc. must
--   be updated to use the new column names.
