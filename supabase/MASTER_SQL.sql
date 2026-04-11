-- ================================================================
--  Smart Support AI — MASTER SQL
--  Run this ONCE in Supabase SQL Editor
-- ================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS vector;

-- ── Tables ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.companies (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name             TEXT        NOT NULL,
  slug             TEXT        UNIQUE,
  logo_url         TEXT,
  primary_color    TEXT        DEFAULT '#6366F1',
  welcome_message  TEXT        DEFAULT 'Hello! How can I help you today?',
  support_email    TEXT,
  whatsapp_number  TEXT,
  plan             TEXT        DEFAULT 'free',
  is_active        BOOLEAN     DEFAULT true,
  api_key          TEXT        UNIQUE DEFAULT ('sk_' || encode(gen_random_bytes(24), 'hex')),
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.users (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id   UUID        REFERENCES public.companies(id) ON DELETE CASCADE,
  role         TEXT        DEFAULT 'admin' CHECK (role IN ('superadmin','admin','agent','viewer')),
  email        TEXT,
  full_name    TEXT,
  avatar_url   TEXT,
  is_active    BOOLEAN     DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.intents (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id       UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name             TEXT        NOT NULL,
  description      TEXT,
  training_phrases TEXT[]      DEFAULT '{}',
  response         TEXT        NOT NULL DEFAULT '',
  category         TEXT        DEFAULT 'general',
  is_active        BOOLEAN     DEFAULT true,
  match_count      INT         DEFAULT 0,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id                UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id        UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  visitor_id        TEXT        NOT NULL,
  visitor_name      TEXT,
  status            TEXT        DEFAULT 'active' CHECK (status IN ('active','closed','handed_off')),
  handoff_triggered BOOLEAN     DEFAULT false,
  failure_count     INT         DEFAULT 0,
  message_count     INT         DEFAULT 0,
  started_at        TIMESTAMPTZ DEFAULT now(),
  ended_at          TIMESTAMPTZ,
  metadata          JSONB       DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS public.messages (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID        NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  company_id UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  content    TEXT        NOT NULL,
  sender     TEXT        DEFAULT 'user' CHECK (sender IN ('user','bot','agent')),
  intent_id  UUID        REFERENCES public.intents(id) ON DELETE SET NULL,
  is_read    BOOLEAN     DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.unknown_questions (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id  UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  session_id  UUID        REFERENCES public.chat_sessions(id) ON DELETE SET NULL,
  question    TEXT        NOT NULL,
  frequency   INT         DEFAULT 1,
  status      TEXT        DEFAULT 'pending' CHECK (status IN ('pending','converted','ignored')),
  created_intent_id UUID  REFERENCES public.intents(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ratings (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID        UNIQUE REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  company_id UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  score      SMALLINT    NOT NULL CHECK (score BETWEEN 1 AND 5),
  comment    TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id           BIGINT      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  company_id   UUID        REFERENCES public.companies(id) ON DELETE CASCADE,
  user_id      UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  action       TEXT        NOT NULL,
  target_table TEXT,
  target_id    UUID,
  payload      JSONB       DEFAULT '{}',
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.company_documents (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id  UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  file_name   TEXT        NOT NULL,
  file_url    TEXT,
  file_size   BIGINT      DEFAULT 0,
  status      TEXT        DEFAULT 'processing' CHECK (status IN ('processing','ready','error')),
  chunk_count INT         DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.document_chunks (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  company_id  UUID        NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  document_id UUID        REFERENCES public.company_documents(id) ON DELETE CASCADE,
  content     TEXT        NOT NULL,
  embedding   vector(1536),
  chunk_index INT         DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_users_company    ON public.users(company_id);
CREATE INDEX IF NOT EXISTS idx_intents_company  ON public.intents(company_id);
CREATE INDEX IF NOT EXISTS idx_sessions_company ON public.chat_sessions(company_id);
CREATE INDEX IF NOT EXISTS idx_messages_session ON public.messages(session_id);
CREATE INDEX IF NOT EXISTS idx_messages_company ON public.messages(company_id);
CREATE INDEX IF NOT EXISTS idx_uq_company       ON public.unknown_questions(company_id);
CREATE INDEX IF NOT EXISTS idx_docs_company     ON public.company_documents(company_id);
CREATE INDEX IF NOT EXISTS idx_chunks_company   ON public.document_chunks(company_id);

-- ── Functions ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

CREATE OR REPLACE FUNCTION handle_new_auth_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN INSERT INTO public.users (id, email, role) VALUES (NEW.id, NEW.email, 'admin') ON CONFLICT (id) DO NOTHING; RETURN NEW; END;
$$;

CREATE OR REPLACE FUNCTION search_company_docs(p_company_id UUID, p_embedding vector(1536), p_limit INT DEFAULT 5)
RETURNS TABLE (content TEXT, similarity FLOAT) LANGUAGE sql STABLE AS $$
  SELECT content, 1 - (embedding <=> p_embedding) AS similarity FROM public.document_chunks
  WHERE company_id = p_company_id AND embedding IS NOT NULL ORDER BY embedding <=> p_embedding LIMIT p_limit;
$$;

-- ── Triggers ─────────────────────────────────────────────────
DROP TRIGGER IF EXISTS set_companies_updated_at  ON public.companies;
DROP TRIGGER IF EXISTS set_intents_updated_at    ON public.intents;
DROP TRIGGER IF EXISTS set_uq_updated_at         ON public.unknown_questions;
DROP TRIGGER IF EXISTS set_docs_updated_at       ON public.company_documents;
DROP TRIGGER IF EXISTS on_auth_user_created      ON auth.users;

CREATE TRIGGER set_companies_updated_at  BEFORE UPDATE ON public.companies         FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_intents_updated_at    BEFORE UPDATE ON public.intents           FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_uq_updated_at         BEFORE UPDATE ON public.unknown_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_docs_updated_at       BEFORE UPDATE ON public.company_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER on_auth_user_created      AFTER  INSERT ON auth.users               FOR EACH ROW EXECUTE FUNCTION handle_new_auth_user();

-- ── Views ────────────────────────────────────────────────────
DROP VIEW IF EXISTS public.company_analytics CASCADE;
DROP VIEW IF EXISTS public.daily_session_counts CASCADE;
CREATE OR REPLACE VIEW public.company_analytics AS
SELECT c.id AS company_id, c.name AS company_name,
  COUNT(DISTINCT cs.id) AS total_sessions, COUNT(DISTINCT m.id) AS total_messages,
  COUNT(DISTINCT uq.id) FILTER (WHERE uq.status='pending') AS unanswered_questions,
  ROUND(AVG(r.score)::numeric,2) AS avg_satisfaction,
  COUNT(DISTINCT cs.id) FILTER (WHERE cs.handoff_triggered) AS handoff_count,
  COUNT(DISTINCT i.id)  FILTER (WHERE i.is_active) AS active_intents
FROM public.companies c
LEFT JOIN public.chat_sessions     cs ON cs.company_id = c.id
LEFT JOIN public.messages          m  ON m.company_id  = c.id
LEFT JOIN public.unknown_questions uq ON uq.company_id = c.id
LEFT JOIN public.ratings           r  ON r.company_id  = c.id
LEFT JOIN public.intents           i  ON i.company_id  = c.id
GROUP BY c.id, c.name;

CREATE OR REPLACE VIEW public.daily_session_counts AS
SELECT company_id, DATE(started_at) AS session_date, COUNT(*) AS session_count
FROM public.chat_sessions GROUP BY company_id, DATE(started_at) ORDER BY session_date DESC;

-- ── RLS ──────────────────────────────────────────────────────
ALTER TABLE public.companies          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intents            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unknown_questions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_documents  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_chunks    ENABLE ROW LEVEL SECURITY;

DO $$ DECLARE r RECORD;
BEGIN FOR r IN SELECT policyname,tablename FROM pg_policies WHERE schemaname='public'
LOOP EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',r.policyname,r.tablename); END LOOP; END $$;

CREATE POLICY "co_read"   ON public.companies FOR SELECT USING (true);
CREATE POLICY "co_insert" ON public.companies FOR INSERT WITH CHECK (auth.role()='authenticated');
CREATE POLICY "co_update" ON public.companies FOR UPDATE USING (id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "co_delete" ON public.companies FOR DELETE USING (id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));

CREATE POLICY "u_read"    ON public.users FOR SELECT USING (id=auth.uid() OR company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "u_insert"  ON public.users FOR INSERT WITH CHECK (auth.role()='authenticated');
CREATE POLICY "u_update"  ON public.users FOR UPDATE USING (id=auth.uid());
CREATE POLICY "u_delete"  ON public.users FOR DELETE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));

CREATE POLICY "i_read"    ON public.intents FOR SELECT USING (is_active=true OR company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "i_insert"  ON public.intents FOR INSERT WITH CHECK (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "i_update"  ON public.intents FOR UPDATE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "i_delete"  ON public.intents FOR DELETE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));

CREATE POLICY "cs_read"   ON public.chat_sessions FOR SELECT USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "cs_insert" ON public.chat_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "cs_update" ON public.chat_sessions FOR UPDATE USING (true);
CREATE POLICY "cs_delete" ON public.chat_sessions FOR DELETE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));

CREATE POLICY "m_read"    ON public.messages FOR SELECT USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "m_insert"  ON public.messages FOR INSERT WITH CHECK (true);
CREATE POLICY "m_update"  ON public.messages FOR UPDATE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "m_delete"  ON public.messages FOR DELETE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));

CREATE POLICY "uq_read"   ON public.unknown_questions FOR SELECT USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "uq_insert" ON public.unknown_questions FOR INSERT WITH CHECK (true);
CREATE POLICY "uq_update" ON public.unknown_questions FOR UPDATE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "uq_delete" ON public.unknown_questions FOR DELETE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));

CREATE POLICY "r_read"    ON public.ratings FOR SELECT USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "r_insert"  ON public.ratings FOR INSERT WITH CHECK (true);
CREATE POLICY "r_delete"  ON public.ratings FOR DELETE USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));

CREATE POLICY "al_read"   ON public.audit_logs        FOR SELECT USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "d_all"     ON public.company_documents  FOR ALL    USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "ch_all"    ON public.document_chunks    FOR ALL    USING (company_id IN (SELECT company_id FROM public.users WHERE id=auth.uid()));
CREATE POLICY "ch_read"   ON public.document_chunks    FOR SELECT USING (true);

-- ── Grants ───────────────────────────────────────────────────
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.companies,public.intents TO anon;
GRANT INSERT ON public.chat_sessions,public.messages,public.unknown_questions,public.ratings TO anon;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.companies,public.users,public.intents,public.chat_sessions,public.messages,public.unknown_questions,public.ratings,public.company_documents,public.document_chunks TO authenticated;
GRANT SELECT ON public.audit_logs TO authenticated;
GRANT SELECT ON public.company_analytics,public.daily_session_counts TO authenticated;

-- ── Storage ──────────────────────────────────────────────────
INSERT INTO storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
VALUES ('company-logos','company-logos',true,2097152,ARRAY['image/jpeg','image/png','image/webp']) ON CONFLICT(id) DO NOTHING;
INSERT INTO storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
VALUES ('company-documents','company-documents',false,10485760,ARRAY['application/pdf','text/plain','application/vnd.openxmlformats-officedocument.wordprocessingml.document']) ON CONFLICT(id) DO NOTHING;

DROP POLICY IF EXISTS "s_logos_read"   ON storage.objects;
DROP POLICY IF EXISTS "s_logos_insert" ON storage.objects;
DROP POLICY IF EXISTS "s_docs_upload"  ON storage.objects;
DROP POLICY IF EXISTS "s_docs_read"    ON storage.objects;
DROP POLICY IF EXISTS "s_docs_delete"  ON storage.objects;

CREATE POLICY "s_logos_read"   ON storage.objects FOR SELECT USING (bucket_id='company-logos');
CREATE POLICY "s_logos_insert" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id='company-logos');
CREATE POLICY "s_docs_upload"  ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id='company-documents');
CREATE POLICY "s_docs_read"    ON storage.objects FOR SELECT TO authenticated USING (bucket_id='company-documents');
CREATE POLICY "s_docs_delete"  ON storage.objects FOR DELETE TO authenticated USING (bucket_id='company-documents');

-- ── Seed ─────────────────────────────────────────────────────
INSERT INTO public.companies (id,name,slug,primary_color,welcome_message,support_email,whatsapp_number,plan)
VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890','Demo Company','demo-company','#6366F1','Hello! I am your AI assistant. How can I help you today?','support@demo.com','+21612345678','pro')
ON CONFLICT(id) DO NOTHING;

INSERT INTO public.intents (company_id,name,training_phrases,response,category) VALUES
('a1b2c3d4-e5f6-7890-abcd-ef1234567890','Business Hours',ARRAY['what are your hours','when do you open','working hours'],'We are open Monday to Friday, 9 AM to 6 PM.','general'),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890','Pricing',ARRAY['how much does it cost','what is the price','pricing plans'],'Our plans start at $49/month.','billing'),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890','Contact Support',ARRAY['how do I contact you','I need help','talk to a human'],'You can reach us at support@demo.com','support'),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890','Cancel Order',ARRAY['how do I cancel','cancel my order','cancel subscription'],'You can cancel anytime from your account settings.','general'),
('a1b2c3d4-e5f6-7890-abcd-ef1234567890','Refund Policy',ARRAY['can I get a refund','refund policy','money back'],'We offer a 30-day money-back guarantee.','billing')
ON CONFLICT DO NOTHING;

-- ── Verify ───────────────────────────────────────────────────
SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;
