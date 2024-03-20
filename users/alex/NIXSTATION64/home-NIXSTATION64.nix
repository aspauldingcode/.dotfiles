{ nix-colors, ... }: 

{
#import other home-manager modules which are NIXSTATION64-specific
imports = [
  nix-colors.homeManagerModules.default
  ./packages-NIXSTATION64.nix 
  ./sway.nix
  ./../extraConfig/nvim/nixvim.nix # Universal nixvim.nix
  ./theme.nix # theme of system.
  ./git.nix
  ./alacritty.nix
  ./mako.nix
  ./discocss.nix
  ./betterdiscord.nix
  ./fish.nix
  ./zsh.nix
  # ./zellij.nix
  ./btop.nix # btop theme!
]; 

    home = {
      username = "alex";
      homeDirectory = "/home/alex";
      stateVersion = "23.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      shellAliases = { 
        python = "python3.11";
        vim = "nvim";
        vi = "nvim";
        reboot = "sudo reboot now";
        rb = "sudo reboot now";
        shutdown = "sudo shutdownnow";
        sd = "sudo shutdown now";
        l = "ls";
      };
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
    text = /* ini */  ''
      [Wallet]
      Enabled=false
    '';
  };
# Nicely reload system units when changing configs
systemd.user.startServices = "sd-switch"; 
}
