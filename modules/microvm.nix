{ inputs, ... }:
{
  config = {
    # ── Darwin Specific Module ──────────────────────────────────
    # Provides the `microvm-run` wrapper script that builds the microvm
    # runner on demand and execs it. The microvm host itself is declared
    # by `modules/host-topology-den.nix` as `den.hosts.aarch64-linux.microvm`.
    flake.modules.darwin.dendritic =
      { pkgs, inputs, ... }:
      let
        microvmRunWrapper = pkgs.writeShellApplication {
          name = "microvm-run";
          runtimeInputs = [ pkgs.nix ];
          text = ''
            set -eu
            runner="$(${pkgs.nix}/bin/nix build --no-link --print-out-paths \
              "/etc/nix-darwin/.dotfiles#nixosConfigurations.microvm.config.microvm.runner.vfkit")"
            exec "$runner/bin/microvm-run" "$@"
          '';
        };
      in
      {
        environment.systemPackages = [
          inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          microvmRunWrapper
        ];
      };
  };
}
