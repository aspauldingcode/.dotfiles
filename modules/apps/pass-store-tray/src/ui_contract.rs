//! Single UI contract for macOS NSMenu + Linux StatusNotifier menus.
//! Both frontends must use these labels/actions so the applet never drifts.

/// Disabled status rows (updated live; not clickable).
pub mod status {
    pub const HEADLINE: &str = "…";
    pub const DETAIL: &str = " ";
    pub const MATERIALIZED: &str = " ";
    pub const WARNINGS: &str = " ";
}

/// Clickable actions — keep this set tiny (native menu, not a window).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    OpenQtPass,
    OpenSyncLog,
    Quit,
}

impl Action {
    pub const fn label(self) -> &'static str {
        match self {
            Self::OpenQtPass => "Open QtPass",
            Self::OpenSyncLog => "Open sync log",
            Self::Quit => "Quit",
        }
    }

    /// Ordered action rows after the status block + separators.
    pub const ALL: &[Action] = &[Self::OpenQtPass, Self::OpenSyncLog, Self::Quit];
}

pub const TOOLTIP_IDLE: &str = "pass store sync";
