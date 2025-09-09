{
  lib,
  config,
  ...
}: {
  # This file was used as a temporary fix for Apple Silicon audio issues
  # The services.pulseaudio.enable option is already declared in main NixOS modules
  # This file can be removed once the upstream issue is resolved
}
