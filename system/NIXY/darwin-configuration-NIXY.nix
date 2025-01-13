{
  config,
  pkgs,
  inputs,
  ...
}:
### System Configuration.nix for Darwin
{
  imports = [
    ./scripts-NIXY.nix
    ./modules/homebrew-pkgs.nix
    ./modules/darwin-defaults.nix
    ./modules/launch-agents.nix
    ./modules/packages.nix
    ./modules/theme.nix
    ./modules/macos-activation-scripts.nix
    ./modules/macos-dock.nix
    ./modules/spicetify/spicetify.nix
    # ./modules/wg-quick.nix
    # ./modules/openssh.nix

    ./sa-resources/ammonia.nix
    ./sa-resources/glow.nix

    ./modules/windowManagement/cursorcerer.nix
    ./modules/windowManagement/karabiner.nix
    ./modules/windowManagement/macforge.nix
    ./modules/windowManagement/yabai.nix
    ./modules/windowManagement/sketchybar.nix
    ./modules/windowManagement/skhd.nix
    ./modules/windowManagement/toggle-scripts.nix
    ./modules/windowManagement/unmenu.nix
    # ./modules/nix-the-planet.nix
  ];
  # programs.okular.enable = true;

  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      powerline-fonts
      powerline-symbols
      font-awesome_5
      jetbrains-mono
      # (pkgs.callPackage ./apple-fonts.nix {})
      (nerdfonts.override {
        fonts = [
          "NerdFontsSymbolsOnly"
          "Hack"
        ];
      })
    ];
  };
  # system.build = builtins.exec "echo 'hello, world.'";
  # Auto upgrade nix package and the daemon service.
  services = {
    nix-daemon.enable = true;
    tailscale.enable = true;
  };
  networking = {
    computerName = "NIXY"; # REQUIRED! "NIXY" to build nix flakes
    #FIXME: first install - Check to see if it works with computerName!
    # OTHERWISE: 'scutil --set NIXY' for the first time install.
    hostName = "NIXY";
    localHostName = "NIXY";
    knownNetworkServices = [
      "AX88179A"
      "USB 10/100 LAN"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
  };

  #Sudoer's file to symlink. removes the need for a password for the admin group
  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    zsh.enable = true; # default shell on catalina
    bash.enable = true;
    fish.enable = true; # NOT Borne COMPAT?
  };

  users.users.alex.shell = pkgs.bashInteractive; # must use nixpkgs bash instead of apple's ancient bash (3.2 id dated)
  nix = {
    # optimise.automatic = true;
    # https://nixos.wiki/wiki/Distributed_build
    # distributedBuilds = false; # set true after configuration
    # buildMachines = [ ]; #FIXME: add NIXSTATION64 as a builder!
    # below are per build machine (* is the entry of the machine in the list above)
    # buildMachines.*.hostName = ""; # Example: "nixbuilder.example.org"
    # buildMachines.*.mandatoryFeatures
    # buildMachines.*.maxJobs
    # nix.buildMachines.*.protocol
    # nix.buildMachines.*.publicHostKey
    # nix.buildMachines.*.speedFactor
    # nix.buildMachines.*.sshKey
    # nix.buildMachines.*.sshUser
    # nix.buildMachines.*.supportedFeatures = [ "kvm" "big-parallel" ];
    # nix.buildMachines.*.systems = [ "x86_64-linux" "aarch64-linux" ];

    gc = {
      automatic = true;
      interval.Hour = 23; # Automaitcally collect garbage each day
      options = "--delete-older-than 30d --delete-old-generations 10";
    };
    settings = {
      # FIXME: add cahcix.nixos.org so I don't have to rebuild home-manager all the time
      # substituters = [
      #   "https://cache.nixos.org/"
      # ];
      # trusted-public-keys = [
      #   "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs="
      # ]; # By default, only the key for cache.nixos.org is included
      # trusted-substituters = [
      #   "https://hydra.nixos.org/"
      # ];
      trusted-users = [
        "root"
        "@admin" # anyone in the wheel group
      ];
    };
    extraOptions = ''
      extra-platforms = aarch64-darwin x86_64-darwin
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config = {
      allowUnfree = true;
      allowUnfreePredictate = (_: true);
      allowUnsupportedSystem = true;
    };
  };

  system.stateVersion = 5;
}
