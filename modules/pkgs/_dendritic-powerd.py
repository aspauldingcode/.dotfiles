"""dendritic-powerd — acoustic/thermal feedback controller for laptops.

Policy: stay quiet. Mechanism: converge RAPL PL1/PL2, then EPP, then
max_perf_pct. Inputs are measured; PL1 is solved for, not hard-coded.
"""

from __future__ import annotations

import argparse
import json
import os
import signal
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

RAPL_PKG = Path("/sys/class/powercap/intel-rapl:0")
PSTATE = Path("/sys/devices/system/cpu/intel_pstate")
CPUFREQ_BASE = Path("/sys/devices/system/cpu")
STATE_DIR = Path("/var/lib/dendritic-power")
RUN_DIR = Path("/run/dendritic-power")
STATUS_PATH = RUN_DIR / "status.json"
CAL_PATH = STATE_DIR / "calibration.json"

# Soft search bounds for PL1 (W). Daemon converges inside these.
PL1_MIN_W = 22.0
PL1_MAX_W_BAT = 38.0
PL1_MAX_W_AC = 48.0
PL2_BONUS_W = 15.0

# Acoustic / thermal targets (policy, not hard trips)
TARGET_TEMP_C = 72.0
QUIET_FAN_RPM = 2800
LOUD_FAN_RPM = 4000

INTERVAL_S = 2.5
EMA_ALPHA = 0.12  # ~25s window at 2.5s tick


@dataclass
class Ema:
    value: Optional[float] = None

    def update(self, x: float) -> float:
        if self.value is None:
            self.value = x
        else:
            self.value = EMA_ALPHA * x + (1.0 - EMA_ALPHA) * self.value
        return self.value


@dataclass
class Cal:
    fan_step_rpm: float = QUIET_FAN_RPM
    idle_pkg_w: float = 8.0
    samples: int = 0


@dataclass
class Controller:
    pl1_w: float = 35.0
    last_write_pl1: float = -1.0
    last_write_epp: str = ""
    last_write_perf: int = -1
    cooldown_until: float = 0.0
    pkg_power: Ema = field(default_factory=Ema)
    pkg_temp: Ema = field(default_factory=Ema)
    fan_rpm: Ema = field(default_factory=Ema)
    prev_energy_uj: Optional[int] = None
    prev_energy_t: Optional[float] = None
    ac_online: bool = True
    docked: bool = False
    workload: str = "idle"
    reason: str = "init"
    acoustic: str = "quiet"
    epp: str = "balance_power"
    backlight_saved: Optional[int] = None
    cal: Cal = field(default_factory=Cal)


def read_int(path: Path, default: Optional[int] = None) -> Optional[int]:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return default


def write_text(path: Path, value: str) -> bool:
    try:
        path.write_text(value)
        return True
    except OSError:
        return False


def read_pkg_energy_uj() -> Optional[int]:
    return read_int(RAPL_PKG / "energy_uj")


def measure_pkg_power_w(ctl: Controller, now: float) -> Optional[float]:
    uj = read_pkg_energy_uj()
    if uj is None:
        return None
    if ctl.prev_energy_uj is not None and ctl.prev_energy_t is not None:
        dt = now - ctl.prev_energy_t
        if dt > 0.2:
            watts = (uj - ctl.prev_energy_uj) / dt / 1_000_000.0
            if watts < 0:
                # counter wrap
                watts = 0.0
            ctl.prev_energy_uj = uj
            ctl.prev_energy_t = now
            return max(0.0, min(watts, 200.0))
    ctl.prev_energy_uj = uj
    ctl.prev_energy_t = now
    return None


def find_pkg_temp_c() -> Optional[float]:
    thermal = Path("/sys/class/thermal")
    if not thermal.exists():
        return None
    # Prefer x86_pkg_temp
    for zone in sorted(thermal.glob("thermal_zone*")):
        try:
            if (zone / "type").read_text().strip() == "x86_pkg_temp":
                return read_int(zone / "temp", 0) / 1000.0  # type: ignore[operator]
        except OSError:
            continue
    for zone in sorted(thermal.glob("thermal_zone*")):
        try:
            t = (zone / "type").read_text().strip()
            if t in ("TCPU", "acpitz"):
                return read_int(zone / "temp", 0) / 1000.0  # type: ignore[operator]
        except OSError:
            continue
    return None


def find_fan1_rpm() -> Optional[float]:
    hwmon = Path("/sys/class/hwmon")
    if not hwmon.exists():
        return None
    for h in hwmon.glob("hwmon*"):
        try:
            name = (h / "name").read_text().strip()
        except OSError:
            continue
        if "msi" not in name and "fan" not in name:
            # still try any fan1
            pass
        fan = h / "fan1_input"
        if fan.exists():
            v = read_int(fan)
            if v is not None and v > 0:
                return float(v)
    # fallback any fan1
    for fan in hwmon.glob("hwmon*/fan1_input"):
        v = read_int(fan)
        if v is not None and v > 0:
            return float(v)
    return None


def ac_is_online() -> bool:
    for p in Path("/sys/class/power_supply").glob("*"):
        try:
            if (p / "type").read_text().strip() != "Mains":
                continue
            return (p / "online").read_text().strip() == "1"
        except OSError:
            continue
    return True


def nvidia_runtime_active() -> bool:
    for d in Path("/sys/bus/pci/devices").glob("*"):
        try:
            if (d / "vendor").read_text().strip() != "0x10de":
                continue
            return (d / "power/runtime_status").read_text().strip() == "active"
        except OSError:
            continue
    return False


def external_display_active() -> bool:
    drm = Path("/sys/class/drm")
    if not drm.exists():
        return False
    for conn in drm.glob("card*-*"):
        name = conn.name
        if "eDP" in name or "Writeback" in name or "HDMI-A-1" == name.split("-", 1)[-1]:
            # still count non-eDP connected
            pass
        if "eDP" in name:
            continue
        try:
            if (conn / "status").read_text().strip() == "connected":
                return True
        except OSError:
            continue
    return False


def usb_audio_present() -> bool:
    for d in Path("/sys/bus/usb/devices").glob("*"):
        prod = d / "product"
        if not prod.exists():
            continue
        try:
            p = prod.read_text().lower()
        except OSError:
            continue
        if any(
            k in p for k in ("scarlett", "focusrite", "audio", "microphone", "headset")
        ):
            return True
        # class check via bInterfaceClass is harder; product heuristics enough
    return False


def usb_nic_up() -> bool:
    for iface in Path("/sys/class/net").glob("*"):
        if iface.name in ("lo", "wlo1", "wlan0"):
            continue
        # skip built-in ethernet name patterns that are down-only later
        try:
            oper = (iface / "operstate").read_text().strip()
        except OSError:
            continue
        if oper != "up":
            continue
        # USB device path?
        try:
            device = (iface / "device").resolve()
            if "usb" in str(device):
                return True
        except OSError:
            continue
    return False


def usb_dock_markers_present() -> bool:
    """Strong dock signals from this machine's known heavy peripherals."""
    # AX88179 USB NIC (0b95:1790), SMI USB Display (090c:0768) — measured on Sword dock.
    markers = {
        ("0b95", "1790"),
        ("090c", "0768"),
        ("25a4", "9311"),
    }  # USB-C video adaptor
    for d in Path("/sys/bus/usb/devices").glob("*"):
        vend = d / "idVendor"
        prod = d / "idProduct"
        if not vend.exists() or not prod.exists():
            continue
        try:
            pair = (vend.read_text().strip().lower(), prod.read_text().strip().lower())
        except OSError:
            continue
        if pair in markers:
            return True
        try:
            name = (d / "product").read_text().lower()
        except OSError:
            continue
        if any(k in name for k in ("ax88179", "smi usb display", "usb c video")):
            return True
    return False


def detect_docked(ac: bool) -> bool:
    """Capability-based dock: markers, external display, USB NIC/audio, busy hub tree."""
    flags = 0
    if usb_dock_markers_present():
        flags += 2  # definitive on this laptop
    if external_display_active():
        flags += 1
    if usb_nic_up():
        flags += 1
    if usb_audio_present():
        flags += 1
    if ac:
        active = 0
        for d in Path("/sys/bus/usb/devices").glob("*"):
            if not (d / "idVendor").exists():
                continue
            try:
                if (d / "power/runtime_status").read_text().strip() == "active":
                    active += 1
            except OSError:
                continue
        if active >= 8:
            flags += 1
    return flags >= 2


def set_rapl_watts(pl1_w: float, pl2_w: float) -> None:
    """Write PL1 then PL2; never allow PL2 < PL1 (kernel may ignore)."""
    if pl2_w < pl1_w:
        pl2_w = pl1_w
    pl1_uw = str(int(pl1_w * 1_000_000))
    pl2_uw = str(int(pl2_w * 1_000_000))
    c0 = RAPL_PKG / "constraint_0_power_limit_uw"
    c1 = RAPL_PKG / "constraint_1_power_limit_uw"
    write_text(c0, pl1_uw)
    if c1.exists():
        write_text(c1, pl2_uw)


def set_epp(epp: str) -> None:
    """Write EPP to every cpufreq policy (and per-cpu nodes) on this H-series chip."""
    written = False
    for pol in Path("/sys/devices/system/cpu/cpufreq").glob(
        "policy*/energy_performance_preference"
    ):
        if write_text(pol, epp):
            written = True
    if not written:
        for pol in CPUFREQ_BASE.glob("cpu*/cpufreq/energy_performance_preference"):
            write_text(pol, epp)


def classify_workload(gpu_active: bool) -> str:
    """Categories: idle | interactive | batch | gpu | background."""
    if gpu_active:
        return "gpu"

    batch_keys = (
        "nix",
        "nix-daemon",
        "rustc",
        "clang",
        "clang++",
        "gcc",
        "g++",
        "cc1",
        "cc1plus",
        "cargo",
        "ld",
        "lld",
        "mold",
        "cmake",
        "ninja",
        "make",
        "javac",
        "go",
        "compile",
    )
    interactive_keys = (
        "firefox",
        "librewolf",
        "chrome",
        "chromium",
        "electron",
        "code",
        "cursor",
        "antigravity",
        "Discord",
        "vesktop",
        "slack",
        "Beeper",
        "niri",
        "ghostty",
        "alacritty",
    )
    background_keys = ("tracker", "baloo", "flatpak", "updatedb", "locate")

    batch = 0
    interactive = 0
    background = 0

    try:
        for pid in os.listdir("/proc"):
            if not pid.isdigit():
                continue
            comm = Path(f"/proc/{pid}/comm")
            try:
                name = comm.read_text().strip()
            except (OSError, ValueError, IndexError):
                continue
            lname = name.lower()
            if any(k in lname for k in batch_keys) or any(
                k == name for k in batch_keys
            ):
                batch += 3
            elif any(k.lower() in lname for k in interactive_keys):
                interactive += 1
            elif any(k in lname for k in background_keys):
                background += 1
    except OSError:
        pass

    try:
        load1 = float(Path("/proc/loadavg").read_text().split()[0])
    except (OSError, ValueError, IndexError):
        load1 = 0.0

    if batch >= 2 and load1 > 1.5:
        return "batch"
    if background >= 2 and load1 > 2.0 and interactive == 0:
        return "background"
    if load1 < 0.35 and batch == 0:
        return "idle"
    return "interactive"


def set_max_perf_pct(pct: int) -> None:
    p = PSTATE / "max_perf_pct"
    if p.exists():
        write_text(p, str(max(20, min(100, pct))))


def set_no_turbo(off: bool) -> None:
    p = PSTATE / "no_turbo"
    if p.exists():
        write_text(p, "1" if off else "0")


def acoustic_state(temp: float, fan: float, cal: Cal) -> str:
    step = cal.fan_step_rpm
    if fan >= LOUD_FAN_RPM or temp >= 88:
        return "loud"
    if fan >= step or temp >= TARGET_TEMP_C + 3:
        return "audible"
    return "quiet"


def choose_epp(workload: str, ac: bool, acoustic: str) -> str:
    if not ac:
        return "power"
    if workload == "gpu" or (workload == "batch" and acoustic == "quiet"):
        return "balance_performance"
    if acoustic == "loud":
        return "power"
    if acoustic == "audible":
        return "balance_power"
    if workload == "idle":
        return "power"
    return "balance_power"


def converge_pl1(
    ctl: Controller,
    temp: float,
    temp_ema: float,
    power_ema: float,
    fan: float,
    acoustic: str,
) -> tuple[float, str]:
    """Solve for PL1 that satisfies acoustic/thermal budget."""
    ac = ctl.ac_online
    lo = PL1_MIN_W
    hi = PL1_MAX_W_AC if ac else PL1_MAX_W_BAT
    if ctl.docked:
        hi += 4.0
    if ctl.workload == "batch":
        hi += 8.0
    if ctl.workload == "gpu":
        hi += 10.0
    if ctl.workload == "idle":
        hi = min(hi, 32.0 if ac else 28.0)

    pl1 = ctl.pl1_w
    reason = "hold"

    # Adaptive step: faster near idle, slower near limits
    near_limit = temp_ema >= TARGET_TEMP_C - 2 or acoustic != "quiet"
    step = 1.0 if near_limit else 2.5

    # Predictive: high package power before temp spikes
    if power_ema > pl1 * 0.95 and temp_ema > TARGET_TEMP_C - 8:
        pl1 -= step
        reason = "predictive_power"
    elif acoustic == "loud" or temp_ema >= TARGET_TEMP_C + 5:
        pl1 -= step * 1.5
        reason = "thermal_budget"
    elif acoustic == "audible" or temp_ema >= TARGET_TEMP_C:
        pl1 -= step
        reason = "thermal_budget"
    elif (
        acoustic == "quiet"
        and temp_ema < TARGET_TEMP_C - 6
        and ctl.workload
        in (
            "batch",
            "gpu",
            "interactive",
        )
    ):
        # race-to-idle: raise when headroom exists
        pl1 += step * (0.5 if near_limit else 1.0)
        reason = "headroom"
    elif acoustic == "quiet" and ctl.workload == "idle" and pl1 > lo + 2:
        pl1 -= 0.5
        reason = "idle_trim"

    # Fan confirmation (low weight): only pull if clearly loud and temp not cold
    if fan > ctl.cal.fan_step_rpm + 400 and temp_ema > 60:
        pl1 -= 0.5
        reason = "fan_confirm"

    pl1 = max(lo, min(hi, pl1))
    return pl1, reason


def io_psi_full_avg10() -> float:
    try:
        line = Path("/proc/pressure/io").read_text().splitlines()[1]  # full
        # full avg10=...
        for part in line.split():
            if part.startswith("avg10="):
                return float(part.split("=", 1)[1])
    except (OSError, ValueError, IndexError):
        pass
    return 0.0


def maybe_tune_swappiness(ctl: Controller) -> None:
    """Keep base 60; raise toward 80 only when zswap healthy and IO PSI low."""
    zswap_on = False
    try:
        zswap_on = Path("/sys/module/zswap/parameters/enabled").read_text().strip() in (
            "Y",
            "1",
        )
    except OSError:
        pass
    psi = io_psi_full_avg10()
    path = Path("/proc/sys/vm/swappiness")
    if not path.exists():
        return
    if zswap_on and psi < 5.0 and ctl.workload != "batch":
        write_text(path, "80")
    else:
        write_text(path, "60")


def set_wifi_powersave(on_battery: bool) -> None:
    """Best-effort; AC keeps powersave off (association stability)."""
    iw = "/run/current-system/sw/bin/iw"
    if not os.path.exists(iw):
        iw = "iw"
    mode = "on" if on_battery else "off"
    for iface in Path("/sys/class/net").iterdir():
        if not (iface / "wireless").exists():
            continue
        os.system(f"{iw} dev {iface.name} set power_save {mode} >/dev/null 2>&1")


def backlight_paths() -> list[Path]:
    bl = Path("/sys/class/backlight")
    if not bl.exists():
        return []
    return [p for p in bl.iterdir() if (p / "brightness").exists()]


def dim_backlight_for_battery(ctl: Controller) -> None:
    for p in backlight_paths():
        cur = read_int(p / "brightness")
        mx = read_int(p / "max_brightness")
        if cur is None or mx is None or mx <= 0:
            continue
        if ctl.backlight_saved is None:
            ctl.backlight_saved = cur
        target = max(1, int(mx * 0.40))
        if cur > target:
            write_text(p / "brightness", str(target))


def restore_backlight(ctl: Controller) -> None:
    if ctl.backlight_saved is None:
        return
    for p in backlight_paths():
        write_text(p / "brightness", str(ctl.backlight_saved))
    ctl.backlight_saved = None


def ensure_r8169_autosuspend() -> None:
    for d in Path("/sys/bus/pci/devices").glob("*"):
        try:
            if (d / "vendor").read_text().strip() != "0x10ec":
                continue
            if (d / "device").read_text().strip() != "0x8168":
                continue
            write_text(d / "power/control", "auto")
        except OSError:
            continue


def update_calibration(ctl: Controller, temp: float, fan: float, power: float) -> None:
    """Light online learning: track fan step and idle package power."""
    cal = ctl.cal
    if ctl.workload == "idle" and temp < 65 and power < 15:
        cal.idle_pkg_w = (cal.idle_pkg_w * 0.95) + (power * 0.05)
    # Detect first sustained fan rise above idle-ish
    if fan > cal.fan_step_rpm and temp > 70:
        # slowly track observed step
        cal.fan_step_rpm = (cal.fan_step_rpm * 0.98) + (fan * 0.02)
    cal.samples += 1
    if cal.samples % 120 == 0:  # ~5 min
        try:
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            CAL_PATH.write_text(
                json.dumps(
                    {
                        "fan_step_rpm": cal.fan_step_rpm,
                        "idle_pkg_w": cal.idle_pkg_w,
                        "samples": cal.samples,
                    }
                )
            )
        except OSError:
            pass


def load_calibration() -> Cal:
    try:
        data = json.loads(CAL_PATH.read_text())
        return Cal(
            fan_step_rpm=float(data.get("fan_step_rpm", QUIET_FAN_RPM)),
            idle_pkg_w=float(data.get("idle_pkg_w", 8.0)),
            samples=int(data.get("samples", 0)),
        )
    except (OSError, ValueError, json.JSONDecodeError):
        return Cal()


def write_status(
    ctl: Controller, pl2: float, perf: int, pkg_w: float, temp: float, fan: float
) -> None:
    RUN_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "state": ctl.acoustic,
        "pl1_w": round(ctl.pl1_w, 1),
        "pl2_w": round(pl2, 1),
        "pkg_w": round(pkg_w, 1),
        "pkg_temp": round(temp, 1),
        "fan_rpm": int(fan),
        "epp": ctl.epp,
        "max_perf_pct": perf,
        "budget_used": round(
            min(
                1.0,
                max(
                    0.0,
                    0.5 * (temp / max(TARGET_TEMP_C, 1.0))
                    + 0.3 * (fan / max(ctl.cal.fan_step_rpm, 1.0))
                    + 0.2 * (pkg_w / max(ctl.pl1_w, 1.0)),
                ),
            ),
            2,
        ),
        "reason": ctl.reason,
        "workload": ctl.workload,
        "ac_online": ctl.ac_online,
        "docked": ctl.docked,
    }
    tmp = STATUS_PATH.with_suffix(".tmp")
    tmp.write_text(json.dumps(payload, separators=(",", ":")))
    tmp.replace(STATUS_PATH)


def tick(ctl: Controller) -> None:
    now = time.time()
    ac = ac_is_online()
    if ac != ctl.ac_online:
        if ac:
            restore_backlight(ctl)
            set_wifi_powersave(False)
            set_no_turbo(False)
        else:
            dim_backlight_for_battery(ctl)
            set_wifi_powersave(True)
        ctl.ac_online = ac

    gpu = nvidia_runtime_active()
    ctl.docked = detect_docked(ac)
    ctl.workload = classify_workload(gpu)

    raw_power = measure_pkg_power_w(ctl, now)
    raw_temp = find_pkg_temp_c()
    raw_fan = find_fan1_rpm()

    if raw_power is not None:
        power_ema = ctl.pkg_power.update(raw_power)
    else:
        power_ema = ctl.pkg_power.value or 15.0

    if raw_temp is not None:
        temp_ema = ctl.pkg_temp.update(raw_temp)
        temp = raw_temp
    else:
        temp_ema = ctl.pkg_temp.value or 60.0
        temp = temp_ema

    if raw_fan is not None:
        fan_ema = ctl.fan_rpm.update(raw_fan)
        fan = raw_fan
    else:
        fan_ema = ctl.fan_rpm.value or 0.0
        fan = fan_ema

    ctl.acoustic = acoustic_state(temp_ema, fan_ema, ctl.cal)

    # Cooldown after aggressive pullback
    if now < ctl.cooldown_until and ctl.acoustic != "quiet":
        pl1 = ctl.pl1_w
        reason = "cooldown"
    else:
        pl1, reason = converge_pl1(ctl, temp, temp_ema, power_ema, fan, ctl.acoustic)
        if reason == "thermal_budget" and pl1 < ctl.pl1_w - 0.5:
            ctl.cooldown_until = now + 15.0

    # Deadband
    if abs(pl1 - ctl.last_write_pl1) >= 1.0 or ctl.last_write_pl1 < 0:
        ctl.pl1_w = pl1
        pl2 = min(
            pl1 + PL2_BONUS_W,
            (PL1_MAX_W_AC if ac else PL1_MAX_W_BAT) + PL2_BONUS_W + 10,
        )
        set_rapl_watts(pl1, pl2)
        ctl.last_write_pl1 = pl1
    else:
        ctl.pl1_w = pl1
        pl2 = min(pl1 + PL2_BONUS_W, 65.0)

    ctl.reason = reason
    epp = choose_epp(ctl.workload, ac, ctl.acoustic)
    if epp != ctl.last_write_epp:
        set_epp(epp)
        ctl.last_write_epp = epp
        ctl.epp = epp
    else:
        ctl.epp = epp

    # max_perf_pct last resort
    if ctl.acoustic == "loud":
        perf = 55
    elif ctl.acoustic == "audible":
        perf = 75
    elif ctl.workload == "batch" and ac:
        perf = 95
    elif ctl.workload == "idle":
        perf = 60
    else:
        perf = 85
    if not ac:
        perf = min(perf, 70)
        if ctl.workload == "idle":
            set_no_turbo(True)
        else:
            set_no_turbo(False)
    if perf != ctl.last_write_perf:
        set_max_perf_pct(perf)
        ctl.last_write_perf = perf

    ensure_r8169_autosuspend()
    maybe_tune_swappiness(ctl)
    update_calibration(ctl, temp_ema, fan_ema, power_ema)
    write_status(ctl, pl2, perf, power_ema, temp_ema, fan_ema)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--status", action="store_true")
    args = parser.parse_args()

    if args.status:
        if STATUS_PATH.exists():
            print(STATUS_PATH.read_text())
        else:
            print("{}")
        return 0

    RUN_DIR.mkdir(parents=True, exist_ok=True)
    STATE_DIR.mkdir(parents=True, exist_ok=True)

    ctl = Controller(cal=load_calibration())
    # Initial quiet-leaning PL1
    ctl.pl1_w = 34.0 if ac_is_online() else 28.0
    ctl.ac_online = ac_is_online()
    if not ctl.ac_online:
        dim_backlight_for_battery(ctl)
        set_wifi_powersave(True)
    else:
        set_wifi_powersave(False)

    stopping = False

    def stop(signum, frame):  # noqa: ARG001
        nonlocal stopping
        stopping = True

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    while not stopping:
        try:
            tick(ctl)
        except Exception as exc:  # noqa: BLE001 — keep daemon alive
            try:
                RUN_DIR.mkdir(parents=True, exist_ok=True)
                (RUN_DIR / "last-error").write_text(repr(exc))
            except OSError:
                pass
        if args.once:
            break
        time.sleep(INTERVAL_S)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
