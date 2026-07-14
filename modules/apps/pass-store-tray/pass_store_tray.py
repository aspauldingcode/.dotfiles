#!/usr/bin/env python3
"""Pass store sync tray — Darwin menubar + Linux StatusNotifier via Qt."""
from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import QTimer, Qt
from PySide6.QtGui import QAction, QColor, QFont, QIcon, QPainter, QPixmap
from PySide6.QtWidgets import QApplication, QMenu, QSystemTrayIcon

STATUS_FILE = Path(
    os.environ.get("PASS_STORE_SYNC_STATUS", Path.home() / ".cache" / "pass-store-sync.status")
)
LOCK_DIR = Path(
    os.environ.get("PASS_STORE_SYNC_LOCK", Path.home() / ".cache" / "pass-store-sync.lock")
)
SYNC_SCRIPT = os.environ.get("PASS_STORE_SYNC_SCRIPT", "")
MATERIALIZE_SCRIPT = os.environ.get("PASS_MATERIALIZE_SCRIPT", "")
SYNC_LOG = Path.home() / ".cache" / "pass-store-sync.log"
PASSWORD_STORE_DIR = os.environ.get(
    "PASSWORD_STORE_DIR", str(Path.home() / ".password-store")
)

REBUILD_PATTERNS = (
    "nh darwin",
    "nh os",
    "darwin-rebuild",
    "nixos-rebuild",
    "nix-darwin-rebuild",
)


def rebuild_running() -> bool:
    try:
        out = subprocess.check_output(["ps", "-ax", "-o", "command="], text=True, errors="replace")
    except (OSError, subprocess.CalledProcessError):
        return False
    for line in out.splitlines():
        low = line.lower()
        if "pass-store-tray" in low:
            continue
        for pat in REBUILD_PATTERNS:
            if pat in low:
                return True
    return False


def load_status() -> dict:
    if not STATUS_FILE.is_file():
        return {
            "state": "idle",
            "direction": "none",
            "message": "no status yet",
            "updated_at": None,
            "ahead_behind": "unknown",
            "error": None,
            "materialized": [],
            "last_pull_at": None,
            "last_push_at": None,
            "last_materialize_at": None,
        }
    try:
        return json.loads(STATUS_FILE.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {
            "state": "error",
            "direction": "none",
            "message": "status unreadable",
            "error": "bad status json",
        }


def make_icon(kind: str) -> QIcon:
    """Paint a simple 64x64 status glyph."""
    pm = QPixmap(64, 64)
    pm.fill(Qt.GlobalColor.transparent)
    p = QPainter(pm)
    p.setRenderHint(QPainter.RenderHint.Antialiasing)
    font = QFont(".AppleSystemUIFont", 28, QFont.Weight.Bold)
    if sys.platform != "darwin":
        font = QFont("Sans Serif", 28, QFont.Weight.Bold)
    p.setFont(font)

    if kind == "up":
        p.setPen(QColor("#3b82f6"))  # blue
        p.drawText(pm.rect(), Qt.AlignmentFlag.AlignCenter, "↑")
    elif kind == "down":
        p.setPen(QColor("#3b82f6"))
        p.drawText(pm.rect(), Qt.AlignmentFlag.AlignCenter, "↓")
    elif kind == "error":
        p.setPen(QColor("#ef4444"))
        p.drawText(pm.rect(), Qt.AlignmentFlag.AlignCenter, "!")
    elif kind == "rebuild":
        p.setPen(QColor("#f59e0b"))  # amber
        p.drawText(pm.rect(), Qt.AlignmentFlag.AlignCenter, "↻")
    else:  # idle / complete green
        p.setPen(QColor("#22c55e"))
        p.drawText(pm.rect(), Qt.AlignmentFlag.AlignCenter, "✓")
    p.end()
    return QIcon(pm)


def icon_kind(status: dict, rebuilding: bool) -> str:
    if rebuilding:
        return "rebuild"
    state = status.get("state") or "idle"
    direction = status.get("direction") or "none"
    if state == "error":
        return "error"
    if state == "uploading" or (state != "idle" and direction == "up"):
        return "up"
    if state == "downloading" or (state != "idle" and direction == "down"):
        return "down"
    return "idle"


def run_bg(env_extra: dict, argv: list[str]) -> None:
    env = os.environ.copy()
    env.update(env_extra)
    subprocess.Popen(
        argv,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


class PassTray:
    def __init__(self) -> None:
        self.app = QApplication(sys.argv)
        self.app.setQuitOnLastWindowClosed(False)
        self.tray = QSystemTrayIcon()
        self.menu = QMenu()
        self.status_action = QAction("Status: …")
        self.status_action.setEnabled(False)
        self.menu.addAction(self.status_action)
        self.detail_action = QAction("")
        self.detail_action.setEnabled(False)
        self.menu.addAction(self.detail_action)
        self.mat_action = QAction("")
        self.mat_action.setEnabled(False)
        self.menu.addAction(self.mat_action)
        self.menu.addSeparator()

        pull = QAction("Pull now")
        pull.triggered.connect(self.do_pull)
        self.menu.addAction(pull)

        remat = QAction("Rematerialize secrets")
        remat.triggered.connect(self.do_materialize)
        self.menu.addAction(remat)

        qtpass = QAction("Open QtPass")
        qtpass.triggered.connect(self.open_qtpass)
        self.menu.addAction(qtpass)

        logs = QAction("Open sync log")
        logs.triggered.connect(self.open_log)
        self.menu.addAction(logs)

        self.menu.addSeparator()
        quit_a = QAction("Quit")
        quit_a.triggered.connect(self.app.quit)
        self.menu.addAction(quit_a)

        self.tray.setContextMenu(self.menu)
        self.tray.setToolTip("pass store sync")
        self.tray.setIcon(make_icon("idle"))

        self.timer = QTimer()
        self.timer.timeout.connect(self.refresh)
        self.timer.start(2000)
        self.refresh()
        self.tray.show()

    def do_pull(self) -> None:
        if not SYNC_SCRIPT:
            return
        run_bg(
            {
                "PASS_STORE_SYNC_MODE": "pull",
                "PASSWORD_STORE_DIR": PASSWORD_STORE_DIR,
            },
            ["bash", SYNC_SCRIPT],
        )

    def do_materialize(self) -> None:
        if not MATERIALIZE_SCRIPT:
            return
        run_bg(
            {"PASSWORD_STORE_DIR": PASSWORD_STORE_DIR},
            ["bash", MATERIALIZE_SCRIPT],
        )

    def open_qtpass(self) -> None:
        for cmd in (("qtpass",), ("open", "-a", "QtPass")):
            try:
                subprocess.Popen(list(cmd), start_new_session=True)
                return
            except OSError:
                continue

    def open_log(self) -> None:
        path = str(SYNC_LOG)
        if sys.platform == "darwin":
            subprocess.Popen(["open", "-t", path], start_new_session=True)
        else:
            for cmd in (("xdg-open", path), ("less", path)):
                try:
                    subprocess.Popen(list(cmd), start_new_session=True)
                    return
                except OSError:
                    continue

    def refresh(self) -> None:
        status = load_status()
        rebuilding = rebuild_running()
        kind = icon_kind(status, rebuilding)
        self.tray.setIcon(make_icon(kind))

        state = status.get("state") or "idle"
        direction = status.get("direction") or "none"
        msg = status.get("message") or ""
        ab = status.get("ahead_behind") or "unknown"
        updated = status.get("updated_at") or "—"
        err = status.get("error")
        mats = status.get("materialized") or []
        last_mat = status.get("last_materialize_at") or "—"

        if rebuilding:
            headline = "Rebuilding system…"
        elif LOCK_DIR.exists():
            headline = f"Syncing ({direction})…"
        elif err:
            headline = f"Error: {err}"
        else:
            headline = f"{state} · {direction}"

        self.status_action.setText(headline)
        self.detail_action.setText(f"{msg} · {ab} · {updated}")
        mat_txt = ", ".join(mats) if mats else "(none)"
        self.mat_action.setText(f"Materialized: {mat_txt} @ {last_mat}")
        tip = f"pass sync: {headline}\n{msg}"
        self.tray.setToolTip(tip)

    def run(self) -> int:
        return self.app.exec()


def main() -> int:
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    # QApplication must exist before isSystemTrayAvailable() on macOS (else SIGSEGV).
    tray = PassTray()
    if not QSystemTrayIcon.isSystemTrayAvailable():
        print("pass-store-tray: no system tray available", file=sys.stderr)
        return 1
    return tray.run()


if __name__ == "__main__":
    raise SystemExit(main())
