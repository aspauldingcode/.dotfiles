# Shared Darwin Base Configuration
# Used by all Darwin systems with system-specific overrides
{
  inputs,
  lib,
  config,
  pkgs,
  user,
  ...
}: {
  # Common fonts
  fonts.packages = with pkgs; [
    dejavu_fonts
    powerline-fonts
    powerline-symbols
    font-awesome_5
    nerd-fonts.jetbrains-mono
  ];

  # Common services
  services = {
    tailscale.enable = true;
    theme-toggle.enable = true;
  };

  # Common networking (hostname will be overridden per system)
  networking = {
    knownNetworkServices = [
      "AX88179A"
      "USB 10/100 LAN"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
  };

  # Sudoer's file to symlink - removes the need for a password for the admin group
  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';

  # Common programs
  programs = {
    zsh.enable = true;
    bash = {
      enable = true;
      completion.enable = true;
    };
    fish.enable = true;
  };

  # Common user configuration
  users.users.${user} = {
    shell = pkgs.bashInteractive;
  };

  # Common nix configuration
  nix = {
    enable = false; # Using determinate nix
    
    # Distributed builds configuration - NIXSTATION64 as builder
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "nixstation64.local";
        system = "x86_64-linux";
        maxJobs = 4;
        speedFactor = 2;
        supportedFeatures = ["kvm" "big-parallel" "nixos-test"];
        mandatoryFeatures = [];
        sshUser = "alex";
        sshKey = "/Users/alex/.ssh/id_ed25519";
        protocol = "ssh-ng";
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUE=";
      }
    ];

    # Common settings for distributed builds
    settings = {
      builders-use-substitutes = true;
      max-jobs = 0; # Don't build locally when remote builders are available
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      trusted-users = [
        "root"
        "@admin"
        "alex"
      ];
    };

    extraOptions = ''
      extra-platforms = aarch64-darwin x86_64-darwin
      experimental-features = nix-command flakes
    '';
  };

  # Common nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredictate = _: true;
      allowUnsupportedSystem = true;
    };
    overlays = [
      (final: prev: {
        # Override Valgrind to be a dummy package on Darwin since it's not supported
        valgrind = prev.runCommand "valgrind-dummy" {} ''
          mkdir -p $out/bin
          echo '#!/bin/sh' > $out/bin/valgrind
          echo 'echo "Valgrind is not supported on Darwin"' >> $out/bin/valgrind
          chmod +x $out/bin/valgrind
        '';

        # Override packages that might depend on Valgrind
        pipewire = prev.pipewire.override {
          vulkanSupport = false;
        };
      })
    ];
  };

  # Common system settings
  system.stateVersion = 5;
}
