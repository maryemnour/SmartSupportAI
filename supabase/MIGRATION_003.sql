-- ================================================================
--  Smart Support AI -- Migration 003
--  Run this in Supabase SQL Editor AFTER MIGRATION_002.sql
--  Switches the RAG embedding pipeline from OpenAI text-embedding-3-small
--  (1536 dim) to local sentence-transformers paraphrase-multilingual-MiniLM-L12-v2
--  (384 dim, multilingual: FR / AR / EN), running inside ml_api on Render.
--
--  WARNING: this DROPS all existing rows from document_chunks because
--  embeddings of different dimensions cannot coexist in one column.
--  Re-ingest your docs via the admin Documents screen after running this.
-- ================================================================

-- 1. Wipe old chunks (they were embedded with OpenAI 1536-d vectors).
TRUNCATE TABLE public.document_chunks;

-- 2. Drop the old vector(1536) column and recreate as vector(384).
--    (Postgres can't ALTER vector dimensions in place.)
ALTER TABLE public.document_chunks
  DROP COLUMN IF EXISTS embedding;

ALTER TABLE public.document_chunks
  ADD COLUMN embedding vector(384);

-- 3. Recreate the vector index for cosine similarity search.
DROP INDEX IF EXISTS public.idx_chunks_embedding;
-- HNSW gives better recall/latency than IVFFLAT and works well at small scale.
CREATE INDEX IF NOT EXISTS idx_chunks_embedding
  ON public.document_chunks
  USING hnsw (embedding vector_cosine_ops);

-- 4. Replace the search RPC with the new vector(384) signature.
DROP FUNCTION IF EXISTS public.search_company_docs(UUID, vector, INT);

CREATE OR REPLACE FUNCTION public.search_company_docs(
  p_company_id UUID,
  p_embedding  vector(384),
  p_limit      INT DEFAULT 5
)
RETURNS TABLE(content TEXT, similarity FLOAT)
LANGUAGE sql STABLE
AS $$
  SELECT content,
         1 - (embedding <=> p_embedding) AS similarity
  FROM public.document_chunks
  WHERE company_id = p_company_id
    AND embedding IS NOT NULL
  ORDER BY embedding <=> p_embedding
  LIMIT p_limit;
$$;

-- Notes:
-- * paraphrase-multilingual-MiniLM-L12-v2 returns 384-dim normalized vectors.
-- * If you ever switch to a different sentence-transformers model with a
--   different dimension, repeat steps 2 + 4 with the new vector(N).
