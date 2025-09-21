{
  description = "Production-Ready Universal Nix Flake - Multi-Host, Multi-User with Home Manager, Nix-Darwin, NixOS & SOPS secrets management";

  inputs = {
    # Core nixpkgs channels - using stable 25.05 for reliability
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Flake framework for better organization
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # System management - using master branches for unstable compatibility
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development and tooling
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-std.url = "github:chessai/nix-std";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theming and UI
    nix-colors.url = "github:misterio77/nix-colors";
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Security and secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Determinate Nix installer and management
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    # macOS specific tools
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    nix-plist-manager = {
      url = "github:sushydev/nix-plist-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Community packages and overlays
    nur.url = "github:nix-community/nur";
    nixtheplanet = {
      url = "github:matthewcroughan/nixtheplanet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apple Silicon and mobile support
    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    mobile-nixos = {
      url = "github:NixOS/mobile-nixos";
      flake = false;
    };

    # Development and reverse engineering
    frida-nix = {
      url = "github:itstarsun/frida-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homebrew taps (non-flake inputs)
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-koekeishiya = {
      url = "github:koekeishiya/homebrew-formulae";
      flake = false;
    };
    homebrew-felixkratz = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };
    homebrew-smudge = {
      url = "github:smudge/homebrew-smudge";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    # Additional macOS tools
    nix-rosetta-builder = {
      url = "github:cpick/nix-rosetta-builder";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Ansible automation with Nix
    nixible = {
      url = "gitlab:TECHNOFAB/nixible?dir=lib";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # Supported systems for multi-platform builds
      systems = [
        "x86_64-linux" # Intel/AMD Linux
        "aarch64-linux" # ARM64 Linux (Apple Silicon, Mobile)
        "x86_64-darwin" # Intel macOS
        "aarch64-darwin" # Apple Silicon macOS
      ];

      # Import modular configuration parts (standard outputs only)
      imports = [
        ./parts/overlays.nix
        ./parts/nixos-configurations.nix
        ./parts/darwin-configurations.nix
        ./parts/home-configurations.nix
        ./parts/packages.nix
        ./parts/apps.nix
        ./parts/devshells.nix
        ./parts/formatter.nix
        ./parts/checks.nix
      ];
    };
}
