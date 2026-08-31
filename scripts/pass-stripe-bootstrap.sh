#!/usr/bin/env bash
# Store STRIPE_SECRET_KEY in pass (SecretSpec path). Reads one line from stdin.
# Never print the key. Prefer a restricted key (rk_test_ / rk_live_).
set -euo pipefail

PASS_PATH="secretspec/shared/default/STRIPE_SECRET_KEY"

if [[ -t 0 && $# -eq 0 ]]; then
  echo "pass-stripe-bootstrap: paste the Stripe secret or restricted key, then Enter." >&2
  echo "  printf '%s\\n' \"\$KEY\" | pass-stripe-bootstrap" >&2
  echo "Do not paste live keys into chat." >&2
fi

key="$(head -n1 | tr -d '[:space:]')"
if [[ -z $key ]]; then
  echo "pass-stripe-bootstrap: empty input" >&2
  exit 1
fi
if [[ ! $key =~ ^(sk|rk)_(test|live)_ ]]; then
  echo "pass-stripe-bootstrap: expected sk_test_/sk_live_/rk_test_/rk_live_ prefix" >&2
  exit 1
fi

printf '%s\n' "$key" | pass insert -e -f "$PASS_PATH"
echo "pass-stripe-bootstrap: stored $PASS_PATH ($(echo "$key" | cut -c1-10)…)" >&2
