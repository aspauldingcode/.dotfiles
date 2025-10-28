_:
let
  # Define hostname once for this system
  hostname = "NIXY2";
in
{
  imports = [
    ./hardware-configuration
    ./scripts
    ./modules
    ./configuration

    # Import sops configuration for secrets management (using personal secrets)
    # (inputs.self.sopsConfigs.systemSopsConfig { environment = "personal"; })
  ];

  # Pass hostname to all imported modules
  _module.args = {
    inherit hostname;
  };
}
