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
    wget
    gnumake
    pfetch
    # unstable.macos-instantview # Temporarily disabled due to build issues
    prismlauncher
    nixfmt-rfc-style
    luaformatter
    alt-tab-macos
    unnaturalscrollwheels
    # xorg.xinit      # FIXME: Broken package darwin
    # xorg.xorgserver # FIXME: Broken package darwin
    yazi
    espeak
    openconnect
    unstable.tart
    iniparser
    bat
    # iproute2mac # Should be installed via brew
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
    treefmt
    nowplaying-cli
    ifstat-legacy
    ranger

    #darwin.iproute2mac #MUST BE BREW PACKAGE?
    ncurses6
    hexedit
    texliveTeTeX

    jdk23
    android-tools
    # unstable.android-studio # FIXME: Someday, this will work.
    undmg
    jq
    libusb1
    # beeper-bridge-manager
    # nodejs_20 # FIXME: causing severe headaches atm 04/28/25
    # unstable.nodePackages.vercel

    #lspconfig
    fd # find tool
    ripgrep
    # (pkgs.callPackage ./../../customDerivations/cursorcerer.nix {}) # Temporarily disabled due to build issues
    (pkgs.callPackage ./../../customDerivations/mousecape.nix { })
    (pkgs.callPackage ./../../customDerivations/inputsourceselector.nix { })
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnsupportedSystemPredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "swiftformat"
        "sourcekit-lsp"
      ];
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

  # nix.linux-builder.enable = true;
}
