{
  flake.modules.homeManager.apps = { pkgs, inputs, ... }: {
    imports = [
      inputs.zen-browser.homeModules.default
    ];

    programs.zen-browser = {
      enable = true;
      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;
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

    home.file."Library/Application Support/Zen/installs.ini".text = ''
      [EE6ABAA7614B74D6]
      Default=Profiles/default
      Locked=1
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
