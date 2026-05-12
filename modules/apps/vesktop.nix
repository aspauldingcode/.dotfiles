{
  # ── Vesktop (Discord replacement) ─────────────────────────────
  # Replaces vanilla Discord entirely with Vesktop (Vencord-powered client).
  # Stylix auto-generates a base16 CSS theme and injects it via Vencord's
  # theme loader using `stylix.targets.vesktop`.
  #
  # Stylix wiring (discord/vesktop.nix target):
  #   stylix.targets.vesktop.enable = true
  #   → programs.vesktop.vencord.themes.stylix = <generated-css>
  #   → programs.vesktop.vencord.settings.enabledThemes = [ "stylix.css" ]
  #
  # Vesktop is supported on both Linux and Darwin (macOS).
  # Reference: https://github.com/nix-community/stylix/blob/master/modules/discord/vesktop.nix

  flake.modules.homeManager.vesktop = { pkgs, lib, inputs, ... }: {
    config = {
      # ── Stylix: enable the vesktop colourscheme target ───────────
      stylix.targets.vesktop.enable = false;

      # ── Vesktop application ──────────────────────────────────────
      programs.vesktop = {
        enable = pkgs.stdenv.isDarwin;
        package = lib.mkIf pkgs.stdenv.isDarwin (lib.mkForce inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.vesktop);

        # Application-level settings
        # Written to $XDG_CONFIG_HOME/vesktop/settings.json
        settings = {
          arRPC                = true;   # Rich Presence via arRPC
          checkUpdates         = false;  # Nix manages the package version
          hardwareAcceleration = true;
          minimizeToTray       = false;
          tray                 = false;
          splashTheming        = true;   # Stylix themes the splash screen too
          staticTitle          = true;
          discordBranch        = "stable";
        };

        # Vencord plugin / theme settings
        # Written to $XDG_CONFIG_HOME/vesktop/settings/settings.json
        vencord.settings = {
          autoUpdate             = false; # Nix pins the Vencord version
          autoUpdateNotification = false;
          notifyAboutUpdates     = false;
          useQuickCss            = true;  # Needed to load extraQuickCss below

          plugins = {
            MessageLogger = {
              enabled    = true;
              ignoreSelf = true;
            };
            NoDevtoolsWarning.enabled = true;
            SilentTyping.enabled      = true;
            FakeNitro.enabled         = true;
          };
        };


      };
    };
  };
}
