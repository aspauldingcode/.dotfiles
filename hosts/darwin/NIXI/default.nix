_:
let
  # Define hostname once for this system
  hostname = "NIXI";
in
{
  imports = [
    ./scripts
    ./modules
    ./modules/windowManagement
    ./configuration
    # ./modules/nix-the-planet.nix

    # Import sops configuration for secrets management (Darwin-specific)
    # Note: SOPS is configured via darwin-configurations.nix modules
  ];

  # Pass hostname to all imported modules
  _module.args = {
    inherit hostname;
  };
}
