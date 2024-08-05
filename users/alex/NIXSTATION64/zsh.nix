{ config, pkgs, ... }:

let
  commonSetup = ''
    # Environment and path settings
    export PATH="/Users/alex/.cargo/bin:/Applications/flameshot.app/Contents/MacOS:/opt/X11/bin:/usr/X11R6/bin:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/Users/alex/.orbstack/bin:/Users/alex/.gem/ruby/3.3.0/bin:/Users/alex/.nix-profile/bin:/etc/profiles/per-user/alex/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
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
    };

    bash = {
      enable = true;
      initExtra =
        commonSetup
        + ''
          shopt -s histappend
        '';
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
    };

    nushell = {
      enable = true; # Enable nushell
      environmentVariables = {
        PATH = "/Users/alex/.cargo/bin:/Applications/flameshot.app/Contents/MacOS:/opt/X11/bin:/usr/X11R6/bin:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/Users/alex/.orbstack/bin:/Users/alex/.gem/ruby/3.3.0/bin:/Users/alex/.nix-profile/bin:/etc/profiles/per-user/alex/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH";
        EDITOR = "nvim";
        VISUAL = "nvim";
        DISPLAY = ":0";
      };
      shellAliases = {
        ll = "ls -l";
        la = "ls -a";
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
        # Configuration settings for oh-my-posh can be added here
      };
    };
  };
}
