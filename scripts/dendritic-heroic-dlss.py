#!/usr/bin/env python3
"""Merge Proton-GE DLSS/NVAPI + PRIME settings into Heroic's mutable JSON.

Heroic rewrites its own config. Never replace the files wholesale — upsert
only the keys this module owns. GlobalConfig reads config.json
`defaultSettings`; setSetting also mirrors into electron-store
store/config.json `settings`. Per-game overrides live under GamesConfig/.

Do not inject gamescope wrappers on niri: nested gamescope-wl has ABRTed
the compositor. Strip bare gamescope entries from Rocket League instead.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any


DLSS_ENV = (
    ("PROTON_ENABLE_NVAPI", "1"),
    ("PROTON_HIDE_NVIDIA_GPU", "0"),
    ("DXVK_ENABLE_NVAPI", "1"),
    ("PROTON_DLSS_UPGRADE", "1"),
)

BOOL_KEYS = {
    "nvidiaPrime": True,
    "useGameMode": True,
    "autoInstallDxvk": True,
    "autoInstallVkd3d": True,
    "autoInstallDxvkNvapi": True,
}


def log(msg: str) -> None:
    print(f"dendritic-heroic: {msg}", file=sys.stderr)


def detect_indent(text: str) -> str | None:
    for line in text.splitlines()[1:6]:
        stripped = line.lstrip(" \t")
        if stripped and stripped != line:
            return line[: len(line) - len(stripped)]
    return None


def load_json(path: Path) -> tuple[dict[str, Any], str | None]:
    if not path.is_file():
        return {}, None
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        return {}, None
    data = json.loads(text)
    if not isinstance(data, dict):
        raise SystemExit(f"{path}: expected a JSON object")
    return data, detect_indent(text)


def atomic_write(path: Path, data: dict[str, Any], indent: str | None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(data, indent=indent if indent is not None else 2, ensure_ascii=False)
    if not payload.endswith("\n"):
        payload += "\n"
    tmp = path.with_name(f".{path.name}.dendritic.tmp")
    tmp.write_text(payload, encoding="utf-8")
    os.replace(tmp, path)


def upsert_env(options: Any) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    seen: set[str] = set()
    if isinstance(options, list):
        for item in options:
            if not isinstance(item, dict):
                continue
            key = item.get("key")
            if not isinstance(key, str) or not key:
                continue
            value = item.get("value", "")
            out.append({"key": key, "value": str(value)})
            seen.add(key)
    for key, value in DLSS_ENV:
        if key in seen:
            for item in out:
                if item["key"] == key:
                    item["value"] = value
                    break
        else:
            out.append({"key": key, "value": value})
    return out


def strip_gamescope(options: Any) -> list[dict[str, str]]:
    out: list[dict[str, str]] = []
    if not isinstance(options, list):
        return out
    for item in options:
        if not isinstance(item, dict):
            continue
        existing_exe = item.get("exe")
        if not isinstance(existing_exe, str) or not existing_exe:
            continue
        name = Path(existing_exe).name
        if name in ("gamescope", "dendritic-rl-fsr", "dendritic-rl-fsr.sh"):
            continue
        existing_args = item.get("args", "")
        out.append({"exe": existing_exe, "args": str(existing_args)})
    return out


def apply_settings(
    settings: dict[str, Any],
    *,
    proton: Path | None,
    strip_wrappers: bool,
) -> None:
    settings.update(BOOL_KEYS)
    settings["enviromentOptions"] = upsert_env(settings.get("enviromentOptions"))
    if proton is not None and proton.is_file():
        settings["wineVersion"] = {
            "bin": str(proton),
            "name": "GE-Proton-latest",
            "type": "proton",
        }
    if strip_wrappers:
        settings["wrapperOptions"] = strip_gamescope(settings.get("wrapperOptions"))


def merge_nested(
    path: Path,
    key: str,
    *,
    create: bool,
    proton: Path | None,
    strip_wrappers: bool,
    extra: dict[str, Any] | None = None,
) -> bool:
    if not path.is_file() and not create:
        log(f"skip missing {path}")
        return False
    data, indent = load_json(path)
    if extra:
        for extra_key, extra_val in extra.items():
            data.setdefault(extra_key, extra_val)
    nested = data.get(key)
    if not isinstance(nested, dict):
        nested = {}
        data[key] = nested
    apply_settings(
        nested,
        proton=proton,
        strip_wrappers=strip_wrappers,
    )
    atomic_write(path, data, indent)
    log(f"merged {path} [{key}]")
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--store-config", type=Path)
    parser.add_argument("--game-config", type=Path)
    parser.add_argument("--game-key", default="Sugar")
    parser.add_argument("--proton", type=Path)
    parser.add_argument(
        "--strip-gamescope",
        action="store_true",
        help="Remove gamescope / dendritic-rl-fsr from wrapperOptions (Rocket League).",
    )
    args = parser.parse_args()

    proton = args.proton if args.proton is not None else None

    merge_nested(
        args.config,
        "defaultSettings",
        create=True,
        proton=proton,
        strip_wrappers=False,
        extra={"version": "v0"},
    )

    if args.store_config is not None:
        merge_nested(
            args.store_config,
            "settings",
            create=False,
            proton=proton,
            strip_wrappers=False,
        )

    if args.game_config is not None:
        merge_nested(
            args.game_config,
            args.game_key,
            create=False,
            proton=proton,
            strip_wrappers=args.strip_gamescope,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
