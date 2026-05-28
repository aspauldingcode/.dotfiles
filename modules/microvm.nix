{ inputs, ... }:
# UNIQUE_COMMENT_TO_FORCE_HASH_CHANGE_V1
{
  config = {
    # ── Darwin Specific Module ──────────────────────────────────
    flake.modules.darwin.microvm = { pkgs, inputs, ... }: {
      environment.systemPackages = [ 
        inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        # inputs.self.nixosConfigurations.microvm.config.microvm.runner.vfkit
      ];
      # environment.shellAliases.microvm-run = "${inputs.self.nixosConfigurations.microvm.config.microvm.runner.vfkit}/bin/microvm-run";
    };

    # ── The MicroVM Definition ──────────────────────────────────
    flake.nixosConfigurations.microvm = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        inputs.microvm.nixosModules.microvm
        inputs.home-manager.nixosModules.home-manager
        inputs.determinate-nix.nixosModules.default
        inputs.self.nixosModules.shell
        # inputs.self.nixosModules.styling
        # inputs.self.nixosModules.linux-desktop
        
        ({ lib, pkgs, ... }: {
          nixpkgs.hostPlatform = "aarch64-linux";
          nixpkgs.config.allowUnfree = true;

          networking.hostName = "dendritic-vm";
          system.stateVersion = "24.11";
          
          users.users."8amps" = {
            isNormalUser = true;
            extraGroups = [ "wheel" "video" "input" ];
            initialPassword = "nix";
          };
          services.getty.autologinUser = "8amps";

            microvm = {
            hypervisor = "vfkit";
            socket = "/Users/8amps/.local/share/microvm/dendritic-vm.sock";
            vcpu = 2; mem = 8192;
            # vsock.cid = 3;
            shares = [{ proto = "virtiofs"; tag = "ro-store"; source = "/nix/store"; mountPoint = "/nix/.ro-store"; }];
            registerWithMachined = false;
            vmHostPackages = inputs.nixpkgs.legacyPackages."aarch64-darwin";
            writableStoreOverlay = "/nix/.rw-store";
            volumes = [{ image = "/Users/8amps/.local/share/microvm/dendritic-vm.img"; mountPoint = "/nix/.rw-store"; size = 20480; }];
            vfkit.logLevel = "info";
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users."8amps" = import ../hosts/hm/8amps-linux;

          nix.settings = { sandbox = false; experimental-features = [ "nix-command" "flakes" ]; };
          boot.initrd.systemd.enable = false;
          boot.kernelPackages = pkgs.linuxPackages;

          # Configure Sway for software rendering
          environment.variables = {
            WLR_RENDERER = "pixman";
            WLR_NO_HARDWARE_CURSORS = "1";
            # Allow sway to run without a seat/logind if needed (common in microvms)
            WLR_BACKENDS = "wayland"; 
          };
          programs.sway.package = lib.mkForce pkgs.sway;
          environment.systemPackages = [
            (lib.hiPrio (pkgs.writeShellScriptBin "sway" ''
              # Ensure XDG_RUNTIME_DIR is set (it should be, but let's be safe)
              export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
              echo "Connecting to macOS host over VSOCK port 1024... (XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR)"
              
              # Ensure the runtime directory exists
              mkdir -p "$XDG_RUNTIME_DIR"
              
              exec ${pkgs.waypipe}/bin/waypipe \
                --display "$XDG_RUNTIME_DIR/wayland-1" \
                --socket vsock:2:1024 \
                server \
                -- ${pkgs.sway}/bin/sway "$@"
            ''))
          ];

          documentation.enable = false;
          documentation.nixos.enable = false;
          documentation.man.enable = false;
          documentation.doc.enable = false;
        })
      ];
    };
  };
}
