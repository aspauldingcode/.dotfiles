# Build a store pack of wallpapers with flavours-generated base16 schemes.
# Each entry gets: wallpaper.png, scheme-{dark,light}.yaml, colors-{dark,light}.toml
#
# Palette extraction uses flavours (colorthief → base16), the same approach as
# most rices (pywal/wallust/flavours) — NOT gowall convert (which tints an image
# toward a named theme). gowall remains optional for manual effects.
{
  pkgs,
  lib,
  wallpapers, # attrsOf path
  effects ? {
    enable = false;
    vignette = "0x40";
  },
}:
let
  inherit (lib)
    mapAttrsToList
    concatStringsSep
    escapeShellArg
    ;

  mkEntry =
    name: src:
    pkgs.runCommand "dendritic-wallpaper-${name}"
      {
        nativeBuildInputs = [
          pkgs.flavours
          pkgs.imagemagick
        ];
        # Attach as a real derivation input so store references keep context.
        src = src;
      }
      ''
        mkdir -p "$out"
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"

        # Normalize to real PNG (repo may have mislabeled JPEGs).
        magick "$src" -strip -alpha off "$out/wallpaper.png"

        ${lib.optionalString effects.enable ''
          magick "$out/wallpaper.png" \
            -gravity center \
            -vignette ${escapeShellArg effects.vignette} \
            "$out/wallpaper.png"
        ''}

        flavours generate dark  "$out/wallpaper.png" --stdout --slug ${escapeShellArg name}-dark  --name ${escapeShellArg name} > "$out/flavours-dark.yaml"
        flavours generate light "$out/wallpaper.png" --stdout --slug ${escapeShellArg name}-light --name ${escapeShellArg name} > "$out/flavours-light.yaml"

        # Convert flavours YAML → tinted-theming / stylix format:
        #   system/name/author/variant + palette.base0X: "#rrggbb"
        to_stylix_scheme() {
          local src_yaml="$1" dest="$2" variant="$3"
          {
            echo "system: \"base16\""
            echo "name: \"${name} ($variant)\""
            echo "author: \"flavours (dendritic-wallpaper)\""
            echo "variant: \"$variant\""
            echo "palette:"
            for key in base00 base01 base02 base03 base04 base05 base06 base07 \
                       base08 base09 base0A base0B base0C base0D base0E base0F; do
              val=$(sed -n "s/^$key: *\"\\?\\([0-9a-fA-F]\\{6\\}\\)\"\\?.*/\\1/p" "$src_yaml" | head -1)
              echo "  $key: \"#$val\""
            done
          } > "$dest"
        }

        to_stylix_scheme "$out/flavours-dark.yaml"  "$out/scheme-dark.yaml"  dark
        to_stylix_scheme "$out/flavours-light.yaml" "$out/scheme-light.yaml" light
        rm -f "$out/flavours-dark.yaml" "$out/flavours-light.yaml"

        # colors.toml fragments consumed by neovim + apply script.
        for variant in dark light; do
          scheme="$out/scheme-$variant.yaml"
          {
            echo "[stylix]"
            echo "variant = \"$variant\""
            echo "wallpaper = ${escapeShellArg name}"
            echo
            echo "[palette]"
            for key in base00 base01 base02 base03 base04 base05 base06 base07 \
                       base08 base09 base0A base0B base0C base0D base0E base0F; do
              val=$(sed -n "s/^  $key: *\"\\?#\\?\\([0-9a-fA-F]\\{6\\}\\)\"\\?.*/\\1/p" "$scheme" | head -1)
              echo "$key = \"#$val\""
            done
          } > "$out/colors-$variant.toml"
        done

        printf '%s\n' ${escapeShellArg name} > "$out/name"
      '';

  entries = lib.mapAttrs mkEntry wallpapers;

  manifest = pkgs.writeText "dendritic-wallpaper-manifest.json" (
    builtins.toJSON {
      version = 1;
      wallpapers = mapAttrsToList (name: drv: {
        inherit name;
        image = "${drv}/wallpaper.png";
        schemes = {
          dark = "${drv}/scheme-dark.yaml";
          light = "${drv}/scheme-light.yaml";
        };
        colors = {
          dark = "${drv}/colors-dark.toml";
          light = "${drv}/colors-light.toml";
        };
      }) entries;
    }
  );
in
pkgs.runCommand "dendritic-wallpaper-pack"
  {
    passAsFile = [ "entryLinks" ];
    entryLinks = concatStringsSep "\n" (mapAttrsToList (name: drv: "${name}=${drv}") entries);
  }
  ''
    mkdir -p "$out/wallpapers"
    cp ${manifest} "$out/manifest.json"
    while IFS='=' read -r name path; do
      [ -n "$name" ] || continue
      ln -s "$path" "$out/wallpapers/$name"
    done < "$entryLinksPath"
  ''
