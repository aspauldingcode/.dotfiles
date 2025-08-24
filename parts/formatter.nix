# Formatter Module using treefmt-nix
{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
    treefmt.config = {
      projectRootFile = "flake.nix";

      programs = {
        # Nix formatting
        alejandra.enable = true;

        # Shell script formatting
        shfmt.enable = true;

        # YAML formatting
        yamlfmt.enable = true;

        # Markdown formatting
        mdformat.enable = true;

        # JSON formatting
        prettier = {
          enable = true;
          includes = [
            "*.json"
            "*.jsonc"
          ];
        };
      };

      settings = {
        global = {
          excludes = [
            "*.png"
            "*.jpg"
            "*.jpeg"
            "*.gif"
            "*.ico"
            "*.icns"
            "*.car"
            "*.bundle/**"
            "*.psd"
            "*.xcf"
            "*.kra"
            "*.cape"
            "*.DS_Store"
            "*.tar.gz"
            "*.plist"
            "*.lock"
            "*.pub"
            "*.conf"
            "*.loctable"
            "*.mac13g"
            "*.bk"
            "*.txt"
            "*.norg"
            "*.kra~"
            "*.png~"
            "*.gitignore"
            "*.xccolortheme"
          ];
        };
        formatter = {
          alejandra = {
            options = ["--quiet"];
            includes = ["*.nix"];
          };
        };
      };
    };

    formatter = config.treefmt.build.wrapper;
  };
}
