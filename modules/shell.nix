{
  flake.modules.nixos.shell =
    { pkgs, lib, config, options, ... }:
    {
      # TODO: Revert to default behavior once https://github.com/NixOS/nixpkgs/issues/513543 is resolved.
      programs.zsh.enable = true;
 
      users = lib.optionalAttrs (options.users ? defaultUserShell) {
        defaultUserShell = pkgs.zsh;
      };
 
      environment = {
        shells = [ pkgs.zsh ];
        systemPackages = [
          pkgs.nh
          pkgs.yazi
        ];
      } // (lib.optionalAttrs (options.environment ? binsh) {
        binsh = "${pkgs.zsh}/bin/zsh";
      });
    };

  flake.modules.darwin.shell =
    { pkgs, inputs, ... }:
    {
      # TODO: Revert to default behavior once https://github.com/NixOS/nixpkgs/issues/513543 is resolved.
      programs.zsh.enable = true;
      environment.systemPackages = [
        pkgs.nh
        pkgs.yazi
        inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };

  flake.modules.homeManager.shell =
    { pkgs, config, lib, ... }:
    {
      programs.zsh = {
        enable = true;
        # TODO: Revert to `package = pkgs.zsh;` once https://github.com/NixOS/nixpkgs/issues/513543 is resolved.
        # Currently using default macOS zsh via emptyDirectory to avoid the issue.
        package = pkgs.emptyDirectory;
        enableCompletion = true;
        autosuggestion.enable = false;
        syntaxHighlighting.enable = false;
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
          command_timeout = 500; # Restore default timeout
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
        FLAKE = "${config.home.homeDirectory}/.dotfiles" + (lib.optionalString pkgs.stdenv.isDarwin "#mba");
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
      ];
    };
}
