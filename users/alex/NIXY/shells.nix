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
      initExtra = commonSetup + ''
        setopt APPEND_HISTORY
      '';
    };

    bash = {
      enable = true;
      initExtra = commonSetup + ''
        shopt -s histappend
      '';
    };

    fish = {
      enable = true;
      shellInit = commonSetup + ''
        set -g fish_user_paths "/opt/X11/bin" "/usr/X11R6/bin" "/opt/local/bin" "/opt/local/sbin" "/opt/homebrew/bin" "/opt/homebrew/sbin" "/Users/alex/.orbstack/bin" (ruby -e 'puts Gem.user_dir')/bin $fish_user_paths
        set -Ux EDITOR nvim
        set -Ux VISUAL $EDITOR
        set -Ux DISPLAY :0
      '';
      interactiveShellInit = ''set fish_greeting ""'';
    };

    nushell = {
      enable = true;  # Enable nushell
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
      enable = true;  # Enable oh-my-posh module
      package = pkgs.oh-my-posh;  # Specify the oh-my-posh package from Nix packages
      useTheme = "gruvbox"; # custom down below.

      # Enable integration with various shells
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
