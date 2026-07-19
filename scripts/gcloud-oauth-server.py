#!/usr/bin/env python3
"""Localhost Google OAuth (authorization code) → credentials JSON on stdout.

Env:
  GCLOUD_CLIENT_ID       required
  GCLOUD_CLIENT_SECRET   required (gcloud SDK public secret is fine)
  GCLOUD_SCOPES          space-separated (default: cloud-platform + email + openid)
  LISTEN_HOST            default 127.0.0.1
  LISTEN_PORT            default 8765 (0 = ephemeral)
  TIMEOUT_SECS           default 600
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


HOST = os.environ.get("LISTEN_HOST", "localhost")
PORT = int(os.environ.get("LISTEN_PORT", "8765"))
TIMEOUT = int(os.environ.get("TIMEOUT_SECS", "600"))
CLIENT_ID = os.environ["GCLOUD_CLIENT_ID"]
CLIENT_SECRET = os.environ["GCLOUD_CLIENT_SECRET"]
SCOPES = os.environ.get(
    "GCLOUD_SCOPES",
    "openid https://www.googleapis.com/auth/userinfo.email "
    "https://www.googleapis.com/auth/cloud-platform",
)

state = secrets.token_urlsafe(24)
result: dict = {"done": False, "error": None, "oauth": None}


def http_form(url: str, data: dict) -> dict:
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(
        url,
        data=body,
        headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
            "User-Agent": "dendritic-gcloud-bootstrap",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        raise RuntimeError(f"HTTP {e.code} from {url}: {detail}") from e


def exchange_code(code: str, redirect_uri: str) -> dict:
    return http_form(
        "https://oauth2.googleapis.com/token",
        {
            "code": code,
            "client_id": CLIENT_ID,
            "client_secret": CLIENT_SECRET,
            "redirect_uri": redirect_uri,
            "grant_type": "authorization_code",
        },
    )


def fetch_email(access_token: str) -> str:
    req = urllib.request.Request(
        "https://www.googleapis.com/oauth2/v3/userinfo",
        headers={
            "Authorization": f"Bearer {access_token}",
            "User-Agent": "dendritic-gcloud-bootstrap",
        },
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = json.loads(resp.read().decode())
    return str(data.get("email") or "")


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:  # noqa: A003
        return

    def do_GET(self) -> None:  # noqa: N802
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path not in ("/", "/oauth-callback", "/callback"):
            self.send_response(404)
            self.end_headers()
            return

        qs = urllib.parse.parse_qs(parsed.query)
        if qs.get("error"):
            result["error"] = qs["error"][0]
            result["done"] = True
            body = b"<html><body><h1>Denied</h1><p>You can close this tab.</p></body></html>"
            self.send_response(400)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        code = (qs.get("code") or [None])[0]
        got_state = (qs.get("state") or [None])[0]
        if not code or got_state != state:
            result["error"] = "missing code or state mismatch"
            result["done"] = True
            self.send_response(400)
            self.end_headers()
            return

        redirect_uri = f"http://{HOST}:{self.server.server_port}"
        try:
            oauth = exchange_code(code, redirect_uri)
            access = oauth.get("access_token") or ""
            if not access:
                raise RuntimeError(f"no access_token in response: {oauth}")
            email = fetch_email(access)
            oauth["email"] = email
            oauth["client_id"] = CLIENT_ID
            oauth["client_secret"] = CLIENT_SECRET
            oauth["redirect_uri"] = redirect_uri
            result["oauth"] = oauth
            result["done"] = True
            body = (
                b"<html><body><h1>gcloud auth OK</h1>"
                b"<p>You can close this tab and return to the terminal.</p>"
                b"</body></html>"
            )
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        except (urllib.error.URLError, RuntimeError, json.JSONDecodeError) as e:
            result["error"] = str(e)
            result["done"] = True
            body = f"<html><body><h1>Error</h1><pre>{e}</pre></body></html>".encode()
            self.send_response(500)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)


def main() -> int:
    httpd = HTTPServer((HOST, PORT), Handler)
    port = httpd.server_address[1]
    redirect_uri = f"http://{HOST}:{port}"
    # Do NOT set include_granted_scopes: prior gcloud SDK grants often include
    # accounts.reauth, which Google rejects here as invalid_scope (Error 400).
    params = {
        "client_id": CLIENT_ID,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": SCOPES,
        "access_type": "offline",
        "prompt": "consent",
        "state": state,
    }
    auth_url = "https://accounts.google.com/o/oauth2/v2/auth?" + urllib.parse.urlencode(
        params
    )

    print(f"gcloud-oauth: listening on {redirect_uri}", file=sys.stderr)
    print("gcloud-oauth: opening browser…", file=sys.stderr)
    print(f"gcloud-oauth: if browser does not open:\n  {auth_url}", file=sys.stderr)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    webbrowser.open(auth_url)

    deadline = time.time() + TIMEOUT
    while time.time() < deadline and not result["done"]:
        time.sleep(0.2)

    httpd.shutdown()

    if not result["done"]:
        print(json.dumps({"error": "timeout waiting for OAuth callback"}), file=sys.stderr)
        return 1
    if result["error"]:
        print(json.dumps({"error": result["error"]}), file=sys.stderr)
        return 1

    oauth = result["oauth"] or {}
    out = {
        "access_token": oauth.get("access_token"),
        "refresh_token": oauth.get("refresh_token"),
        "expires_in": oauth.get("expires_in", 3600),
        "token_type": oauth.get("token_type", "Bearer"),
        "scope": oauth.get("scope"),
        "email": oauth.get("email") or "",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
    }
    if not out["refresh_token"]:
        print(
            json.dumps(
                {
                    "error": "no refresh_token — revoke prior grant at "
                    "https://myaccount.google.com/permissions and retry with prompt=consent"
                }
            ),
            file=sys.stderr,
        )
        return 1
    json.dump(out, sys.stdout)
    print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
