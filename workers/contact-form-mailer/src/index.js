// Contact form mailer: static site -> Worker -> Cloudflare Email -> inbox.
// Sends only to the verified destination address in wrangler.jsonc
// (pankajdoharey@gmail.com), which is free on the Workers Free plan.

const ALLOWED_ORIGINS = [
  "https://rubylearning.in",
  "https://www.rubylearning.in",
  "http://localhost:3000",
];

function corsHeaders(origin) {
  return {
    "Access-Control-Allow-Origin": ALLOWED_ORIGINS.includes(origin)
      ? origin
      : ALLOWED_ORIGINS[0],
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}

function escapeHtml(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "";

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders(origin) });
    }

    if (request.method !== "POST") {
      return new Response("Method not allowed", {
        status: 405,
        headers: corsHeaders(origin),
      });
    }

    let data;
    try {
      data = await request.formData();
    } catch {
      return new Response(JSON.stringify({ error: "Invalid form data" }), {
        status: 400,
        headers: { ...corsHeaders(origin), "Content-Type": "application/json" },
      });
    }

    const name = String(data.get("name") || "").trim().slice(0, 200);
    const fromEmail = String(data.get("email") || "").trim().slice(0, 200);
    const track = String(data.get("track") || "").trim().slice(0, 200);
    const message = String(data.get("message") || "").trim().slice(0, 5000);

    if (!name || !fromEmail || !message) {
      return new Response(JSON.stringify({ error: "Missing fields" }), {
        status: 400,
        headers: { ...corsHeaders(origin), "Content-Type": "application/json" },
      });
    }

    try {
      await env.EMAIL.send({
        from: "mentorship@rubylearning.in", // must be on the onboarded domain
        to: "pankajdoharey@gmail.com",      // verified destination address
        reply_to: fromEmail,
        subject: `Mentorship application from ${name}`,
        text:
          `Name: ${name}\nEmail: ${fromEmail}\nTrack: ${track || "(not specified)"}\n\n${message}`,
        html:
          `<p><strong>Name:</strong> ${escapeHtml(name)}</p>` +
          `<p><strong>Email:</strong> ${escapeHtml(fromEmail)}</p>` +
          `<p><strong>Track:</strong> ${escapeHtml(track || "(not specified)")}</p>` +
          `<p><strong>Message:</strong></p><p>${escapeHtml(message).replace(/\n/g, "<br>")}</p>`,
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: "Email send failed" }), {
        status: 502,
        headers: { ...corsHeaders(origin), "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders(origin), "Content-Type": "application/json" },
    });
  },
};
