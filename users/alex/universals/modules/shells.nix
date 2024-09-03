{ config, pkgs, lib, ... }:

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
    eval $(thefuck --alias)
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

  commonAliases = {
    ll = "ls -l";
    la = "ls -a";
  };

  darwinAliases = {
    reboot = "sudo reboot now";
    rb = "sudo reboot now";
    shutdown = "sudo shutdown -h now";
    sd = "sudo shutdown -h now";
  };

  linuxAliases = {
    reboot = "sudo systemctl reboot";
    rb = "sudo systemctl reboot";
    shutdown = "sudo systemctl poweroff";
    sd = "sudo systemctl poweroff";
  };

  shellAliases = commonAliases // (if pkgs.stdenv.isDarwin then darwinAliases else linuxAliases);

  inherit (config.colorScheme) colors;
in
{
  home.packages = with pkgs; [
    oh-my-fish
    fishPlugins.plugin-git
    thefuck
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      initExtra = fullSetup + ''
        setopt APPEND_HISTORY
        # Enable case-insensitive tab completion
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      '';
      shellAliases = shellAliases;
    };

    bash = {
      enable = true;
      enableCompletion = true;
      initExtra = fullSetup + ''
        shopt -s histappend
        # Enable case-insensitive tab completion
        bind "set completion-ignore-case on"
      '';
      shellAliases = shellAliases;
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
        # Enable case-insensitive tab completion
        set -g fish_complete_path (string match -v '*/__fish_build_paths.fish' $fish_complete_path)
        set -g fish_complete_path $fish_complete_path ~/.config/fish/completions
        set -U fish_features qmark-noglob
      '';
      interactiveShellInit = ''
        set fish_greeting ""
        # Enable case-insensitive tab completion
        set -g fish_completion_ignore_case 1
      '';
      shellAliases = shellAliases;
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
      shellAliases = shellAliases;
      extraConfig = ''
        # Enable case-insensitive tab completion
        $env.config = {
          completions: {
            case_sensitive: false
          }
        }
      '';
    };

    oh-my-posh = {
      enable = true;
      package = pkgs.oh-my-posh;
      # useTheme = "gruvbox"; # Ignored when using settings
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      # Additional settings can be configured here
      settings = {
        "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
        blocks = [
          {
            alignment = "left";
            segments = [
              {
                background = "#${colors.base01}";
                foreground = "#${colors.base05}";
                style = "powerline";
                template = "{{ if .WSL }}WSL at{{ end }} {{.Icon}} ";
                type = "os";
              }
              {
                background = "#${colors.base0D}";
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                properties = {
                  style = "full";
                };
                style = "powerline";
                template = " {{ .Path }} ";
                type = "path";
              }
              {
                background = "#${colors.base0B}";
                background_templates = [
                  "{{ if or (.Working.Changed) (.Staging.Changed) }}#${colors.base09}{{ end }}"
                  "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#${colors.base0A}{{ end }}"
                  "{{ if gt .Ahead 0 }}#${colors.base0C}{{ end }}"
                  "{{ if gt .Behind 0 }}#${colors.base0E}{{ end }}"
                ];
                foreground = "#${colors.base00}";
                leading_diamond = "◀";
                powerline_symbol = "";
                properties = {
                  branch_max_length = 25;
                  fetch_stash_count = true;
                  fetch_status = true;
                  branch_icon = "⎇ ";
                  branch_identical_icon = "≡";
                };
                style = "powerline";
                template = " {{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} ✎ {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} ✓ {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} ⚑ {{ .StashCount }}{{ end }} ";
                trailing_diamond = "";
                type = "git";
              }
              {
                background = "#${colors.base0A}";
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                properties = {
                  fetch_version = true;
                };
                style = "powerline";
                template = " ⬢ {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "go";
              }
              {
                background = "#${colors.base0C}";
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                properties = {
                  fetch_version = true;
                };
                style = "powerline";
                template = " ⋈ {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "julia";
              }
              {
                background = "#${colors.base09}";
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                properties = {
                  display_mode = "files";
                  fetch_virtual_env = false;
                };
                style = "powerline";
                template = " 🐍 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "python";
              }
              {
                background = "#${colors.base0E}";
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                properties = {
                  display_mode = "files";
                  fetch_version = true;
                };
                style = "powerline";
                template = " 💎 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "ruby";
              }
              {
                background = "#${colors.base0D}";
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                properties = {
                  display_mode = "files";
                  fetch_version = false;
                };
                style = "powerline";
                template = " ⚡{{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "azfunc";
              }
              {
                background_templates = [
                  "{{if contains \"default\" .Profile}}#${colors.base09}{{end}}"
                  "{{if contains \"jan\" .Profile}}#${colors.base0A}{{end}}"
                ];
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                properties = {
                  display_default = false;
                };
                style = "powerline";
                template = " ☁️ {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} ";
                type = "aws";
              }
              {
                background = "#${colors.base0C}";
                foreground = "#${colors.base00}";
                powerline_symbol = "";
                style = "powerline";
                template = " 🔧 ";
                type = "root";
              }
              {
                background = "#${colors.base03}";
                foreground = "#${colors.base05}";
                powerline_symbol = "";
                style = "powerline";
                template = " {{ .Name }} ";
                type = "shell";
              }
            ];
            type = "prompt";
          }
        ];
        console_title_template = "{{ .Folder }}";
        final_space = true;
        version = 2;
      };
    };
  };
}
