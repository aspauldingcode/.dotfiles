# Shared NixOS Base Configuration
# Used by all NixOS systems with system-specific overrides
{
  inputs,
  lib,
  config,
  pkgs,
  user,
  ...
}: {
  # Common boot configuration
  boot = {
    loader = {
      timeout = 3;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = [
      "boot.shell_on_fail"
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
        (adi1090x-plymouth-themes.override {
          selected_themes = ["rings"];
        })
      ];
    };
  };

  # Common hardware configuration
  hardware = {
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
    graphics.enable = true;
  };

  # Common networking
  networking = {
    networkmanager.enable = true;
    networkmanager.dns = lib.mkDefault "default";
    firewall = {
      allowedTCPPorts = [5354 1714 1764];
      allowedUDPPorts = [5353 1714 1764];
    };
  };

  # Common time configuration
  time.timeZone = lib.mkDefault "America/Denver";

  # Common internationalization
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

  # Common programs
  programs = {
    fish.enable = false;
    zsh.enable = true;
    ssh.enableAskPassword = false;
    adb.enable = true;
    gnome-disks.enable = true;
  };

  # Common services
  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    printing.enable = true;
    fwupd.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    thermald.enable = true;
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };

  # Common system configuration
  systemd.services.avahi-daemon = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "5";
    };
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # Common user configuration
  users.users.${user} = {
    isNormalUser = true;
    description = "Alex Spaulding";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "adbusers"
      "input"
    ];
    shell = pkgs.zsh;
  };

  # Common fonts
  fonts.packages = with pkgs; [
    dejavu_fonts
    powerline-fonts
    powerline-symbols
    font-awesome_5
    nerd-fonts.jetbrains-mono
  ];

  # Common nix configuration
  nix = {
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
  };

  # Common system settings
  system = {
    autoUpgrade = {
      enable = lib.mkDefault true;
      allowReboot = false;
    };
    stateVersion = lib.mkDefault "23.05";
  };

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # Common environment
  environment = {
    systemPackages = with pkgs; [
      # Essential system tools
      neovim
      fastfetch
      zellij
      gh
      git
      curl
      wget
      tree
      htop
      killall
      lazygit
      nixfmt-rfc-style
      pstree
      zoxide
      fzf
    ];
    
    variables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
    };
  };
}
