# Store pack: original wallpapers + official base16 theme families.
#
# Schemes come from pkgs.base16-schemes (or vendored light poles), not flavours.
# lutgen-rs recolors the photo to the day's palette at apply time (cached).
{
  pkgs,
  lib,
  wallpapers, # attrsOf path
  themes, # list of { name, dark, light } scheme yaml paths
  pairs ? [ ], # list of { id, light, dark, tags? }
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
    attrNames
    filter
    elem
    hasSuffix
    removeSuffix
    groupBy
    flatten
    ;

  python = pkgs.python3;

  mkEntry =
    name: src: pairId: polarity:
    pkgs.runCommand "dendritic-wallpaper-${name}"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
        src = src;
      }
      ''
        mkdir -p "$out"
        magick "$src" -strip -alpha off -resize '3840x2160>' PNG32:"$out/wallpaper.png"

        ${lib.optionalString effects.enable ''
          magick "$out/wallpaper.png" \
            -gravity center \
            -vignette ${escapeShellArg effects.vignette} \
            "$out/wallpaper.png"
        ''}

        magick "$out/wallpaper.png" \
          -auto-orient \
          -resize '1920x1080^' \
          -gravity center -extent 1920x1080 \
          -scale 5% \
          -gaussian-blur 0x1.4 \
          -resize 1920x1080! \
          -quality 92 \
          PNG32:"$out/auth-blur.png"

        printf '%s\n' ${escapeShellArg name} > "$out/name"
        printf '%s\n' ${escapeShellArg pairId} > "$out/pair"
        printf '%s\n' ${escapeShellArg polarity} > "$out/polarity"
      '';

  usedNames = flatten (
    map (p: [
      p.light
      p.dark
    ]) pairs
  );

  leftoverNames = filter (n: !(elem n usedNames)) (attrNames wallpapers);

  baseOf =
    n:
    if hasSuffix "-light" n then
      removeSuffix "-light" n
    else if hasSuffix "-dark" n then
      removeSuffix "-dark" n
    else
      n;

  extraPairs = mapAttrsToList (
    base: members:
    let
      light = lib.findFirst (n: hasSuffix "-light" n) (lib.head members) members;
      dark = lib.findFirst (n: hasSuffix "-dark" n) (lib.head members) members;
    in
    {
      id = base;
      inherit light dark;
      tags = [ "extra" ];
    }
  ) (groupBy baseOf leftoverNames);

  allPairs = (filter (p: wallpapers ? ${p.light} && wallpapers ? ${p.dark}) pairs) ++ extraPairs;

  polarityOf =
    name: pair:
    if name == pair.light && name == pair.dark then
      "any"
    else if name == pair.light then
      "light"
    else
      "dark";

  entries = lib.listToAttrs (
    flatten (
      map (
        pair:
        let
          names =
            if pair.light == pair.dark then
              [ pair.light ]
            else
              lib.unique [
                pair.light
                pair.dark
              ];
        in
        map (name: {
          inherit name;
          value = mkEntry name wallpapers.${name} pair.id (polarityOf name pair);
        }) names
      ) allPairs
    )
  );

  mkTheme =
    t:
    pkgs.runCommand "dendritic-theme-${t.name}"
      {
        nativeBuildInputs = [ python ];
        darkYaml = t.dark;
        lightYaml = t.light;
      }
      ''
        mkdir -p "$out"
        cp "$darkYaml" "$out/dark.yaml"
        cp "$lightYaml" "$out/light.yaml"

        ${python}/bin/python3 - ${escapeShellArg t.name} "$out" <<'PY'
        import json, re, sys
        from pathlib import Path

        name, out = sys.argv[1], Path(sys.argv[2])
        keys = [f"base0{x}" for x in "0123456789ABCDEF"]

        def palette(path):
            text = path.read_text()
            found = {}
            for m in re.finditer(r'(base0[0-9A-Fa-f]):\s*["\']?#?([0-9A-Fa-f]{6})', text):
                found[m.group(1)] = m.group(2).lower()
            missing = [k for k in keys if k not in found]
            if missing:
                raise SystemExit(f"{path}: missing {missing}")
            return found

        for variant in ("dark", "light"):
            pal = palette(out / f"{variant}.yaml")
            toml = out / f"colors-{variant}.toml"
            lines = [
                "# ~/.colors.toml — live Stylix / dendritic palette",
                f"# Official base16 family {name} ({variant})",
                "",
                "[stylix]",
                'system = "base16"',
                f'polarity = "{variant}"',
                f'variant = "{variant}"',
                f'scheme = "{name}-{variant}"',
                f'name = "{name}"',
                f'slug = "{name}-{variant}"',
                'author = "base16-schemes"',
                f'wallpaper = "{name}"',
                "",
                "[palette]",
            ]
            for k in keys:
                lines.append(f'{k} = "#{pal[k]}"')
            toml.write_text("\n".join(lines) + "\n")
            (out / f"gowall-{variant}.json").write_text(
                json.dumps(
                    {"name": f"{name}-{variant}", "colors": [f"#{pal[k]}" for k in keys]},
                    indent=2,
                )
                + "\n"
            )
        PY
      '';

  themeEntries = lib.listToAttrs (
    map (t: {
      name = t.name;
      value = mkTheme t;
    }) themes
  );

  manifestNoIfd = pkgs.writeText "dendritic-wallpaper-manifest.json" (
    builtins.toJSON {
      version = 2;
      themes = map (t: {
        inherit (t) name;
        schemes = {
          dark = "${themeEntries.${t.name}}/dark.yaml";
          light = "${themeEntries.${t.name}}/light.yaml";
        };
        colors = {
          dark = "${themeEntries.${t.name}}/colors-dark.toml";
          light = "${themeEntries.${t.name}}/colors-light.toml";
        };
        gowall = {
          dark = "${themeEntries.${t.name}}/gowall-dark.json";
          light = "${themeEntries.${t.name}}/gowall-light.json";
        };
        lutgen = {
          dark = t.lutgenDark or "";
          light = t.lutgenLight or "";
        };
      }) themes;
      pairs = map (p: {
        inherit (p) id;
        light = p.light;
        dark = p.dark;
        tags = p.tags or [ ];
      }) allPairs;
      wallpapers = flatten (
        map (
          pair:
          let
            names =
              if pair.light == pair.dark then
                [ pair.light ]
              else
                lib.unique [
                  pair.light
                  pair.dark
                ];
          in
          map (name: {
            inherit name;
            image = "${entries.${name}}/wallpaper.png";
            blur = "${entries.${name}}/auth-blur.png";
            pair = pair.id;
            polarity = polarityOf name pair;
          }) names
        ) allPairs
      );
    }
  );
in
pkgs.runCommand "dendritic-wallpaper-pack"
  {
    passAsFile = [
      "entryLinks"
      "themeLinks"
    ];
    entryLinks = concatStringsSep "\n" (mapAttrsToList (name: drv: "${name}=${drv}") entries);
    themeLinks = concatStringsSep "\n" (mapAttrsToList (name: drv: "${name}=${drv}") themeEntries);
  }
  ''
    mkdir -p "$out/wallpapers" "$out/themes"
    cp ${manifestNoIfd} "$out/manifest.json"
    while IFS='=' read -r name path; do
      [ -n "$name" ] || continue
      ln -s "$path" "$out/wallpapers/$name"
    done < "$entryLinksPath"
    while IFS='=' read -r name path; do
      [ -n "$name" ] || continue
      ln -s "$path" "$out/themes/$name"
    done < "$themeLinksPath"
  ''
