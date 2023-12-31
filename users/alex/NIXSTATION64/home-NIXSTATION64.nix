{ nix-colors, ... }: 

{
#import other home-manager modules which are NIXSTATION64-specific
imports = [
  nix-colors.homeManagerModules.default
  ./packages-NIXSTATION64.nix 
  ./sway.nix
  ./nvim.nix
  ./git.nix
  ./alacritty.nix
  ./mako.nix
  ./fish.nix
  ./zsh.nix
  ./zellij.nix
]; 

    colorScheme = nix-colors.colorSchemes.gruvbox-dark-soft;

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

# Decoratively fix virt-manager error: "Could not detect a default hypervisor" instead of imperitively through virt-manager's menubar > file > Add Connection
dconf.settings = {
  "org/virt-manager/virt-manager/connections" = {
    autoconnect = ["qemu:///system"];
    uris = ["qemu:///system"];
  };
};

# Nicely reload system units when changing configs
systemd.user.startServices = "sd-switch"; 
}
