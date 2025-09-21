# NixOS Configurations Module - Pure Flake Schema Compliance
{
  inputs,
  lib,
  ...
}: let
  # Inline common configurations (no custom outputs)
  commonSpecialArgs = {
    inherit inputs;
    inherit (inputs) nix-colors;
    user = "alex";
  };

  # Common NixOS modules (inlined)
  commonNixOSModules = [
    ../shared/scripts
    ../modules/theme-toggle.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    {
      # Use centralized overlays
      nixpkgs.overlays = [inputs.self.overlays.default];
      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-19.1.9"
          "electron-33.4.11"
          "olm-3.2.16"
        ];
      };
    }
  ];

  # Common Home Manager configuration (inlined)
  commonHomeManagerNixOS = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
      {home.enableNixpkgsReleaseCheck = false;}
    ];
    extraSpecialArgs = {
      inherit inputs;
      inherit (inputs) nix-colors apple-silicon mobile-nixos;
      user = "alex";
    };
  };
in {
  flake.nixosConfigurations = {
    # x86_64 Linux - Desktop workstation
    NIXSTATION64 = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs =
        commonSpecialArgs
        // {
          inherit (inputs) apple-silicon mobile-nixos;
        };
      modules =
        commonNixOSModules
        ++ [
          ../hosts/nixos/NIXSTATION64
          {
            home-manager =
              commonHomeManagerNixOS
              // {
                users.alex = import ../users/alex/NIXSTATION64;
              };
          }
        ];
    };

    # aarch64 Linux (Apple Silicon) - VM/Development system
    NIXY2 = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs =
        commonSpecialArgs
        // {
          inherit (inputs) apple-silicon mobile-nixos;
        };
      modules =
        commonNixOSModules
        ++ [
          ../hosts/nixos/NIXY2
          inputs.apple-silicon.nixosModules.apple-silicon-support
          {
            home-manager =
              commonHomeManagerNixOS
              // {
                users.alex = import ../users/alex/NIXY2;
              };
          }
        ];
    };

    # x86_64 Linux - DELIVERER server/workstation
    DELIVERER = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs =
        commonSpecialArgs
        // {
          inherit (inputs) apple-silicon mobile-nixos;
        };
      modules =
        commonNixOSModules
        ++ [
          ../hosts/nixos/DELIVERER
          {
            home-manager =
              commonHomeManagerNixOS
              // {
                users.alex = import ../users/alex/DELIVERER;
              };
          }
        ];
    };

    # aarch64 Linux (mobile) - OnePlus 6T with Mobile NixOS
    NIXEDUP = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs;
        inherit (inputs) mobile-nixos;
        user = "alex";
      };
      modules = [
        ../hosts/nixos/NIXEDUP
        inputs.sops-nix.nixosModules.sops
        {
          nixpkgs.overlays = [inputs.self.overlays.default];
          nixpkgs.config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "electron-19.1.9"
              "electron-33.4.11"
              "olm-3.2.16"
            ];
          };
          # Suppress mobile-nixos documentation generation warnings
          documentation.nixos.enable = false;
        }
      ];
    };
  };
}
