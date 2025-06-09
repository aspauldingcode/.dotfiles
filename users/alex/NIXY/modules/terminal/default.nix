{
  config,
  user,
  pkgs,
  nix-colors,
  ...
}:

let
  name = "${config.colorScheme.slug}";
  inherit (config.colorScheme) palette;
in
{
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
      };
    };
  };
}
