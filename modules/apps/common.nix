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
      programs.librewolf = {
        enable = true;
        package = pkgs.librewolf;

        profiles.default = {
          id = 0;
          name = "default";
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.drawInTitlebar" = true;
            "svg.context-properties.content.enabled" = true;
          };
        };
        profiles.default-release = {
          id = 1;
          name = "default-release";
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.tabs.drawInTitlebar" = true;
            "svg.context-properties.content.enabled" = true;
          };
        };
        policies = {
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

      home.activation.removeLibreWolfUserJS = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        rm -f "${config.home.homeDirectory}/Library/Application Support/LibreWolf/Profiles/default/user.js"
        rm -f "${config.home.homeDirectory}/Library/Application Support/LibreWolf/Profiles/default-release/user.js"
      '';

      home.packages =
        with pkgs;
        (lib.optionals pkgs.stdenv.isDarwin [ librewolf ]) ++
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
    { pkgs, ... }:
    {
      dendritic.dock.apps = [
        "/System/Cryptexes/App/System/Applications/Safari.app"
        "${pkgs.librewolf}/Applications/LibreWolf.app"
        "${pkgs.brave}/Applications/Brave Browser.app"
        "${pkgs.jetbrains.idea}/Applications/IntelliJ IDEA.app"
        "${pkgs.jetbrains.clion}/Applications/CLion.app"
        "${pkgs.jetbrains.rust-rover}/Applications/RustRover.app"
        "${pkgs.code-cursor}/Applications/Cursor.app"
        "${pkgs.antigravity}/Applications/Antigravity.app"
      ];
    };
}
