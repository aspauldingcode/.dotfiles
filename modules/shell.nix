{
  flake.modules.nixos.shell =
    { pkgs, lib, options, ... }:
    {
      programs.zsh.enable = true;

      users = lib.optionalAttrs (options ? users && options.users ? defaultUserShell) {
        defaultUserShell = pkgs.zsh;
      };

      environment = {
        systemPackages = [
          pkgs.nh
          pkgs.yazi
        ];
      } // (lib.optionalAttrs (options ? environment && options.environment ? shells) {
        shells = [ pkgs.zsh ];
      });
    };

  flake.modules.darwin.shell =
    { pkgs, inputs, ... }:
    {
      programs.zsh.enable = true;
      environment.shells = [ pkgs.zsh ];
      
      environment.systemPackages = [
        pkgs.nh
        pkgs.yazi
        inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };

  flake.modules.homeManager.shell =
    { pkgs, config, lib, inputs, ... }:
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        # Use zsh from nixpkgs to override macOS default
        package = pkgs.zsh;
        
        history = {
          size = 10000;
          path = "${config.home.homeDirectory}/.zsh_history";
        };

        initContent = ''
          # Any custom zsh config can go here
          bindkey '^[[A' up-line-or-search
          bindkey '^[[B' down-line-or-search
        '';
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          # Keep Docker disabled as it was confirmed to cause noise
          docker_context.disabled = true;

          # Restore other modules
          git_status.disabled = false;
          nix_shell.disabled = false;

          # Performance optimizations
          command_timeout = 2000; # Increased to 2s to prevent Swift/Swiftly timeouts
          scan_timeout = 100;    # Default 30ms is too low for dirs with nix store symlinks

          # Clean up the directory module
          directory = {
            read_only = "";
            truncation_length = 3;
            truncate_to_repo = true;
          };
        };
      };

      home.sessionVariables = {
        NH_FLAKE = "${config.home.homeDirectory}/.dotfiles" + (lib.optionalString pkgs.stdenv.isDarwin "#mba");
      };

      # Yazi minimal configuration with ANSI inheritance
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
        settings = {
          manager = {
            show_hidden = true;
            sort_by = "natural";
          };
        };
      };

      # Btop (themed by Stylix)
      programs.btop = {
        enable = true;
        settings = {
          theme_background = false;
          truecolor = true;
        };
      };

      programs.htop.enable = true;

      home.packages = with pkgs; [
        nh
        zsh-completions
      ];
    };
}
