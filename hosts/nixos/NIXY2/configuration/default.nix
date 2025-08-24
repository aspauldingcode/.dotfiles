{
  inputs,
  lib,
  config,
  pkgs,
  mobile-nixos,
  apple-silicon,
  ...
}: {
  # SOPS secrets declarations
  sops.secrets = {
    wifi_bubbles_passwd = {};
    wifi_eduroam_userID = {};
    wifi_eduroam_passwd = {};
  };

  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };

  boot = {
    kernel.sysctl."net.ipv4.ip_forward" = true;
    loader = {
      timeout = 0;
      systemd-boot.enable = true; # switch to dinit for mac/linux/bsd?
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "boot.shell_on_fail"
      "ipv6.disable=1"
      "loglevel=3"
      "quiet"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "splash"
      "udev.log_priority=3"
    ];
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {selected_themes = ["rings"];})
      ];
    };
  };

  hardware = {
    asahi = {
      # Disable firmware extraction since asahi-fwextract was removed
      extractPeripheralFirmware = false;
      useExperimentalGPUDriver = true;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true; # Showing battery charge of bluetooth devices (which might lead to bugs)
        };
      };
    };
    graphics = {
      enable = true;
      extraPackages = with pkgs; [];
      extraPackages32 = with pkgs; [];
    };
  };

  networking = {
    wireless.iwd = {
      enable = true;
      settings = {
        IPv6 = {
          Enabled = false;
        };
        Settings = {
          AutoConnect = true;
        };
      };
    };
    interfaces."usb" = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.7.1";
          prefixLength = 24;
        }
      ];
    };
    networkmanager = {
      enable = true;
      wifi.backend = "iwd"; # for asahi wifi!
      dns = "dnsmasq";
    };
    firewall = {
      enable = false;
      extraCommands = ''
        # Replace "eth0" with your primary network interface
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        iptables -A FORWARD -i eth0 -o usb0 -m state --state RELATED,ESTABLISHED -j ACCEPT
        iptables -A FORWARD -i usb0 -o eth0 -j ACCEPT
      '';
    };
  };

  programs = {
    regreet = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.swayfx}/bin/sway --config ${../modules/greetd/sway-config}";
          user = "greeter";
        };
        background = {
          path = "${../../../../users/alex/extraConfig/wallpapers/gruvbox-nix.png}";
          fit = "Fill";
        };
        env = {
          ENV_VARIABLE = "value";
        };
        GTK = {
          application_prefer_dark_theme = true;
          cursor_theme_name = lib.mkForce "Bibata-Modern-Ice";
          font_name = lib.mkForce "JetBrains Mono";
          icon_theme_name = "Adwaita";
          theme_name = "Adwaita";
        };
        commands = {
          reboot = [
            "systemctl"
            "reboot"
          ];
          poweroff = [
            "systemctl"
            "poweroff"
          ];
        };
        appearance = {
          greeting_msg = "Welcome back!";
        };
      };
    };
    sway = {
      enable = true;
    };
    light.enable = true;
    fish.enable = false;
    zsh.enable = true;
    ssh.enableAskPassword = false;
    adb.enable = true; # Enable Android De-Bugging.
    gnome-disks.enable = true; # GNOME Disks daemon, UDisks2 GUI
    xwayland.enable = false;
  };

  environment.systemPackages = with pkgs; [
    jetbrains-mono
    adwaita-icon-theme
    bibata-cursors
    gtklock-userinfo-module
    # Asahi packages for Apple Silicon Macs
    asahi-audio
    asahi-bless
    asahi-btsync
    asahi-nvram
    asahi-wifisync
  ];

  services = {
    greetd = {
      enable = true; # use Greetd along with ReGreet gtk themer.
      settings = {
        default_session = {
          # command = "${pkgs.greetd.greetd}/bin/agreety --cmd sway";
          command = "${pkgs.sway}/bin/sway --config ${../modules/greetd/sway-config}";
          user = "greeter";
        };
      };
      vt = 1; # signed integer
    };

    input-remapper = {
      enable = true;
    };

    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      extraConfig = {
        pipewire."92-low-latency" = {
          context.properties = {
            default.clock.rate = 48000;
            default.clock.quantum = 32;
            default.clock.min-quantum = 32;
            default.clock.max-quantum = 32;
          };
        };
        pipewire-pulse."92-low-latency" = {
          context.modules = [
            {
              name = "libpipewire-module-protocol-pulse";
              args = {
                pulse.min.req = "32/48000";
                pulse.default.req = "32/48000";
                pulse.max.req = "32/48000";
                pulse.min.quantum = "32/48000";
                pulse.max.quantum = "32/48000";
              };
            }
          ];
          stream.properties = {
            node.latency = "32/48000";
            resample.quality = 1;
          };
        };
      };
      wireplumber.extraConfig.bluetoothEnhancements = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
          ];
        };
      };
    };

    displayManager = {
      sddm = {
        enable = false;
        wayland.enable = true; # Correctly placed under displayManager
        theme = "${import ./sddm-themes.nix {inherit pkgs;}}"; # Correctly placed under displayManager
      };
    };
    desktopManager = {
      plasma6.enable = false;
    };
    xserver = {
      enable = false;
      windowManager.i3.enable = true;
    };
    xrdp = {
      enable = true;
      port = 3389; # default 3389
      openFirewall = true;
      defaultWindowManager = "i3";
    };

    udisks2.enable = true;

    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false; # Use keys only. Remove if you want to SSH using password (not recommended)
        X11Forwarding = true;
        KbdInteractiveAuthentication = false;
      };
    };
    resolved = {
      enable = false;
      fallbackDns = [
        "8.8.8.8"
        "2001:4860:4860::8844"
      ];
      llmnr = "true";
    };

    avahi = {
      enable = true;
      nssmdns4 = true; # Printing
      openFirewall = true;
      ipv4 = true;
      ipv6 = true;
      reflector = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
        userServices = true;
        hinfo = true;
        domain = true;
      };
    };

    printing = {
      listenAddresses = ["*:631"];
      allowFrom = ["all"];
      browsing = true;
      defaultShared = true;
    };
    blueman.enable = true;
  };

  security = {
    sudo = {
      wheelNeedsPassword = false;
      extraRules = [
        {
          users = ["privileged_user"];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"]; # "SETENV" #
            }
          ];
        }
      ];
    };
    polkit.enable = true;
    pam.loginLimits = [
      {
        domain = "*";
        type = "-";
        item = "memlock";
        value = "infinity";
      }
      {
        domain = "*";
        type = "-";
        item = "nofile";
        value = "65536";
      }
    ];
  };

  users.users = {
    alex = {
      isNormalUser = true;
      description = "Alex Spaulding";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "kvm"
        "libvirtd"
        "adbusers"
        "input"
      ];
      openssh.authorizedKeys = {
        keys = [
          # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKfaO41wp3p/dkpuqIP6tj78SCrn2RSQUG2OSiHAv7j aspauldingcode@gmail.com"
          # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
        ];
        # keyFiles = [ ./../extraConfig/id_ed25519.pub ];
      };
      shell = pkgs.zsh;
    };

    susu = {
      isNormalUser = true;
      description = "Su Su Oo";
      extraGroups = ["networkmanager"];
    };
  };

  fonts.packages = with pkgs; [
    dejavu_fonts
    powerline-fonts
    powerline-symbols
    font-awesome_5
    nerd-fonts.jetbrains-mono
  ];

  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      auto-optimise-store = true; # Auto Optimize nix store.
      experimental-features = [
        "nix-command"
        "flakes"
      ]; # Enable experimental features.
    };
  };

  # nixpkgs = {
  #   config = {
  #     allowUnfree = true;
  #     permittedInsecurePackages = [ "electron-19.1.9" ];
  #   };
  #   overlays = [
  #     inputs.nur.overlays.default
  #     (final: _prev: {
  #       unstable = import inputs.unstable_nixpkgs {
  #         inherit (final) system config;
  #       };
  #     })
  #   ];
  # };

  virtualisation = {
    docker.enable = true;
    libvirtd.enable = true;
    waydroid.enable = false; # FIXME asahi linux?
    lxd.enable = true;
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = false;
    };
    stateVersion = "24.11"; # Did you read the comment?
    activationScripts.script.text = ''
      cp /home/alex/.dotfiles/users/alex/face.png /var/lib/AccountsService/icons/alex
      cp /home/alex/.dotfiles/users/susu/face.png /var/lib/AccountsService/icons/susu

      # adds way-displays configuration
      cd ${../modules/way-displays}
      find . -type d -exec mkdir -p /etc/way-displays/{} \;
      find . -type f -exec ln -sf ${../modules/way-displays}/{} /etc/way-displays/{} \;
    '';
  };

  # Console configuration for TTY
  console = {
    earlySetup = true;
    font = "ter-132n";
    packages = with pkgs; [terminus_font];
    keyMap = "us";
  };

  # Enable kmscon to replace default TTYs with support for TrueType fonts
  services.kmscon = {
    enable = true;
    extraConfig = ''
      font-name=JetBrains Mono Nerd Font Mono
      font-size=14
      font-dpi=192
    '';
  };

  # Keep a fallback traditional TTY (tty1) for emergencies
  systemd.services."getty@tty1".enable = true;
}
