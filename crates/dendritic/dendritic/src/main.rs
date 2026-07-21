//! Monolithic dendritic CLI + privileged helper.

mod agent;
mod client;
mod helper;
mod ide;
mod notify;
mod powerd;
mod wg;

use std::path::PathBuf;

use anyhow::Result;
use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "dendritic", about = "Dendritic fleet CLI + privileged helper")]
struct Cli {
    #[command(subcommand)]
    cmd: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Privileged helper (root launchd/systemd)
    Helper {
        #[command(subcommand)]
        cmd: HelperCmd,
    },
    /// WireGuard overlay
    Wg {
        #[command(subcommand)]
        cmd: WgCmd,
    },
    /// User notification (no osascript)
    Notify {
        title: String,
        body: String,
    },
    /// Pass store agents
    Pass {
        #[command(subcommand)]
        cmd: PassCmd,
    },
    /// GPG preset from sops
    Gpg {
        #[command(subcommand)]
        cmd: GpgCmd,
    },
    /// Fleet heartbeat
    Fleet {
        #[command(subcommand)]
        cmd: FleetCmd,
    },
    /// Wi-Fi / eduroam
    Wifi {
        #[command(subcommand)]
        cmd: WifiCmd,
    },
    Eduroam {
        #[command(subcommand)]
        cmd: EduroamCmd,
    },
    /// CLI auth rotation
    Auth {
        #[command(subcommand)]
        cmd: AuthCmd,
    },
    /// Android converge agent
    Android {
        #[command(subcommand)]
        cmd: AndroidCmd,
    },
    /// Linux power daemon / status
    Power {
        #[arg(long)]
        status: bool,
    },
    /// IDE helpers
    Ide {
        #[command(subcommand)]
        cmd: IdeCmd,
    },
    /// Menubar tray helpers (collect / sync / switch-peer)
    Tray {
        #[command(subcommand)]
        cmd: TrayCmd,
    },
}

#[derive(Subcommand)]
enum HelperCmd {
    /// Run the root helper daemon
    Run {
        #[arg(long, env = "DENDRITIC_HELPER_SOCK")]
        sock: Option<PathBuf>,
    },
    /// Ping a running helper
    Ping,
}

#[derive(Subcommand)]
enum WgCmd {
    Ensure {
        #[arg(long)]
        no_up: bool,
    },
    InstallConf {
        #[arg(long, default_value = "dendritic")]
        iface: String,
        source: PathBuf,
    },
    Up {
        #[arg(long, default_value = "dendritic")]
        iface: String,
    },
    Down {
        #[arg(long, default_value = "dendritic")]
        iface: String,
    },
}

#[derive(Subcommand)]
enum PassCmd {
    Sync,
    Watch,
    Notify,
}

#[derive(Subcommand)]
enum GpgCmd {
    Preset,
}

#[derive(Subcommand)]
enum FleetCmd {
    Heartbeat,
}

#[derive(Subcommand)]
enum WifiCmd {
    Ensure,
}

#[derive(Subcommand)]
enum EduroamCmd {
    Ensure,
    Rotate,
}

#[derive(Subcommand)]
enum AuthCmd {
    Rotate {
        #[arg(long)]
        auto: bool,
        #[arg(long)]
        yes: bool,
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        extra: Vec<String>,
    },
}

#[derive(Subcommand)]
enum AndroidCmd {
    Converge,
}

#[derive(Subcommand)]
enum IdeCmd {
    /// Disable Cursor Agent commit/PR attribution
    CursorDisableAttribution,
}

#[derive(Subcommand)]
enum TrayCmd {
    /// Refresh ~/.cache/dendritic-tray.status
    Collect,
    /// Local flake sync (git + flake update + nh switch)
    Sync,
    /// SSH to peer over WG and nh switch
    SwitchPeer,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.cmd {
        Commands::Helper { cmd } => match cmd {
            HelperCmd::Run { sock } => helper::run(sock),
            HelperCmd::Ping => client::ping(),
        },
        Commands::Wg { cmd } => match cmd {
            WgCmd::Ensure { no_up } => wg::ensure(no_up),
            WgCmd::InstallConf { iface, source } => wg::install_conf(iface, source),
            WgCmd::Up { iface } => wg::up(iface),
            WgCmd::Down { iface } => wg::down(iface),
        },
        Commands::Notify { title, body } => notify::show(&title, &body),
        Commands::Pass { cmd } => match cmd {
            PassCmd::Sync => agent::pass_sync(),
            PassCmd::Watch => agent::pass_watch(),
            PassCmd::Notify => agent::pass_notify(),
        },
        Commands::Gpg { cmd } => match cmd {
            GpgCmd::Preset => agent::gpg_preset(),
        },
        Commands::Fleet { cmd } => match cmd {
            FleetCmd::Heartbeat => agent::fleet_heartbeat(),
        },
        Commands::Wifi { cmd } => match cmd {
            WifiCmd::Ensure => agent::wifi_ensure(),
        },
        Commands::Eduroam { cmd } => match cmd {
            EduroamCmd::Ensure => agent::eduroam_ensure(),
            EduroamCmd::Rotate => agent::eduroam_rotate(),
        },
        Commands::Auth { cmd } => match cmd {
            AuthCmd::Rotate { auto, yes, extra } => agent::auth_rotate(auto, yes, &extra),
        },
        Commands::Android { cmd } => match cmd {
            AndroidCmd::Converge => agent::android_converge(),
        },
        Commands::Power { status } => powerd::status_or_run(status),
        Commands::Ide { cmd } => match cmd {
            IdeCmd::CursorDisableAttribution => ide::cursor_disable_attribution(),
        },
        Commands::Tray { cmd } => match cmd {
            TrayCmd::Collect => agent::tray_collect(),
            TrayCmd::Sync => agent::tray_sync(),
            TrayCmd::SwitchPeer => agent::tray_switch_peer(),
        },
    }
}
