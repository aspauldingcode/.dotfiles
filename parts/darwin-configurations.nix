# Darwin Configurations Module
{ inputs, ... }:
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
  };
}
