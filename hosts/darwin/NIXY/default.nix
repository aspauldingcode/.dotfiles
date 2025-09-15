{
  pkgs,
  user,
  inputs,
  ...
}: let
  # Define hostname once for this system
  hostname = "NIXY";
in {
  imports = [
    ./scripts
    ./modules
    ./modules/windowManagement
    ./configuration
    # ./modules/nix-the-planet.nix

    # Import sops configuration for secrets management (Darwin-specific)
    inputs.self.sopsConfigs.systemSopsConfig
  ];

  # Pass hostname to all imported modules
  _module.args = {
    inherit hostname;
  };
}
