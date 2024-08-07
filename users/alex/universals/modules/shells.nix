{ config, pkgs, lib, ... }:


# sudo: /run/current-system/sw/bin/sudo must be owned by uid 0 and have the setuid bit set
# on nixos means use /run/wrappers/bin/sudo, not /run/current-system/sw/bin/sudo

let
  commonSetup = ''
    # Common environment and path settings
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
    export PATH="/run/current-system/sw/bin:$PATH"
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    export PATH="/run/wrappers/bin:$PATH"
    export EDITOR=nvim
    export VISUAL="$EDITOR"
    export DISPLAY=:0
    touch ~/.hushlogin
  '';

  darwinSetup = ''
    # Darwin-specific environment and path settings
    export PATH="$HOME/.cargo/bin:$PATH"
    export PATH="$HOME/.gem/ruby/3.3.0/bin:$PATH"
    export PATH="$HOME/.nix-profile/bin:$PATH"
    export PATH="/Applications/flameshot.app/Contents/MacOS:$PATH"
    export PATH="/opt/X11/bin:/usr/X11R6/bin:$PATH"
    export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    export PATH="$HOME/.orbstack/bin:$PATH"
    export PATH="/opt/homebrew/opt/libiconv/bin:$PATH"
    export LDFLAGS="-L/opt/homebrew/opt/libiconv/lib"
    export CPPFLAGS="-I/opt/homebrew/opt/libiconv/include"
    export LIBRARY_PATH="$LIBRARY_PATH:/opt/homebrew/opt/libiconv/lib"
    alias pkg-config='pkgconf'
  '';

  fullSetup = if pkgs.stdenv.isDarwin then commonSetup + darwinSetup else commonSetup;

  inherit (config.colorScheme) colors;
in
{
  home.packages = with pkgs; [
    oh-my-fish
    fishPlugins.plugin-git
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      initExtra = fullSetup + ''
        setopt APPEND_HISTORY
      '';
    };

    bash = {
      enable = true;
      initExtra = fullSetup + ''
        shopt -s histappend
      '';
    };

    fish = {
      enable = true;
      shellInit = fullSetup + lib.optionalString pkgs.stdenv.isDarwin ''
        fish_add_path -p "/opt/X11/bin" "/usr/X11R6/bin" "/opt/local/bin"
        fish_add_path -p "/opt/local/sbin" "/opt/homebrew/bin"
        fish_add_path -p "/opt/homebrew/sbin" "$HOME/.orbstack/bin"
        fish_add_path -p (ruby -e 'puts Gem.user_dir')/bin
        fish_add_path -p "/opt/homebrew/opt/libiconv/bin"
        set -Ux LDFLAGS "-L/opt/homebrew/opt/libiconv/lib"
        set -Ux CPPFLAGS "-I/opt/homebrew/opt/libiconv/include"
        set -Ux LIBRARY_PATH "$LIBRARY_PATH:/opt/homebrew/opt/libiconv/lib"
      '';
      interactiveShellInit = ''set fish_greeting ""'';
    };

    nushell = {
      enable = true;
      environmentVariables = {
        PATH = lib.concatStringsSep ":" ([
          "$HOME/.local/bin"
          "$HOME/.cargo/bin"
          "$HOME/.gem/ruby/3.3.0/bin"
          "$HOME/.nix-profile/bin"
          "/etc/profiles/per-user/$USER/bin"
          "/run/current-system/sw/bin"
          "/nix/var/nix/profiles/default/bin"
          "/usr/local/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
          "/run/wrappers/bin"
        ] ++ lib.optionals pkgs.stdenv.isDarwin [
          "/Applications/flameshot.app/Contents/MacOS"
          "/opt/X11/bin"
          "/usr/X11R6/bin"
          "/opt/local/bin"
          "/opt/local/sbin"
          "/opt/homebrew/bin"
          "/opt/homebrew/sbin"
          "$HOME/.orbstack/bin"
          "/opt/homebrew/opt/libiconv/bin"
        ]);
        EDITOR = "nvim";
        VISUAL = "nvim";
        DISPLAY = ":0";
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        LDFLAGS = "-L/opt/homebrew/opt/libiconv/lib";
        CPPFLAGS = "-I/opt/homebrew/opt/libiconv/include";
        LIBRARY_PATH = "$LIBRARY_PATH:/opt/homebrew/opt/libiconv/lib";
      };
      shellAliases = {
        ll = "ls -l";
        la = "ls -a";
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        pkg-config = "pkgconf";
      };
    };

    oh-my-posh = {
      enable = true;
      package = pkgs.oh-my-posh;
      useTheme = "gruvbox";
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      # Additional settings can be configured here
      # settings = {
      #   # Configuration settings for oh-my-posh can be added here
      #   # Add correct colors for theme.
      #   "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
      #   version = 2;
      #   final_space = true;
      #   console_title_template = "{{ .Folder }}";
      #   blocks = [
      #     {
      #       type = "prompt";
      #       alignment = "left";
      #       segments = [
      #         {
      #           type = "os";
      #           style = "powerline";
      #           foreground = "${colors.base05}";
      #           background = "${colors.base01}";
      #           template = "{{ if .WSL }}WSL at{{ end }} {{.Icon}} ";
      #         }
      #         {
      #           type = "path";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base00}";
      #           background = "${colors.base0A}";
      #           template = " {{ .Path }} ";
      #           properties = {
      #             style = "full";
      #           };
      #         }
      #         {
      #           type = "git";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base00}";
      #           background = "${colors.base0B}";
      #           background_templates = [
      #             "{{ if or (.Working.Changed) (.Staging.Changed) }}${colors.base09}{{ end }}"
      #             "{{ if and (gt .Ahead 0) (gt .Behind 0) }}${colors.base08}{{ end }}"
      #             "{{ if gt .Ahead 0 }}${colors.base0D}{{ end }}"
      #             "{{ if gt .Behind 0 }}${colors.base0D}{{ end }}"
      #           ];
      #           leading_diamond = "\ue0b6";
      #           trailing_diamond = "\ue0b4";
      #           template = " {{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} ";
      #           properties = {
      #             branch_icon = "\ue0a0 ";
      #             branch_identical_icon = "\u25cf";
      #             branch_max_length = 25;
      #             fetch_stash_count = true;
      #             fetch_status = true;
      #           };
      #         }
      #         {
      #           type = "go";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base07}";
      #           background = "${colors.base0C}";
      #           template = " \ue626 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
      #           properties = {
      #             fetch_version = true;
      #           };
      #         }
      #         {
      #           type = "julia";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base07}";
      #           background = "${colors.base0D}";
      #           template = " \ue624 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
      #           properties = {
      #             fetch_version = true;
      #           };
      #         }
      #         {
      #           type = "python";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base07}";
      #           background = "${colors.base0E}";
      #           template = " \ue235 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
      #           properties = {
      #             display_mode = "files";
      #             fetch_virtual_env = false;
      #           };
      #         }
      #         {
      #           type = "ruby";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base07}";
      #           background = "${colors.base09}";
      #           template = " \ue791 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
      #           properties = {
      #             display_mode = "files";
      #             fetch_version = true;
      #           };
      #         }
      #         {
      #           type = "azfunc";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base07}";
      #           background = "${colors.base0A}";
      #           template = " \uf0e7{{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
      #           properties = {
      #             display_mode = "files";
      #             fetch_version = false;
      #           };
      #         }
      #         {
      #           type = "aws";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base07}";
      #           background_templates = [
      #             "{{if contains \"default\" .Profile}}${colors.base09}{{end}}"
      #             "{{if contains \"jan\" .Profile}}${colors.base08}{{end}}"
      #           ];
      #           template = " \ue7ad {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} ";
      #           properties = {
      #             display_default = false;
      #           };
      #         }
      #         {
      #           type = "root";
      #           style = "powerline";
      #           powerline_symbol = "\ue0b0";
      #           foreground = "${colors.base07}";
      #           background = "${colors.base0B}";
      #           template = " \uf0ad ";
      #         }
      #       ];
      #     }
      #   ];
      # };
    };
  };
}