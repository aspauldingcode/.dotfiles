{ nix-colors, ... }:

{
  imports = [
    nix-colors.homeManagerModules.default
    ./../extraConfig/nvim/nixvim.nix # Universal nixvim.nix
    ./../universals/modules/alacritty.nix
    ./../universals/modules/discord.nix
    ./../universals/modules/firefox.nix
    ./../universals/modules/shells.nix
    ./../universals/modules/btop.nix
    ./../universals/modules/git.nix
    ./../universals/modules/yazi.nix
    ./modules/mako.nix
    ./modules/bemenu.nix
    ./modules/mimeapps.nix
    ./modules/packages.nix
    ./modules/sway.nix
    ./modules/theme.nix # theme of system.
    ./scripts-NIXY2.nix
  ];

  home = {
    username = "alex";
    homeDirectory = "/home/alex";
    stateVersion = "24.11"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  };

  services.ssh-agent.enable = true;
  programs.ssh = {
    addKeysToAgent = true;
  };

  # Decoratively fix virt-manager error: "Could not detect a default hypervisor" instead of imperitively through virt-manager's menubar > file > Add Connection
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # Disable KDE Wallet 5 from plasma! UGH!
  home.file.kwalletrc = {
    #executable = true;
    target = ".config/kwalletrc";
    text = # ini
      ''
        [Wallet]
        Enabled=false
      '';
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
