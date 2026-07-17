"""Disable Cursor Agent commit/PR attribution (Made-with / Co-authored-by).

Reverse-engineered from Cursor 3.9.x:

1. UI (Agent / Git & PRs → Attribution) is NOT settings.json.
   It reads/writes application storage via keys:
     cursor/attributeCommitsToAgent
     cursor/attributePRsToAgent
   Storage path: <User>/globalStorage/state.vscdb → ItemTable
   Values: strings "true" / "false" (default true when missing).
   Key prefix comes from rQi(name) => "cursor/" + name.

2. When enabled, the agent request sets:
     commitAttributionMessage / prAttributionMessage = "enabled"

3. cursor-agent-exec then rewrites shell commands to inject:
     git commit … --trailer "Co-authored-by: Cursor <cursoragent@cursor.com>"
     gh pr create … body += "\\n\\nMade with [Cursor](https://cursor.com)"
"""

from __future__ import annotations

import os
import sqlite3
import sys

KEYS = (
    "cursor/attributeCommitsToAgent",
    "cursor/attributePRsToAgent",
)
VALUE = "false"


def db_candidates() -> list[str]:
    home = os.path.expanduser("~")
    return [
        # macOS
        os.path.join(
            home,
            "Library/Application Support/Cursor/User/globalStorage/state.vscdb",
        ),
        # Linux
        os.path.join(home, ".config/Cursor/User/globalStorage/state.vscdb"),
    ]


def patch(db_path: str) -> bool:
    if not os.path.isfile(db_path):
        return False
    con = sqlite3.connect(db_path)
    try:
        cur = con.cursor()
        cur.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='ItemTable'"
        )
        if not cur.fetchone():
            print(f"cursor-disable-attribution: no ItemTable in {db_path}", file=sys.stderr)
            return False
        for key in KEYS:
            cur.execute(
                "INSERT INTO ItemTable (key, value) VALUES (?, ?) "
                "ON CONFLICT(key) DO UPDATE SET value=excluded.value",
                (key, VALUE),
            )
        con.commit()
        print(f"cursor-disable-attribution: set {KEYS} = {VALUE!r} in {db_path}")
        return True
    finally:
        con.close()


def main() -> int:
    patched = False
    for path in db_candidates():
        if patch(path):
            patched = True
    if not patched:
        print(
            "cursor-disable-attribution: no Cursor state.vscdb found yet (ok on first boot)",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
