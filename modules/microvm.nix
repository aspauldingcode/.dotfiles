{ inputs, ... }:
{
  config = {
    # ── Darwin Specific Module ──────────────────────────────────
    flake.modules.darwin.microvm = { pkgs, inputs, ... }: {
      environment.systemPackages = [ 
        inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.self.nixosConfigurations.microvm.config.microvm.runner.vfkit
      ];
      environment.shellAliases.microvm-run = "${inputs.self.nixosConfigurations.microvm.config.microvm.runner.vfkit}/bin/microvm-run";
    };

    # ── The MicroVM Definition ──────────────────────────────────
    flake.nixosConfigurations.microvm = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        inputs.microvm.nixosModules.microvm
        inputs.home-manager.nixosModules.home-manager
        inputs.determinate-nix.nixosModules.default
        inputs.self.modules.nixos.shell
        inputs.self.modules.nixos.styling
        inputs.self.modules.nixos.linux-desktop
        
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
            vcpu = 2; mem = 2047;
            vsock.cid = 3;
            shares = [{ proto = "virtiofs"; tag = "ro-store"; source = "/nix/store"; mountPoint = "/nix/.ro-store"; }];
            registerWithMachined = false;
            vmHostPackages = inputs.nixpkgs.legacyPackages."aarch64-darwin";
            writableStoreOverlay = "/nix/.rw-store";
            volumes = [{ image = "/Users/8amps/.local/share/microvm/dendritic-vm.img"; mountPoint = "/nix/.rw-store"; size = 10240; }];
            vfkit.logLevel = "info";
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users."8amps" = import ../hosts/hm/8amps-linux;

          nix.settings = { sandbox = false; experimental-features = [ "nix-command" "flakes" ]; };
          boot.initrd.systemd.enable = false;
          boot.kernelPackages = pkgs.linuxPackages;

          # Guest-side Wayland proxy: listens on /run/user/1000/wayland-1 and connects to VSOCK Host (CID 2), port 1024
          systemd.user.services.wayland-vsock-proxy = {
            description = "Wayland VSOCK Proxy";
            wantedBy = [ "default.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.socat}/bin/socat UNIX-LISTEN:%t/wayland-1,fork VSOCK-CONNECT:2:1024";
              Restart = "always";
            };
          };

          environment.variables = {
            WAYLAND_DISPLAY = "wayland-1";
          };

          documentation.enable = false;
          documentation.nixos.enable = false;
          documentation.man.enable = false;
          documentation.doc.enable = false;
        })
      ];
    };
  };
}
