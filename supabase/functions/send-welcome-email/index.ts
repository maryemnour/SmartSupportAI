import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const { to, companyName, companyId, apiKey } = await req.json();
    const resendKey = Deno.env.get("RESEND_API_KEY");

    if (!resendKey) {
      console.log("No RESEND_API_KEY — email skipped");
      return json({ success: true, note: "no email provider" });
    }

    // Update these with your real URLs before deploying
    const ANDROID_URL = "https://play.google.com/store/apps/details?id=com.smartsupportai.app";
    const IOS_URL     = "https://apps.apple.com/app/smart-support-ai/id000000000";
    const WEB_APP_URL = "https://smartsupport-admin.vercel.app";

    const html = `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Welcome to Smart Support AI</title></head>
<body style="margin:0;padding:0;background:#f3f4f6;font-family:'Segoe UI',Arial,sans-serif">
  <div style="max-width:580px;margin:32px auto;background:white;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,.08)">
    <div style="background:linear-gradient(135deg,#6366F1,#4F46E5);padding:36px 32px;text-align:center">
      <div style="width:56px;height:56px;background:rgba(255,255,255,.2);border-radius:14px;display:inline-flex;align-items:center;justify-content:center;font-size:28px;margin-bottom:16px">🤖</div>
      <h1 style="color:white;margin:0;font-size:22px;font-weight:700">Welcome to Smart Support AI!</h1>
      <p style="color:rgba(255,255,255,.8);margin:8px 0 0;font-size:14px">Your account is ready — let's get started</p>
    </div>
    <div style="padding:32px">
      <p style="color:#374151;font-size:15px;margin:0 0 8px">Hi <strong>${companyName}</strong>,</p>
      <p style="color:#6b7280;font-size:14px;line-height:1.6;margin:0 0 28px">Your Smart Support AI account has been created successfully. Below are your credentials and everything you need to get your chatbot live.</p>
      <div style="background:#f9fafb;border:1px solid #e5e7eb;border-radius:10px;padding:20px;margin-bottom:20px">
        <p style="margin:0 0 14px;font-size:13px;font-weight:700;color:#111827">🔑 Your Credentials</p>
        <div style="margin-bottom:12px">
          <p style="margin:0 0 6px;font-size:11px;color:#6b7280;text-transform:uppercase;letter-spacing:.8px;font-weight:600">Company ID</p>
          <div style="background:white;border:1px solid #e5e7eb;border-radius:8px;padding:10px 14px;font-family:monospace;font-size:13px;color:#6366F1;word-break:break-all">${companyId}</div>
        </div>
        <div>
          <p style="margin:0 0 6px;font-size:11px;color:#6b7280;text-transform:uppercase;letter-spacing:.8px;font-weight:600">API Key</p>
          <div style="background:white;border:1px solid #e5e7eb;border-radius:8px;padding:10px 14px;font-family:monospace;font-size:13px;color:#6366F1;word-break:break-all">${apiKey}</div>
          <p style="margin:5px 0 0;font-size:11px;color:#ef4444">⚠️ Never share this key publicly</p>
        </div>
      </div>
      <div style="background:#eef2ff;border:1px solid #c7d2fe;border-radius:10px;padding:20px;margin-bottom:24px">
        <p style="margin:0 0 6px;font-size:14px;font-weight:700;color:#3730a3">📱 Download the Admin App</p>
        <p style="margin:0 0 16px;font-size:13px;color:#4338ca;line-height:1.5">Manage your chatbot, add intents, upload documents, and view analytics — all from the app.</p>
        <div style="display:flex;gap:10px;flex-wrap:wrap">
          <a href="${ANDROID_URL}" style="display:inline-block;background:#4F46E5;color:white;text-decoration:none;padding:10px 18px;border-radius:8px;font-size:13px;font-weight:600">📥 Download for Android</a>
          <a href="${IOS_URL}" style="display:inline-block;background:#4F46E5;color:white;text-decoration:none;padding:10px 18px;border-radius:8px;font-size:13px;font-weight:600">📥 Download for iPhone</a>
          <a href="${WEB_APP_URL}/dashboard?companyId=${companyId}" style="display:inline-block;background:white;color:#4F46E5;border:1px solid #c7d2fe;text-decoration:none;padding:10px 18px;border-radius:8px;font-size:13px;font-weight:600">🌐 Open Web App</a>
        </div>
      </div>
      <div style="margin-bottom:28px">
        <p style="margin:0 0 14px;font-size:14px;font-weight:700;color:#111827">🚀 Next steps</p>
        <div style="display:flex;gap:12px;align-items:flex-start;margin-bottom:12px">
          <div style="min-width:26px;height:26px;background:#6366F1;border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-size:12px;font-weight:700;flex-shrink:0">1</div>
          <div><p style="margin:0;font-size:13px;font-weight:600;color:#111827">Download and open the app</p><p style="margin:3px 0 0;font-size:12px;color:#6b7280">Log in with your email and password.</p></div>
        </div>
        <div style="display:flex;gap:12px;align-items:flex-start;margin-bottom:12px">
          <div style="min-width:26px;height:26px;background:#6366F1;border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-size:12px;font-weight:700;flex-shrink:0">2</div>
          <div><p style="margin:0;font-size:13px;font-weight:600;color:#111827">Add your intents</p><p style="margin:3px 0 0;font-size:12px;color:#6b7280">Go to Intents and add the questions your customers usually ask — with the answers.</p></div>
        </div>
        <div style="display:flex;gap:12px;align-items:flex-start;margin-bottom:12px">
          <div style="min-width:26px;height:26px;background:#6366F1;border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-size:12px;font-weight:700;flex-shrink:0">3</div>
          <div><p style="margin:0;font-size:13px;font-weight:600;color:#111827">Upload your documents (optional)</p><p style="margin:3px 0 0;font-size:12px;color:#6b7280">Upload a PDF or text file — the AI will use it to answer questions automatically.</p></div>
        </div>
        <div style="display:flex;gap:12px;align-items:flex-start">
          <div style="min-width:26px;height:26px;background:#10B981;border-radius:50%;display:flex;align-items:center;justify-content:center;color:white;font-size:12px;font-weight:700;flex-shrink:0">4</div>
          <div><p style="margin:0;font-size:13px;font-weight:600;color:#111827">Embed the chatbot in your website</p><p style="margin:3px 0 0;font-size:12px;color:#6b7280">Go to <strong>Embed / API Key</strong> in the app and copy the one-line script into your website.</p></div>
        </div>
      </div>
      <div style="background:#0f172a;border-radius:8px;padding:16px;margin-bottom:28px">
        <p style="margin:0 0 8px;font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:.8px;font-weight:600">Your embed code</p>
        <code style="font-size:12px;color:#10B981;line-height:1.7;display:block">&lt;script<br>&nbsp;&nbsp;src="https://cdn.smartsupport.ai/widget.js"<br>&nbsp;&nbsp;data-key="${apiKey}"&gt;<br>&lt;/script&gt;</code>
      </div>
      <div style="text-align:center">
        <a href="${WEB_APP_URL}/dashboard?companyId=${companyId}" style="display:inline-block;background:#6366F1;color:white;text-decoration:none;padding:14px 32px;border-radius:10px;font-size:15px;font-weight:700">Open My Dashboard →</a>
      </div>
    </div>
    <div style="border-top:1px solid #f3f4f6;padding:20px 32px;text-align:center;background:#f9fafb">
      <p style="margin:0;color:#9ca3af;font-size:12px">Smart Support AI — PFE Project ISET Tunis 2026</p>
      <p style="margin:4px 0 0;color:#d1d5db;font-size:11px">If you didn't create this account, you can ignore this email.</p>
    </div>
  </div>
</body>
</html>`;

    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { "Authorization": `Bearer ${resendKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: "Smart Support AI <onboarding@resend.dev>",
        to: [to],
        subject: `Welcome ${companyName} — Your credentials & app download`,
        html,
      }),
    });

    return json({ success: true });

  } catch (e) {
    console.error(e);
    return json({ success: true, note: "email failed non-critically" });
  }
});

function json(data: unknown) {
  return new Response(JSON.stringify(data), {
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
