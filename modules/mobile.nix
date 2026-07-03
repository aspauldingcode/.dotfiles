{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.mobile;
      agentDevicePkg = import ./pkgs/_agent-device.nix { inherit pkgs; };
    in
    {
      options.dendritic.mobile = {
        enable = lib.mkEnableOption "Mobile app automation (agent-device, iOS/Android simulators)";

        agentDevice = {
          enable = lib.mkEnableOption "Install agent-device CLI globally in PATH";
        };
      };

      config = lib.mkIf cfg.enable {
        dendritic.mobile.agentDevice.enable = lib.mkDefault true;

        home.packages =
          lib.optionals cfg.agentDevice.enable [ agentDevicePkg ]
          ++ lib.optionals pkgs.stdenv.isDarwin [
            pkgs.android-tools
          ];

        home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isDarwin {
          DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
          AGENT_DEVICE_NO_UPDATE_NOTIFIER = "1";
        };
      };
    };
}
