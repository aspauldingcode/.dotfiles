{ pkgs, lib, ... }:

{
  # Enable greetd service for regreet to work properly
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.regreet}/bin/regreet";
        user = "alex";
      };
    };
  };

  # Create log directory with proper permissions
  systemd.services.greetd = {
    serviceConfig = {
      # Create log directory before starting
      ExecStartPre = [
        "+${pkgs.coreutils}/bin/mkdir -p /var/log/regreet"
        "+${pkgs.coreutils}/bin/chown alex /var/log/regreet"
        "+${pkgs.coreutils}/bin/chmod 755 /var/log/regreet"
      ];
    };
  };

  # Use regreet (GTK-based greeter) instead
  programs.regreet = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.sway}/bin/sway --config ${./sway-config}";
        user = "alex";
      };
      background = {
        path = "${../../../../users/alex/extraConfig/wallpapers/gruvbox-nix.png}";
        fit = "Fill";
      };
      GTK = {
        application_prefer_dark_theme = true;
        cursor_theme_name = lib.mkForce "Bibata-Modern-Ice";
        font_name = lib.mkForce "JetBrains Mono";
        icon_theme_name = "Adwaita";
        theme_name = "Adwaita";
      };
      commands = {
        reboot = [
          "systemctl"
          "reboot"
        ];
        poweroff = [
          "systemctl"
          "poweroff"
        ];
      };
      appearance = {
        greeting_msg = "Welcome back!";
      };
    };
  };

  environment.etc."greetd/regreet.css" = lib.mkForce {
    source = ./custom.css;
    mode = "0644";
  };
}
