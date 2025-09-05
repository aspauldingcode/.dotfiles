{
  pkgs,
  user,
  inputs,
  ...
}: {
  imports = [
    ./scripts
    ./modules
    ./modules/windowManagement
    ./configuration
    # ./modules/nix-the-planet.nix
    
    # Import sops configuration for secrets management (Darwin-specific)
    inputs.self.sopsConfigs.systemSopsConfig
  ];
}
