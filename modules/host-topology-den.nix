{
  inputs,
  config,
  lib,
  ...
}:
let
  # Wrap nix-darwin/nixos system builders so they pass `specialArgs.inputs`,
  # matching the convention used by the existing hosts/<class>/<name>/default.nix
  # files (they receive `inputs` from specialArgs in our pre-den setup).
  #
  # Den's default `instantiate` would call inputs.nix-darwin.lib.darwinSystem
  # without specialArgs, breaking every host file that destructures `inputs`
  # at module entry.
  withInputs =
    builder: args:
    builder (
      args
      // {
        specialArgs = (args.specialArgs or { }) // {
          inherit inputs;
        };
      }
    );
  darwinSystemWithInputs = withInputs inputs.nix-darwin.lib.darwinSystem;
  nixosSystemWithInputs = withInputs inputs.nixpkgs.lib.nixosSystem;
in
{
  # Pull den's flake-parts integration into our flake-parts evaluation. This
  # adds the `den.*` option namespace and lets us declare aspects + hosts.
  # `den-aspects/styling.nix` defines `den.aspects.styling`; this file owns
  # the host topology that consumes it.
  imports = [
    inputs.den.flakeModule
    ../den-aspects/styling.nix
  ];

  # ── Host declarations ─────────────────────────────────────────────────
  # Den auto-generates `flake.{darwin,nixos}Configurations.<name>` from
  # these entries by calling each host's `instantiate` with its resolved
  # `mainModule`. The resolved mainModule already includes the aspect chain
  # (host's own aspect + everything in `includes`).

  den.hosts.aarch64-darwin.mba = {
    instantiate = darwinSystemWithInputs;
  };

  den.hosts.aarch64-darwin.mba-dark = {
    instantiate = darwinSystemWithInputs;
  };

  den.hosts.aarch64-linux.mba-asahi = {
    instantiate = nixosSystemWithInputs;
  };

  den.hosts.aarch64-linux.nixos-test = {
    instantiate = nixosSystemWithInputs;
  };

  den.hosts.aarch64-linux.microvm = {
    instantiate = nixosSystemWithInputs;
  };

  den.hosts.x86_64-linux.sliceanddice = {
    instantiate = nixosSystemWithInputs;
  };

  den.hosts.x86_64-linux.sliceanddice-installer = {
    instantiate = nixosSystemWithInputs;
  };

  # ── Host-aspect bindings ──────────────────────────────────────────────
  # Each host's aspect:
  #   • includes the shared styling aspect (gets `os`-class Stylix + per-class
  #     extras automatically)
  #   • imports the existing hosts/<class>/<name>/default.nix raw module via
  #     the appropriate class body (`darwin` or `nixos`), preserving every
  #     bit of platform/identity/HM-config that already exists there
  #   • applies host-specific variant overrides where needed (mba-dark)

  den.aspects.mba = {
    includes = [ config.den.aspects.styling ];
    darwin = {
      imports = [
        { nixpkgs.config.allowUnsupportedSystem = true; }
        ../hosts/darwin/mba
        { dendritic.theme.variant = "light"; }
      ];
    };
  };

  den.aspects.mba-dark = {
    includes = [ config.den.aspects.styling ];
    darwin = {
      imports = [
        { nixpkgs.config.allowUnsupportedSystem = true; }
        ../hosts/darwin/mba
        { dendritic.theme.variant = lib.mkForce "dark"; }
      ];
    };
  };

  den.aspects.mba-asahi = {
    includes = [ config.den.aspects.styling ];
    nixos = {
      imports = [ ../hosts/nixos/mba-asahi ];
    };
  };

  den.aspects.nixos-test = {
    includes = [ config.den.aspects.styling ];
    nixos = {
      imports = [ ../hosts/nixos/nixos-test ];
    };
  };

  den.aspects.sliceanddice = {
    includes = [ config.den.aspects.styling ];
    nixos = {
      imports = [ ../hosts/nixos/sliceanddice ];
    };
  };

  den.aspects.sliceanddice-installer = {
    nixos = {
      imports = [ ../hosts/nixos/sliceanddice-installer ];
    };
  };

  # The microvm host is a vfkit-hypervised aarch64-linux NixOS guest used as
  # a Wayland sandbox from the Darwin host. Its body used to live in
  # `modules/microvm.nix` as a hand-rolled `flake.nixosConfigurations.microvm`;
  # migrating it here gives it the same aspect-resolution treatment as the
  # other hosts (so it picks up `den.aspects.styling`).
  den.aspects.microvm = {
    includes = [ config.den.aspects.styling ];
    nixos =
      { lib, pkgs, ... }:
      {
        imports = [
          inputs.microvm.nixosModules.microvm
          inputs.home-manager.nixosModules.home-manager
          inputs.determinate-nix.nixosModules.default
        ];

        nixpkgs.hostPlatform = "aarch64-linux";
        nixpkgs.config.allowUnfree = true;

        networking.hostName = "dendritic-vm";
        system.stateVersion = "24.11";

        users.users."8amps" = {
          isNormalUser = true;
          extraGroups = [
            "wheel"
            "video"
            "input"
          ];
          initialPassword = "nix";
        };
        services.getty.autologinUser = "8amps";

        microvm = {
          hypervisor = "vfkit";
          socket = "/Users/8amps/.local/share/microvm/dendritic-vm.sock";
          vcpu = 2;
          mem = 8192;
          shares = [
            {
              proto = "virtiofs";
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];
          registerWithMachined = false;
          vmHostPackages = inputs.nixpkgs.legacyPackages."aarch64-darwin";
          writableStoreOverlay = "/nix/.rw-store";
          volumes = [
            {
              image = "/Users/8amps/.local/share/microvm/dendritic-vm.img";
              mountPoint = "/nix/.rw-store";
              size = 20480;
            }
          ];
          vfkit.logLevel = "info";
        };

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users."8amps" = import ../hosts/hm/8amps-linux;
        home-manager.sharedModules = [
          {
            stylix.targets.neovim.enable = lib.mkForce false;
            stylix.targets.neovide.enable = lib.mkForce false;
            targets.genericLinux.enable = lib.mkForce false;
            programs.firefox.enable = lib.mkForce false;
            programs.brave.enable = lib.mkForce false;
          }
        ];

        nix.settings = {
          sandbox = false;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
        boot.initrd.systemd.enable = false;
        boot.kernelPackages = pkgs.linuxPackages;

        environment.variables = {
          WLR_RENDERER = "pixman";
          WLR_NO_HARDWARE_CURSORS = "1";
          WLR_BACKENDS = "wayland";
        };
        programs.sway.package = lib.mkForce pkgs.sway;
        environment.systemPackages = [
          (lib.hiPrio (
            pkgs.writeShellScriptBin "sway" ''
              export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
              echo "Connecting to macOS host over VSOCK port 1024... (XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR)"
              mkdir -p "$XDG_RUNTIME_DIR"
              exec ${pkgs.waypipe}/bin/waypipe \
                --display "$XDG_RUNTIME_DIR/wayland-1" \
                --socket vsock:2:1024 \
                server \
                -- ${pkgs.sway}/bin/sway "$@"
            ''
          ))
        ];

        documentation.enable = false;
        documentation.nixos.enable = false;
        documentation.man.enable = false;
        documentation.doc.enable = false;
      };
  };

}
