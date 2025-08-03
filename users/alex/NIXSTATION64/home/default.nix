{nix-colors, ...}: {
  home = {
    username = "alex";
    homeDirectory = "/home/alex";
    stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  };

  services.ssh-agent.enable = true;
  programs.ssh = {
    addKeysToAgent = true;
  };

  # Decoratively fix virt-manager error: "Could not detect a default hypervisor" instead of imperitively through virt-manager's menubar > file > Add Connection
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Disable KDE Wallet 5 from plasma! UGH!
  home.file.kwalletrc = {
    #executable = true;
    target = ".config/kwalletrc";
    text =
      # ini
      ''
        [Wallet]
        Enabled=false
      '';
  };
  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
