{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "sway";
        user = "alex";
      };
    };
  };

  environment.etc."greetd/sway-config" = {
    source = ./sway-config;
    mode = "0644";
  };

  environment.etc."greetd/regreet.css" = lib.mkForce {
    source = ./custom.css;
    mode = "0644";
  };
}
