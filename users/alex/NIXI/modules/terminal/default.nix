{
  config,
  user,
  pkgs,
  nix-colors,
  ...
}: let
  name = "${config.colorScheme.slug}";
  inherit (config.colorScheme) palette;
in {
  targets.darwin.defaults."com.apple.Terminal" = {
    "Default Window Settings" = name;
    "Startup Window Settings" = name;
    "Window Settings" = {
      ${name} = {
        name = name;
        type = "Window Settings";
        BackgroundBlur = 0;
        FontAntialias = 0;
        ShowWindowSettingsNameInTitle = 0;
        shellExitAction = 2;
        # Font = {
        #   length = 259;
        #   bytes = "0x62706c69 73743030 d4010203 04050607 ... 00000000 000000c7";
        # };
      };
    };
  };
}
