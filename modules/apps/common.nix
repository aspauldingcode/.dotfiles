{
  flake.modules.homeManager.apps = { pkgs, inputs, config, lib, ... }: {
    programs.librewolf = {
      enable = lib.mkForce true;
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
        };
      };
    };

    home.activation.removeLibreWolfUserJS = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      rm -f "${config.home.homeDirectory}/Library/Application Support/LibreWolf/Profiles/default/user.js"
      rm -f "${config.home.homeDirectory}/Library/Application Support/LibreWolf/Profiles/default-release/user.js"
    '';

    programs.brave = {
      enable = true;
      extensions = [
        { id = "ddkjecaebecekiijgeokobnjphlglake"; } # uBlock Origin Lite
        { id = "gkkmiofalnjagdcjheckamobghglpdpm"; } # YouTube Windowed Fullscreen
      ];
    };

    home.packages = with pkgs; [
      # IDEs
      jetbrains.clion
      jetbrains.idea
      # Dev tools
      gh                  # GitHub CLI
      ghidra              # Reverse engineering
      jdk21               # Java development
      # System
      fastfetch           # System info
    ];
  };
}
