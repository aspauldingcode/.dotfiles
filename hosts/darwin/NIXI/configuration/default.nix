{
  pkgs,
  user,
  ...
}:
### System Configuration.nix for Darwin
{
  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      powerline-fonts
      powerline-symbols
      font-awesome_5
      nerd-fonts.jetbrains-mono
    ];
  };
  # system.build = builtins.exec "echo 'hello, world.'";
  # Auto upgrade nix package and the daemon service.
  services = {
    tailscale.enable = true;
    theme-toggle.enable = true;
  };
  networking = {
    computerName = "NIXI"; # REQUIRED! "NIXI" to build nix flakes
    hostName = "NIXI";
    localHostName = "NIXI";
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
    zsh.enable = true;
    bash = {
      enable = true;
      completion.enable = true;
    };
    fish.enable = true;
  };

  users.users.${user} = {
    shell = pkgs.bashInteractive;
  };

  nix = {
    enable = false; # Switching to determinate nix!
    # optimise.automatic = true;

    # Distributed builds configuration - NIXSTATION64 as builder
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "nixstation64.local"; # or use IP address
        system = "x86_64-linux";
        maxJobs = 4; # Adjust based on NIXSTATION64 CPU cores
        speedFactor = 2; # x86_64 is typically faster for builds
        supportedFeatures = [
          "kvm"
          "big-parallel"
          "nixos-test"
        ];
        mandatoryFeatures = [];
        sshUser = "alex";
        sshKey = "/Users/alex/.ssh/id_ed25519"; # SSH key for connecting to NIXSTATION64
        protocol = "ssh-ng"; # Use new SSH protocol for better performance
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE="; # Replace with actual host key
      }
    ];

    # Additional settings for distributed builds
    settings = {
      builders-use-substitutes = true; # Allow builders to use substitutes
      max-jobs = 0; # Don't build locally when remote builders are available
      # FIXME: add cachix.nixos.org so I don't have to rebuild home-manager all the time
      substituters = [
        "https://cache.nixos.org/"
        # "https://your-cachix-cache.cachix.org" # Add your cachix cache here
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        # "your-cachix-cache.cachix.org-1:your-public-key-here" # Add your cachix public key
      ];
      trusted-users = [
        "root"
        "@admin" # anyone in the admin group
        "alex"
      ];
    };

    extraOptions = ''
      extra-platforms = aarch64-darwin x86_64-darwin
      experimental-features = nix-command flakes
    '';

    #gc = {
    #  automatic = true;
    #  interval.Hour = 23; # Automatically collect garbage each day
    #  options = "--delete-older-than 30d --delete-old-generations 10";
    #};
  };

  nixpkgs = {
    hostPlatform = "x86_64-darwin";
    config = {
      allowUnfree = true;
      allowUnfreePredictate = _: true;
      allowUnsupportedSystem = true;
    };
  };

  system.stateVersion = 5;
}
