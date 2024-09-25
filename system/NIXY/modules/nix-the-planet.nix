{ pkgs, nixtheplanet, ... }:

# error: attribute 'aarch64-darwin' missing
{
  services.macos-ventura = {
    enable = true;
    package = nixtheplanet.packages.${pkgs.system}.makeImage { diskSizeBytes = 60000000000; };
  };
}