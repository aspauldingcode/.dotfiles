{
  # Wayland login: greetd → sway (kiosk) → gtkgreet → niri-session.
  # Gated on programs.niri.enable so non-niri hosts (e.g. nixos-test) stay clear.
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      colors = config.lib.stylix.colors.withHashtag;
      wallpaper = config.stylix.image or null;
      authCss = import ./_gtk-auth-style.nix {
        inherit colors wallpaper;
      };
      gtkgreet = pkgs.gtkgreet;
      swayGreeterConfig = pkgs.writeText "greetd-sway-gtkgreet" ''
        # Minimal kiosk compositor for gtkgreet (desktop sway stays disabled).
        exec "${gtkgreet}/bin/gtkgreet -l -s /etc/greetd/gtkgreet.css; ${pkgs.sway}/bin/swaymsg exit"
        bindsym Mod4+shift+e exec ${pkgs.sway}/bin/swaynag \
          -t warning \
          -m 'Power?' \
          -b 'Poweroff' 'systemctl poweroff' \
          -b 'Reboot' 'systemctl reboot'
      '';
    in
    {
      config = lib.mkIf ((config.programs ? niri) && config.programs.niri.enable) {
        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${pkgs.sway}/bin/sway --config ${swayGreeterConfig}";
            user = "greeter";
          };
        };

        environment.etc."greetd/environments".text = ''
          niri-session
        '';

        environment.etc."greetd/gtkgreet.css".text = authCss;

        # Session lock (gtklock) PAM — unlock after idle / Super+Alt+L.
        security.pam.services.gtklock = { };
      };
    };
}
