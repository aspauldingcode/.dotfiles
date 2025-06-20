{
  inputs,
  lib,
  config,
  pkgs,
  mobile-nixos,
  ...
}:

{
  imports = [
    ../hardware-configuration
    ../modules/packages
    ../modules/theme
    ../modules/virtual-machines
    ../scripts
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_6_13;
    loader = {
      timeout = 3;
      systemd-boot.enable = true; # switch to dinit for mac/linux/bsd?
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "amdgpu.si_support=0"
      "boot.shell_on_fail"
      "ipv6.disable=1"
      "loglevel=3"
      "nvidia-drm.modeset=1"
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
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };
  };

  hardware = {
    amdgpu.initrd.enable = true;
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
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        amdvlk
      ];
      # extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];
    };
    pulseaudio.enable = false;
  };

  # https://nixos.wiki/wiki/AMD_GPU#HIP
  systemd.tmpfiles.rules = [ "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" ];

  networking = {
    hostName = "NIXSTATION64";
    domain = "local";
    networkmanager.enable = true;

    networkmanager.dns = lib.mkForce "default"; # Use NetworkManager's default DNS settings
    firewall = {
      allowedTCPPorts = [
        5354
        1714
        1764
      ];
      allowedUDPPorts = [
        5353
        1714
        1764
      ];
    };
  };

  systemd.services.avahi-daemon = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
    };
  };

  time = {
    timeZone = "America/Denver";
  };

  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = [
      "network.target"
      "sound.target"
    ];
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };

  systemd.user.services.waybar = {
    description = "Waybar";
    after = [
      "network.target"
      "graphical-session.target"
    ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.waybar}/bin/waybar";
      ExecStartPre = "${pkgs.procps}/bin/pkill waybar || true";
      Restart = "always";
      Type = "simple";
    };
  };

  systemd.user.services.wl-gammarelay = {
    enable = true;
    description = "Gamma adjustment service for Wayland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wl-gammarelay-rs}/bin/wl-gammarelay-rs";
      Restart = "always";
    };
  };

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

  programs = {
    regreet = {
      enable = true;
      package = pkgs.regreet;
      settings = {
        default_session = {
          command = "${pkgs.sway}/bin/sway --config ${../modules/greetd/sway-config}";
          user = "greeter";
        };
        background = {
          path = "${../../users/alex/extraConfig/wallpapers/gruvbox-nix.png}";
          fit = "Fill";
        };
        env = {
          ENV_VARIABLE = "value";
        };
        GTK = {
          application_prefer_dark_theme = true;
          cursor_theme_name = lib.mkForce "Bibata-Modern-Classic";
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
    kdeconnect = {
      enable = true;
      package = pkgs.plasma5Packages.kdeconnect-kde;
    };
  };

  environment.systemPackages = with pkgs; [
    jetbrains-mono
    adwaita-icon-theme
    bibata-cursors
  ];

  services = {
    greetd = {
      enable = true; # use Greetd along with ReGreet gtk themer.
      settings = {
        default_session = {
          command = "${pkgs.sway}/bin/sway --config ${./modules/greetd/sway-config}";
          user = "greeter";
        };
      };
      vt = 1;
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

    xrdp = {
      enable = true;
      port = 3389;
      openFirewall = true;
      defaultWindowManager = "sway";
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
      enable = true;
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
      ipv6 = false;
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
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
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
          users = [ "privileged_user" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ]; # "SETENV" #
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
      extraGroups = [ "networkmanager" ];
    };
  };

  fonts.packages = with pkgs; [
    powerline-fonts
    powerline-symbols
    jetbrains-mono
    font-awesome_5
    (nerdfonts.override {
      fonts = [
        "NerdFontsSymbolsOnly"
        "Hack"
      ];
    })
    dejavu_fonts
  ];

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      auto-optimise-store = true; # Auto Optimize nix store.
      experimental-features = [
        "nix-command"
        "flakes"
      ]; # Enable experimental features.
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [ "electron-19.1.9" ];
    };
    overlays = [
      inputs.nur.overlays.default
      (final: _prev: {
        unstable = import inputs.unstable_nixpkgs {
          inherit (final) system config;
        };
      })
    ];
  };

  virtualisation = {
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
    stateVersion = "23.05"; # Did you read the comment?
    activationScripts.script.text = ''
      cp /home/alex/.dotfiles/users/alex/face.png /var/lib/AccountsService/icons/alex
      cp /home/alex/.dotfiles/users/susu/face.png /var/lib/AccountsService/icons/susu

      # adds way-displays configuration
      cd ${../../system/NIXSTATION64/modules/way-displays}
      find . -type d -exec mkdir -p /etc/way-displays/{} \;
      find . -type f -exec ln -sf ${../../system/NIXSTATION64/modules/way-displays}/{} /etc/way-displays/{} \;
    '';
  };
}
