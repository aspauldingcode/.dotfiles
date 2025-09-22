# Shared Home Manager Base Configuration for Alex
# Used across all systems with system-specific overrides
{
  inputs,
  pkgs,
  lib,
  user,
  nix-colors,
  ...
}: {
  imports = [
    inputs.nix-colors.homeManagerModules.default
  ];

  home = {
    username = user;
    homeDirectory =
      if pkgs.stdenv.isDarwin
      then "/Users/${user}"
      else "/home/${user}";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;

  # Default color scheme
  colorScheme = lib.mkDefault nix-colors.colorSchemes.gruvbox-dark-medium;

  # Linux-specific configuration
  targets.genericLinux.enable = !pkgs.stdenv.isDarwin;

  # Common packages across all systems
  home.packages = with pkgs;
    [
      # Essential tools
      curl
      wget
      jq
      tree
      htop
      unzip
      zip
      git
      lazygit
      neovim
      fastfetch
      zellij
      tldr

      # Development tools
      nodejs_20
      python3
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      # Linux-specific packages
      xdg-utils
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # Darwin-specific packages
      macos-instantview
    ]
    ;

  # Common session variables
  home.sessionVariables =
    {
      EDITOR = lib.mkDefault "nvim";
      TERMINAL = lib.mkDefault "alacritty";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      BROWSER = lib.mkDefault "firefox";
    };

  # Linux-specific XDG configuration
  xdg = lib.mkIf (!pkgs.stdenv.isDarwin) {
    enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "application/pdf" = "org.kde.okular.desktop";
        "image/jpeg" = "org.kde.gwenview.desktop";
        "image/png" = "org.kde.gwenview.desktop";
      };
    };
  };

  # Common programs - these will be available on all systems
  programs = {
    git = {
      enable = true;
      userName = lib.mkDefault "Alex Spaulding";
      userEmail = lib.mkDefault "aspauldingcode@gmail.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
        core.autocrlf = "input";
        core.editor = "nvim";
        push.default = "simple";
      };
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };

    bash = {
      enable = true;
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          opacity = 0.95;
          padding = {
            x = 10;
            y = 10;
          };
        };
        font = {
          normal = {
            family = "JetBrains Mono Nerd Font";
            style = "Regular";
          };
          size = 12.0;
        };
      };
    };

    btop = {
      enable = true;
      settings = {
        color_theme = "gruvbox_dark_v2";
        theme_background = false;
      };
    };

    fastfetch.enable = true;
    yazi.enable = true;
  };
}
