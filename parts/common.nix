# Common Modules - Shared configuration across all systems
{ inputs, ... }:
{
  flake.commonModules = {
    # Base modules for all NixOS systems
    nixos = [
      ../shared/scripts
      inputs.self.modules.theme-toggle
      inputs.home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      { imports = [ inputs.self.sopsConfigs.nixosSopsConfig ]; }
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

    # Base modules for all Darwin systems
    darwin = [
      ../shared/scripts
      inputs.self.modules.theme-toggle
      inputs.home-manager.darwinModules.home-manager
      inputs.sops-nix.darwinModules.sops
      inputs.nix-homebrew.darwinModules.nix-homebrew
      inputs.spicetify-nix.darwinModules.default
      {
        # Use centralized overlays
        nixpkgs.overlays = [ inputs.self.overlays.default ];
        nixpkgs.config = {
          allowUnfree = true;
          allowBroken = true;
          permittedInsecurePackages = [
            "electron-19.1.9"
            "electron-33.4.11"
            "olm-3.2.16"
          ];
          # Security: only allow specific unfree packages
          allowUnfreePredicate =
            pkg:
            builtins.elem (inputs.nixpkgs.lib.getName pkg) [
              "vscode"
              # "discord" # Removed - only install via nixcord
              "spotify"
              "zoom"
              "slack"
              "chrome"
              "firefox"
              "cursor"
              "1password"
              "1password-cli"
            ];
        };
      }
    ];
  };

  flake.commonConfigs = {
    # Common specialArgs for all systems
    specialArgs = {
      inherit inputs;
      inherit (inputs) nix-colors;
      user = "alex";
    };

    # Common Home Manager configuration
    homeManager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit inputs;
        inherit (inputs) nix-colors;
        user = "alex";
      };
    };

    # NixOS-specific Home Manager config
    homeManagerNixOS = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      sharedModules = [
        inputs.sops-nix.homeManagerModules.sops
        { imports = [ inputs.self.sopsConfigs.hmSopsConfig ]; }
        # Disable version check to prevent warnings
        { home.enableNixpkgsReleaseCheck = false; }
      ];
      extraSpecialArgs = {
        inherit inputs;
        inherit (inputs) nix-colors apple-silicon mobile-nixos;
        user = "alex";
      };
    };

    # Darwin-specific Home Manager config
    homeManagerDarwin = {
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
  };
}
