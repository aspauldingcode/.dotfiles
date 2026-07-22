# Desktop essentials for Linux (niri) — curated “atelier” set, not a GNOME dump.
#
# Goals: the roles every rice setup expects (calc, calendar, editor, viewers,
# players, annotate) with distinctive GTK4 / Wayland-native picks that Stylix
# and Dolphin already play with. Dolphin stays the file manager (host).
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.desktopEssentials;
      niriOn = config.dendritic.apps.niri.enable or false;

      # grim+slurp → satty annotate (unixporn screenshot pipeline).
      annotateShot = pkgs.writeShellScriptBin "dendritic-annotate" ''
        set -euo pipefail
        grim=${lib.escapeShellArg (lib.getExe pkgs.grim)}
        slurp=${lib.escapeShellArg (lib.getExe pkgs.slurp)}
        satty=${lib.escapeShellArg (lib.getExe pkgs.satty)}
        dir="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
        mkdir -p "$dir"
        file="$dir/Annotate-$(date +%Y-%m-%d-%H-%M-%S).png"
        geom="$("$slurp")" || exit 0
        "$grim" -g "$geom" - | "$satty" --filename - --output-filename "$file" \
          --early-exit --copy-command ${lib.escapeShellArg "${pkgs.wl-clipboard}/bin/wl-copy"}
      '';
    in
    {
      options.dendritic.apps.desktopEssentials = {
        enable = lib.mkEnableOption ''
          Curated Linux desktop essentials (calculator, calendar, editors,
          image/PDF/media viewers, annotate). Distinctive GTK4 / Wayland set —
          not the stock GNOME metapackage.
        '';
      };

      config = lib.mkMerge [
        # Ship with niri by default; hosts can mkForce false.
        (lib.mkIf niriOn {
          dendritic.apps.desktopEssentials.enable = lib.mkDefault true;
        })

        (lib.mkIf cfg.enable {
          home.packages = with pkgs; [
            # Calc — RPN/units/currency; not gnome-calculator.
            qalculate-gtk
            # Calendar — GTK4, clean.
            gnome-calendar
            # Editors — Adwaita plain text + distraction-free markdown.
            gnome-text-editor
            apostrophe
            # Images / docs
            loupe
            papers
            # Media — celluloid (GTK mpv UI) + amberol (album player).
            celluloid
            amberol
            # Capture / color / OCR / light draw
            eyedropper
            satty
            annotateShot
            snapshot
            gnome-frog
            drawing
            # Thumbnails for Dolphin / file pickers (mpv comes from programs.mpv).
            ffmpegthumbnailer
          ];

          # mpv backend; celluloid is the GUI face. Fonts/colors come from Stylix
          # (modules/mpv/hm.nix) — do not set osd-font here.
          programs.mpv = {
            enable = true;
            bindings = {
              "WHEEL_UP" = "seek 5";
              "WHEEL_DOWN" = "seek -5";
              "Alt+LEFT" = "add video-rotate -90";
              "Alt+RIGHT" = "add video-rotate 90";
            };
            config = lib.mapAttrs (_: lib.mkDefault) {
              profile = "gpu-hq";
              hwdec = "auto-safe";
              vo = "gpu-next";
              keep-open = "yes";
              save-position-on-quit = "yes";
              # uosc replaces the stock OSC (Stylix themes uosc.color).
              osc = "no";
              screenshot-directory = "~/Pictures/Screenshots";
              screenshot-template = "mpv-%F-%P";
            };
            scripts = with pkgs.mpvScripts; [
              mpris
              uosc
            ];
          };

          xdg.mimeApps = {
            enable = true;
            defaultApplications = {
              # Images → Loupe
              "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
              "image/png" = [ "org.gnome.Loupe.desktop" ];
              "image/gif" = [ "org.gnome.Loupe.desktop" ];
              "image/webp" = [ "org.gnome.Loupe.desktop" ];
              "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
              "image/avif" = [ "org.gnome.Loupe.desktop" ];
              "image/heic" = [ "org.gnome.Loupe.desktop" ];
              # Documents → Papers
              "application/pdf" = [ "org.gnome.Papers.desktop" ];
              "application/epub+zip" = [ "org.gnome.Papers.desktop" ];
              "application/x-cbr" = [ "org.gnome.Papers.desktop" ];
              "application/x-cbz" = [ "org.gnome.Papers.desktop" ];
              # Video → Celluloid (mpv)
              "video/mp4" = [ "io.github.celluloid_player.Celluloid.desktop" ];
              "video/x-matroska" = [ "io.github.celluloid_player.Celluloid.desktop" ];
              "video/webm" = [ "io.github.celluloid_player.Celluloid.desktop" ];
              "video/x-msvideo" = [ "io.github.celluloid_player.Celluloid.desktop" ];
              "video/quicktime" = [ "io.github.celluloid_player.Celluloid.desktop" ];
              "video/mpeg" = [ "io.github.celluloid_player.Celluloid.desktop" ];
              # Audio → Amberol
              "audio/mpeg" = [ "io.bassi.Amberol.desktop" ];
              "audio/flac" = [ "io.bassi.Amberol.desktop" ];
              "audio/ogg" = [ "io.bassi.Amberol.desktop" ];
              "audio/mp4" = [ "io.bassi.Amberol.desktop" ];
              "audio/x-wav" = [ "io.bassi.Amberol.desktop" ];
              "audio/x-vorbis+ogg" = [ "io.bassi.Amberol.desktop" ];
              # Text
              "text/plain" = [ "org.gnome.TextEditor.desktop" ];
              "text/markdown" = [ "org.gnome.gitlab.somas.Apostrophe.desktop" ];
              "text/x-markdown" = [ "org.gnome.gitlab.somas.Apostrophe.desktop" ];
            };
          };

          # Ensure screenshot dir exists for mpv / annotate.
          home.activation.dendriticScreenshotDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/Pictures/Screenshots"
          '';
        })
      ];
    };
}
