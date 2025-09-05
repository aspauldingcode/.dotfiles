{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    eza
    powershell # FIXME: make it available upstream in nix options as programs.powershell.enable?
  ];

  home.file = lib.mkIf pkgs.stdenv.isDarwin {
    ".hushlogin" = {
      text = "";
    };
  };

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      initContent = ''
        setopt APPEND_HISTORY
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        export EDITOR=nvim

        export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

        oh-my-posh disable notice
      '';
      shellAliases = {
        l = "eza --icons --group-directories-first";
        ls = "eza --icons --group-directories-first";
        ll = "eza --icons --group-directories-first -al";
        la = "eza --icons --group-directories-first -a";
        tree = "eza --icons --tree";
        lsdir = "ls -d */";
        nu = "nu --login";

        reboot =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        rb =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        shutdown =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
        sd =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
      };
    };

    bash = {
      enable = true;
      package = pkgs.bashInteractive;
      enableCompletion = true;
      initExtra = ''
        shopt -s histappend
        bind "set completion-ignore-case on"
        export BASH_SILENCE_DEPRECATION_WARNING=1
        export EDITOR=nvim

        export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

        oh-my-posh disable notice
      '';
      shellAliases = {
        l = "eza --icons --group-directories-first";
        ls = "eza --icons --group-directories-first";
        ll = "eza --icons --group-directories-first -al";
        la = "eza --icons --group-directories-first -a";
        tree = "eza --icons --tree";
        lsdir = "ls -d */";
        nu = "nu --login";

        reboot =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        rb =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        shutdown =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
        sd =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
      };
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting ""
        set -g fish_completion_ignore_case 1
        set -gx EDITOR nvim

        set -gx SOPS_AGE_KEY_FILE "$HOME/.config/sops/age/keys.txt"

        oh-my-posh disable notice
      '';
      shellAliases = {
        l = "eza --icons --group-directories-first";
        ls = "eza --icons --group-directories-first";
        ll = "eza --icons --group-directories-first -al";
        la = "eza --icons --group-directories-first -a";
        tree = "eza --icons --tree";
        lsdir = "ls -d */";
        nu = "nu --login";

        reboot =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        rb =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        shutdown =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
        sd =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
      };
    };

    nushell = {
      enable = true;
      package = pkgs.unstable.nushell;
      configFile = {
        source = null;
        text = '''';
      };
      envFile = {
        source = null;
        text = '''';
      };
      loginFile = {
        source = null;
        text = '''';
      };
      environmentVariables = {
        EDITOR = "nvim";
        SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
      };
      extraConfig = ''
        $env.config.show_banner = false

        def lsdir [path: path = '.'] { ls $path | where type == 'dir' }

        # Secrets temporarily disabled for build - need proper SOPS encryption setup
        $env.SOPS_AGE_KEY_FILE = ($env.HOME | path join ".config" "sops" "age" "keys.txt")

        oh-my-posh disable notice
      '';
      extraEnv = '''';
      extraLogin = '''';
      shellAliases = {
        l = "ls";
        ll = "ls -l";
        la = "ls -a";
        tree = "ls **/*";
        nu = "nu --login";

        reboot =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        rb =
          if pkgs.stdenv.isDarwin
          then "sudo reboot now"
          else "sudo systemctl reboot";
        shutdown =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
        sd =
          if pkgs.stdenv.isDarwin
          then "sudo shutdown -h now"
          else "sudo systemctl poweroff";
      };
    };

    oh-my-posh = {
      enable = true;
      package = pkgs.oh-my-posh;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      settings = {
        upgrade = {
          notice = false;
          interval = "168h";
          auto = false;
          source = "cdn";
        };

        "$schema" = "https://raw.gith1busercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json";
        blocks = [
          {
            alignment = "left";
            segments = [
              {
                type = "text";
                style = "powerline";
                powerline_symbol = "";
                foreground = "#${config.colorScheme.palette.base0D}";
                background = "#${config.colorScheme.palette.base00}";
                template = "";
              }
              {
                background = "#${config.colorScheme.palette.base0D}";
                foreground = "#${config.colorScheme.palette.base00}";
                powerline_symbol = "";
                style = "powerline";
                template = "{{ if .WSL }}WSL at{{ end }} {{.Icon}} ";
                type = "os";
              }
              {
                background = "#${config.colorScheme.palette.base03}";
                foreground = "#${config.colorScheme.palette.base00}";
                powerline_symbol = "";
                properties = {
                  style = "full";
                };
                style = "powerline";
                template = " {{ .Path }} ";
                type = "path";
              }
              {
                background = "#${config.colorScheme.palette.base0B}";
                background_templates = [
                  "{{ if or (.Working.Changed) (.Staging.Changed) }}#${config.colorScheme.palette.base09}{{ end }}"
                  "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#${config.colorScheme.palette.base0A}{{ end }}"
                  "{{ if gt .Ahead 0 }}#${config.colorScheme.palette.base0C}{{ end }}"
                  "{{ if gt .Behind 0 }}#${config.colorScheme.palette.base0E}{{ end }}"
                ];
                foreground = "#${config.colorScheme.palette.base00}";
                leading_diamond = "";
                powerline_symbol = "";
                properties = {
                  branch_max_length = 25;
                  fetch_stash_count = true;
                  fetch_status = true;
                  branch_icon = "⎇ ";
                  branch_identical_icon = "≡";
                };
                style = "powerline";
                template = " {{ .HEAD }}{{ if .Working.Changed }}*{{ end }} ";
                trailing_diamond = "";
                type = "git";
              }
              {
                background = "#${config.colorScheme.palette.base0A}";
                foreground = "#${config.colorScheme.palette.base07}";
                powerline_symbol = "";
                properties = {
                  fetch_version = true;
                };
                style = "powerline";
                template = " ⬢ {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "go";
              }
              {
                background = "#${config.colorScheme.palette.base0C}";
                foreground = "#${config.colorScheme.palette.base07}";
                powerline_symbol = "";
                properties = {
                  fetch_version = true;
                };
                style = "powerline";
                template = " ⋈ {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "julia";
              }
              {
                background = "#${config.colorScheme.palette.base0B}";
                foreground = "#${config.colorScheme.palette.base00}";
                powerline_symbol = "";
                properties = {
                  display_mode = "files";
                  fetch_virtual_env = false;
                };
                style = "powerline";
                template = " 🐍 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "python";
              }
              {
                background = "#${config.colorScheme.palette.base08}";
                foreground = "#${config.colorScheme.palette.base07}";
                powerline_symbol = "";
                properties = {
                  display_mode = "files";
                  fetch_version = true;
                };
                style = "powerline";
                template = " 💎 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "ruby";
              }
              {
                background = "#${config.colorScheme.palette.base0E}";
                foreground = "#${config.colorScheme.palette.base00}";
                powerline_symbol = "";
                properties = {
                  fetch_version = true;
                };
                style = "powerline";
                template = " ☕ {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ";
                type = "java";
              }
              {
                background = "#${config.colorScheme.palette.base0D}";
                foreground = "#${config.colorScheme.palette.base07}";
                powerline_symbol = "";
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
                  "{{if contains \"default\" .Profile}}#${config.colorScheme.palette.base09}{{end}}"
                  "{{if contains \"jan\" .Profile}}#${config.colorScheme.palette.base0A}{{end}}"
                ];
                foreground = "#${config.colorScheme.palette.base07}";
                powerline_symbol = "";
                properties = {
                  display_default = false;
                };
                style = "powerline";
                template = " ☁️ {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} ";
                type = "aws";
              }
              {
                type = "command";
                style = "powerline";
                powerline_symbol = "";
                foreground = "#${config.colorScheme.palette.base00}";
                background = "#${config.colorScheme.palette.base0F}";
                properties = {
                  command = "if ls *.sh > /dev/null 2>&1; then echo '📜'; fi";
                  cache_timeout = 0;
                };
                template = " {{ .Output }} ";
              }
              {
                background = "#${config.colorScheme.palette.base0D}";
                foreground = "#${config.colorScheme.palette.base00}";
                powerline_symbol = "";
                style = "powerline";
                type = "nix-shell";
                template = " ❄️ (nix-{{ .Type }})";
              }
              {
                background = "#${config.colorScheme.palette.base01}";
                foreground = "#${config.colorScheme.palette.base07}";
                powerline_symbol = "";
                style = "powerline";
                template = " 🔧 ";
                type = "root";
              }
              {
                background = "#${config.colorScheme.palette.base01}";
                foreground = "#${config.colorScheme.palette.base05}";
                powerline_symbol = "";
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
