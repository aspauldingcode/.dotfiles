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

        home.packages = lib.optionals cfg.agentDevice.enable [ agentDevicePkg ] ++ [
          pkgs.android-tools
          # Wireless adb pair/connect (also: nix run .#adb-wireless).
          (pkgs.writeShellApplication {
            name = "adb-wireless";
            runtimeInputs = [ pkgs.android-tools ];
            text = ''
              exec bash ${../scripts/adb-wireless.sh} "$@"
            '';
          })
        ];

        home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isDarwin {
          DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
          AGENT_DEVICE_NO_UPDATE_NOTIFIER = "1";
        };
      };
    };
}
