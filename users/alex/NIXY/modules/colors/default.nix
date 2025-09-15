{
  config,
  pkgs,
  lib,
  nix-colors,
  ...
}:
# generate a color palette from nix-colors (to view all colors in a file!)
{
  home.file = {
    "colors.toml" = {
      text = ''
        # 🎨 Color Palette Configuration
        # Generated from nix-colors: ${config.colorScheme.slug} (${config.colorScheme.variant})

        [theme]
        name = "${config.colorScheme.slug}"
        variant = "${config.colorScheme.variant}"

        # 🎯 Current Active Colors (${config.colorScheme.slug})
        [colors]
        base00 = "#${config.colorScheme.palette.base00}"  # Background (Darkest)
        base01 = "#${config.colorScheme.palette.base01}"  # Lighter Background (Status bars)
        base02 = "#${config.colorScheme.palette.base02}"  # Selection Background
        base03 = "#${config.colorScheme.palette.base03}"  # Comments, Invisibles, Line Highlighting
        base04 = "#${config.colorScheme.palette.base04}"  # Dark Foreground (Status bars)
        base05 = "#${config.colorScheme.palette.base05}"  # Default Foreground, Caret, Delimiters
        base06 = "#${config.colorScheme.palette.base06}"  # Light Foreground
        base07 = "#${config.colorScheme.palette.base07}"  # Lightest Foreground (Highlights)
        base08 = "#${config.colorScheme.palette.base08}"  # Red (Errors, Important)
        base09 = "#${config.colorScheme.palette.base09}"  # Orange (Warnings, Escape Sequences)
        base0A = "#${config.colorScheme.palette.base0A}"  # Yellow (Classes, Constants)
        base0B = "#${config.colorScheme.palette.base0B}"  # Green (Strings, Success)
        base0C = "#${config.colorScheme.palette.base0C}"  # Cyan (Special Cases, Regexp)
        base0D = "#${config.colorScheme.palette.base0D}"  # Blue (Functions, Methods)
        base0E = "#${config.colorScheme.palette.base0E}"  # Magenta (Keywords, Storage)
        base0F = "#${config.colorScheme.palette.base0F}"  # Brown (Deprecated, Special)

        # 📋 Base16 Default Reference Colors
        [reference.colors]
        base00 = "#181818"  # Background (Darkest)
        base01 = "#282828"  # Lighter Background (Status bars)
        base02 = "#383838"  # Selection Background
        base03 = "#585858"  # Comments, Invisibles, Line Highlighting
        base04 = "#b8b8b8"  # Dark Foreground (Status bars)
        base05 = "#d8d8d8"  # Default Foreground, Caret, Delimiters
        base06 = "#e8e8e8"  # Light Foreground
        base07 = "#f8f8f8"  # Lightest Foreground (Highlights)
        base08 = "#ff0000"  # Red (Errors, Important)
        base09 = "#ffa500"  # Orange (Warnings, Escape Sequences)
        base0A = "#ffff00"  # Yellow (Classes, Constants)
        base0B = "#008000"  # Green (Strings, Success)
        base0C = "#00ffff"  # Cyan (Special Cases, Regexp)
        base0D = "#0000ff"  # Blue (Functions, Methods)
        base0E = "#ff00ff"  # Magenta (Keywords, Storage)
        base0F = "#a52a2a"  # Brown (Deprecated, Special)

        # 📖 Color Usage Guide
        [guide]
        base00 = "Background (Darkest)"
        base01 = "Lighter Background (Status bars)"
        base02 = "Selection Background"
        base03 = "Comments, Invisibles, Line Highlighting"
        base04 = "Dark Foreground (Status bars)"
        base05 = "Default Foreground, Caret, Delimiters"
        base06 = "Light Foreground"
        base07 = "Lightest Foreground (Highlights)"
        base08 = "Red (Errors, Important)"
        base09 = "Orange (Warnings, Escape Sequences)"
        base0A = "Yellow (Classes, Constants)"
        base0B = "Green (Strings, Success)"
        base0C = "Cyan (Special Cases, Regexp)"
        base0D = "Blue (Functions, Methods)"
        base0E = "Magenta (Keywords, Storage)"
        base0F = "Brown (Deprecated, Special)"

        # 🔧 macOS Integration
        # To get AppleHighlightColor: defaults read -g AppleHighlightColor
      '';
    };
  };
}
