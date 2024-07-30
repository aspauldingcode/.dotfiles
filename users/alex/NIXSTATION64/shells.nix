{ config, pkgs, ... }:

let
  commonSetup = ''
    # Environment and path settings
    export PATH="/run/wrappers/bin:/Users/alex/.cargo/bin:/Applications/flameshot.app/Contents/MacOS"
    export PATH="$PATH:/opt/X11/bin:/usr/X11R6/bin:/opt/local/bin:/opt/local/sbin"
    export PATH="$PATH:/opt/homebrew/bin:/opt/homebrew/sbin:/Users/alex/.orbstack/bin"
    export PATH="$PATH:/home/alex/.local/share/gem/ruby/3.3.0/bin:/Users/alex/.gem/ruby/3.3.0/bin"
    export PATH="$PATH:/Users/alex/.nix-profile/bin:/etc/profiles/per-user/alex/bin"
    export PATH="$PATH:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
    export PATH="$PATH:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
    export PATH="$PATH:/run/wrappers/bin:/home/alex/.nix-profile/bin:/nix/profile/bin"
    export PATH="$PATH:/home/alex/.local/state/nix/profile/bin:$PATH"
    export EDITOR=nvim
    export VISUAL="$EDITOR"
    export DISPLAY=:0
    touch ~/.hushlogin
  '';
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
      initExtra =
        commonSetup
        + ''
          setopt APPEND_HISTORY
        '';
      shellAliases = {
        beeper = "beeper --disable-gpu";
        sl = "sl -e";
      };
    };

    bash = {
      enable = true;
      initExtra =
        commonSetup
        + ''
          shopt -s histappend
        '';
      shellAliases = {
        beeper = "beeper --disable-gpu";
        sl = "sl -e";
      };
    };

    fish = {
      enable = true;
      shellInit =
        commonSetup
        + ''
          set -g fish_user_paths "/opt/X11/bin" "/usr/X11R6/bin" "/opt/local/bin" "/opt/local/sbin" "/opt/homebrew/bin" "/opt/homebrew/sbin" "/Users/alex/.orbstack/bin" (ruby -e 'puts Gem.user_dir')/bin $fish_user_paths
          set -Ux EDITOR nvim
          set -Ux VISUAL $EDITOR
          set -Ux DISPLAY :0
        '';
      interactiveShellInit = ''set fish_greeting ""'';
      shellAliases = {
        beeper = "beeper --disable-gpu";
        sl = "sl -e";
      };
    };

    nushell = {
      enable = true; # Enable nushell
      environmentVariables = {
        PATH = "/Users/alex/.cargo/bin:/Applications/flameshot.app/Contents/MacOS:/opt/X11/bin:/usr/X11R6/bin:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/Users/alex/.orbstack/bin:/Users/alex/.gem/ruby/3.3.0/bin:/Users/alex/.nix-profile/bin:/etc/profiles/per-user/alex/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin:/run/wrappers/bin:/home/alex/.nix-profile/bin:/nix/profile/bin:/home/alex/.local/state/nix/profile/bin:$PATH";
        EDITOR = "nvim";
        VISUAL = "nvim";
        DISPLAY = ":0";
      };
      shellAliases = {
        ll = "ls -l";
        la = "ls -a";
        beeper = "beeper --disable-gpu";
        sl = "sl -e";
      };
    };

    # Additional configurations for oh-my-posh across shells if applicable
    # This would typically be set up in the shell's prompt configuration
    oh-my-posh = {
      enable = true; # Enable oh-my-posh module
      package = pkgs.oh-my-posh; # Specify the oh-my-posh package from Nix packages
      useTheme = "gruvbox";

      # Enable integration with various shells
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableNushellIntegration = true; # Now enabled for Nushell

      # Additional settings can be configured here
      settings = {
        # palette = {
        #   "git-foreground" = "#193549";
        #   "git" = "#FFFB38";
        #   "git-modified" = "#FF9248";
        #   "git-diverged" = "#FF4500";
        #   "git-ahead" = "#B388FF";
        #   "git-behind" = "#B388FF";
        #   "red" = "#FF0000";
        #   "green" = "#00FF00";
        #   "blue" = "#0000FF";
        #   "white" = "#FFFFFF";
        #   "black" = "#111111";
        # };
        # segments = [
        #   {
        #     type = "git";
        #     style = "powerline";
        #     powerline_symbol = "\uE0B0";
        #     foreground = "p:git-foreground";
        #     background = "p:git";
        #     background_templates = [
        #       "{{ if or (.Working.Changed) (.Staging.Changed) }}p:git-modified{{ end }}"
        #       "{{ if and (gt .Ahead 0) (gt .Behind 0) }}p:git-diverged{{ end }}"
        #       "{{ if gt .Ahead 0 }}p:git-ahead{{ end }}"
        #       "{{ if gt .Behind 0 }}p:git-behind{{ end }}"
        #     ];
        #   }
        #   {
        #     type = "aws";
        #     style = "powerline";
        #     powerline_symbol = "\uE0B0";
        #     foreground = "#ffffff";
        #     background = "#111111";
        #     foreground_templates = [
        #       "{{if contains \"default\" .Profile}}#FFA400{{end}}"
        #       "{{if contains \"jan\" .Profile}}#f1184c{{end}}"
        #     ];
        #   }
        # ];
        # color_overrides = {
        #   battery = {
        #     type = "battery";
        #     style = "powerline";
        #     invert_powerline = true;
        #     powerline_symbol = "\uE0B2";
        #     foreground = "p:white";
        #     background = "p:black";
        #     properties = {
        #       discharging_icon = "<#ffa500>-</> ";
        #       charging_icon = "+ ";
        #       charged_icon = "* ";
        #     };
        #   };
        # };
        # cycle = [
        #   {
        #     background = "p:blue";
        #     foreground = "p:white";
        #   }
        #   {
        #     background = "p:green";
        #     foreground = "p:black";
        #   }
        #   {
        #     background = "p:orange";
        #     foreground = "p:white";
        #   }
        # ];
      };
    };
  };
}
