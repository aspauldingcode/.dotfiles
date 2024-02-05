{ inputs, lib, config, pkgs, mobile-nixos, ... }:

{
  imports = [
    ./hardware-configuration.nix
    # ("${mobile-nixos}/lib/configuration.nix" { device = "oneplus-fajita"; })
    ./packages.nix
    ./virtual-machines.nix
    ./wg-quick.nix
  ];

  # Bootloader.
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # choose your kernel
    loader = { # TODO: Use whatever bootloader you prefer!
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
};

  # This is using a rec (recursive) expression to set and access XDG_BIN_HOME within the expression
  # For more on rec expressions see https://nix.dev/tutorials/first-steps/nix-language#recursive-attribute-set-rec
  # environment.sessionVariables = rec {
  #   XDG_CACHE_HOME  = "$HOME/.cache";
  #   XDG_CONFIG_HOME = "$HOME/.config";
  #   XDG_DATA_HOME   = "$HOME/.local/share";
  #   XDG_STATE_HOME  = "$HOME/.local/state";
  #   
  #   # Not officially in the specification
  #   XDG_BIN_HOME    = "$HOME/.local/bin";
  #   PATH = [ 
  #     "${XDG_BIN_HOME}"
  #   ];
  # };

  environment = {
    # systemPackages = with pkgs; [ #FIXME: INCLUDE IN SDDM THEMES INSTEAD!
    #   # Get tokyo dark theme from github in sddm-themes.nix then call it here
    #   # (callPackage ./sddm-themes.nix{}).tokyo-night-sddm
    #   # (pkgs.callPackage ./sddm-themes.nix {})
    #   (pkgs.libsForQt5.callPackage ./sddm_themes.nix {})
    #   # libsForQt5.qt5.qtgraphicaleffects  # required for tokyo-night-sddm
    #   # libsForQt5.qt5.qtsvg               # add qtsvg
    #   # libsForQt5.qt5.qtbase              # add qtbase
    #   # libsForQt5.qt5.qtquickcontrols2    # add qtquickcontrols2
    #   # libsForQt5.qt5.qtdeclarative       # add qtdeclarative (for QML support)
    # ];
    plasma5.excludePackages = with pkgs; [
      libsForQt5.oxygen
      xwayland
      libsForQt5.konsole
      xterm
      libsForQt5.kwalletmanager
      libsForQt5.kwallet
      libsForQt5.kwallet-pam
      kwalletcli
    ]; 

    variables = rec {
      QT_QPA_PLATFORMTHEME = "qt5ct";
      #QT_STYLE_OVERRIDE     = "qt5ct";
    };
  };
  # Enable networking
  networking = {
    hostName = "NIXSTATION64";
    networkmanager.enable = true;
  };

  # time settings
  time.timeZone = "America/Denver";

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true; # FIXME

  #add opengl (to fix Qemu)
  hardware.opengl.enable = true;

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

# services
  services = {
    # PRETTY LOGIN SCREEN! (FIXME needs to be configured with osx sddm theme)
    xserver = {
      enable = true;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          theme = "${import ./sddm-themes.nix {inherit pkgs; }}";
        };
      };
      desktopManager = {
      	plasma5 = { 
        	enable = true;
        	runUsingSystemd = false;
      	};
	mate = {
		enable = true;
		# runUsingSystemd = false;
	};	
      };
    };
    pipewire = { # fix for pipewire audio:
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    #getty.autologinUser = "alex"; # Enable automatic login for the user.
    udisks2.enable = true;

    # This setups a SSH server. Very important if you're setting up a headless system.
    openssh = { #be sure to check allowed firewall ports
      enable = true;
      settings = {
        #PermitRootLogin = "no"; # Forbid root login through SSH.
        PasswordAuthentication = false; # Use keys only. Remove if you want to SSH using password (not recommended)
        X11Forwarding = true; 
        KbdInteractiveAuthentication = false;
        #AllowUsers = [ "alex" ];
        };
      };

    # Network Discovery
    avahi = {
      enable = true;
      nssmdns4 = true; # Printing
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
        domain = true;
      };
    };

    printing = {
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
    };

  };

  security = {
    sudo = {
      wheelNeedsPassword = false;
      extraRules = [{
        users = [ "privileged_user" ];
        commands = [{
          command = "ALL";
          options = [ "NOPASSWD" ]; # "SETENV" #
        }];
      }];
    };
    polkit.enable = true;
  };

  # allow AirPrinter through firewall
  networking.firewall = {
    allowedTCPPorts = [ 631 7000 7001 7100 22 ];
    allowedUDPPorts = [ 631 5353 6000 6001 7011 22 ];
  };

  # programs
  programs = {
    fish.enable = false;
    zsh.enable = true;
    ssh.enableAskPassword = false;
    adb.enable = true; # Enable Android De-Bugging.
    gnome-disks.enable = true; # GNOME Disks daemon, UDisks2 GUI
    xwayland.enable = false;
    sway = {
      enable = true;
      package = pkgs.swayfx;
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    alex = {
      isNormalUser = true;
      description = "Alex Spaulding";
      extraGroups =
        [ "networkmanager" "wheel" "docker" "kvm" "libvirtd" "adbusers" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKfaO41wp3p/dkpuqIP6tj78SCrn2RSQUG2OSiHAv7j aspauldingcode@gmail.com"
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [ ./../extraConfig/id_ed25519_NIXY.pub ];
    };

    susu = {
      isNormalUser = true;
      description = "Su Su Oo";
      extraGroups = [ "networkmanager" ];
    };
  };

  # fonts
  fonts.packages = with pkgs; [
    # font-awesome
    powerline-fonts
    powerline-symbols
    jetbrains-mono
    font-awesome_5
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" "Hack" ]; })
    dejavu_fonts
  ];

  nixpkgs = {
    overlays = [ # You can add overlays here
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];

    #config = { # Configure your nixpkgs instance
    #allowUnfree = true; # Allow unfree packages #FIXME: DOES THIS EVEN WORK?

    #};
  };

  # nix
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}")
    config.nix.registry;
    settings = { # Nix Settings
    auto-optimise-store = true; # Auto Optimize nix store.
    experimental-features =
      [ "nix-command" "flakes" ]; # Enable experimental features.
    };
    #trusted-users = [ "root" "alex" "susu"]; #fix trusted user issue
  };

  virtualisation = { # enable virtualization support
  docker.enable = true;
  libvirtd.enable = true;
  waydroid.enable = true;
  lxd.enable = true;
};

system = {
  autoUpgrade = {
    enable = true;
    allowReboot = false;
  };
    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "23.05"; # Did you read the comment?
  };
}
