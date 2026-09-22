{
  lib,
  stdenvNoCC,
  runCommand,
  imagemagick,
  fontconfig,
  grub2,
  makeFontsConf,
  colors,
  fonts,
  wallpaper ? null,
  hostName,
}:
let
  hex = name: colors.${name};

  mkGrubFont =
    font:
    runCommand "${font.package.pname or font.package.name}-grub.pf2"
      {
        FONTCONFIG_FILE = makeFontsConf { fontDirectories = [ font.package ]; };
        nativeBuildInputs = [
          fontconfig
          grub2
        ];
      }
      ''
        font=$(fc-match ${lib.escapeShellArg font.name} --format=%{file})
        grub-mkfont "$font" --output "$out" --size ${toString fonts.sizes.applications}
      '';

  sansPf2 = mkGrubFont fonts.sansSerif;
  monoPf2 = mkGrubFont fonts.monospace;

  themeTxt = ''
    desktop-image: "background.png"
    desktop-image-scale-method: "crop"
    desktop-color: "#${hex "base00"}"

    title-text: "${hostName}"
    title-font: "${fonts.sansSerif.name}"
    title-color: "#${hex "base05"}"

    terminal-left: "10%"
    terminal-top: "20%"
    terminal-width: "80%"
    terminal-height: "60%"
    terminal-box: "background_*.png"
    terminal-border: "0"
    terminal-font: "${fonts.monospace.name}"

    + label {
      id = "__timeout__"
      left = 25%
      top = 8%
      width = 50%
      height = 28
      font = "${fonts.sansSerif.name}"
      color = "#${hex "base05"}"
      align = "center"
      text = "%d"
    }

    + progress_bar {
      id = "__timeout__"
      left = 25%
      top = 80%+24
      width = 50%
      height = 4
      show_text = false
      border_color = "#${hex "base00"}"
      bg_color = "#${hex "base02"}"
      fg_color = "#${hex "base0D"}"
    }

    + boot_menu {
      left = 25%
      top = 18%
      width = 50%
      height = 58%
      menu_pixmap_style = "background_*.png"

      item_height = 40
      item_icon_space = 8
      item_spacing = 2
      item_padding = 8
      item_font = "${fonts.sansSerif.name}"
      item_color = "#${hex "base05"}"

      selected_item_color = "#${hex "base00"}"
      selected_item_pixmap_style = "selection_*.png"
    }
  '';
  theme = stdenvNoCC.mkDerivation {
    pname = "dendritic-grub-theme";
    version = "1.0.0";

    dontUnpack = true;
    dontConfigure = true;

    nativeBuildInputs = [ imagemagick ];

    inherit themeTxt;
    passAsFile = [ "themeTxt" ];
    wallpaperPath = if wallpaper == null then "" else wallpaper;

    buildPhase = ''
      runHook preBuild
      mkdir -p build
      cp "$themeTxtPath" build/theme.txt

      if [ -n "$wallpaperPath" ]; then
        magick "$wallpaperPath" \
          -auto-orient \
          -resize '1920x1080^' -gravity center -extent 1920x1080 \
          png32:build/background.png
      else
        magick -size 1920x1080 "xc:#${hex "base00"}" png32:build/background.png
      fi

      magick -size 1x1 "xc:#${hex "base01"}" png32:build/background_c.png
      magick -size 1x1 "xc:#${hex "base0D"}" png32:build/selection_c.png
      cp ${sansPf2} build/sans_serif.pf2
      cp ${monoPf2} build/monospace.pf2
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r build/. "$out/"
      runHook postInstall
    '';

    passthru.font = monoPf2;

    meta = {
      description = "Stylix-colored GRUB theme (wallpaper, accent selection, timeout clock)";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  };
in
theme.overrideAttrs {
  passthru = {
    font = monoPf2;
    # Path-typed NixOS options reject "${drv}/file.png" (wrong output
    # placeholder). Expose the splash as its own derivation whose $out is
    # the PNG.
    splashImage = runCommand "dendritic-grub-splash.png" { } ''
      cp ${theme}/background.png "$out"
    '';
  };
}
