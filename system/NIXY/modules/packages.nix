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
    alacritty
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
    qemu
    # kdePackages.okular
    # spotify
    # xquartz

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
    jdk23
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
    libusb1
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
    (pkgs.callPackage ./../customDerivations/inputsourceselector.nix { })
    # (pkgs.callPackage ./../customDerivations/okular.nix { })
    # (pkgs.callPackage ./../customDerivations/recording-indicator-utility.nix { })
    git
    clang
    openssh
    inputs.agenix.packages.${pkgs.system}.agenix # Add agenix CLI tool
  ];

  nixpkgs.config = {
    allowUnfree = true;
    extra-platforms = [ "aarch64-linux" "x86_64-linux" ];
  };

  # Enable Linux building support
  nix.settings = {
    extra-platforms = [ "aarch64-linux" "x86_64-linux" ];
    trusted-users = [ "@admin" "root" "demo" "alex" ];
    extra-sandbox-paths = [ "/bin/sh=${pkgs.bash}/bin/sh" ];
    builders-use-substitutes = true;
    experimental-features = [ "nix-command" "flakes" ];
  };

  # # Enable remote builder for Orb VM
  # nix.buildMachines = [{
  #   hostName = "alex@nixos@orb";
  #   system = "aarch64-linux";
  #   maxJobs = 4;
  #   speedFactor = 2;
  #   supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  #   mandatoryFeatures = [ ];
  # }];
  # nix.distributedBuilds = true;
}
