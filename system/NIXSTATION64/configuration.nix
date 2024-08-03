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
    ./hardware-configuration.nix
    # ("${mobile-nixos}/lib/configuration.nix" { device = "oneplus-fajita"; })
    ./packages.nix
    ./virtual-machines.nix
    ./theme.nix
    #./wg-quick.nix
  ];


  # Bootloader.
  boot = {
    # choose your kernel
    #kernelPackages = pkgs.linuxPackages_latest;      # standard
    kernelPackages = pkgs.linuxPackages-rt_latest; # real-time
    loader = {
      # TODO: Use whatever bootloader you prefer!
      systemd-boot.enable = true; # switch to dinit for mac/linux/bsd?
      efi.canTouchEfiVariables = true;
    };
  };

  # Whether to enable loading amdgpu kernelModule in stage 1. 
  # Can fix lower resolution in boot screen during initramfs phase!
  hardware.amdgpu.initrd.enable = true;

  # If you encounter problems having multiple monitors connected to your GPU, adding `video` parameters for each connector to the kernel command line sometimes helps. 
  boot.kernelParams = [
    "amdgpu.si_support=0"
    "boot.shell_on_fail"
    "ipv6.disable=1"
    "loglevel=3"
    "nvidia-drm.modeset=1"
    "quiet"
    "rd.systemd.show_status=false"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "splash"
    "udev.log_priority=3"
    "video=DP-4:1920x1080@60"
    "video=DP-5:1920x1080@60"
    "video=DP-6:1920x1080@60"
    # "video=DP-1:1920x1080@60"
    # "video=DP-2:1920x1080@60"
    # "video=DP-3:1920x1080@60"

  ];

  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = with pkgs; [
      # By default we would install all themes
      (adi1090x-plymouth-themes.override {
        selected_themes = [ "rings" ];
      })
    ];
  };

  # Hide the OS choice for bootloaders.
  # It's still possible to open the bootloader list by pressing any key
  # It will just not appear on screen unless a key is pressed
  boot.loader.timeout = 0;

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

  # https://nixos.wiki/wiki/AMD_GPU#HIP
  systemd.tmpfiles.rules = [ "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" ];

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
      plasma5Packages.oxygen
      xwayland
      plasma5Packages.konsole
      xterm
      plasma5Packages.kwalletmanager
      plasma5Packages.kwallet
      plasma5Packages.kwallet-pam
      kwalletcli
    ];

    variables = rec {
      QT_QPA_PLATFORMTHEME = "qt5ct";
      #QT_STYLE_OVERRIDE     = "qt5ct";
      ROC_ENABLE_PRE_VEGA = "1";
    };
  };
  # Enable networking
  networking = {
    hostName = "NIXSTATION64";
    domain = "local";
    networkmanager = {
      enable = true;
      # connectionConfig = "connection.mdns=2";
    };
    #   useDHCP = false;
    #   useNetworkd = true;
    #   useHostResolvConf = false;
    #   firewall = {
    #     enable = false; # temp disable firewall?
    #     allowedTCPPorts = [
    #       631
    #       7000
    #       7001
    #       7100
    #       22
    #       25565
    #     ];
    #     allowedUDPPorts = [
    #       631
    #       5353
    #       6000
    #       6001
    #       7011
    #       22
    #       25565
    #     ];
    #   };
    # };
    # systemd.network = {
    #   networks = {
    #     "wlp56s0" = {
    #       name = "wlp56s0";
    #       DHCP = "ipv4";
    #       networkConfig = {
    #         MulticastDNS = true;
    #       };
    #     };
    #   };
  };
  # time settings
  time.timeZone = "America/Denver";
  # Enable Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true; # pairing for bluetooth items in systray.
  # Using Bluetooth headset buttons to control media player
  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = [ "network.target" "sound.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };
  # Enabling A2DP Sink
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true; # Showing battery charge of bluetooth devices (which might lead to bugs)
    };
  };
  # Disable PulseAudio
  hardware.pulseaudio.enable = false;
  
  # Enable PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # Low-latency setup
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 32;
        default.clock.min-quantum = 32;
        default.clock.max-quantum = 32;
      };
    };

    # PulseAudio backend low-latency setup
    extraConfig.pipewire-pulse."92-low-latency" = {
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
  security.rtkit.enable = true;

  #add opengl (to fix Qemu)
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true; # This is already enabled by default
  hardware.opengl.driSupport32Bit = true; # For 32 bit applications
  # For 32 bit applications 
  hardware.opengl.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    amdvlk
  ];
  hardware.opengl.extraPackages32 = with pkgs; [ driversi686Linux.amdvlk ];

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

  # grab user profile pictures and set greetd ReGreet Configurations.
  system.activationScripts.script.text = ''
    cp /home/alex/.dotfiles/users/alex/face.png /var/lib/AccountsService/icons/alex
    cp /home/alex/.dotfiles/users/susu/face.png /var/lib/AccountsService/icons/susu
    
    # adds greetd configuration for ReGreet 
    cd ${../../system/NIXSTATION64/greetd}
    find . -type d -exec mkdir -p /etc/greetd/{} \;
    find . -type f -exec ln -sf ${../../system/NIXSTATION64/greetd}/{} /etc/greetd/{} \;

    # adds way-displays configuration
    cd ${../../system/NIXSTATION64/way-displays}
    find . -type d -exec mkdir -p /etc/way-displays/{} \;
    find . -type f -exec ln -sf ${../../system/NIXSTATION64/way-displays}/{} /etc/way-displays/{} \;
  '';

  #programs.regreet.enable = true;
  # To use ReGreet, services.greetd has to be enabled and services.greetd.settings.default_session should contain the appropriate configuration to launch config.programs.regreet.package. For examples, see the ReGreet Readme. 
  # https://github.com/rharish101/ReGreet#set-as-default-session

  # services
  services = {
    greetd = {
      enable = true; # use Greetd along with ReGreet gtk themer.
      settings = {
        default_session = {
          # command = "${pkgs.greetd.greetd}/bin/agreety --cmd sway";
          # command = "${pkgs.greetd.greetd}/bin/agreety --cmd sway";
          command = "${pkgs.sway}/bin/sway --config /etc/greetd/sway-config";
          user = "greeter";
        };
      };
      # Whether to restart greetd when it terminates (e.g. on failure). This is usually desirable so a user can always log in, but should be disabled when using ‘settings.initial_session’ (autologin), because every greetd restart will trigger the autologin again.
      # restart = !(config.services.greetd.settings ? initial_session)

      # The virtual console (tty) that greetd should use. This option also disables getty on that tty.
      vt = 1; # signed integer
    };

    displayManager = {
      sddm = {
        enable = false;
        wayland = {
          enable = true; # Correctly placed under displayManager
        };
        theme = "${import ./sddm-themes.nix { inherit pkgs; }}"; # Correctly placed under displayManager
      };
    };
    desktopManager.plasma6.enable = false;
    xserver = {
      videoDrivers = [ "amdgpu" ];
      desktopManager = {
        plasma5 = {
          enable = false;
          mobile.enable = false; # for login remote
          runUsingSystemd = false;
          useQtScaling = false; # enable HIDPI scaling in qt
        };
        xfce = {
          enable = true;
          enableScreensaver = false;
        };
        #phosh = {
        #  enable = true;
        #  user = "alex";
        #  group = "users";
        #};
      };
    };
    xrdp = {
      enable = true;
      port = 3389; # default 3389
      openFirewall = true;
      defaultWindowManager = "xfce4-session";
    };

    #getty.autologinUser = "alex"; # Enable automatic login for the user.
    udisks2.enable = true;

    # This setups a SSH server. Very important if you're setting up a headless system.
    openssh = {
      # be sure to check allowed firewall ports
      enable = true;
      settings = {
        #PermitRootLogin = "no"; # Forbid root login through SSH.
        PasswordAuthentication = false; # Use keys only. Remove if you want to SSH using password (not recommended)
        X11Forwarding = true;
        KbdInteractiveAuthentication = false;
        #AllowUsers = [ "alex" ];
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

    # Network Discovery
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
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
    };
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
      # xwayland.enable = false;
      # extraPackages = with pkgs; [ swaylock swayidle foot dmenu wmenu ];
    };
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
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
    (nerdfonts.override {
      fonts = [
        "NerdFontsSymbolsOnly"
        "Hack"
      ];
    })
    dejavu_fonts
  ];

  nixpkgs = {
    overlays = [
      # You can add overlays here
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];

    # config = { # Configure your nixpkgs instance
    # # allowUnfree = true; # Allow unfree packages #FIXME: DOES THIS EVEN WORK?
    # allowUnfreePredicate = pkg:
    # builtins.elem (lib.getName pkg) [
    #   # Add additional package names here
    #   #"hello-unfree"
    #   "oneplus-sdm845-firmware-x"
    # ];
    # };
  };

  # nix
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      # Nix Settings
      auto-optimise-store = true; # Auto Optimize nix store.
      experimental-features = [
        "nix-command"
        "flakes"
      ]; # Enable experimental features.
    };
    #trusted-users = [ "root" "alex" "susu"]; #fix trusted user issue
  };

  virtualisation = {
    # enable virtualization support
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
