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
    ./modules/openssh.nix
    ./modules/gowall.nix

    # ./sa-resources/ammonia.nix
    # ./sa-resources/glow.nix\
    ./sa-resources/glow-themes/base16_glow_theme.nix

    ./modules/windowManagement/cursorcerer.nix
    ./modules/windowManagement/karabiner.nix
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
    zsh.enable = true;
    bash = {
      enable = true;
      completion.enable = true;
    };
    fish.enable = true;
  };

  users.users.alex = {
    shell = pkgs.bashInteractive;
  };

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
      download-buffer-size = 500000000; # 500 MB
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

  # Add sops-nix configuration
  sops = {
    defaultSopsFile = ../../secrets/nixy/secrets.yaml;
    defaultSopsFormat = "yaml";
    age = {
      # This will automatically import SSH keys as age keys
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Key location
      keyFile = "/var/lib/sops-nix/key.txt";
      # Generate a new key if it doesn't exist
      generateKey = true;
    };
    secrets = {
      test_secret = {
        # Optional: specify owner/permissions if needed
        owner = "alex";
        mode = "0400";
      };
      claude_api_key = {
        owner = "alex";
        mode = "0400";
      };
      openai_api_key = {
        owner = "alex";
        mode = "0400";
      };
      azure_openai_api_key = {
        owner = "alex";
        mode = "0400";
      };
      bedrock_keys = {
        owner = "alex";
        mode = "0400";
      };
    };
  };

  # FIXME: MIGHT NOT BE NEEDED!
  # Create required directories for sops-nix
  system.activationScripts.postActivation.text = ''
    # Create sops-nix directory
    echo "Setting up sops-nix directories..."
    sudo mkdir -p /var/lib/sops-nix
    sudo chmod 750 /var/lib/sops-nix

    # Create and set permissions for secrets directory
    sudo mkdir -p /run/secrets
    sudo chown -R alex:staff /run/secrets
    sudo chmod -R 750 /run/secrets
  '';

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "test-system-secret" ''
      #!${pkgs.bashInteractive}/bin/bash
      if [ -f ${config.sops.secrets.test_secret.path} ]; then
        echo "Reading test_secret:"
        echo "Secret name: ${config.sops.secrets.test_secret.name}"
        echo "Secret path: ${config.sops.secrets.test_secret.path}"
        echo "Secret key: ${config.sops.secrets.test_secret.key}"
        echo "Secret format: ${config.sops.secrets.test_secret.format}"
        echo "Secret mode: ${config.sops.secrets.test_secret.mode}"
        echo "Secret sopsFile: ${config.sops.secrets.test_secret.sopsFile}"
      else
        echo "Error: test_secret file not found at ${config.sops.secrets.test_secret.path}"
        exit 1
      fi
    '')
  ];
}
