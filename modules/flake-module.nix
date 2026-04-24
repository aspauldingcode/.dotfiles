{ config, lib, inputs, ... }:

{
  options.flake.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.unspecified);
    default = {};
  };

  imports = [
    ./shell.nix
    ./secrets.nix
    ./editor.nix
    ./styling.nix
    ./linux-desktop.nix
    ./mobile.nix
    ./apps.nix
  ];

  config = {
    flake = {
      # Generate the actual configurations
    nixosConfigurations = {
      nixos-test = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          { 
            config = { 
              nixpkgs.config.allowUnfree = true;
              system.stateVersion = "24.11"; 
              users.users."8amps" = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
              };
            }; 
          }
          inputs.home-manager.nixosModules.home-manager
          
          # Import dendritic modules
          inputs.self.modules.nixos.shell
          inputs.self.modules.nixos.secrets
          inputs.self.modules.nixos.styling
          inputs.self.modules.nixos.linux-desktop

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users."8amps" = {
              imports = [
                inputs.self.modules.homeManager.shell
                inputs.self.modules.homeManager.editor
                inputs.self.modules.homeManager.secrets
                inputs.self.modules.homeManager.styling
                inputs.self.modules.homeManager.apps
              ];
              home.username = "8amps";
              home.homeDirectory = "/home/8amps";
              home.stateVersion = "24.11";
            };
          }
        ];
      };

      mba-asahi = inputs.nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          { 
            config = { 
              nixpkgs.config.allowUnfree = true;
              system.stateVersion = "24.11"; 
              users.users."8amps" = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
              };
              fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
              fileSystems."/boot" = { device = "/dev/disk/by-label/boot"; fsType = "vfat"; };
              fileSystems."/boot/asahi" = { device = "/dev/disk/by-label/asahi"; fsType = "vfat"; };
              hardware.asahi.extractPeripheralFirmware = false; # Bypass check for evaluation
            }; 
          }
          inputs.apple-silicon.nixosModules.apple-silicon-support
          inputs.home-manager.nixosModules.home-manager
          
          # Import dendritic modules
          inputs.self.modules.nixos.shell
          inputs.self.modules.nixos.secrets
          inputs.self.modules.nixos.styling
          inputs.self.modules.nixos.linux-desktop

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users."8amps" = {
              imports = [
                inputs.self.modules.homeManager.shell
                inputs.self.modules.homeManager.editor
                inputs.self.modules.homeManager.secrets
                inputs.self.modules.homeManager.styling
                inputs.self.modules.homeManager.apps
              ];
              home.username = "8amps";
              home.homeDirectory = "/home/8amps";
              home.stateVersion = "24.11";
            };
          }
        ];
      };
    };

    darwinConfigurations = {
      # M1 MacBook Air 2020
      mba = inputs.nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.config.allowUnfree = true;
            system.stateVersion = 5; # For nix-darwin
            nix.enable = false; # Let determinate manage it
            users.users."8amps" = {
              name = "8amps";
              home = "/Users/8amps";
            };
          }
          inputs.home-manager.darwinModules.home-manager
          
          # Import dendritic modules
          inputs.self.modules.darwin.shell
          inputs.self.modules.darwin.secrets
          inputs.self.modules.darwin.styling

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users."8amps" = {
              imports = [
                inputs.self.modules.homeManager.shell
                inputs.self.modules.homeManager.editor
                inputs.self.modules.homeManager.secrets
                inputs.self.modules.homeManager.styling
                inputs.self.modules.homeManager.apps
              ];
              home.username = "8amps";
              home.homeDirectory = "/Users/8amps";
              home.stateVersion = "24.11";
            };
          }
        ];
      };
    };

    homeConfigurations = {
      # Example standalone Home Manager config
      "8amps-linux" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.config.allowUnfree = true;
            home.username = "8amps";
            home.homeDirectory = "/home/8amps";
            home.stateVersion = "24.11";
            targets.genericLinux.enable = true;
          }
          # Import dendritic modules
          inputs.self.modules.homeManager.shell
          inputs.self.modules.homeManager.editor
          inputs.self.modules.homeManager.secrets
          inputs.self.modules.homeManager.styling
          inputs.self.modules.homeManager.apps
          inputs.stylix.homeModules.stylix
        ];
      };
    };

    systemConfigs = {
      # System manager configuration for regular linux
      default = inputs.system-manager.lib.makeSystemConfig {
        modules = [
          {
            config = {
              nixpkgs.hostPlatform = "x86_64-linux";
              nixpkgs.config.allowUnfree = true;
            };
          }
        ];
      };
      };
    };
  };
}
