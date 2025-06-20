{ lib, config, ... }:

{
  options.services.pulseaudio.enable = lib.mkEnableOption "pulseaudio";

  config.hardware.pulseaudio.enable = config.services.pulseaudio.enable;
}
