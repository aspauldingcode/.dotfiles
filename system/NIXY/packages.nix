{ lib, pkgs, config, inputs, ... }:

{
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config = {
      allowUnfree = true;
      allowUnfreePredictate = (_: true);
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    ## macosINSTANTView?
    zellij
    neofetch
    htop
    git
    tree
    ifstat-legacy 
    ranger
    #darwin.iproute2mac #MUST BE BREW PACKAGE?
    ncurses6
    hexedit
    # javaPackages.openjfx19
    #inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk20
    python311
    python311Packages.pygame
    oh-my-zsh #zsh shell framework
    oh-my-fish #fish shell framework
    #oh-my-git #git learning game
    dmenu
    dwm
    zoom-us
    android-tools
    jq
    libusb
    lolcat
    tree-sitter
    nodejs_20
    #lspconfig
    fd #find tool
    ripgrep
  ];

  system.activationScripts.extraActivation.text = '' 
  ln -sf "${inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk20}/zulu-20.jdk" "/Library/Java/JavaVirtualMachines/"
  '';
}
