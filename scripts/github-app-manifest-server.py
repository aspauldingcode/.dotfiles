#!/usr/bin/env python3
"""Localhost GitHub App Manifest handshake → credentials JSON on stdout.

Env:
  MANIFEST_PATH   path to base manifest JSON
  LISTEN_HOST     default 127.0.0.1
  LISTEN_PORT     default 8741
  TIMEOUT_SECS    default 600
"""
from __future__ import annotations

import json
import os
import secrets
import sys
import threading
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer


HOST = os.environ.get("LISTEN_HOST", "127.0.0.1")
PORT = int(os.environ.get("LISTEN_PORT", "8741"))
TIMEOUT = int(os.environ.get("TIMEOUT_SECS", "600"))
MANIFEST_PATH = os.environ["MANIFEST_PATH"]

state = secrets.token_urlsafe(16)
result: dict = {"done": False, "error": None, "credentials": None, "oauth": None}
phase = {"value": "manifest"}  # manifest → oauth → done


def load_manifest() -> dict:
    with open(MANIFEST_PATH, encoding="utf-8") as f:
        m = json.load(f)
    base = f"http://{HOST}:{PORT}"
    m["redirect_url"] = f"{base}/manifest-callback"
    m["callback_urls"] = [f"{base}/oauth-callback"]
    # Ensure webhook inactive
    m.setdefault("hook_attributes", {})
    m["hook_attributes"]["active"] = False
    m["hook_attributes"].setdefault("url", "https://example.com/dendritic-cli-auth-webhook")
    return m


MANIFEST = load_manifest()


def http_json(url: str, method: str = "GET", data: dict | None = None) -> dict:
    body = None
    headers = {
        "Accept": "application/json",
        "User-Agent": "dendritic-github-app-bootstrap",
    }
    if data is not None:
        body = urllib.parse.urlencode(data).encode()
        headers["Content-Type"] = "application/x-www-form-urlencoded"
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode())


def convert_manifest(code: str) -> dict:
    url = f"https://api.github.com/app-manifests/{urllib.parse.quote(code)}/conversions"
    req = urllib.request.Request(
        url,
        data=b"",
        method="POST",
        headers={
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "dendritic-github-app-bootstrap",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode())


def exchange_oauth(code: str, client_id: str, client_secret: str) -> dict:
    return http_json(
        "https://github.com/login/oauth/access_token",
        method="POST",
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "code": code,
            "redirect_uri": f"http://{HOST}:{PORT}/oauth-callback",
        },
    )


REGISTER_HTML = """<!doctype html>
<html><head><meta charset="utf-8"><title>Register dendritic-cli-auth</title></head>
<body>
  <h1>Register dendritic GitHub App</h1>
  <p>Submitting deterministic manifest (permissions from flake)…</p>
  <form id="f" action="https://github.com/settings/apps/new?state={state}" method="post">
    <input type="hidden" name="manifest" id="manifest">
    <button type="submit">Create GitHub App</button>
  </form>
  <script>
    document.getElementById('manifest').value = {manifest_json};
    document.getElementById('f').submit();
  </script>
</body></html>
"""


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:  # quiet
        sys.stderr.write("github-app-bootstrap: " + (fmt % args) + "\n")

    def _html(self, code: int, body: str) -> None:
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)

        if parsed.path in ("/", "/register"):
            html = REGISTER_HTML.format(
                state=state,
                manifest_json=json.dumps(json.dumps(MANIFEST)),
            )
            self._html(200, html)
            return

        if parsed.path == "/manifest-callback":
            if qs.get("state", [None])[0] != state:
                self._html(400, "<h1>Invalid state</h1>")
                result["error"] = "invalid state on manifest callback"
                result["done"] = True
                return
            code = qs.get("code", [None])[0]
            if not code:
                err = qs.get("error_description", qs.get("error", ["missing code"]))[0]
                self._html(400, f"<h1>Manifest failed</h1><pre>{err}</pre>")
                result["error"] = str(err)
                result["done"] = True
                return
            try:
                creds = convert_manifest(code)
            except Exception as e:  # noqa: BLE001
                self._html(500, f"<h1>Conversion failed</h1><pre>{e}</pre>")
                result["error"] = str(e)
                result["done"] = True
                return
            result["credentials"] = creds
            phase["value"] = "oauth"
            client_id = creds["client_id"]
            auth_url = (
                "https://github.com/login/oauth/authorize?"
                + urllib.parse.urlencode(
                    {
                        "client_id": client_id,
                        "redirect_uri": f"http://{HOST}:{PORT}/oauth-callback",
                        "state": state,
                    }
                )
            )
            # Also nudge install on this account
            slug = creds.get("slug") or MANIFEST.get("name")
            install_url = f"https://github.com/apps/{slug}/installations/new"
            self._html(
                200,
                f"""<!doctype html><html><body>
                <h1>App created</h1>
                <p>Next: authorize as your user (refresh tokens).</p>
                <p><a href="{auth_url}">Continue OAuth</a></p>
                <p>If prompted, also install on your account:
                   <a href="{install_url}">Install App</a></p>
                <script>location.href={json.dumps(auth_url)};</script>
                </body></html>""",
            )
            return

        if parsed.path == "/oauth-callback":
            if qs.get("state", [None])[0] != state:
                self._html(400, "<h1>Invalid state</h1>")
                result["error"] = "invalid state on oauth callback"
                result["done"] = True
                return
            code = qs.get("code", [None])[0]
            if not code:
                err = qs.get("error_description", qs.get("error", ["missing code"]))[0]
                self._html(400, f"<h1>OAuth failed</h1><pre>{err}</pre>")
                result["error"] = str(err)
                result["done"] = True
                return
            creds = result.get("credentials") or {}
            try:
                tok = exchange_oauth(code, creds["client_id"], creds["client_secret"])
            except Exception as e:  # noqa: BLE001
                self._html(500, f"<h1>Token exchange failed</h1><pre>{e}</pre>")
                result["error"] = str(e)
                result["done"] = True
                return
            if tok.get("error"):
                self._html(400, f"<h1>Token error</h1><pre>{tok}</pre>")
                result["error"] = json.dumps(tok)
                result["done"] = True
                return
            result["oauth"] = tok
            result["done"] = True
            phase["value"] = "done"
            self._html(
                200,
                """<!doctype html><html><body>
                <h1>Bootstrap complete</h1>
                <p>Credentials stored by the CLI. You can close this tab.</p>
                </body></html>""",
            )
            return

        self._html(404, "<h1>Not found</h1>")


def main() -> int:
    server = HTTPServer((HOST, PORT), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    url = f"http://{HOST}:{PORT}/register"
    sys.stderr.write(f"github-app-bootstrap: open {url}\n")
    try:
        webbrowser.open(url)
    except Exception:  # noqa: BLE001
        pass

    start = time.time()
    while not result["done"] and time.time() - start < TIMEOUT:
        time.sleep(0.25)

    server.shutdown()

    if result["error"]:
        sys.stderr.write(f"github-app-bootstrap: error: {result['error']}\n")
        return 1
    if not result["credentials"] or not result["oauth"]:
        sys.stderr.write("github-app-bootstrap: timed out waiting for browser flow\n")
        return 1

    out = {
        "credentials": {
            "id": result["credentials"].get("id"),
            "slug": result["credentials"].get("slug"),
            "client_id": result["credentials"].get("client_id"),
            "client_secret": result["credentials"].get("client_secret"),
            "pem": result["credentials"].get("pem"),
            "html_url": result["credentials"].get("html_url"),
        },
        "oauth": {
            "access_token": result["oauth"].get("access_token"),
            "refresh_token": result["oauth"].get("refresh_token"),
            "expires_in": result["oauth"].get("expires_in"),
            "refresh_token_expires_in": result["oauth"].get("refresh_token_expires_in"),
            "token_type": result["oauth"].get("token_type"),
        },
    }
    json.dump(out, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        sys.stderr.write(f"HTTP {e.code}: {body}\n")
        raise SystemExit(1)
