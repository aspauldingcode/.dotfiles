{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # desktop_cleaner
  ];

  launchd = {
    daemons = {
      "limit.maxfiles" = {
        serviceConfig = {
          Label = "limit.maxfiles";
          ProgramArguments = [
            "/bin/launchctl"
            "limit"
            "maxfiles"
            "65536"
            "65536"
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}
