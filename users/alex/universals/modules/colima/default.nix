{
  pkgs,
  config,
  ...
}:
# Colima allows containers on macOS and Linux using:
/*
  Docker (with optional Kubernetes)
  Containerd (with optional Kubernetes)
  Incus (containers and virtual machines)
*/
{
  home.packages = with pkgs; [
    colima
    docker
    # kubernetes # doesn't build on macos.
    # containerd
    # incus
  ];
}
