{
  pkgs,
  inputs,
  ...
}:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    uutils-coreutils-noprefix
    alacritty
    ## macosINSTANTView?
    wget
    gnumake
    pfetch
    htop
    prismlauncher
    nixfmt-rfc-style
    luaformatter
    alt-tab-macos
    unnaturalscrollwheels
    # xorg.xinit      # FIXME: Broken package darwin
    # xorg.xorgserver # FIXME: Broken package darwin
    yazi
    fftw
    espeak
    openconnect
    gp-saml-gui
    libreoffice-bin
    libtool
    automake
    autoconf-archive
    unstable.tart
    iniparser
    unstable.iproute2mac
    m-cli
    ansible
    bws
    gtk-mac-integration
    # libiconv
    # choose-gui
    # ddcctl
    # cliclick
    # sublime4
    # nightlight
    cmake
    blueutil
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

    python311Packages.pillow
    python311Packages.pillow-heif
    python311Packages.tqdm
    python311Packages.moviepy
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
    android-tools
    undmg
    jq
    libusb1
    beeper-bridge-manager
    nodejs_20
    unstable.nodePackages.vercel

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
    substituters = [ "https://cache.nixos.org/" ];
    trusted-public-keys = [
      "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
    ];
    always-allow-substitutes = true;
  };

  nix.linux-builder.enable = true;
}
