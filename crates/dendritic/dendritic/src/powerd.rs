//! Quiet-first laptop power controller (Linux RAPL / intel_pstate).
//! Port of modules/pkgs/_dendritic-powerd.py core loop.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;
use std::time::{Duration, Instant};

use anyhow::{bail, Result};
use serde::Serialize;

const RAPL_PKG: &str = "/sys/class/powercap/intel-rapl:0";
const PSTATE: &str = "/sys/devices/system/cpu/intel_pstate";
const STATE_DIR: &str = "/var/lib/dendritic-power";
const RUN_DIR: &str = "/run/dendritic-power";
const STATUS_PATH: &str = "/run/dendritic-power/status.json";

const PL1_MIN_W: f64 = 22.0;
const PL1_MAX_W_BAT: f64 = 38.0;
const PL1_MAX_W_AC: f64 = 48.0;
const PL2_BONUS_W: f64 = 15.0;
const TARGET_TEMP_C: f64 = 72.0;
const QUIET_FAN_RPM: f64 = 2800.0;
const LOUD_FAN_RPM: f64 = 4000.0;
const INTERVAL: Duration = Duration::from_millis(2500);
const EMA_ALPHA: f64 = 0.12;

#[derive(Default)]
struct Ema {
    value: Option<f64>,
}

impl Ema {
    fn update(&mut self, x: f64) -> f64 {
        self.value = Some(match self.value {
            None => x,
            Some(v) => EMA_ALPHA * x + (1.0 - EMA_ALPHA) * v,
        });
        self.value.unwrap()
    }
}

struct Controller {
    pl1_w: f64,
    epp: String,
    acoustic: String,
    workload: String,
    reason: String,
    ac_online: bool,
    docked: bool,
    fan_step_rpm: f64,
    pkg_power: Ema,
    pkg_temp: Ema,
    fan_rpm: Ema,
    prev_energy_uj: Option<u64>,
    prev_energy_t: Option<Instant>,
}

impl Default for Controller {
    fn default() -> Self {
        Self {
            pl1_w: 35.0,
            epp: "balance_power".into(),
            acoustic: "quiet".into(),
            workload: "idle".into(),
            reason: "init".into(),
            ac_online: true,
            docked: false,
            fan_step_rpm: QUIET_FAN_RPM,
            pkg_power: Ema::default(),
            pkg_temp: Ema::default(),
            fan_rpm: Ema::default(),
            prev_energy_uj: None,
            prev_energy_t: None,
        }
    }
}

fn read_text(path: &Path) -> Option<String> {
    fs::read_to_string(path).ok().map(|s| s.trim().to_string())
}

fn read_int(path: &Path) -> Option<i64> {
    read_text(path)?.parse().ok()
}

fn write_text(path: &Path, value: &str) -> bool {
    fs::write(path, value).is_ok()
}

fn measure_pkg_power_w(ctl: &mut Controller, now: Instant) -> Option<f64> {
    let uj = read_int(&Path::new(RAPL_PKG).join("energy_uj"))? as u64;
    if let (Some(prev), Some(t0)) = (ctl.prev_energy_uj, ctl.prev_energy_t) {
        let dt = now.duration_since(t0).as_secs_f64();
        if dt > 0.2 {
            let mut watts = (uj.saturating_sub(prev)) as f64 / dt / 1_000_000.0;
            if watts < 0.0 {
                watts = 0.0;
            }
            ctl.prev_energy_uj = Some(uj);
            ctl.prev_energy_t = Some(now);
            return Some(watts.clamp(0.0, 200.0));
        }
    }
    ctl.prev_energy_uj = Some(uj);
    ctl.prev_energy_t = Some(now);
    None
}

fn find_pkg_temp_c() -> Option<f64> {
    let thermal = Path::new("/sys/class/thermal");
    if !thermal.exists() {
        return None;
    }
    for zone in sorted_dirs(thermal) {
        if read_text(&zone.join("type")).as_deref() == Some("x86_pkg_temp") {
            return read_int(&zone.join("temp")).map(|t| t as f64 / 1000.0);
        }
    }
    for zone in sorted_dirs(thermal) {
        let t = read_text(&zone.join("type")).unwrap_or_default();
        if t == "TCPU" || t == "acpitz" {
            return read_int(&zone.join("temp")).map(|v| v as f64 / 1000.0);
        }
    }
    None
}

fn sorted_dirs(dir: &Path) -> Vec<PathBuf> {
    let mut v: Vec<_> = fs::read_dir(dir)
        .into_iter()
        .flatten()
        .flatten()
        .map(|e| e.path())
        .filter(|p| p.is_dir())
        .collect();
    v.sort();
    v
}

fn find_fan1_rpm() -> Option<f64> {
    let hwmon = Path::new("/sys/class/hwmon");
    if !hwmon.exists() {
        return None;
    }
    for h in sorted_dirs(hwmon) {
        let fan = h.join("fan1_input");
        if let Some(v) = read_int(&fan) {
            if v > 0 {
                return Some(v as f64);
            }
        }
    }
    None
}

fn ac_is_online() -> bool {
    let root = Path::new("/sys/class/power_supply");
    if !root.exists() {
        return true;
    }
    for p in fs::read_dir(root).into_iter().flatten().flatten() {
        let path = p.path();
        if read_text(&path.join("type")).as_deref() != Some("Mains") {
            continue;
        }
        return read_text(&path.join("online")).as_deref() == Some("1");
    }
    true
}

fn load1() -> f64 {
    read_text(Path::new("/proc/loadavg"))
        .and_then(|s| s.split_whitespace().next()?.parse().ok())
        .unwrap_or(0.0)
}

fn nvidia_runtime_active() -> bool {
    let root = Path::new("/sys/bus/pci/devices");
    if !root.exists() {
        return false;
    }
    for d in fs::read_dir(root).into_iter().flatten().flatten() {
        let p = d.path();
        if read_text(&p.join("vendor")).as_deref() != Some("0x10de") {
            continue;
        }
        if read_text(&p.join("power/runtime_status")).as_deref() == Some("active") {
            return true;
        }
    }
    false
}

fn classify_workload(ac: bool) -> String {
    if nvidia_runtime_active() {
        return "gpu".into();
    }
    let l = load1();
    if !ac && l < 0.5 {
        return "idle".into();
    }
    if l < 0.35 {
        "idle".into()
    } else if l > 2.0 {
        "batch".into()
    } else {
        "interactive".into()
    }
}

fn acoustic_state(temp: f64, fan: f64, fan_step: f64) -> &'static str {
    if fan >= LOUD_FAN_RPM || temp >= 88.0 {
        "loud"
    } else if fan >= fan_step || temp >= TARGET_TEMP_C + 3.0 {
        "audible"
    } else {
        "quiet"
    }
}

fn choose_epp(workload: &str, ac: bool, acoustic: &str) -> &'static str {
    if !ac {
        return "power";
    }
    if workload == "gpu" || (workload == "batch" && acoustic == "quiet") {
        return "balance_performance";
    }
    if acoustic == "loud" {
        return "power";
    }
    if acoustic == "audible" {
        return "balance_power";
    }
    if workload == "idle" {
        return "power";
    }
    "balance_power"
}

fn converge_pl1(ctl: &Controller, temp_ema: f64, power_ema: f64, fan: f64, acoustic: &str) -> (f64, String) {
    let lo = PL1_MIN_W;
    let mut hi = if ctl.ac_online {
        PL1_MAX_W_AC
    } else {
        PL1_MAX_W_BAT
    };
    if ctl.docked {
        hi += 4.0;
    }
    if ctl.workload == "batch" {
        hi += 8.0;
    }
    if ctl.workload == "gpu" {
        hi += 10.0;
    }
    if ctl.workload == "idle" {
        hi = hi.min(if ctl.ac_online { 32.0 } else { 28.0 });
    }

    let mut pl1 = ctl.pl1_w;
    let mut reason = "hold".to_string();
    let near_limit = temp_ema >= TARGET_TEMP_C - 2.0 || acoustic != "quiet";
    let step = if near_limit { 1.0 } else { 2.5 };

    if power_ema > pl1 * 0.95 && temp_ema > TARGET_TEMP_C - 8.0 {
        pl1 -= step;
        reason = "predictive_power".into();
    } else if acoustic == "loud" || temp_ema >= TARGET_TEMP_C + 5.0 {
        pl1 -= step * 1.5;
        reason = "thermal_budget".into();
    } else if acoustic == "audible" || temp_ema >= TARGET_TEMP_C {
        pl1 -= step;
        reason = "thermal_budget".into();
    } else if acoustic == "quiet"
        && temp_ema < TARGET_TEMP_C - 6.0
        && matches!(ctl.workload.as_str(), "batch" | "gpu" | "interactive")
    {
        pl1 += step * (if near_limit { 0.5 } else { 1.0 });
        reason = "headroom".into();
    } else if acoustic == "quiet" && ctl.workload == "idle" && pl1 > lo + 2.0 {
        pl1 -= 0.5;
        reason = "idle_trim".into();
    }
    if fan > ctl.fan_step_rpm + 400.0 && temp_ema > 60.0 {
        pl1 -= 0.5;
        reason = "fan_confirm".into();
    }
    (pl1.clamp(lo, hi), reason)
}

fn set_constraint_uw(name: &str, watts: f64) -> bool {
    let path = Path::new(RAPL_PKG).join(name);
    let uw = ((watts * 1_000_000.0).round() as i64).max(0);
    write_text(&path, &uw.to_string())
}

fn set_epp(epp: &str) -> bool {
    // Prefer intel_pstate energy_performance_preference on cpu0
    let p = Path::new("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference");
    if p.exists() {
        return write_text(p, epp);
    }
    false
}

fn set_max_perf_pct(pct: i64) -> bool {
    let p = Path::new(PSTATE).join("max_perf_pct");
    if p.exists() {
        write_text(&p, &pct.clamp(20, 100).to_string())
    } else {
        false
    }
}

fn set_wifi_powersave(on_battery: bool) {
    let mode = if on_battery { "on" } else { "off" };
    let iw = which_iw();
    let net = Path::new("/sys/class/net");
    if !net.exists() {
        return;
    }
    for iface in fs::read_dir(net).into_iter().flatten().flatten() {
        if !iface.path().join("wireless").exists() {
            continue;
        }
        let _ = Command::new(&iw)
            .args(["dev", iface.file_name().to_str().unwrap_or(""), "set", "power_save", mode])
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status();
    }
}

fn which_iw() -> PathBuf {
    for p in [
        "/run/current-system/sw/bin/iw",
        "/usr/bin/iw",
        "iw",
    ] {
        let pb = PathBuf::from(p);
        if p == "iw" || pb.is_file() {
            return pb;
        }
    }
    PathBuf::from("iw")
}

#[derive(Serialize)]
struct Status<'a> {
    state: &'a str,
    pl1_w: f64,
    pl2_w: f64,
    pkg_w: f64,
    pkg_temp: f64,
    fan_rpm: i64,
    epp: &'a str,
    max_perf_pct: i64,
    workload: &'a str,
    reason: &'a str,
    ac_online: bool,
}

fn write_status(ctl: &Controller, pl2: f64, perf: i64, pkg_w: f64, temp: f64, fan: f64) {
    let _ = fs::create_dir_all(RUN_DIR);
    let payload = Status {
        state: &ctl.acoustic,
        pl1_w: (ctl.pl1_w * 10.0).round() / 10.0,
        pl2_w: (pl2 * 10.0).round() / 10.0,
        pkg_w: (pkg_w * 10.0).round() / 10.0,
        pkg_temp: (temp * 10.0).round() / 10.0,
        fan_rpm: fan as i64,
        epp: &ctl.epp,
        max_perf_pct: perf,
        workload: &ctl.workload,
        reason: &ctl.reason,
        ac_online: ctl.ac_online,
    };
    if let Ok(s) = serde_json::to_string_pretty(&payload) {
        let _ = fs::write(STATUS_PATH, s);
    }
}

pub fn print_status() -> Result<()> {
    let path = Path::new(STATUS_PATH);
    if path.is_file() {
        print!("{}", fs::read_to_string(path)?);
        return Ok(());
    }
    bail!("no status at {STATUS_PATH} (is dendritic-powerd running?)");
}

pub fn run() -> Result<()> {
    if !cfg!(target_os = "linux") {
        bail!("dendritic powerd is Linux-only");
    }
    if unsafe { libc::geteuid() } != 0 {
        bail!("powerd must run as root");
    }
    if !Path::new(RAPL_PKG).exists() {
        bail!("RAPL package constraint missing at {RAPL_PKG}");
    }
    let _ = fs::create_dir_all(STATE_DIR);
    let _ = fs::create_dir_all(RUN_DIR);

    let mut ctl = Controller::default();
    eprintln!("dendritic-powerd: starting quiet-first controller");

    loop {
        let now = Instant::now();
        ctl.ac_online = ac_is_online();
        ctl.workload = classify_workload(ctl.ac_online);
        let temp = find_pkg_temp_c().unwrap_or(60.0);
        let fan = find_fan1_rpm().unwrap_or(0.0);
        let pkg_w = measure_pkg_power_w(&mut ctl, now).unwrap_or(0.0);
        let temp_ema = ctl.pkg_temp.update(temp);
        let power_ema = ctl.pkg_power.update(pkg_w);
        let _ = ctl.fan_rpm.update(fan);

        ctl.acoustic = acoustic_state(temp, fan, ctl.fan_step_rpm).into();
        let (pl1, reason) = converge_pl1(&ctl, temp_ema, power_ema, fan, &ctl.acoustic);
        ctl.pl1_w = pl1;
        ctl.reason = reason;
        let pl2 = pl1 + PL2_BONUS_W;
        let epp = choose_epp(&ctl.workload, ctl.ac_online, &ctl.acoustic);
        ctl.epp = epp.into();
        let perf = match ctl.acoustic.as_str() {
            "loud" => 55,
            "audible" => 75,
            _ if ctl.workload == "idle" => 60,
            _ => 90,
        };

        let _ = set_constraint_uw("constraint_0_power_limit_uw", pl1);
        let _ = set_constraint_uw("constraint_1_power_limit_uw", pl2);
        let _ = set_epp(&ctl.epp);
        let _ = set_max_perf_pct(perf);
        set_wifi_powersave(!ctl.ac_online);
        write_status(&ctl, pl2, perf, pkg_w, temp, fan);

        thread::sleep(INTERVAL);
    }
}

/// Convenience used by `dendritic power` (status alias).
pub fn status_or_run(status_only: bool) -> Result<()> {
    if status_only {
        print_status()
    } else {
        run()
    }
}
