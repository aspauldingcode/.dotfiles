# Hot-patch IDE settings.json workbench colors from a dendritic colors.toml.
# settings.json is watched live by Cursor / VS Code / Antigravity.
#
# HM often installs settings.json as a nix-store symlink (immutable). We
# materialize it (read → unlink → write) so wallpaper rotates can update
# Cursor without Reload Window — same pattern as Ghostty themes.
import json
import pathlib
import re
import sys


def load_palette(colors_path: str) -> dict[str, str]:
    palette: dict[str, str] = {}
    for line in pathlib.Path(colors_path).read_text().splitlines():
        m = re.match(r'(base0[0-9A-F])\s*=\s*"?(#?[0-9a-fA-F]{6})"?', line, re.I)
        if not m:
            continue
        val = m.group(2)
        if not val.startswith("#"):
            val = "#" + val
        palette[m.group(1)] = val
    return palette


def normalize_rgb(hex_color: str) -> str:
    return hex_color.strip().lstrip("#")[:6].lower()


def remap_hex(val: str, old_to_new: dict[str, str]) -> str | None:
    if not isinstance(val, str) or not val.startswith("#") or len(val) < 7:
        return None
    body = val[1:]
    rgb, alpha = body[:6].lower(), body[6:]
    new = old_to_new.get(rgb)
    if not new:
        return None
    return f"#{new}{alpha}"


def is_nix_store_symlink(path: pathlib.Path) -> bool:
    try:
        return path.is_symlink() and "/nix/store/" in str(path.readlink())
    except OSError:
        return False


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: dendritic-wallpaper-patch-ide <colors.toml> [prev-colors.toml]", file=sys.stderr)
        sys.exit(2)

    palette = load_palette(sys.argv[1])
    prev = load_palette(sys.argv[2]) if len(sys.argv) > 2 else {}
    old_to_new: dict[str, str] = {}
    for i in range(16):
        key = f"base{i:02X}"
        if key in prev and key in palette:
            o, n = normalize_rgb(prev[key]), normalize_rgb(palette[key])
            if o != n:
                old_to_new[o] = n

    def g(key: str, fallback: str = "base05") -> str:
        return palette.get(key, palette.get(fallback, "#ffffff"))

    patch = {
        "titleBar.activeBackground": g("base00"),
        "titleBar.activeForeground": g("base05"),
        "titleBar.inactiveBackground": g("base01"),
        "titleBar.inactiveForeground": g("base04"),
        "activityBar.background": g("base00"),
        "activityBar.foreground": g("base05"),
        "sideBar.background": g("base00"),
        "sideBar.foreground": g("base05"),
        "editor.background": g("base00"),
        "editor.foreground": g("base05"),
        "editor.lineHighlightBackground": g("base01"),
        "editor.selectionBackground": g("base02"),
        "editorCursor.foreground": g("base05"),
        "editorWidget.background": g("base01"),
        "panel.background": g("base00"),
        "statusBar.background": g("base01"),
        "statusBar.foreground": g("base05"),
        "tab.activeBackground": g("base01"),
        "tab.inactiveBackground": g("base00"),
        "tab.activeForeground": g("base05"),
        "tab.inactiveForeground": g("base04"),
        "terminal.background": g("base00"),
        "terminal.foreground": g("base05"),
        "focusBorder": g("base0D"),
        "button.background": g("base0D"),
        "button.foreground": g("base00"),
        "list.activeSelectionBackground": g("base02"),
        "list.hoverBackground": g("base01"),
    }

    home = pathlib.Path.home()
    candidates = [
        home / "Library/Application Support/Cursor/User/settings.json",
        home / "Library/Application Support/Antigravity/User/settings.json",
        home / "Library/Application Support/Code/User/settings.json",
        home / ".config/Cursor/User/settings.json",
        home / ".config/Antigravity/User/settings.json",
        home / ".config/Code/User/settings.json",
    ]

    for path in candidates:
        if not path.exists() and not path.is_symlink():
            continue
        try:
            data = json.loads(path.read_text())
        except Exception as exc:
            print(f"dendritic-wallpaper: skip {path}: read failed ({exc})")
            continue
        existing = data.get("workbench.colorCustomizations") or {}
        if not isinstance(existing, dict):
            existing = {}
        if old_to_new:
            for k, v in list(existing.items()):
                mapped = remap_hex(v, old_to_new) if isinstance(v, str) else None
                if mapped:
                    existing[k] = mapped
        existing.update(patch)
        data["workbench.colorCustomizations"] = existing
        try:
            materialized = is_nix_store_symlink(path)
            if materialized:
                path.unlink()
            else:
                path.chmod(path.stat().st_mode | 0o200)
            path.write_text(json.dumps(data, indent=2) + "\n")
            suffix = " (materialized HM symlink)" if materialized else ""
            print(f"dendritic-wallpaper: patched {path}{suffix}")
        except PermissionError:
            print(f"dendritic-wallpaper: skip {path}: permission denied")
        except Exception as exc:
            print(f"dendritic-wallpaper: skip {path}: {exc}")


if __name__ == "__main__":
    main()
