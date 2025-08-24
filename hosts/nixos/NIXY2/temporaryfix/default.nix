{
  lib,
  config,
  ...
}: {
  options.services.pulseaudio.enable = lib.mkEnableOption "pulseaudio";
}
