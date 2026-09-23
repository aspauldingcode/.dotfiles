#!/usr/bin/env python3
"""Write Remmina VNC profiles for 8amps@mba, password from pass materialize.

Remmina encrypts profile passwords with 3DES-CBC using the `secret=` key in
~/.config/remmina/remmina.pref (see remmina_crypt.c). This script does the
same so gnome-keyring is never involved — password=. would prompt forever
when the login keyring is locked.

Password never enters the Nix store. Source is LOGIN_PASSWORD materialized
to ~/.config/dendritic/identity/login.password (macOS Screen Sharing auth
for 8amps is that shared login secret).
"""
from __future__ import annotations

import argparse
import base64
import configparser
import os
import secrets
import subprocess
import sys
from pathlib import Path


def log(msg: str) -> None:
    print(f"dendritic-remmina: {msg}", file=sys.stderr)


def remmina_encrypt(secret_b64: str, plaintext: str) -> str:
    secret = base64.b64decode(secret_b64)
    if len(secret) < 32:
        raise SystemExit("remmina secret corrupted (need ≥32 decoded bytes)")
    key, iv = secret[:24], secret[24:32]
    data = plaintext.encode("utf-8")
    pad = 8 - (len(data) % 8)
    buf = data + b"\x00" * pad
    cipher_mod = None
    for name in ("Cryptodome.Cipher.DES3", "Crypto.Cipher.DES3"):
        try:
            cipher_mod = __import__(name, fromlist=["new"])
            break
        except ImportError:
            continue
    if cipher_mod is not None:
        ct = cipher_mod.new(key, cipher_mod.MODE_CBC, iv).encrypt(buf)
    else:
        proc = subprocess.run(
            [
                "openssl",
                "enc",
                "-des-ede3-cbc",
                "-K",
                key.hex(),
                "-iv",
                iv.hex(),
                "-nopad",
                "-nosalt",
            ],
            input=buf,
            capture_output=True,
            check=False,
        )
        if proc.returncode != 0:
            raise SystemExit(
                "need python3Packages.pycryptodome or openssl enc -des-ede3-cbc "
                f"(openssl: {proc.stderr.decode().strip()})"
            )
        ct = proc.stdout
    return base64.b64encode(ct).decode("ascii")


def load_pref(path: Path) -> configparser.ConfigParser:
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.optionxform = str
    if path.is_file():
        cfg.read(path)
    if not cfg.has_section("remmina_pref"):
        cfg.add_section("remmina_pref")
    return cfg


def ensure_secret(cfg: configparser.ConfigParser) -> str:
    secret = cfg.get("remmina_pref", "secret", fallback="").strip()
    raw = base64.b64decode(secret) if secret else b""
    if len(raw) >= 32:
        return secret
    secret = base64.b64encode(secrets.token_bytes(32)).decode("ascii")
    cfg.set("remmina_pref", "secret", secret)
    log("generated remmina.pref secret")
    return secret


def merge_pref(cfg: configparser.ConfigParser, datadir: Path) -> None:
    pref = cfg["remmina_pref"]
    pref["use_primary_password"] = "false"
    pref["disable_tray_icon"] = "true"
    pref["applet_enable_avahi"] = "true"
    pref["datadir_path"] = str(datadir)
    # GCrypt (3DES) for profile secrets — not libsecret / gnome-keyring.
    pref["enc_mode"] = "4"
    if not cfg.has_section("remmina"):
        cfg.add_section("remmina")
    cfg["remmina"]["ignore-tls-errors"] = "1"


def write_profile(
    path: Path,
    *,
    name: str,
    server: str,
    username: str,
    password_enc: str | None,
    notes: str,
) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    body = [
        "[remmina]",
        f"name={name}",
        "group=dendritic",
        "protocol=VNC",
        f"server={server}",
        f"username={username}",
        f"notes_text={notes}",
        "colordepth=32",
        "quality=9",
        "showcursor=1",
        "viewmode=1",
        "window_maximize=1",
        "scale=1",
        "ignore-tls-errors=1",
        "disablepasswordstoring=0",
        "disableencryption=0",
        "disableclipboard=0",
        "closeonfailure=0",
    ]
    if password_enc:
        body.append(f"password={password_enc}")
    else:
        body.append("password=")
    path.write_text("\n".join(body) + "\n", encoding="utf-8")
    path.chmod(0o600)


def main() -> int:
    home = Path(os.environ.get("HOME", "")).expanduser()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--password-file",
        default=str(home / ".config/dendritic/identity/login.password"),
    )
    parser.add_argument("--username", default="8amps")
    parser.add_argument("--server", default="mba.local")
    parser.add_argument("--wg-server", default="10.87.0.1")
    parser.add_argument("--port", type=int, default=5900)
    parser.add_argument(
        "--pref",
        default=str(home / ".config/remmina/remmina.pref"),
    )
    parser.add_argument(
        "--profile-dir",
        default=str(home / ".local/share/remmina"),
    )
    parser.add_argument(
        "--connect",
        choices=("mba", "mba-wg"),
        help="After writing profiles, exec remmina against that profile.",
    )
    parser.add_argument("--remmina", default="remmina")
    args = parser.parse_args()

    password_file = Path(args.password_file)
    password = ""
    if password_file.is_file():
        password = password_file.read_text(encoding="utf-8").rstrip("\n")
    else:
        log(f"password file missing: {password_file} (profile written, not auth'd)")

    pref_path = Path(args.pref)
    pref_path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    pref = load_pref(pref_path)
    secret = ensure_secret(pref)
    merge_pref(pref, Path(args.profile_dir))
    with pref_path.open("w", encoding="utf-8") as fh:
        pref.write(fh, space_around_delimiters=False)
    pref_path.chmod(0o600)

    password_enc = remmina_encrypt(secret, password) if password else None
    if password:
        log(f"encrypted password from {password_file}")

    profile_dir = Path(args.profile_dir)
    lan = args.server if ":" in args.server else f"{args.server}:{args.port}"
    wg = args.wg_server if ":" in args.wg_server else f"{args.wg_server}:{args.port}"
    profiles = {
        "mba": profile_dir / "dendritic-mba.remmina",
        "mba-wg": profile_dir / "dendritic-mba-wg.remmina",
    }
    write_profile(
        profiles["mba"],
        name=f"{args.username}@mba",
        server=lan,
        username=args.username,
        password_enc=password_enc,
        notes="8amps@mba Screen Sharing (mba.local / Bonjour)",
    )
    write_profile(
        profiles["mba-wg"],
        name=f"{args.username}@mba (wireguard)",
        server=wg,
        username=args.username,
        password_enc=password_enc,
        notes="8amps@mba Screen Sharing over WireGuard 10.87.0.1",
    )
    log(f"wrote {profiles['mba']}")
    log(f"wrote {profiles['mba-wg']}")

    if args.connect:
        os.execvp(args.remmina, [args.remmina, "-c", str(profiles[args.connect])])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
