---
name: stripe-wawona
description: >-
  Wawona.io Stripe donations and invoicing. Use when building or reviewing
  wawona.io Checkout, one-time vs monthly support, Stripe secret/publishable
  keys, pass/SecretSpec STRIPE_SECRET_KEY, the local checkout API on :4242,
  or Ko-fi as a fallback (not a Checkout Session API).
---

# Stripe on Wawona.io

Read `stripe-best-practices` (payments, billing, security) before writing Stripe code.

## Product

Wawona (https://wawona.io) is a native Wayland compositor. The download page
collects optional support: **one-time** or **monthly**, custom USD amount,
then Stripe-hosted Checkout. Ko-fi is a fallback donation page only — it has
webhooks, not a create-checkout-session API.

Stripe products in use: **Payments** (Checkout Sessions) and **Invoicing**
(`invoice_creation` on one-time sessions; Billing invoices on subscriptions).

## Keys (never in git)

| Key | Where |
|---|---|
| Publishable `pk_test_` / `pk_live_` | `wawona.io/config.toml` `stripe_publishable_key` (public by design) |
| Secret `sk_` / restricted `rk_` | `pass` → `secretspec/shared/default/STRIPE_SECRET_KEY` only |

Never put `sk_` / `rk_` in `config.toml`, JS, HTML, GitHub Actions plaintext,
or chat. Prefer a restricted key (`rk_`) with Checkout + Invoices permissions.

Load at runtime:

```bash
export STRIPE_SECRET_KEY="$(pass show secretspec/shared/default/STRIPE_SECRET_KEY | head -n1)"
```

Bootstrap: `pass-stripe-bootstrap` (stdin, no echo).

## Integration rules

- Server creates Checkout Sessions. Browser never talks to the Stripe API with a secret.
- One-time → `mode: payment` + `invoice_creation.enabled`.
- Monthly → `mode: subscription` + `price_data.recurring.interval = month`.
- Omit `payment_method_types` (dynamic payment methods).
- Use `StripeClient`, not `stripe.api_key = …`.
- Latest API version unless pinned. Tag sessions with `integration_identifier`.
- Do not enable `automatic_tax` until a Stripe Tax registration exists.
- Card data stays on Stripe Checkout (PCI SAQ-A). No Card Element.

Local API: `http://127.0.0.1:4242/create-checkout-session` (flake `.#stripe-checkout`).
Site: Zola on `:1111`. Production needs a hosted session API; GitHub Pages cannot hold the secret.

Cursor on this machine: nix-darwin installs the official Stripe plugin to
`~/.cursor/plugins/local/stripe` and mirrors skills to `~/.cursor/skills/`.
MCP is `https://mcp.stripe.com` in `~/.cursor/mcp.json` (OAuth in Cursor).
