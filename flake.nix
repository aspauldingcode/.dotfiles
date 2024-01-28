{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url =               "github:nixos/nixpkgs/nixos-23.11";
    pkgs-unstable.url =         "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url =                     "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows =  "nixpkgs";
    };
    home-manager.url =          "github:nix-community/home-manager/release-23.11"; # HOME-MANGER INSTALLED AS A NixOS/Darwin MODULE!
    nixvim = {
      url =                     "github:nix-community/nixvim";
      #inputs.nixpkgs.follows =  "pkgs-unstable";
    };
    nix-colors.url =            "github:misterio77/nix-colors"; 
    mobile-nixos = {
      url =                     "github:NixOS/mobile-nixos";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, pkgs-unstable, nix-darwin, home-manager, nixvim, flake-parts, nix-colors, mobile-nixos }: 
  let inherit (self) inputs;
    # Define common specialArgs for nixosConfigurations and homeConfigurations
    commonSpecialArgs = { inherit inputs nix-darwin nixvim home-manager flake-parts nix-colors self; };
    commonExtraSpecialArgs = { inherit inputs nix-darwin nixvim flake-parts nix-colors self; };
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    # Define NixOS configurations
    nixosConfigurations = {
      NIXSTATION64 = nixpkgs.lib.nixosSystem {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        specialArgs = commonSpecialArgs; /* // { extraPkgs = [ mobile-nixos ]; };*/
        modules = [ ./system/NIXSTATION64/configuration.nix ];
      };
      NIXEDUP = nixpkgs.lib.nixosSystem {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        specialArgs = commonSpecialArgs;
        modules = [ ./system/NIXEDUP/configuration.nix ];
      };
    };

    # Define Darwin (macOS) configurations
    darwinConfigurations = {
      NIXY = nix-darwin.lib.darwinSystem {
        #pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        #pkgs-unstable = import pkgs-unstable;
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          overlays = [ 
            (final: prev: {
              #htmx-lsp = prev.pkgs.callPackage ./users/alex/extraConfig/nvim/htmx-lsp.nix {};
              #htmx-lsp = prev.pkgs.emptyDirectory;
              htmx-lsp = pkgs-unstable.htmx-lsp; # if you have separate pkgs for unstable and want to use it from that
              templ = pkgs-unstable.templ;
            })
          ];
        };

        specialArgs = commonSpecialArgs;
        modules = [
          ./system/NIXY/darwin-configuration.nix 
          home-manager.darwinModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.alex = import ./users/alex/NIXY/home-NIXY.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
            home-manager.extraSpecialArgs = commonExtraSpecialArgs;
          }
        ];
      };
    };

    # FIXME: now using home-manager as system modules for NixOS and Darwin.
    # Define home-manager configurations for Users
    /*
    homeConfigurations = {

      # User: "Alex"
      "alex@NIXY" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = commonSpecialArgs;
        modules = [ ./users/alex/NIXY/home-NIXY.nix ];
      };

      "alex@NIXEDUP" = home-manager.lib.homeManagerConfiguration { 
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        extraSpecialArgs = commonSpecialArgs;
        modules = [ ./users/alex/NIXEDUP/home-NIXEDUP.nix];
      };

      "alex@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = commonSpecialArgs;
        modules = [ ./users/alex/NIXSTATION64/home-NIXSTATION64.nix ];
      };

    # User: "Su Su"
    "susu@NIXY" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = commonSpecialArgs;
      modules = [ ./users/susu/home-NIXY.nix ];
    };

    "susu@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = commonSpecialArgs;
      modules = [ ./users/susu/home-NIXSTATION64.nix ];
    };
  };
  */

  in {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      darwinConfigurations = darwinConfigurations;

      ## Ignore all this sh*t:
      #homeConfigurations = homeConfigurations;

      #apps = eachSystem (pkgs: {
      #let
      #  setup = pkgs.writeScriptBin "setup" /* bash */ '' 
      #  #!/bin/bash
      #  # run the rebuild!
      #  rebuild -r -f #FIXME: add -r -f flags to NIXSTATION64 and NIXEDUP! 
      #  '';
      #in {
      #  type = "app";
      #  program = "${setup}/bin/setup";
      #};
    #});    
  };
}
