# airplay.nix
{
  config,
  pkgs,
  ...
}:
{
  # Enable PipeWire and configure it for AirPlay (RAOP) support

  services.pipewire = {
    enable = true;

    extraConfig = {
      # avahi is required for service discovery
      # avahi.enable = true;

      pipewire = {
        raopOpenFirewall = true;
        extraConfig = {
          "context.modules" = [
            {
              name = "libpipewire-module-raop-discover";
              args = {
                "raop.latency.ms" = 500; # Optional latency configuration
              };
            }
          ];
        };
      };
    };
  };

  # Correct Avahi configuration (with proper attribute set)
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
    };
  };

  # Install necessary packages for PipeWire and Avahi
  environment.systemPackages = with pkgs; [
    pipewire
    avahi
  ];
}
