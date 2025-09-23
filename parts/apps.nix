# Apps Module - Flake applications
{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      apps = {
        # Default app - system info
        default = {
          type = "app";
          program = "${pkgs.writeShellScript "dotfiles-info" ''
            echo "Dotfiles Configuration"
            echo "====================="
            echo "System: $(uname -s)"
            echo "Architecture: $(uname -m)"
            echo "Hostname: $(hostname)"
            echo "Nix version: $(nix --version)"
            echo "Flake path: ${inputs.self}"
          ''}";
          meta.description = "Show dotfiles configuration information";
        };

        # System info app
        system-info = {
          type = "app";
          program = "${pkgs.writeShellScript "system-info" ''
            echo "=== System Information ==="
            echo "OS: $(uname -s)"
            echo "Kernel: $(uname -r)"
            echo "Architecture: $(uname -m)"
            echo "Hostname: $(hostname)"
            echo "User: $(whoami)"
            echo "Shell: $SHELL"
            echo "Nix version: $(nix --version)"
            echo "Home: $HOME"
            echo "PWD: $PWD"
          ''}";
          meta.description = "Display detailed system information";
        };

        # Nixible CLI for 8AMPS iPhone configuration
        "8AMPS" =
          let
            # Import nixible lib from non-flake input (GitLab source)
            nixible_lib = (import "${inputs.nixible}") {
              inherit pkgs;
              inherit (pkgs) lib;
            };
            nixible_cli = nixible_lib.mkNixibleCli ../playbooks/remote-device-setup.nix;
          in
          {
            type = "app";
            program = "${nixible_cli}/bin/nixible";
            meta.description = "Configure 8AMPS iPhone using Nixible/Ansible";
          };
      };
    };
}
