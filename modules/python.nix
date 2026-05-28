{
  # ── Python Development Environment ────────────────────────────
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      pythonPkg = pkgs.python3;

      pythonEnv = pythonPkg.withPackages (
        ps: with ps; [
          pip
          setuptools
          wheel
          ipython
          six
        ]
      );
    in
    {
      options.dendritic.python = {
        enable = lib.mkEnableOption "Python development environment";
        safePip = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enforce PIP_REQUIRE_VIRTUALENV to prevent accidental global installs.";
        };
      };

      config = lib.mkIf config.dendritic.python.enable {
        environment.systemPackages = with pkgs; [
          pythonEnv
          uv
          poetry
          pipx
          black
          python3Packages.flake8
          isort
          mypy
          ruff
          httpie
        ];

        environment.variables = lib.optionalAttrs config.dendritic.python.safePip {
          PIP_REQUIRE_VIRTUALENV = "true";
        };
      };
    };

  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      pythonPkg = pkgs.python3;

      pythonEnv = pythonPkg.withPackages (
        ps: with ps; [
          pip
          setuptools
          wheel
          ipython
          six
        ]
      );
    in
    {
      options.dendritic.python = {
        enable = lib.mkEnableOption "Python development environment";
        safePip = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enforce PIP_REQUIRE_VIRTUALENV to prevent accidental global installs.";
        };
      };

      config = lib.mkIf config.dendritic.python.enable {
        environment.systemPackages = with pkgs; [
          pythonEnv
          uv
          poetry
          pipx
          black
          python3Packages.flake8
          isort
          mypy
          ruff
          httpie
        ];

        environment.variables = lib.optionalAttrs config.dendritic.python.safePip {
          PIP_REQUIRE_VIRTUALENV = "true";
        };
      };
    };

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      pythonPkg = pkgs.python3;

      pythonEnv = pythonPkg.withPackages (
        ps: with ps; [
          pip
          setuptools
          wheel
          ipython
          six
        ]
      );
    in
    {
      options.dendritic.python = {
        enable = lib.mkEnableOption "Python development environment";
        safePip = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enforce PIP_REQUIRE_VIRTUALENV to prevent accidental global installs.";
        };
      };

      config = lib.mkIf config.dendritic.python.enable {
        home.packages = with pkgs; [
          pythonEnv
          uv
          poetry
          pipx
          black
          python3Packages.flake8
          isort
          mypy
          ruff
          httpie
        ];

        home.file.".config/pypoetry/config.toml".text = ''
          [virtualenvs]
          in-project = true
        '';

        programs.zsh.shellAliases = {
          py = "python3";
          pv = "python3 -m venv .venv && source .venv/bin/activate";
          pipx = "PIP_REQUIRE_VIRTUALENV=false pipx";
        };

        home.sessionVariables = lib.optionalAttrs config.dendritic.python.safePip {
          PIP_REQUIRE_VIRTUALENV = "true";
        };
      };
    };
}
