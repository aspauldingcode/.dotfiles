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


# nvidiaPrime only exports DRI_PRIME / __NV_PRIME_RENDER_OFFLOAD /
# __GLX_VENDOR_LIBRARY_NAME. On driver 610.57 that enables VK_LAYER_NV_optimus
# and still enumerates Intel UHD and llvmpipe; __VK_LAYER_NV_optimus=NVIDIA_only
# does not remove them. Rocket League's DXVK then builds a D3D11 device on the
# iGPU and the RTX 3050 Ti stays idle. DXVK_FILTER_DEVICE_NAME is read by the
# DXVK in GE-Proton (d3d11.dll) and drops every device whose name lacks the
# substring. It is not a Vulkan ICD path, so pressure-vessel cannot strand it
# the way VK_DRIVER_FILES can.
DLSS_ENV = (
    ("PROTON_ENABLE_NVAPI", "1"),
    ("PROTON_HIDE_NVIDIA_GPU", "0"),
    ("DXVK_ENABLE_NVAPI", "1"),
    ("PROTON_DLSS_UPGRADE", "1"),
    ("DXVK_FILTER_DEVICE_NAME", "NVIDIA"),
    # This session has no X11 socket. Proton must use the Wine Wayland driver.
    ("PROTON_ENABLE_WAYLAND", "1"),
    ("WINE_GRAPHICS_DRIVER", "wayland"),
    # GE-Proton keeps winex11.drv available for "compatibility fallbacks"
    # and will use an XWayland from the Steam runtime if DISPLAY is set.
    # `d` disables that driver. Proton appends its own overrides after this.
    ("WINEDLLOVERRIDES", "winex11.drv=d"),
    # Heroic's GUI may still have inherited DISPLAY=:0. An empty value
    # overwrites that for the game process. Proton does not clear DISPLAY.
    ("DISPLAY", ""),
)

BOOL_KEYS = {
    "nvidiaPrime": True,
    # gamemoderun preloads libgamemodeauto.so.0; libgamemode.so is not in
    # umu's pressure-vessel, so the preload fails on every launch.
    "useGameMode": False,
    "autoInstallDxvk": True,
    "autoInstallVkd3d": True,
    "autoInstallDxvkNvapi": True,
    # Wine fullscreen FSR (WINE_FULLSCREEN_FSR=1) presented Rocket League
    # at 864x486. Scale with the game's resolution settings instead.
    "enableFSR": False,
    # Heroic injects WINEDEBUG=+fixme, DXVK_LOG_LEVEL=info and
    # VKD3D_DEBUG=fixme when this is true. The fixme spam runs on the
    # game thread.
    "verboseLogs": False,
    # Heroic maps this to PROTON_ENABLE_WAYLAND=1 for Proton.
    "enableWineWayland": True,
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


def host_env() -> tuple[tuple[str, str], ...]:
    """Machine facts Heroic cannot see. Absent on a host that lacks them."""
    extra: list[tuple[str, str]] = []
    eac = Path.home() / ".config" / "heroic" / "tools" / "runtimes" / "eac_runtime"
    bridge = eac / "v2" / "lib64" / "easyanticheat_x64.so"
    if bridge.is_file():
        # ntdll loads this directory when rocketleague_eac starts. Without
        # it that module page-faults a few seconds after the window opens.
        extra.append(("PROTON_EAC_RUNTIME", str(eac)))
    egl = Path("/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json")
    if egl.is_file():
        # Pressure-vessel otherwise reports the NVIDIA PCI id with a null
        # EGL driver and the Wayland surface never finishes presenting.
        extra.append(("__EGL_VENDOR_LIBRARY_FILENAMES", str(egl)))
    drm = Path("/sys/class/drm")
    if drm.is_dir():
        for status in sorted(drm.glob("card*-eDP-1/status")):
            try:
                connected = status.read_text(encoding="utf-8").strip() == "connected"
            except OSError:
                continue
            if connected:
                # xrandr is not installed. Proton then leaves the Wayland
                # driver without a monitor, and the game exclusive-fullscreens
                # a 640x480 VGA mode, which drops the surface.
                extra.append(("PROTON_WAYLAND_MONITOR", "eDP-1"))
                break
    return tuple(extra)


def upsert_env(options: Any, extra: tuple[tuple[str, str], ...] = ()) -> list[dict[str, str]]:
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
    for key, value in (*DLSS_ENV, *extra):
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
    settings["enviromentOptions"] = upsert_env(settings.get("enviromentOptions"), host_env())
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


def self_check() -> None:
    """Merge a fixture and assert the Rocket League GPU/log settings."""
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        config = root / "config.json"
        store = root / "store.json"
        game = root / "Sugar.json"
        config.write_text('{\n  "defaultSettings": {\n    "verboseLogs": true\n  }\n}\n', encoding="utf-8")
        store.write_text(
            '{\n  "settings": {\n    "enableFSR": true,\n    "useGameMode": true,\n    "enviromentOptions": [\n      {"key": "PROTON_ENABLE_NVAPI", "value": "0"}\n    ]\n  }\n}\n',
            encoding="utf-8",
        )
        game.write_text(
            '{\n  "Sugar": {\n    "enableFSR": true,\n    "verboseLogs": true,\n    "useGameMode": true,\n    "wrapperOptions": [\n      {"exe": "/usr/bin/gamescope", "args": ""},\n      {"exe": "/usr/bin/true", "args": "--keep"}\n    ]\n  }\n}\n',
            encoding="utf-8",
        )
        merge_nested(config, "defaultSettings", create=True, proton=None, strip_wrappers=False, extra={"version": "v0"})
        merge_nested(store, "settings", create=False, proton=None, strip_wrappers=False)
        merge_nested(game, "Sugar", create=False, proton=None, strip_wrappers=True)

        def env_map(settings: dict[str, Any]) -> dict[str, str]:
            return {item["key"]: item["value"] for item in settings["enviromentOptions"]}

        for path, key in ((config, "defaultSettings"), (store, "settings"), (game, "Sugar")):
            settings = json.loads(path.read_text(encoding="utf-8"))[key]
            env = env_map(settings)
            if env.get("DXVK_FILTER_DEVICE_NAME") != "NVIDIA":
                raise SystemExit(f"{path.name}: DXVK filter missing: {env}")
            if env.get("PROTON_ENABLE_NVAPI") != "1":
                raise SystemExit(f"{path.name}: NVAPI not forced on")
            for flag in ("enableFSR", "useGameMode", "verboseLogs"):
                if settings.get(flag) is not False:
                    raise SystemExit(f"{path.name}: {flag}={settings.get(flag)}")
            if env.get("PROTON_ENABLE_WAYLAND") != "1" or settings.get("enableWineWayland") is not True:
                raise SystemExit(f"{path.name}: Wine Wayland not forced on")
            if env.get("WINE_GRAPHICS_DRIVER") != "wayland" or env.get("WINEDLLOVERRIDES") != "winex11.drv=d":
                raise SystemExit(f"{path.name}: X11 Wine driver not disabled: {env}")
            if env.get("DISPLAY") != "":
                raise SystemExit(f"{path.name}: DISPLAY not cleared: {env.get('DISPLAY')!r}")
            for key, value in host_env():
                if env.get(key) != value:
                    raise SystemExit(f"{path.name}: {key}={env.get(key)!r}")
        sugar = json.loads(game.read_text(encoding="utf-8"))["Sugar"]
        wrappers = sugar["wrapperOptions"]
        if wrappers != [{"exe": "/usr/bin/true", "args": "--keep"}]:
            raise SystemExit(f"gamescope strip failed: {wrappers}")
    log("self-check ok")


def main() -> int:
    if "--self-check" in sys.argv:
        self_check()
        return 0

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
