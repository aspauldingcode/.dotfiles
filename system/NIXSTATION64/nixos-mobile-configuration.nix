# configuration.nix
{
  # "xxx-yyy" is your device "Identifier" from https://mobile.nixos.org/devices,
  # e.g. "google-marlin".
  imports = [
    (import <mobile-nixos/lib/configuration.nix> { device = "oneplus-fajita"; })
    # ...
  ];

  # ...
  # Other configurations...
  # ...
}

