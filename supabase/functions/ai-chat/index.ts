import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { message, companyId, apiKey, companyName, welcomeMessage, conversationHistory } = await req.json();
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) return json({ fallback: true, response: null });

    // RAG: search knowledge base
    let context = "";
    if (companyId) {
      try {
        const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
        const embRes = await fetch("https://api.openai.com/v1/embeddings", {
          method: "POST",
          headers: { "Authorization": `Bearer ${openaiKey}`, "Content-Type": "application/json" },
          body: JSON.stringify({ model: "text-embedding-3-small", input: message }),
        });
        const embData = await embRes.json();
        if (embData.data?.[0]?.embedding) {
          const { data: chunks } = await sb.rpc("search_company_docs", {
            p_company_id: companyId, p_embedding: embData.data[0].embedding, p_limit: 5,
          });
          if (chunks?.length) context = chunks.map((c: any) => c.content).join("\n\n");
        }
      } catch (_) {}
    }

    const system = `You are a helpful AI assistant for ${companyName ?? "this company"}.
${context ? `\nKnowledge base context:\n${context}\n` : ""}
Be concise, friendly, and accurate. If you don't know something, say so honestly.
Welcome message: ${welcomeMessage ?? "Hello!"}`;

    const messages = [
      { role: "system", content: system },
      ...(conversationHistory ?? []).map((m: any) => ({ role: m.sender === "user" ? "user" : "assistant", content: m.content })),
      { role: "user", content: message },
    ];

    const res = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { "Authorization": `Bearer ${openaiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-4o-mini", messages, max_tokens: 500, temperature: 0.7 }),
    });

    const data = await res.json();
    const reply = data.choices?.[0]?.message?.content;
    if (!reply) return json({ fallback: true, response: null });
    return json({ response: reply, fallback: false });
  } catch (e) {
    console.error(e);
    return json({ fallback: true, response: null });
  }
});

function json(data: unknown) {
  return new Response(JSON.stringify(data), { headers: { ...cors, "Content-Type": "application/json" } });
}
