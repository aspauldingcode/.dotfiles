{
  pkgs,
  inputs,
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
    # teams # FIXMEL failing atm.
    gnumake
    pfetch
    htop
    prismlauncher
    kitty
    ghidra
    nixfmt-rfc-style
    luaformatter
    alt-tab-macos
    unnaturalscrollwheels
    docker
    # xorg.xinit      # FIXME: Broken package darwin
    # xorg.xorgserver # FIXME: Broken package darwin
    yazi
    fftw
    libtool
    automake
    autoconf-archive
    portaudio
    iniparser
    zenity
    unstable.iproute2mac
    m-cli
    ansible
    gtk-mac-integration
    # libiconv
    # choose-gui
    # ddcctl
    # cliclick
    # sublime4
    # nightlight
    cmake
    blueutil
    gh
    cava
    git
    tree
    treefmt2
    nowplaying-cli
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
    python311Packages.raylib-python-cffi
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
    # gittyup
    libusb1
    beeper-bridge-manager
    darling-dmg
    lolcat
    tree-sitter
    nodejs_20
    unstable.nodePackages.vercel
    raylib

    #lspconfig
    fd # find tool
    ripgrep
    (pkgs.callPackage ./../customDerivations/instantview.nix { })
    #(pkgs.callPackage ./../customDerivations/macforge.nix { })
    # (pkgs.callPackage ./../customDerivations/cdock.nix { })
    (pkgs.callPackage ./../customDerivations/cursorcerer.nix { })
    (pkgs.callPackage ./../customDerivations/mousecape.nix { })
    (pkgs.callPackage ./../customDerivations/inputsourceselector.nix { })
    # (pkgs.callPackage ./../customDerivations/okular.nix { })
    # (pkgs.callPackage ./../customDerivations/ammonia.nix { })
    (pkgs.callPackage ./../customDerivations/recording-indicator-utility.nix { })
    git
    llvmPackages_19.clang-unwrapped
    llvmPackages_19.llvm
    llvmPackages_19.bintools
    openssh
    inputs.agenix.packages.${pkgs.system}.agenix # Add agenix CLI tool
  ];

  nixpkgs.config = {
    allowUnfree = true;
    extra-platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
  };

  # Enable Linux building support
  nix.settings = {
    extra-platforms = [
      "aarch64-linux"
      "x86_64-linux"
    ];
    trusted-users = [
      "@admin"
      "root"
      "demo"
      "alex"
    ];
    extra-sandbox-paths = [ "/bin/sh=${pkgs.bash}/bin/sh" ];
    builders-use-substitutes = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  #nix.linux-builder.enable = true;
  nix.settings.substituters = [ "https://cache.nixos.org/" ];
  nix.settings.trusted-public-keys = [
    "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
  ];
  nix.settings.always-allow-substitutes = true;

  # # Enable remote builder for Orb VM
  # nix.buildMachines = [{
  #   hostName = "localhost:32222";
  #   sshUser = "default";
  #   system = "aarch64-linux";
  #   maxJobs = 4;
  #   speedFactor = 2;
  #   supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
  #   mandatoryFeatures = [ ];
  #   protocol = "ssh";
  #   sshKey = "/Users/alex/.orbstack/ssh/id_ed25519";
  #   #    ~/.orbstack/ssh  zsh  base64 -b 0 -i id_ed25519.pub
  #   publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUQ2a2xMZWRxSEF3eTI3L25pWjhjUW5qMy9DUElwT2tPNTViTzM3OTVmTHIK";
  # }];
  # nix.distributedBuilds = true;
}
