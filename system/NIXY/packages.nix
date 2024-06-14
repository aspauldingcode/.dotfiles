{
  pkgs,
  inputs,
  config,
  ...
}:

{
  # copy Nix-Darwin GUI apps to ~/Applications
  system.activationScripts.postUserActivation.text = ''
    rsyncArgs="--archive --checksum --chmod=-w --copy-unsafe-links --delete"
    apps_source="${config.system.build.applications}/Applications"
    moniker="Nix Trampolines"
    app_target_base="$HOME/Applications"
    app_target="$app_target_base/$moniker"
    mkdir -p "$app_target"
    ${pkgs.rsync}/bin/rsync $rsyncArgs "$apps_source/" "$app_target"
  '';

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
    wget
    zellij
    # neofetch
    pfetch
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
    (pkgs.callPackage ./cursorcerer.nix { })
  ];

  system.activationScripts.extraActivation.text = ''
    ln -sf "${inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk20}/zulu-20.jdk" "/Library/Java/JavaVirtualMachines/"
  '';
}
