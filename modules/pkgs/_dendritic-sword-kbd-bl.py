#!/usr/bin/env python3
"""Sword 15 keyboard backlight control via HID (never EC).

Probes known SteelSeries/MSIKLM HID IDs. Sends MSIKLM-style 8-byte feature
reports for brightness levels when a device opens. Exit codes:
  0 success
  1 usage / send error
  2 no matching HID device (expected on Linux until Windows factory path exists)
"""
from __future__ import annotations

import argparse
import sys

# (vid, pid) candidates — order: classic MSIKLM, factory MSI block, newer KLC.
CANDIDATES = [
    (0x1770, 0xFF00),  # MSIKLM region RGB
    *[(0x1038, pid) for pid in range(0x2000, 0x2040)],  # ssdevfactory / msihid
    (0x1038, 0x1122),  # MSI KLC (Raider-class)
    (0x1038, 0x1123),
]

# MSIKLM brightness: 0=high 1=medium 2=low 3=off
LEVEL_TO_BRIGHTNESS = {0: 3, 1: 2, 2: 1, 3: 0}
BRIGHTNESS_TO_LEVEL = {v: k for k, v in LEVEL_TO_BRIGHTNESS.items()}

def _default_state_path() -> str:
    import os

    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if runtime:
        return f"{runtime}/dendritic-sword-kbd-bl.level"
    return "/tmp/dendritic-sword-kbd-bl.level"


STATE_PATH_DEFAULT = _default_state_path()


def build_level_packets(level: int) -> list[bytes]:
    """Return feature reports to set all three regions to white at `level` (0–3)."""
    if level < 0 or level > 3:
        raise ValueError("level must be 0..3")
    bright = LEVEL_TO_BRIGHTNESS[level]
    color = 0 if bright == 3 else 8  # off or white preset
    packets = []
    for region in (1, 2, 3):
        packets.append(bytes([0x01, 0x02, 0x42, region, color, bright, 0x00, 0xEC]))
    # mode = normal
    packets.append(bytes([0x01, 0x02, 0x41, 0x01, 0x00, 0x00, 0x00, 0xEC]))
    return packets


def open_device():
    try:
        import hid  # type: ignore
    except ImportError as e:
        print("dendritic-sword-kbd-bl: hidapi not installed", file=sys.stderr)
        raise SystemExit(1) from e

    for vid, pid in CANDIDATES:
        try:
            d = hid.device()
            d.open(vid, pid)
            d.set_nonblocking(1)
            return d, vid, pid
        except Exception:
            continue
    return None, None, None


def cmd_list() -> int:
    try:
        import hid
    except ImportError:
        print("hidapi missing", file=sys.stderr)
        return 1
    found = False
    for info in hid.enumerate():
        vid, pid = info["vendor_id"], info["product_id"]
        if (vid, pid) in CANDIDATES or vid in (0x1038, 0x1770):
            found = True
            print(
                f"{vid:04x}:{pid:04x}  {info.get('product_string')!r}  "
                f"path={info.get('path')!r}"
            )
    if not found:
        print("no SteelSeries/MSIKLM HID candidates present", file=sys.stderr)
        return 2
    return 0


def send_level(level: int) -> int:
    dev, vid, pid = open_device()
    if dev is None:
        print(
            "dendritic-sword-kbd-bl: no HID device "
            "(Windows SteelSeries factory not present under Linux — see "
            "docs/re/sword-kbd-bl/STATUS.md)",
            file=sys.stderr,
        )
        return 2
    try:
        print(f"dendritic-sword-kbd-bl: using {vid:04x}:{pid:04x}", file=sys.stderr)
        for pkt in build_level_packets(level):
            # hidapi: first byte is report ID; MSIKLM uses 0x01 as report id.
            n = dev.send_feature_report(pkt)
            if n < 0:
                print("send_feature_report failed", file=sys.stderr)
                return 1
        return 0
    finally:
        dev.close()


def read_state(path: str) -> int:
    try:
        with open(path, encoding="utf-8") as f:
            return max(0, min(3, int(f.read().strip() or "0")))
    except (OSError, ValueError):
        return 0


def write_state(path: str, level: int) -> None:
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(f"{level}\n")
    except OSError:
        pass


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "--state-file",
        default=STATE_PATH_DEFAULT,
        help="persist last level for cycle (default: %(default)s)",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list", help="list matching HID devices")
    sp = sub.add_parser("set", help="set brightness level 0..3 (0=off)")
    sp.add_argument("level", type=int)
    sub.add_parser("cycle", help="cycle 0→1→2→3→0")
    sub.add_parser("get", help="print last cycled level from state file")

    args = p.parse_args(argv)
    if args.cmd == "list":
        return cmd_list()
    if args.cmd == "get":
        print(read_state(args.state_file))
        return 0
    if args.cmd == "set":
        if args.level < 0 or args.level > 3:
            print("level must be 0..3", file=sys.stderr)
            return 1
        rc = send_level(args.level)
        if rc == 0:
            write_state(args.state_file, args.level)
        return rc
    if args.cmd == "cycle":
        cur = read_state(args.state_file)
        nxt = (cur + 1) % 4
        rc = send_level(nxt)
        if rc == 0:
            write_state(args.state_file, nxt)
            print(nxt)
        return rc
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
