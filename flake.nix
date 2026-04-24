{
  description = "Dendritic Nix Flake with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    
    flake-parts.url = "github:hercules-ci/flake-parts";
    
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate-nix.url = "github:DeterminateSystems/determinate";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    apple-silicon = {
      url = "github:tpwrules/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        # In a fully dendritic pattern, we can import our top-level configuration modules.
        # However, for NixOS, Darwin, and Home Manager, we will define them in `flake` output
        # or use flake-parts modules if we're setting up the entire config matrix.
        ./modules/flake-module.nix
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Formatter for `nix fmt`
        formatter = pkgs.nixfmt-rfc-style;

        # Development shell available via `nix develop`
        devShells.default = pkgs.mkShell {
          name = "dotfiles-devshell";
          buildInputs = with pkgs; [
            git
            nixfmt-rfc-style
            sops
            age
          ] ++ [
            inputs'.nixvim.packages.default
          ];
        };
      };

      flake = {
        # NixOS, Darwin, and Home Manager configurations will be built dynamically
        # or defined in the flake-module.
      };
    };
}