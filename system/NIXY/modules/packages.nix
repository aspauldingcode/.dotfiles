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
    gnumake
    pfetch
    htop
    git
    tree
    ifstat-legacy
    ranger
    # kdePackages.okular
    spotify
    xquartz

    #darwin.iproute2mac #MUST BE BREW PACKAGE?
    ncurses6
    hexedit
    texliveTeTeX
    ruby_3_3
    rbenv
    postman
    arc-browser

    python311Packages.pillow
    python311Packages.tqdm
    python311Packages.numpy
    python311Packages.torch
    python311Packages.torchvision
    python311Packages.diffusers
    python311Packages.transformers
    python311Packages.accelerate
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
    # neovim
    libusb
    darling-dmg
    lolcat
    tree-sitter
    nodejs_20
    #lspconfig
    fd # find tool
    ripgrep
    (pkgs.callPackage ./../customDerivations/instantview.nix { })
    (pkgs.callPackage ./../customDerivations/macforge.nix { })
    # (pkgs.callPackage ./../customDerivations/cdock.nix { })
    (pkgs.callPackage ./../customDerivations/cursorcerer.nix { })
    (pkgs.callPackage ./../customDerivations/mousecape.nix { })
    # (pkgs.callPackage ./../customDerivations/okular.nix { })
    # (pkgs.callPackage ./../customDerivations/recording-indicator-utility.nix { })
    (pkgs.callPackage ./../customDerivations/yabai.nix { })
    git
    clang
    openssh
  ];
}
