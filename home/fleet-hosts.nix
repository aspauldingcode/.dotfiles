# Enrolled dendritic hosts that report fleet heartbeats.
# Public CI expects one hosts/<id>.json per entry in the private
# aspauldingcode/dendritic-fleet-status repo. Unknown ids are ignored.
{
  mba = {
    platform = "darwin";
    description = "MacBook Air (nix-darwin)";
  };
  mba-asahi = {
    platform = "nixos";
    description = "MacBook Air (NixOS Asahi)";
  };
  sliceanddice = {
    platform = "nixos";
    description = "NixOS laptop";
  };
  oneplus6t = {
    platform = "android";
    description = "OnePlus 6T (LineageOS / nix-android)";
  };
}
