{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    ## macosINSTANTView?
    wget
    #zellij
    jetbrains.idea-community
    teams
    fastfetch
    gnumake
    pfetch
    htop
    git
    tree
    ifstat-legacy
    ranger
    # kdePackages.okular
    spotify

    #darwin.iproute2mac #MUST BE BREW PACKAGE?
    ncurses6
    hexedit
    texliveTeTeX
    ruby_3_3
    rbenv
    postman

    # javaPackages.openjfx19
    #inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk22
    jdk22
    #python311
    oh-my-zsh # zsh shell framework
    oh-my-fish # fish shell framework
    #oh-my-git #git learning game
    dmenu
    dwm
    zoom-us
    android-tools
    undmg
    p7zip
    jq
    libusb
    darling-dmg
    lolcat
    tree-sitter
    nodejs_20
    #lspconfig
    fd # find tool
    ripgrep
    (pkgs.callPackage ./instantview.nix { })
    (pkgs.callPackage ./macforge.nix { })
    # (pkgs.callPackage ./cdock.nix { })
    (pkgs.callPackage ./cursorcerer.nix { })
    (pkgs.callPackage ./mousecape.nix { })
  ];
}
