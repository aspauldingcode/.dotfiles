# Apps Module - Flake applications
{inputs, ...}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
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
      };
    };
  };
}
