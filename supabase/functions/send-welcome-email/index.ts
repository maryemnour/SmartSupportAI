import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { to, companyName, companyId, apiKey } = await req.json();
    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) { console.log("No RESEND_API_KEY — email skipped"); return json({ success: true, note: "no email provider" }); }

    const html = `<div style="font-family:sans-serif;max-width:600px;margin:0 auto">
      <div style="background:#6366F1;padding:32px;text-align:center;border-radius:12px 12px 0 0">
        <h1 style="color:white;margin:0">Welcome to Smart Support AI 🎉</h1>
        <p style="color:rgba(255,255,255,.8);margin:8px 0 0">Your account is ready</p>
      </div>
      <div style="background:white;padding:32px;border:1px solid #e5e7eb;border-radius:0 0 12px 12px">
        <p>Hi <strong>${companyName}</strong>,</p>
        <p>Your Smart Support AI account is set up. Here are your credentials:</p>
        <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:8px;padding:16px;margin:16px 0">
          <p style="margin:0 0 8px;font-size:12px;color:#6b7280;text-transform:uppercase;font-weight:600">Company ID</p>
          <code style="font-size:13px;color:#4f46e5;background:white;padding:6px 10px;border-radius:6px;border:1px solid #e5e7eb;display:block">${companyId}</code>
        </div>
        <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:8px;padding:16px;margin:16px 0">
          <p style="margin:0 0 8px;font-size:12px;color:#6b7280;text-transform:uppercase;font-weight:600">API Key</p>
          <code style="font-size:13px;color:#4f46e5;background:white;padding:6px 10px;border-radius:6px;border:1px solid #e5e7eb;display:block">${apiKey}</code>
          <p style="color:#ef4444;font-size:11px;margin:6px 0 0">⚠️ Never share this key publicly</p>
        </div>
        <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:8px;padding:16px;margin:16px 0">
          <p style="margin:0 0 8px;font-size:12px;color:#6b7280;font-weight:600">Flutter embed code:</p>
          <code style="font-size:12px;color:#059669;background:#f9fafb;padding:8px;border-radius:6px;display:block">SmartSupportChatbotWidget(companyId: '${companyId}')</code>
        </div>
        <p style="color:#6b7280;font-size:13px">Smart Support AI Team</p>
      </div>
    </div>`;

    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { "Authorization": `Bearer ${resendKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ from: "Smart Support AI <onboarding@resend.dev>", to: [to], subject: `Welcome ${companyName} — Your credentials`, html }),
    });
    return json({ success: true });
  } catch (e) {
    console.error(e);
    return json({ success: true, note: "email failed non-critically" });
  }
});

function json(data: unknown) {
  return new Response(JSON.stringify(data), { headers: { ...cors, "Content-Type": "application/json" } });
}
