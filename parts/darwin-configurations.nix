# Darwin Configurations Module - Pure Flake Schema Compliance
{
  inputs,
  ...
}:
let
  # Inline common configurations (no custom outputs)
  commonSpecialArgs = {
    inherit inputs;
    inherit (inputs) nix-colors;
    user = "alex";
  };

  # Common Darwin modules (inlined)
  commonDarwinModules = [
    ../shared/scripts
    ../modules/theme-toggle.nix
    inputs.home-manager.darwinModules.home-manager
    inputs.sops-nix.darwinModules.sops
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.nix-plist-manager.darwinModules.default
    {
      # Use centralized overlays
      nixpkgs.overlays = [ inputs.self.overlays.default ];
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

  # Common Home Manager configuration for Darwin (inlined)
  commonHomeManagerDarwin = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.spicetify-nix.homeManagerModules.default
    ];
    extraSpecialArgs = {
      inherit inputs;
      inherit (inputs) nix-colors;
      user = "alex";
    };
  };
in
{
  flake.darwinConfigurations = {
    # aarch64 Darwin (Apple Silicon)
    NIXY = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = commonSpecialArgs;
      modules = commonDarwinModules ++ [
        ../hosts/darwin/NIXY
        {
          home-manager = commonHomeManagerDarwin // {
            users.alex = {
              imports = [ ../users/alex/NIXY ];
              home.username = "alex";
            };
          };
        }
      ];
    };

    # x86_64 Darwin (Intel Mac)
    NIXI = inputs.nix-darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      specialArgs = commonSpecialArgs;
      modules = commonDarwinModules ++ [
        ../hosts/darwin/NIXI
        {
          home-manager = commonHomeManagerDarwin // {
            users.alex = {
              imports = [ ../users/alex/NIXI ];
              home.username = "alex";
            };
          };
        }
      ];
    };
  };
}
