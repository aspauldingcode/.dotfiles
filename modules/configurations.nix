{ inputs, ... }:
{
  # ── Home Manager standalone configurations ────────────────────────────
  # System-level hosts (mba, mba-dark, mba-asahi, nixos-test) are now owned
  # by `modules/host-topology-den.nix`; den auto-generates their
  # `flake.{darwin,nixos}Configurations.*` outputs from `den.hosts.*`.
  #
  # HM-standalone configurations remain hand-rolled here for now (Phase 2
  # will migrate them to `den.homes.*` if/when we extend the framework
  # ownership further).

  flake.homeConfigurations."8amps-linux" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config = {
        allowUnfree = true;
      };
    };
    extraSpecialArgs = { inherit inputs; };
    modules = [
      inputs.stylix.homeModules.stylix
      ../hosts/hm/8amps-linux
    ];
  };
}
