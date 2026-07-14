#!/usr/bin/env bash
# Render public-safe fleet status from private dendritic-fleet-status.
# Writes README block (between markers) + docs/fleet-status.json.
# Never prints or embeds IP addresses.
set -euo pipefail

OWNER="${FLEET_STATUS_OWNER:-aspauldingcode}"
REPO="${FLEET_STATUS_REPO:-dendritic-fleet-status}"
ROOT="${FLEET_DOTFILES_ROOT:-.}"
README="${ROOT}/README.md"
OUT_JSON="${ROOT}/docs/fleet-status.json"
ROSTER="${ROOT}/home/fleet-hosts.nix"
ONLINE_SEC=$((30 * 60))
STALE_SEC=$((24 * 60 * 60))
NOW="$(date -u +%s)"

command -v gh >/dev/null
command -v jq >/dev/null
command -v python3 >/dev/null

roster_hosts="$(
  python3 - "$ROSTER" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
keys = re.findall(r"(?m)^  ([a-z0-9][a-z0-9-]*)\s*=\s*\{", text)
print("\n".join(keys))
PY
)"

[[ -n $roster_hosts ]] || {
  echo "error: empty roster from $ROSTER" >&2
  exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/hosts"

listing="$(gh api "repos/${OWNER}/${REPO}/contents/hosts" 2>/dev/null || echo '[]')"
printf '%s' "$listing" | jq -e 'type=="array"' >/dev/null

while IFS= read -r name; do
  [[ $name == *.json ]] || continue
  path="hosts/${name}"
  raw="$(gh api "repos/${OWNER}/${REPO}/contents/${path}" --jq .content | tr -d '\n' | base64 --decode 2>/dev/null || true)"
  [[ -n $raw ]] || continue
  if ! printf '%s' "$raw" | jq -e '
      .schema == 1
      and (.host | type == "string")
      and (.platform == "darwin" or .platform == "nixos" or .platform == "linux")
      and (.flake_rev | test("^[0-9a-f]{7,40}$"))
      and (.seen_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"))
      and ((keys | sort) == ["flake_rev","host","platform","schema","seen_at"])
    ' >/dev/null; then
    echo "error: invalid heartbeat $path" >&2
    exit 1
  fi
  if printf '%s' "$raw" | grep -EIq \
    '(^|[^0-9])([0-9]{1,3}\.){3}[0-9]{1,3}([^0-9]|$)|([0-9a-fA-F]{1,4}:){5,7}[0-9a-fA-F]{1,4}'; then
    echo "error: IP-like content in $path" >&2
    exit 1
  fi
  host="$(printf '%s' "$raw" | jq -r .host)"
  base="${name%.json}"
  [[ $host == "$base" ]] || {
    echo "error: host mismatch in $path" >&2
    exit 1
  }
  printf '%s\n' "$raw" >"$tmpdir/hosts/${host}.json"
done < <(printf '%s' "$listing" | jq -r '.[].name // empty')

python3 - "$tmpdir" "$roster_hosts" "$README" "$OUT_JSON" "$NOW" "$ONLINE_SEC" "$STALE_SEC" <<'PY'
import json, pathlib, sys
from datetime import datetime, timezone

tmpdir, roster_text, readme_path, out_json, now_s, online_s, stale_s = sys.argv[1:8]
now = int(now_s)
online_sec = int(online_s)
stale_sec = int(stale_s)
roster = [h for h in roster_text.splitlines() if h.strip()]
hosts_dir = pathlib.Path(tmpdir) / "hosts"

def parse_seen(iso: str) -> int:
    return int(datetime.strptime(iso, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc).timestamp())

def status_for(iso: str | None) -> str:
    if not iso:
        return "offline"
    age = now - parse_seen(iso)
    if age <= online_sec:
        return "online"
    if age <= stale_sec:
        return "stale"
    return "offline"

def badge_color(st: str) -> str:
    return {"online": "brightgreen", "stale": "yellow"}.get(st, "lightgrey")

rows = []
badges = []
for host in roster:
    path = hosts_dir / f"{host}.json"
    data = json.loads(path.read_text()) if path.exists() else None
    seen = data["seen_at"] if data else None
    plat = data["platform"] if data else "unknown"
    tip = data["flake_rev"] if data else "—"
    st = status_for(seen)
    color = badge_color(st)
    badges.append(
        f"[![{host}](https://img.shields.io/badge/{host}-{st}-{color})](docs/fleet-status.md)"
    )
    rows.append(
        {
            "host": host,
            "platform": plat,
            "flake_rev": tip,
            "status": st,
            "seen_at": seen,
        }
    )

generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
pathlib.Path(out_json).write_text(
    json.dumps({"schema": 1, "generated_at": generated_at, "hosts": rows}, indent=2) + "\n"
)

# README: badges only — no table / relative ages (those go stale until the next
# CI commit; badges are the only public signal worth rewriting).
block = "\n".join(
    [
        "",
        "## Fleet",
        "",
        " ".join(badges),
        "",
        "Host presence via private heartbeats (no public IPs). "
        "Badges: online ≤30m · stale ≤24h · else offline. "
        "See [docs/fleet-status.md](docs/fleet-status.md).",
        "",
    ]
)

readme = pathlib.Path(readme_path)
text = readme.read_text()
start, end = "<!-- fleet-status:start -->", "<!-- fleet-status:end -->"
section = f"{start}\n{block}{end}"
if start in text and end in text:
    pre, rest = text.split(start, 1)
    _, post = rest.split(end, 1)
    text = pre + section + post
else:
    lines = text.splitlines(True)
    insert_at = 1
    for i, line in enumerate(lines):
        if i > 0 and line.strip() == "":
            insert_at = i + 1
            break
    lines.insert(insert_at, section + "\n")
    text = "".join(lines)
readme.write_text(text)
print(f"ok: rendered {len(rows)} hosts (badges only)")
PY
