# Contact form mailer (Cloudflare Worker)

Receives the mentorship application form from rubylearning.in and forwards it
to **pankajdoharey@gmail.com** via Cloudflare Email Routing's `send_email`
binding. Free on the Workers Free plan (sends to a verified destination
address).

## One-time Cloudflare setup

1. Onboard `rubylearning.in` for **Email Routing** (Cloudflare dashboard →
   Email → Email Routing). Cloudflare adds MX/SPF/DKIM records automatically.
2. Add **pankajdoharey@gmail.com** as a *Destination Address* and click the
   verification link Cloudflare sends there.
3. Make sure `mentorship@rubylearning.in` (the `from` address) exists as a
   custom address or catch-all on the domain.

## Deploy

```bash
cd workers/contact-form-mailer
npx wrangler login        # one time, opens browser auth
npx wrangler deploy
```

After deploy, note the worker URL
(`https://contact-form-mailer.<your-subdomain>.workers.dev`) and set it in
`content/pages/mentorship.md` in the `FORM_ENDPOINT` constant at the top of
the form's script block.

Optionally route a nice URL instead: Workers → contact-form-mailer →
Settings → Triggers → add route `rubylearning.in/api/mentorship` (then set
`FORM_ENDPOINT = "/api/mentorship"`).
