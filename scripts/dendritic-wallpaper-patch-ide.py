# Hot-patch IDE settings.json workbench colors from a dendritic colors.toml.
# settings.json is watched live by Cursor / VS Code / Antigravity.
import json
import pathlib
import re
import sys


def load_palette(colors_path: str) -> dict[str, str]:
    palette: dict[str, str] = {}
    for line in pathlib.Path(colors_path).read_text().splitlines():
        m = re.match(r'(base0[0-9A-F])\s*=\s*"?(#?[0-9a-fA-F]{6})"?', line)
        if not m:
            continue
        val = m.group(2)
        if not val.startswith("#"):
            val = "#" + val
        palette[m.group(1)] = val
    return palette


def main() -> None:
    if len(sys.argv) < 2:
        print("usage: dendritic-wallpaper-patch-ide <colors.toml>", file=sys.stderr)
        sys.exit(2)

    palette = load_palette(sys.argv[1])

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
        if not path.is_file():
            continue
        try:
            data = json.loads(path.read_text())
        except Exception as exc:
            print(f"dendritic-wallpaper: skip {path}: read failed ({exc})")
            continue
        existing = data.get("workbench.colorCustomizations") or {}
        if not isinstance(existing, dict):
            existing = {}
        existing.update(patch)
        data["workbench.colorCustomizations"] = existing
        try:
            path.chmod(path.stat().st_mode | 0o200)
            path.write_text(json.dumps(data, indent=2) + "\n")
            print(f"dendritic-wallpaper: patched {path}")
        except PermissionError:
            # HM/nix often leaves IDE settings read-only; palette still applies
            # via colors.toml. Don't abort the wallpaper apply.
            print(f"dendritic-wallpaper: skip {path}: permission denied")
        except Exception as exc:
            print(f"dendritic-wallpaper: skip {path}: {exc}")


if __name__ == "__main__":
    main()
