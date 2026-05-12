{
  flake.modules.homeManager.apps =
    {
      pkgs,
      inputs,
      config,
      lib,
      ...
    }:
    {


      programs.brave = {
        enable = true;
        extensions = [
          { id = "ddkjecaebecekiijgeokobnjphlglake"; } # uBlock Origin Lite
          { id = "gkkmiofalnjagdcjheckamobghglpdpm"; } # YouTube Windowed Fullscreen
          { id = "mnjggpindoocnndabpppocagnlbhbggn"; } # SponsorBlock
          { id = "eimadpbcbfnmbkpkfnekohlhhenbhjje"; } # Dark Reader
        ];
      };
      programs.firefox = {
        enable = true;
        package = pkgs.firefox-bin;

        profiles.default = {
          id = 0;
          name = "default";
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.drawInTitlebar" = true;
            "svg.context-properties.content.enabled" = true;
            
            # Disable Telemetry
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.server" = "data:,";
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.updatePing.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.coverage.opt-out" = true;
            "toolkit.coverage.opt-out" = true;
            "toolkit.coverage.endpoint.base" = "";
            "browser.ping-centre.telemetry" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
          };
        };
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          ExtensionSettings = {
            "uBlock0@raymondhill.net" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            };
            "youtube-windowed-fullscreen@navi-jador" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-windowed-fullscreen/latest.xpi";
            };
            "sponsorBlocker@ajay.app" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
            };
            "addon@darkreader.org" = {
              installation_mode = "normal_installed";
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
            };
          };
        };
      };



      home.activation.signApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "$HOME/Applications/Home Manager Apps/Firefox.app" ]; then
          /usr/bin/codesign --force --deep --sign - "$HOME/Applications/Home Manager Apps/Firefox.app"
        fi
        if [ -d "$HOME/Applications/Home Manager Apps/Vesktop.app" ]; then
          /usr/bin/codesign --force --deep --sign - "$HOME/Applications/Home Manager Apps/Vesktop.app"
        fi
      '';

      home.packages =
        with pkgs;
        [
          # Dev tools
          gh # GitHub CLI
          ghidra # Reverse engineering
          jdk21 # Java development
          # System
          fastfetch # System info
        ]
        ++ lib.optionals (config.dendritic.apps.jetbrains.enable or false) [
          # IDEs
          jetbrains.clion
          jetbrains.idea
          jetbrains.rust-rover
        ];
    };

  # Dock registration: Brave owns its dock entry
  flake.modules.darwin.apps =
    { pkgs, inputs, ... }:
    {
      dendritic.dock.apps = [
        "/System/Cryptexes/App/System/Applications/Safari.app"
        "${pkgs.firefox-bin}/Applications/Firefox.app"
        "${pkgs.brave}/Applications/Brave Browser.app"
        "${inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.vesktop}/Applications/Vesktop.app"
        "${pkgs.ghostty-bin}/Applications/Ghostty.app"
        "${pkgs.jetbrains.idea}/Applications/IntelliJ IDEA.app"
        "${pkgs.jetbrains.clion}/Applications/CLion.app"
        "${pkgs.jetbrains.rust-rover}/Applications/RustRover.app"
        "${pkgs.code-cursor}/Applications/Cursor.app"
        "${pkgs.antigravity}/Applications/Antigravity.app"
      ];
    };
}
