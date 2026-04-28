// Smart Support AI -- Edge Function: ai-chat
// Stack: Google Gemini 2.0 Flash (chat) + sentence-transformers (embeddings via ml_api)
// All free-tier friendly.
//
// Required Supabase secrets:
//   GEMINI_API_KEY   -- from aistudio.google.com/apikey (free tier: 1500 req/day)
//   ML_API_URL       -- e.g. https://smartsupport-ml-api.onrender.com
// Optional secrets:
//   GEMINI_MODEL     -- defaults to gemini-2.0-flash

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const PERSONALITIES: Record<string, string> = {
  friendly:     "You are warm, friendly, and conversational. Use simple language, feel free to add a friendly emoji occasionally. Make the customer feel welcome and comfortable.",
  professional: "You are professional, precise, and formal. Use clear and structured language. Be efficient and stay on topic.",
  funny:        "You are cheerful and light-hearted. You can use humor and wit while still being helpful. Keep it fun but always answer the question.",
};

const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";
const ML_API_URL   = Deno.env.get("ML_API_URL")   ?? "";

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const {
      message,
      companyId,
      companyName,
      welcomeMessage,
      conversationHistory,
      personality = "friendly",
    } = await req.json();

    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) return json({ fallback: true, response: null });

    // --- RAG: search knowledge base via ml_api /embed ----------------------
    let context = "";
    if (companyId && ML_API_URL) {
      try {
        const sb = createClient(
          Deno.env.get("SUPABASE_URL")!,
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
        );
        const embRes = await fetch(`${ML_API_URL}/embed`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ text: message }),
        });
        const embData = await embRes.json();
        const embedding = embData?.embeddings?.[0];
        if (embedding) {
          const { data: chunks } = await sb.rpc("search_company_docs", {
            p_company_id: companyId,
            p_embedding: embedding,
            p_limit: 5,
          });
          if (chunks?.length) {
            context = chunks.map((c: any) => c.content).join("\n\n");
          }
        }
      } catch (err) {
        console.error("RAG lookup failed:", err);
      }
    }

    const personalityPrompt = PERSONALITIES[personality] ?? PERSONALITIES.friendly;

    // FEATURE 1 -- MULTILINGUAL: auto-detect user language, reply in same language
    // FEATURE 2 -- BOT PERSONALITY: inject personality style
    // FEATURE 3 -- RAG: inject knowledge-base context when available
    const systemPrompt = `You are an AI assistant for ${companyName ?? "this company"}.

${personalityPrompt}

IMPORTANT -- LANGUAGE RULE:
Detect the language of the user's message and ALWAYS reply in that same language.
If the user writes in Arabic, reply in Arabic.
If the user writes in French, reply in French.
If the user writes in English, reply in English.
Never switch languages unless the user switches first.
${context ? `\nKnowledge base (use this to answer when relevant):\n${context}\n` : ""}
${welcomeMessage ? `Welcome message context: ${welcomeMessage}` : ""}

Keep responses concise and accurate. If you don't know something, say so honestly.`;

    // Gemini uses "model" instead of "assistant" and groups text in `parts`.
    const contents = [
      ...(conversationHistory ?? []).map((m: any) => ({
        role: m.sender === "user" ? "user" : "model",
        parts: [{ text: String(m.content ?? "") }],
      })),
      { role: "user", parts: [{ text: String(message) }] },
    ];

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${geminiKey}`;
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents,
        generationConfig: {
          temperature: personality === "funny" ? 0.9 : 0.7,
          maxOutputTokens: 500,
        },
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      console.error("Gemini error", res.status, errText);
      return json({ fallback: true, response: null });
    }

    const data = await res.json();
    // Gemini response: { candidates: [{ content: { parts: [{ text: "..." }] } }], ... }
    const reply = data?.candidates?.[0]?.content?.parts
      ?.map((p: any) => p.text)
      .filter(Boolean)
      .join("\n");
    if (!reply) return json({ fallback: true, response: null });
    return json({ response: reply, fallback: false });

  } catch (e) {
    console.error("ai-chat fatal:", e);
    return json({ fallback: true, response: null });
  }
});

function json(data: unknown) {
  return new Response(JSON.stringify(data), {
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
