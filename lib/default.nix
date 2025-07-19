# Enhanced shared library functions for the flake
{ inputs }:
let
  inherit (inputs.nixpkgs) lib;

  # Helper function to create package sets for different systems
  mkPkgs =
    {
      system,
      channel ? inputs.nixpkgs,
      overlays ? [ ],
      config ? { },
    }:
    import channel {
      inherit system;
      config = {
        allowUnfree = true;
        allowBroken = true;
        permittedInsecurePackages = [
          "electron-19.1.9"
          "electron-33.4.11"
          "olm-3.2.16"
        ];
      } // config;
      overlays = overlays;
    };

  # Helper function to create common special arguments
  mkSpecialArgs =
    {
      user ? "alex",
      extraArgs ? { },
    }:
    {
      inherit inputs user;
    }
    // extraArgs;

  # Helper function to create Home Manager configuration
  mkHomeManagerConfig =
    {
      user,
      extraSpecialArgs ? { },
      sharedModules ? [ ],
      backupFileExtension ? "backup",
    }:
    {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = extraSpecialArgs;
      backupFileExtension = backupFileExtension;
      sharedModules = sharedModules;
    };

  # Helper function to create NixOS system configuration
  mkNixOSSystem =
    {
      system,
      modules,
      specialArgs ? { },
      pkgs ? null,
    }:
    let
      systemPkgs = if pkgs != null then pkgs else mkPkgs { inherit system; };
    in
    lib.nixosSystem {
      inherit system modules;
      specialArgs = mkSpecialArgs { } // specialArgs;
      pkgs = systemPkgs;
    };

  # Helper function to create Darwin system configuration
  mkDarwinSystem =
    {
      system,
      modules,
      specialArgs ? { },
      pkgs ? null,
    }:
    let
      systemPkgs = if pkgs != null then pkgs else mkPkgs { inherit system; };
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system modules;
      specialArgs = mkSpecialArgs { } // specialArgs;
      pkgs = systemPkgs;
    };

  # Helper function to create development shell
  mkDevShell =
    {
      pkgs,
      name ? "dev-shell",
      buildInputs ? [ ],
      shellHook ? "",
      env ? { },
    }:
    pkgs.mkShell (
      {
        inherit name buildInputs shellHook;
      }
      // env
    );

  # Mobile NixOS helper functions
  mkMobileSystem =
    {
      device,
      modules ? [ ],
      specialArgs ? { },
      user ? "alex",
    }:
    mkNixOSSystem {
      system = "aarch64-linux";
      modules = [
        (import "${inputs.mobile-nixos}/lib/configuration.nix" { inherit device; })
      ] ++ modules;
      specialArgs = specialArgs // {
        inherit user;
      };
    };

  # Validation helpers
  validateFlake =
    flake:
    let
      requiredOutputs = [
        "nixosConfigurations"
        "darwinConfigurations"
        "devShells"
      ];
      hasOutput = output: builtins.hasAttr output flake;
      missingOutputs = builtins.filter (output: !(hasOutput output)) requiredOutputs;
    in
    if missingOutputs == [ ] then
      {
        valid = true;
        errors = [ ];
      }
    else
      {
        valid = false;
        errors = [ "Missing outputs: ${builtins.toString missingOutputs}" ];
      };

  # System detection helpers
  isDarwin = system: lib.hasSuffix "-darwin" system;
  isLinux = system: lib.hasSuffix "-linux" system;
  isAarch64 = system: lib.hasPrefix "aarch64-" system;
  isX86_64 = system: lib.hasPrefix "x86_64-" system;

  # Configuration helpers
  enableUnfree = {
    nixpkgs.config.allowUnfree = true;
  };

  enableFlakes = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Mobile-specific helpers
  mobileOptimizations = {
    # Power management optimizations
    powerManagement.enable = true;

    # Reduce memory usage
    nix.settings.max-jobs = 2;

    # Aggressive garbage collection
    nix.gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
  };

  # Security hardening
  securityHardening = {
    security = {
      sudo.wheelNeedsPassword = false;
      polkit.enable = true;
    };

    services.openssh = {
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
in
{
  inherit
    mkPkgs
    mkSpecialArgs
    mkHomeManagerConfig
    mkNixOSSystem
    mkDarwinSystem
    mkDevShell
    mkMobileSystem
    validateFlake
    isDarwin
    isLinux
    isAarch64
    isX86_64
    enableUnfree
    enableFlakes
    mobileOptimizations
    securityHardening
    ;
}
