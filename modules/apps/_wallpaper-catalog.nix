# Curated theme families (official base16, both poles) + scenic wallpaper pairs.
# Images are fetchurl (Unsplash License). No palette extraction.
{ pkgs, ... }:
let
  scheme = name: "${pkgs.base16-schemes}/share/themes/${name}.yaml";

  kanagawaLotus = pkgs.writeText "kanagawa-lotus.yaml" ''
    system: "base16"
    name: "Kanagawa Lotus"
    author: "rebelot (vendored; not in base16-schemes)"
    variant: "light"
    palette:
      base00: "#f2ecbc"
      base01: "#e7dba0"
      base02: "#e4d794"
      base03: "#8a8980"
      base04: "#716e61"
      base05: "#545464"
      base06: "#43436c"
      base07: "#1f1f28"
      base08: "#c84053"
      base09: "#cc6d00"
      base0A: "#77713f"
      base0B: "#6f894e"
      base0C: "#597b75"
      base0D: "#4d699b"
      base0E: "#b35b79"
      base0F: "#624c83"
  '';

  everforestLightHard = pkgs.writeText "everforest-light-hard.yaml" ''
    system: "base16"
    name: "Everforest Light Hard"
    author: "Sainnhe Park (vendored; not in this base16-schemes revision)"
    variant: "light"
    palette:
      base00: "#fffbef"
      base01: "#f4f0d9"
      base02: "#efebd4"
      base03: "#a6b0a0"
      base04: "#939f91"
      base05: "#5c6a72"
      base06: "#4a555b"
      base07: "#2d353b"
      base08: "#f85552"
      base09: "#f57d26"
      base0A: "#dfa000"
      base0B: "#8da101"
      base0C: "#35a77c"
      base0D: "#3a94c5"
      base0E: "#df69ba"
      base0F: "#f57d26"
  '';

  draculaLight = pkgs.writeText "dracula-light.yaml" ''
    system: "base16"
    name: "Dracula light"
    author: "Dracula accents on inverted surfaces (dendritic vendor)"
    variant: "light"
    palette:
      base00: "#f8f8f2"
      base01: "#e6e6dc"
      base02: "#d5d5cb"
      base03: "#6272a4"
      base04: "#4d4f68"
      base05: "#282a36"
      base06: "#21222c"
      base07: "#191a21"
      base08: "#ff5555"
      base09: "#ffb86c"
      base0A: "#f1fa8c"
      base0B: "#50fa7b"
      base0C: "#8be9fd"
      base0D: "#bd93f9"
      base0E: "#ff79c6"
      base0F: "#ffb86c"
  '';

  fetchUnsplash =
    {
      name,
      id,
      sha256,
    }:
    pkgs.fetchurl {
      inherit name sha256;
      url = "https://images.unsplash.com/${id}?w=2560&q=80";
    };

  mkPair = id: light: dark: tags: {
    inherit
      id
      light
      dark
      tags
      ;
  };
  mkTheme =
    {
      name,
      dark,
      light,
      lutgenDark,
      lutgenLight,
    }:
    {
      inherit
        name
        dark
        light
        lutgenDark
        lutgenLight
        ;
    };
in
{
  # One family per calendar day. Appearance selects dark vs light pole.
  # lutgen* = lutgen-rs builtin palette (full, no posterization). Empty = hex fallback.
  themes = [
    (mkTheme {
      name = "gruvbox";
      dark = scheme "gruvbox-dark-hard";
      light = scheme "gruvbox-light-hard";
      lutgenDark = "gruvbox-dark-hard";
      lutgenLight = "gruvbox-light-hard";
    })
    (mkTheme {
      name = "catppuccin-mocha";
      dark = scheme "catppuccin-mocha";
      light = scheme "catppuccin-latte";
      lutgenDark = "catppuccin-mocha";
      lutgenLight = "catppuccin-latte";
    })
    (mkTheme {
      name = "catppuccin-frappe";
      dark = scheme "catppuccin-frappe";
      light = scheme "catppuccin-latte";
      lutgenDark = "catppuccin-frappe";
      lutgenLight = "catppuccin-latte";
    })
    (mkTheme {
      name = "catppuccin-macchiato";
      dark = scheme "catppuccin-macchiato";
      light = scheme "catppuccin-latte";
      lutgenDark = "catppuccin-macchiato";
      lutgenLight = "catppuccin-latte";
    })
    (mkTheme {
      name = "tokyo-night";
      dark = scheme "tokyo-night-dark";
      light = scheme "tokyo-night-light";
      lutgenDark = "tokyo-night-dark";
      lutgenLight = "tokyo-night-light";
    })
    (mkTheme {
      name = "tokyo-night-storm";
      dark = scheme "tokyo-night-storm";
      light = scheme "tokyo-night-light";
      lutgenDark = "tokyo-night-storm";
      lutgenLight = "tokyo-night-light";
    })
    (mkTheme {
      name = "tokyo-night-moon";
      dark = scheme "tokyo-night-moon";
      light = scheme "tokyo-night-light";
      lutgenDark = "tokyo-night-moon";
      lutgenLight = "tokyo-night-light";
    })
    (mkTheme {
      name = "nord";
      dark = scheme "nord";
      light = scheme "nord-light";
      lutgenDark = "nord";
      lutgenLight = "nord-light";
    })
    (mkTheme {
      name = "everforest";
      dark = scheme "everforest-dark-hard";
      light = everforestLightHard;
      lutgenDark = "everforest-dark-hard";
      lutgenLight = "everforest-light-hard";
    })
    (mkTheme {
      name = "rose-pine";
      dark = scheme "rose-pine";
      light = scheme "rose-pine-dawn";
      lutgenDark = "rose-pine";
      lutgenLight = "rose-pine-dawn";
    })
    (mkTheme {
      name = "rose-pine-moon";
      dark = scheme "rose-pine-moon";
      light = scheme "rose-pine-dawn";
      lutgenDark = "rose-pine-moon";
      lutgenLight = "rose-pine-dawn";
    })
    (mkTheme {
      name = "kanagawa";
      dark = scheme "kanagawa";
      light = kanagawaLotus;
      lutgenDark = "kanagawa";
      lutgenLight = "";
    })
    (mkTheme {
      name = "solarized";
      dark = scheme "solarized-dark";
      light = scheme "solarized-light";
      lutgenDark = "solarized-dark";
      lutgenLight = "solarized-light";
    })
    (mkTheme {
      name = "dracula";
      dark = scheme "dracula";
      light = draculaLight;
      lutgenDark = "dracula";
      lutgenLight = "";
    })
  ];

  pairs = [
    (mkPair "skyline" "skyline-light" "skyline-dark" [ "cityscape" ])
    (mkPair "bustling" "bustling-light" "bustling-dark" [ "cityscape" ])
    (mkPair "alpine" "alpine-light" "alpine-dark" [ "mountain" ])
    (mkPair "wildlife" "wildlife-light" "wildlife-dark" [ "wildlife" ])
    (mkPair "tokyo" "tokyo-light" "tokyo-dark" [ "cityscape" ])
    (mkPair "lake" "lake-light" "lake-dark" [
      "mountain"
      "terrain"
    ])
    (mkPair "harbor" "harbor-light" "harbor-dark" [ "cityscape" ])
    (mkPair "forest" "forest-light" "forest-dark" [ "nature" ])
    (mkPair "canyon" "canyon-light" "canyon-dark" [ "terrain" ])
    (mkPair "coast" "coast-light" "coast-dark" [ "nature" ])
  ];

  images = {
    skyline-light = fetchUnsplash {
      name = "skyline-light.jpg";
      id = "photo-1477959858617-67f85cf4f1df";
      sha256 = "0dkzm96jn2l8h04gvri17cxgxwqidxaccbsq2n8wwmc3xs45wdin";
    };
    skyline-dark = fetchUnsplash {
      name = "skyline-dark.jpg";
      id = "photo-1519501025264-65ba15a82390";
      sha256 = "0aw5yiqldm4lsvb3rmfxmr6dnb4gh9mw64fbry6id0x2a29cxckq";
    };
    bustling-light = fetchUnsplash {
      name = "bustling-light.jpg";
      id = "photo-1449824913935-59a10b8d2000";
      sha256 = "1969jxsyz0kjb1wkyad15s573kyanhchhb1j4rz291vvyp98kpdg";
    };
    bustling-dark = fetchUnsplash {
      name = "bustling-dark.jpg";
      id = "photo-1480714378408-67cf0d13bc1b";
      sha256 = "0qs7xssl9fks8gjvs53x09yyfpv74nqz2gp7wcfizskf32h1g91w";
    };
    alpine-light = fetchUnsplash {
      name = "alpine-light.jpg";
      id = "photo-1464822759023-fed622ff2c3b";
      sha256 = "1kndpgxy37kl3768g4xbylql0fzr0ccr83gf6n37r193kiivii4m";
    };
    alpine-dark = fetchUnsplash {
      name = "alpine-dark.jpg";
      id = "photo-1469474968028-56623f02e42e";
      sha256 = "0aijbspndl1r03hd9p3hnsvizwcypiz34p6zxg0gjfwjilwbzh6z";
    };
    wildlife-light = fetchUnsplash {
      name = "wildlife-light.jpg";
      id = "photo-1549366021-9f761d450615";
      sha256 = "0qq038g7kzyxhl332pavij06yrqdhvfkphxx2g6sv63apa3hw27n";
    };
    wildlife-dark = fetchUnsplash {
      name = "wildlife-dark.jpg";
      id = "photo-1456926631375-92c8ce872def";
      sha256 = "0p91w4a0cwmxsd75w247h79mcmrknjzm6pw6y4hs02lwbg65w1dp";
    };
    tokyo-light = fetchUnsplash {
      name = "tokyo-light.jpg";
      id = "photo-1540959733332-eab4deabeeaf";
      sha256 = "1l8zkn31hkmjj39ar3n35k2czcqwijcdb6dr724cvgfv8xwnsz7c";
    };
    tokyo-dark = fetchUnsplash {
      name = "tokyo-dark.jpg";
      id = "photo-1542051841857-5f90071e7989";
      sha256 = "0h4f689vd2g40hacd8my3j7q3laiqmv90z42gbp72hgg3p6mwn7h";
    };
    lake-light = fetchUnsplash {
      name = "lake-light.jpg";
      id = "photo-1501785888041-af3ef285b470";
      sha256 = "0v9mjh2xzfvfv53p6wc40bh1f486jxqmrmnrgf4a3pmvg6j2rfbh";
    };
    lake-dark = fetchUnsplash {
      name = "lake-dark.jpg";
      id = "photo-1419242902214-272b3f66ee7a";
      sha256 = "19x4iq5s1isrsj9b262464a5wdkyc1fi9fkyb3ygkgg9v4wv5nir";
    };
    harbor-light = fetchUnsplash {
      name = "harbor-light.jpg";
      id = "photo-1474181487882-5abf3f0ba6c2";
      sha256 = "1fkhwd24yd1k5casxxnmb7vyqa64x2xmjcahgkhy4a3mvb058adj";
    };
    harbor-dark = fetchUnsplash {
      name = "harbor-dark.jpg";
      id = "photo-1536098561742-ca998e48cbcc";
      sha256 = "0bj0l5p2galcs8nmxbspr4y1hqcvr30plcph6cdqdf3cx338yfzz";
    };
    forest-light = fetchUnsplash {
      name = "forest-light.jpg";
      id = "photo-1448375240586-882707db888b";
      sha256 = "0cc6m7145q8ncg64cb9mfnhhbfhiw63p0lfvha1ir4zkz5rhg7pa";
    };
    forest-dark = fetchUnsplash {
      name = "forest-dark.jpg";
      id = "photo-1470071459604-3b5ec3a7fe05";
      sha256 = "10x6i0vyvpvrqz2k5ja25c74w8x2ca46k8wsjskgh00c3bh72aha";
    };
    canyon-light = fetchUnsplash {
      name = "canyon-light.jpg";
      id = "photo-1509316785289-025f5b846b35";
      sha256 = "1fkphxjh8ks9x07ms254w00lz0qjn39kp1d51sghcqpjbpxfjpah";
    };
    canyon-dark = fetchUnsplash {
      name = "canyon-dark.jpg";
      id = "photo-1547234935-80c7145ec969";
      sha256 = "0b6zz5rf4kqpzrx6261l9mkm9zv8x0q759pyamzqjanak9ppfprc";
    };
    coast-light = fetchUnsplash {
      name = "coast-light.jpg";
      id = "photo-1507525428034-b723cf961d3e";
      sha256 = "1hslh6y11wppanaqb4g5c72gqdza0lsp0d5jm50m4lzcmgbygzr9";
    };
    coast-dark = fetchUnsplash {
      name = "coast-dark.jpg";
      id = "photo-1475924156734-496f6cac6ec1";
      sha256 = "07wrx1yvhb89scpivajk34bk5dflwmh0agxa5imnyqa20hl5hi9q";
    };
  };
}
