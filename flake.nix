{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    home-manager.url = "github:nix-community/home-manager";

    language-servers.url = "git+https://git.sr.ht/~bwolf/language-servers.nix";
    #language-servers.flake = false;
    plugin-onedark.url = "github:navarasu/onedark.nvim";
    plugin-onedark.flake = false;
  };

  outputs = { self, nixpkgs, darwin, home-manager, language-servers, plugin-onedark }: 
  let
    inherit (self) inputs;

      # Define common specialArgs for nixosConfigurations and homeConfigurations
      commonSpecialArgs = { inherit inputs self; };

      # Define NixOS configurations
      nixosConfigurations = {
        NIXSTATION64 = nixpkgs.lib.nixosSystem {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          specialArgs = commonSpecialArgs;
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
        NIXY = darwin.lib.darwinSystem {
          specialArgs = commonSpecialArgs;
          modules = [ ./system/NIXY/darwin-configuration.nix ];
        };
      };

      # Define home-manager configurations for Users
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
<<<<<<< HEAD

    devShell = pkgs: self: { # NOT WORKING! FIXME
      devShells.aarch64-darwin.default = self.devShell;
      devShells.x86_64-linux.default = self.devShell;  # Add any other architectures you need

      buildInputs = with pkgs; [
        cargo
        clang-tools
        cmake
        corrosion
        extra-cmake-modules
        rustc
        iconv
        python311
        python311Packages.numpy
        python311Packages.matplotlib
        python311Packages.keyboard
        nodejs-18_x
        (language-servers.packages.x86_64-linux.angular-language-server)
        (language-servers.packages.x86_64-linux.typescript-language-server)
        (language-servers.packages.x86_64-linux.vscode-langservers-extracted)
        (language-servers.packages.x86_64-linux.svelte-language-server)
        (language-servers.packages.x86_64-linux.jdt-language-server)
      ];

      # Workaround for https://github.com/NixOS/nixpkgs/issues/76486
      # when clang is the stdenv (i.e. on Darwin)
      shellHook = ''
      PATH="${pkgs.clang-tools}/bin:$PATH"
      echo "Environment with Python, NumPy, and Matplotlib activated!"
      echo "Also working with cmake, and some extras.."
      '';
    };
=======
>>>>>>> 4649f12f8cad59904d0997bec7067e7f1aba80e4
  };
  in {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      homeConfigurations = homeConfigurations;
      darwinConfigurations = darwinConfigurations;
    };
  }
