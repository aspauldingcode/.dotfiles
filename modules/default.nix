{ config, lib, inputs, ... }:

{
  # ── Options ──────────────────────────────────────────────────
  options.flake.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.unspecified);
    default = {};
  };

  # ── Automated Module Discovery ──────────────────────────────
  # In a 100% Dendritic pattern, we import everything in the modules/ directory.
  # For now, we'll keep the explicit imports for clarity but move towards 
  # a structure where the host configurations are built dynamically.
  # ── Automated Module Discovery ──────────────────────────────
  imports = 
    let
      # Recursively find all .nix files in the modules directory (excluding default.nix itself)
      # This is a key part of the Dendritic pattern.
      getFiles = dir:
        lib.flatten (lib.mapAttrsToList (name: type:
          let path = dir + "/${name}"; in
          if type == "directory" then getFiles path
          else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then [ path ]
          else []
        ) (builtins.readDir dir));
    in
    getFiles ./.;


  config = {
    flake = {
      # ── Host Configurations (Dendritic Composition) ───────────
      # Hosts now pull their entire identity from their own directories.
      
      darwinConfigurations = {
        mba = inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [ 
            { nixpkgs.config.allowUnsupportedSystem = true; }
            ../hosts/darwin/mba 
          ];
        };
      };

      nixosConfigurations = {
        nixos-test = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ../hosts/nixos/nixos-test ];
        };

        mba-asahi = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ../hosts/nixos/mba-asahi ];
        };
      };

      homeConfigurations = {
        "8amps-linux" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ../hosts/hm/8amps-linux ];
        };
      };

      systemConfigs = {
        linux-generic = inputs.system-manager.lib.makeSystemConfig {
          specialArgs = { inherit inputs; };
          modules = [ ../hosts/system-manager/linux-generic ];
        };
      };
    };
  };
}
