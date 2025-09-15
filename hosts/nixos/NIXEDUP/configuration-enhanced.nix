# Enhanced Mobile NixOS configuration for OnePlus 6T (NIXEDUP)
# Integrates phoneputer configuration with improved mobile support
{
  config,
  lib,
  pkgs,
  inputs,
  user,
  ...
}: {
  imports = [
    # Import mobile-nixos device configuration
    (import "${inputs.mobile-nixos}/lib/configuration.nix" {device = "oneplus-fajita";})
  ];

  # Allow unfree packages (needed for OnePlus firmware and proprietary drivers)
  nixpkgs.config.allowUnfree = true;

  # Device-specific configuration for OnePlus 6T (fajita)
  mobile = {
    device = {
      name = "oneplus-fajita";
      identity = {
        name = "OnePlus 6T";
      };
    };

    # Disable boot control to avoid Ruby/Perl build issues during cross-compilation
    boot.boot-control.enable = false;

    # Enable mobile-specific features
    beautification = {
      silentBoot = true;
      splash = true;
    };
  };

  # System configuration
  system = {
    stateVersion = "25.05";
    # Enable cross-compilation optimizations
    nixos.variant_id = "mobile";
  };

  # Boot configuration
  boot = {
    # Enable systemd in stage 1 for faster boot
    initrd.systemd.enable = true;

    # Kernel parameters for mobile optimization
    kernelParams = [
      "console=ttyMSM0,115200"
      "androidboot.console=ttyMSM0"
      "androidboot.hardware=qcom"
      "user_debug=31"
      "msm_rtb.filter=0x237"
      "ehci-hcd.park=3"
      "service_locator.enable=1"
      "swiotlb=0"
      "loop.max_part=7"
    ];
  };

  # Networking configuration
  networking = {
    hostName = "nixedup";
    networkmanager = {
      enable = true;
      wifi.powersave = false; # Better for mobile usage
    };
    wireless.enable = false; # Use NetworkManager instead
  };

  # Disable documentation generation to suppress mobile-nixos warnings
  documentation = {
    enable = false;
    nixos.enable = false;
    man.enable = false;
    info.enable = false;
  };

  # User configuration
  users.users = {
    root = {
      password = "nixtheplanet";
      openssh.authorizedKeys.keys = [
        # Add your SSH public key here for secure access
      ];
    };

    ${user} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "dialout" # For modem access
        "plugdev" # For device access
      ];
      hashedPassword = "!"; # Disable password login, use SSH keys
    };
  };

  # Services configuration
  services = {
    # SSH for remote access
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password"; # More secure
        PasswordAuthentication = false; # Use keys only
        KbdInteractiveAuthentication = false;
      };
    };

    # Display manager for mobile
    xserver = {
      enable = true;
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
        autoLogin = {
          enable = true;
          user = user;
        };
      };
    };

    # Audio system
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    # Mobile-specific services
    geoclue2 = {
      enable = true;
      enableDemoAgent = false;
      geoProviderUrl = "https://beacondb.net/v1/geolocate";
      appConfig = {
        "gnome-maps" = {
          isAllowed = true;
          isSystem = true;
        };
        "megapixels" = {
          isAllowed = true;
          isSystem = true;
        };
        "calls" = {
          isAllowed = true;
          isSystem = true;
        };
      };
    };

    # ModemManager for cellular connectivity
    modemmanager.enable = true;

    # Bluetooth
    blueman.enable = true;

    # Power management
    upower.enable = true;
    thermald.enable = true;

    # GNOME services
    gnome = {
      gnome-keyring.enable = true;
      evolution-data-server.enable = true;
    };

    # D-Bus and system services
    dbus.enable = true;
    udisks2.enable = true;
  };

  # Hardware configuration
  hardware = {
    # Audio
    pulseaudio.enable = false; # Using pipewire instead

    # Bluetooth
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    # Sensors
    sensor.iio.enable = true;

    # OpenGL for mobile graphics
    graphics = {
      enable = true;
      driSupport = true;
    };
  };

  # Programs and desktop environment
  programs = {
    dconf.enable = true;
    gnupg.agent.enable = true;

    # Mobile-friendly shell
    fish.enable = true;

    # Development tools
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };
  };

  # Environment packages
  environment = {
    systemPackages = with pkgs; [
      # Core mobile environment
      phosh
      phoc
      squeekboard

      # Communication apps
      calls
      chatty

      # Camera and media
      megapixels

      # Mobile settings
      phosh-mobile-settings

      # GNOME mobile apps
      gnome-contacts
      gnome-calendar
      gnome-maps
      gnome-weather
      gnome-clocks
      gnome-calculator
      gnome-screenshot
      gnome-system-monitor
      gnome-settings-daemon

      # System utilities
      networkmanagerapplet
      blueman

      # Development tools
      git
      neovim
      htop
      tree
      curl
      wget

      # Mobile development
      android-tools
      adb-sync

      # Terminal and shell
      kitty
      fish

      # Debugging tools
      gdb
      strace
      lsof
      dmesg

      # Network tools
      networkmanager
      modemmanager
      mobile-broadband-provider-info

      # Fun stuff
      asciiquarium
      neofetch
    ];

    # Shell aliases for mobile development
    shellAliases = {
      ll = "ls -la";
      la = "ls -la";
      mobile-logs = "journalctl -f";
      mobile-status = "systemctl status";
      adb-connect = "adb connect localhost:5555";
    };

    # Environment variables
    variables = {
      EDITOR = "nvim";
      BROWSER = "gnome-web";
      TERMINAL = "kitty";
    };
  };

  # Security configuration
  security = {
    sudo.wheelNeedsPassword = false;
    polkit.enable = true;
    rtkit.enable = true; # For audio
  };

  # Fonts for mobile UI
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];

    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif"];
        sansSerif = ["Noto Sans"];
        monospace = ["Fira Code"];
        emoji = ["Noto Color Emoji"];
      };
    };
  };

  # Sops-nix secrets management
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets = {
      wifi_bubbles_passwd = {
        owner = user;
        group = "users";
        mode = "0600";
      };
    };
  };

  # Allow insecure packages (temporary workaround)
  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  # Systemd services for mobile optimization
  systemd.services = {
    # Mobile-specific optimizations
    mobile-optimization = {
      description = "Mobile device optimizations";
      wantedBy = ["multi-user.target"];
      script = ''
        # CPU governor for battery life
        echo powersave > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor || true

        # Disable unnecessary services for battery life
        echo 1 > /sys/module/printk/parameters/console_suspend || true
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  # Nix configuration optimized for mobile
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      max-jobs = 2; # Limit for mobile device
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
