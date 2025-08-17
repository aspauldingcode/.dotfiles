{ pkgs, ... }:
{
  # enable dconf (System Management Tool)
  programs.dconf.enable = true;

  # Add user to libvirtd group
  users.users.alex.extraGroups = [
    "libvirtd"
    "kvm"
  ];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    virt-manager
    rkvm
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    adwaita-icon-theme
  ];
  # enable nested virtualization
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  # Manage the virtualisation services
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMFFull.override {
              secureBoot = true;
              tpmSupport = true;
            }).fd
          ];
        };
      };
    };
    kvmgt.enable = true;
    spiceUSBRedirection.enable = true;
  };
  services = {
    spice-vdagentd.enable = true;
    spice-autorandr.enable = true;

    # A key list specifying a host switch combination.
    rkvm.server.settings.switch-keys = [
      "left-alt"
      "left-ctrl"
    ];
  };
  # A set of virtual proxy device labels with backing physical device ids.
  # persistent-evdev.devices = [
  #
  # ];
}
