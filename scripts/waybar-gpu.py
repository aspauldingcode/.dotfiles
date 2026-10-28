#!/usr/bin/env python3
"""Waybar GPU menu for a hybrid Intel + NVIDIA laptop.

The bar label shows which GPU is doing work. The tooltip is the per-program
breakdown (macOS battery-menu shape): engine time share and, when the dGPU
is awake, its memory, power, temperature, and clocks.

Does not call nvidia-smi while the dGPU is in D3cold. A poll that wakes the
chip would undo idle power management.
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path


DRIVERS = {
    "i915": "Intel UHD",
    "xe": "Intel",
    "nvidia": "NVIDIA",
}
STATE_NAME = "waybar-gpu.json"


def util_pct(delta_busy: int, delta_wall: int) -> float:
    if delta_wall <= 0 or delta_busy <= 0:
        return 0.0
    return min(100.0, 100.0 * delta_busy / delta_wall)


def client_busy_ns(engines: dict[str, int]) -> int:
    return max(engines.values()) if engines else 0


def _read(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None


def sysfs_text(path: Path) -> str | None:
    # sysfs values are newline-terminated. Comparing "active\n" to "active"
    # made the bar report a running GPU as asleep.
    text = _read(path)
    if text is None:
        return None
    value = text.strip()
    return value or None


def nvidia_runtime() -> str | None:
    root = Path("/sys/bus/pci/devices")
    if not root.is_dir():
        return None
    for dev in sorted(root.iterdir()):
        if sysfs_text(dev / "vendor") != "0x10de":
            continue
        return sysfs_text(dev / "power" / "runtime_status")
    return None


def program_name(pid: str) -> str:
    comm = (_read(Path(f"/proc/{pid}/comm")) or pid).strip()
    cmdline = _read(Path(f"/proc/{pid}/cmdline")) or ""
    parts = [p for p in cmdline.split("\x00") if p]
    for part in reversed(parts):
        base = Path(part).name
        if base.lower().endswith(".exe"):
            return base
    return comm or pid


def scan_clients() -> list[dict]:
    clients: list[dict] = []
    seen: set[tuple[str, str, str]] = set()
    proc = Path("/proc")
    try:
        pids = [p for p in os.listdir(proc) if p.isdigit()]
    except OSError:
        return clients
    for pid in pids:
        fdinfo = proc / pid / "fdinfo"
        try:
            fds = os.listdir(fdinfo)
        except OSError:
            continue
        for fd in fds:
            text = _read(fdinfo / fd)
            if not text or "drm-driver" not in text:
                continue
            fields: dict[str, str] = {}
            for line in text.splitlines():
                if ":" not in line:
                    continue
                key, value = line.split(":", 1)
                fields[key.strip()] = value.strip()
            driver = fields.get("drm-driver", "")
            if driver not in DRIVERS:
                continue
            cid = fields.get("drm-client-id", fd)
            key = (pid, driver, cid)
            if key in seen:
                continue
            seen.add(key)
            engines: dict[str, int] = {}
            for name, value in fields.items():
                if not name.startswith("drm-engine-"):
                    continue
                try:
                    engines[name.removeprefix("drm-engine-")] = int(value.split()[0])
                except (IndexError, ValueError):
                    continue
            mem_kib = 0
            for mem_key in ("drm-memory-vram", "drm-memory-gtt"):
                raw = fields.get(mem_key)
                if not raw:
                    continue
                try:
                    mem_kib += int(raw.split()[0])
                except (IndexError, ValueError):
                    continue
            clients.append(
                {
                    "key": f"{pid}:{driver}:{cid}",
                    "pid": pid,
                    "driver": driver,
                    "name": program_name(pid),
                    "engines": engines,
                    "busy": client_busy_ns(engines),
                    "mem_kib": mem_kib,
                }
            )
    return clients


def load_state(path: Path) -> dict | None:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return data if isinstance(data, dict) else None


def save_state(path: Path, clients: list[dict], now: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "t": now,
        "clients": {c["key"]: c["busy"] for c in clients},
    }
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(payload), encoding="utf-8")
    os.replace(tmp, path)


def nvidia_processes() -> list[dict]:
    """Processes nvidia-smi attributes to the dGPU.

    This driver's fdinfo does not report drm-engine time for Vulkan clients,
    so a scan of /proc misses Rocket League even while it holds a gigabyte
    of VRAM. Only call this when the device is already awake.
    """
    import subprocess

    smi = os.environ.get("NVIDIA_SMI", "nvidia-smi")
    try:
        proc = subprocess.run(
            [
                smi,
                "--query-compute-apps=pid,process_name,used_gpu_memory",
                "--format=csv,noheader,nounits",
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
    except (OSError, subprocess.TimeoutExpired):
        return []
    if proc.returncode != 0:
        return []
    rows: list[dict] = []
    for line in proc.stdout.splitlines():
        parts = [part.strip() for part in line.split(",")]
        if len(parts) < 3:
            continue
        pid, mem = parts[0], parts[-1]
        name = ",".join(parts[1:-1]).strip()
        base = Path(name.replace("\\", "/")).name or name
        try:
            mem_kib = int(float(mem) * 1024)
        except ValueError:
            mem_kib = 0
        rows.append({"name": base, "pid": pid, "util": 0.0, "mem_kib": mem_kib})
    return rows


def nvidia_query() -> dict | None:
    import subprocess

    smi = os.environ.get("NVIDIA_SMI", "nvidia-smi")
    try:
        proc = subprocess.run(
            [
                smi,
                "--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,clocks.gr",
                "--format=csv,noheader,nounits",
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=2,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    parts = [p.strip() for p in proc.stdout.splitlines()[0].split(",")]
    if len(parts) < 7:
        return None

    def num(raw: str) -> float | None:
        try:
            return float(raw)
        except ValueError:
            return None

    return {
        "name": parts[0],
        "util": num(parts[1]),
        "mem_used": num(parts[2]),
        "mem_total": num(parts[3]),
        "temp": num(parts[4]),
        "power": num(parts[5]),
        "clock": num(parts[6]),
    }


def fmt_mib(kib: int) -> str:
    mib = kib / 1024.0
    if mib >= 100:
        return f"{mib:.0f} MiB"
    if mib >= 10:
        return f"{mib:.0f} MiB"
    return f"{mib:.1f} MiB"


def fmt_pct(value: float) -> str:
    return f"{int(round(value)):03d}%"


def build(now: int | None = None) -> dict:
    now = time.monotonic_ns() if now is None else now
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/tmp/waybar-gpu-{os.getuid()}")
    state_path = Path(runtime) / STATE_NAME
    previous = load_state(state_path)
    clients = scan_clients()
    save_state(state_path, clients, now)

    prev_clients = previous.get("clients", {}) if previous else {}
    prev_t = int(previous["t"]) if previous and "t" in previous else None
    wall = now - prev_t if prev_t is not None else 0

    per_driver: dict[str, list[dict]] = {k: [] for k in DRIVERS}
    for client in clients:
        old = prev_clients.get(client["key"])
        busy = client["busy"] - int(old) if isinstance(old, int) else 0
        if busy < 0:
            busy = 0
        per_driver[client["driver"]].append(
            {
                "name": client["name"],
                "pid": client["pid"],
                "util": util_pct(busy, wall),
                "mem_kib": client["mem_kib"],
            }
        )

    def driver_util(driver: str) -> float:
        return min(100.0, sum(row["util"] for row in per_driver[driver]))

    intel_util = max(driver_util("i915"), driver_util("xe"))
    awake = nvidia_runtime() == "active"
    nv = nvidia_query() if awake else None
    nv_util = nv["util"] if nv and nv["util"] is not None else driver_util("nvidia")
    nv_apps = nvidia_processes() if awake else []
    if not nv_apps:
        nv_apps = per_driver["nvidia"]
    intel_apps = per_driver["i915"] + per_driver["xe"]

    def lines_for(rows: list[dict]) -> list[str]:
        merged: dict[str, dict] = {}
        for row in rows:
            slot = merged.setdefault(row["name"], {"name": row["name"], "util": 0.0, "mem_kib": 0})
            slot["util"] = min(100.0, slot["util"] + row["util"])
            slot["mem_kib"] += row["mem_kib"]
        ranked = sorted(merged.values(), key=lambda row: (row["util"], row["mem_kib"]), reverse=True)
        visible = [row for row in ranked if row["util"] >= 1.0 or row["mem_kib"] >= 1024]
        if not visible:
            visible = ranked[:3]

        def render(row: dict) -> str:
            mem = f"  {fmt_mib(row['mem_kib'])}" if row["mem_kib"] else ""
            return f"  {row['name']}  {fmt_pct(row['util'])}{mem}"

        return [render(row) for row in visible[:8]]

    tooltip = []
    if awake and nv:
        tooltip.append(nv["name"] or "NVIDIA")
        bits = [fmt_pct(nv_util)]
        if nv["power"] is not None:
            bits.append(f"{nv['power']:.0f} W")
        if nv["temp"] is not None:
            bits.append(f"{nv['temp']:.0f}°C")
        if nv["clock"] is not None:
            bits.append(f"{nv['clock']:.0f} MHz")
        tooltip.append("  " + "   ".join(bits))
        if nv["mem_used"] is not None and nv["mem_total"] is not None:
            tooltip.append(f"  {nv['mem_used']:.0f} / {nv['mem_total']:.0f} MiB")
    elif awake:
        tooltip.append(f"NVIDIA  {fmt_pct(nv_util)}")
    else:
        tooltip.append("NVIDIA  asleep")
    tooltip.extend(lines_for(nv_apps) or ["  no program"])
    tooltip.append("")
    tooltip.append(f"Intel UHD  {fmt_pct(intel_util)}")
    tooltip.extend(lines_for(intel_apps) or ["  no program"])

    show_nv = awake and (nv_util >= 3 or any(row["mem_kib"] > 32 * 1024 for row in nv_apps))
    if show_nv:
        text = f"NV {fmt_pct(nv_util)}"
        css = "nvidia"
    else:
        text = f"iGPU {fmt_pct(intel_util)}"
        css = "asleep" if not awake else "intel"

    return {"text": text, "tooltip": "\n".join(tooltip), "class": css}


def self_check() -> None:
    if util_pct(0, 1_000_000_000) != 0:
        raise SystemExit("zero busy must be 0%")
    if abs(util_pct(250_000_000, 1_000_000_000) - 25.0) > 0.01:
        raise SystemExit("25% busy failed")
    if util_pct(5_000_000_000, 1_000_000_000) != 100.0:
        raise SystemExit("cap at 100 failed")
    if client_busy_ns({"render": 10, "copy": 40}) != 40:
        raise SystemExit("busy is the busiest engine")
    if client_busy_ns({}) != 0:
        raise SystemExit("empty engines")
    if sysfs_text(Path("/proc/self/does-not-exist")) is not None:
        raise SystemExit("missing sysfs must be None")
    # The helper reads files. The newline case is what the GPU runtime file uses.
    sample = Path("/tmp/waybar-gpu-sysfs-sample")
    sample.write_text("active\n", encoding="utf-8")
    try:
        if sysfs_text(sample) != "active":
            raise SystemExit("sysfs newline was not stripped")
    finally:
        sample.unlink(missing_ok=True)
    print("waybar-gpu self-check ok")


def main() -> int:
    import sys

    if "--self-check" in sys.argv:
        self_check()
        return 0
    print(json.dumps(build(), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
