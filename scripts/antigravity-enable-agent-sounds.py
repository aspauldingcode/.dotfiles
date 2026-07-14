"""Enable Antigravity agent completion sounds via USS agent preferences."""

import base64
import os
import sqlite3
import sys

SENTINEL = "enableSoundsForSpecialEventsSentinelKey"
TRUE_VALUE = b"\x0a\x04CAE="  # protobuf-wrapped base64 for boolean true
DB_KEY = "antigravityUnifiedStateSync.agentPreferences"


def decode_varint(data, i):
    result = 0
    shift = 0
    while i < len(data):
        b = data[i]
        i += 1
        result |= (b & 0x7f) << shift
        if not (b & 0x80):
            return result, i
        shift += 7
    raise ValueError("truncated varint")


def encode_varint(n):
    out = bytearray()
    while True:
        b = n & 0x7f
        n >>= 7
        out.append(b | (0x80 if n else 0))
        if not n:
            break
    return bytes(out)


def encode_len_field(field_num, data):
    tag = (field_num << 3) | 2
    return encode_varint(tag) + encode_varint(len(data)) + data


def decode_entries(data):
    entries = {}
    i = 0
    while i < len(data):
        tag, i = decode_varint(data, i)
        field = tag >> 3
        wire = tag & 7
        if wire != 2:
            raise ValueError(f"unexpected wire type {wire}")
        length, i = decode_varint(data, i)
        chunk = data[i : i + length]
        i += length
        if field != 1:
            continue
        j = 0
        key = None
        value = None
        while j < len(chunk):
            t, j = decode_varint(chunk, j)
            f = t >> 3
            w = t & 7
            if w != 2:
                raise ValueError(f"unexpected nested wire type {w}")
            length, j = decode_varint(chunk, j)
            s = chunk[j : j + length]
            j += length
            if f == 1:
                key = s.decode()
            elif f == 2:
                value = s
        if key is not None:
            entries[key] = value
    return entries


def encode_preferences(entries):
    parts = []
    for key in sorted(entries):
        body = encode_len_field(1, key.encode()) + encode_len_field(2, entries[key])
        parts.append(encode_len_field(1, body))
    return b"".join(parts)


def candidate_db_paths():
    home = os.environ.get("HOME", "")
    if sys.platform == "darwin":
        yield os.path.join(
            home,
            "Library/Application Support/Antigravity/User/globalStorage/state.vscdb",
        )
    yield os.path.join(home, ".config/Antigravity/User/globalStorage/state.vscdb")
    yield os.path.join(home, ".antigravity/User/globalStorage/state.vscdb")


def main():
    for db_path in candidate_db_paths():
        if not os.path.isfile(db_path):
            continue
        conn = sqlite3.connect(db_path)
        try:
            row = conn.execute(
                "SELECT value FROM ItemTable WHERE key = ?", (DB_KEY,)
            ).fetchone()
            if row is None:
                raw = b""
            else:
                raw = base64.b64decode(row[0])
            entries = decode_entries(raw) if raw else {}
            if entries.get(SENTINEL) == TRUE_VALUE:
                continue
            entries[SENTINEL] = TRUE_VALUE
            encoded = base64.b64encode(encode_preferences(entries)).decode()
            conn.execute(
                "INSERT OR REPLACE INTO ItemTable (key, value) VALUES (?, ?)",
                (DB_KEY, encoded),
            )
            conn.commit()
        finally:
            conn.close()


if __name__ == "__main__":
    main()
