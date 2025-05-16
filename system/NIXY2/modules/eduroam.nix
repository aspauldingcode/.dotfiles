{
  config,
  pkgs,
  ...
}:
{
  # Install the EWU CA certificate under /etc
  environment.etc."iwd/ewu-ca.pem" = {
    source = ./ca.pem;
    mode = "0644";
  };

  networking.wireless.iwd.settings = {
    Network = {
      EnableIPv6 = true;
      RoutePriorityOffset = 300;
    };
    Settings = {
      AutoConnect = true;
    };
  };
}
