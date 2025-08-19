# Darwin Configurations Module
{ inputs, lib, ... }:
let
  # Centralized theme selection
  themes = {
    NIXY = {
      dark = "selenized-dark";
      light = "selenized-light";
    };
    NIXI = {
      dark = "selenized-dark";
      light = "selenized-light";
    };
  };
in
{
  flake.darwinConfigurations = {
    NIXY = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = inputs.self.commonConfigs.specialArgs;
      modules = inputs.self.commonModules.darwin ++ [
        ../hosts/darwin/NIXY
        {
          home-manager = inputs.self.commonConfigs.homeManagerDarwin // {
            users.alex = {
              imports = [
                ../users/alex/NIXY
              ];
              home = {
                username = "alex";
              };
            };
          };
        }
      ];
    };

    NIXI = inputs.nix-darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      specialArgs = inputs.self.commonConfigs.specialArgs;
      modules = inputs.self.commonModules.darwin ++ [
        ../hosts/darwin/NIXI
        {
          home-manager = inputs.self.commonConfigs.homeManagerDarwin // {
            users.alex = {
              imports = [
                ../users/alex/NIXI
              ];
              home = {
                username = "alex";
              };
            };
          };
        }
      ];
    };

    # Light theme configurations
    NIXY-light = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = inputs.self.commonConfigs.specialArgs;
      modules = inputs.self.commonModules.darwin ++ [
        ../hosts/darwin/NIXY
        {
          # Override colorScheme at system level for postActivation script
          colorScheme = lib.mkForce inputs.nix-colors.colorSchemes.${themes.NIXY.light};

          home-manager = inputs.self.commonConfigs.homeManagerDarwin // {
            users.alex = {
              imports = [
                ../users/alex/NIXY
              ];
              home = {
                username = "alex";
              };
              # Use light theme from centralized theme selection
              colorScheme = lib.mkForce inputs.nix-colors.colorSchemes.${themes.NIXY.light};
            };
          };
        }
      ];
    };

    NIXI-light = inputs.nix-darwin.lib.darwinSystem {
      system = "x86_64-darwin";
      specialArgs = inputs.self.commonConfigs.specialArgs;
      modules = inputs.self.commonModules.darwin ++ [
        ../hosts/darwin/NIXI
        {
          # Override colorScheme at system level for postActivation script
          colorScheme = lib.mkForce inputs.nix-colors.colorSchemes.${themes.NIXI.light};

          home-manager = inputs.self.commonConfigs.homeManagerDarwin // {
            users.alex = {
              imports = [
                ../users/alex/NIXI
              ];
              home = {
                username = "alex";
              };
              # Use light theme from centralized theme selection
              colorScheme = lib.mkForce inputs.nix-colors.colorSchemes.${themes.NIXI.light};
            };
          };
        }
      ];
    };
  };
}
