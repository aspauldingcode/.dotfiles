# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs, ... }: 

{
  imports = [ # Include the results of the hardware scan
# If you want to use modules from other flakes (such as nixos-hardware):
# inputs.hardware.nixosModules.common-cpu-amd
# inputs.hardware.nixosModules.common-ssd
./hardware-configuration.nix
#./sway-configuration.nix #FIXME: NOT USING!
./packages.nix
./virtual-machines.nix
#./sddm-themes.nix
      ];

# Bootloader.
boot = {
  kernelPackages = pkgs.linuxPackages_latest; #choose your kernel
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

    environment.variables = rec {
      QT_QPA_PLATFORMTHEME  = "qt5ct";
      #QT_STYLE_OVERRIDE     = "qt5ct";
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
  pipewire = { # fix for pipewire audio:
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
  jack.enable = true;
};
        # PRETTY LOGIN SCREEN! (FIXME needs to be configured with osx sddm theme)
        xserver = {
          enable = true;
          displayManager = { 
            sddm = {
              enable = true;
              wayland.enable = true;
              theme = "maldives";
            };
          #find swayfx binary with: ls /nix/store | grep swayfx
        };
        windowManager = {
          session = [{
            name = "swayfx";
            start = ''
              systemd-cat -t sway-x86_64-linux -- /nix/store/8qdp8r1bafgz4g1rxwn0fc2im15adsly-swayfx-0.3.2/bin/sway & 
              waitPID=$!
            '';
          }];
        };
      };

        #getty.autologinUser = "alex"; # Enable automatic login for the user.
        udisks2.enable = true;

        # This setups a SSH server. Very important if you're setting up a headless system.
        openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no"; # Forbid root login through SSH.
            PasswordAuthentication = false; # Use keys only. Remove if you want to SSH using password (not recommended)
          };
        };

        avahi = {
          enable = true;
          nssmdns = true;
          openFirewall = true;
          publish = {
            enable = true;
            userServices = true;
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
          extraRules= [{  users = [ "privileged_user" ];
          commands = [{ command = "ALL" ;
          options= [ "NOPASSWD" ]; # "SETENV" # 
        }];}];
      };
      polkit.enable = true;
    };
    # allow AirPrinter through firewall
networking.firewall = {
  allowedTCPPorts = [ 631 ];
  allowedUDPPorts = [ 631 ];
};
# programs
programs = {
  fish.enable = true;
  ssh.enableAskPassword = false;
  adb.enable = true; # Enable Android De-Bugging.
  gnome-disks.enable = true; # GNOME Disks daemon, UDisks2 GUI
  xwayland.enable = false;
};

# Define a user account. Don't forget to set a password with ‘passwd’.
users.users = {
  alex = {
    isNormalUser = true;
    description = "Alex Spaulding";
    extraGroups = [ "networkmanager" "wheel" "docker" "kvm" "libvirtd" "adbusers"];
    openssh.authorizedKeys.keys = [
      ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKfaO41wp3p/dkpuqIP6tj78SCrn2RSQUG2OSiHAv7j aspauldingcode@gmail.com''
# TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
                ];
                shell = pkgs.fish;
              };

              susu = {
                isNormalUser = true;
                description = "Su Su Oo";
                extraGroups = [ "networkmanager"];
              };
            };

# fonts
fonts.packages = with pkgs; [
  font-awesome
  powerline-fonts
  powerline-symbols
  jetbrains-mono
  (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
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
registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
# This will additionally add your inputs to the system's legacy channels
# Making legacy nix commands consistent as well, awesome!
nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
settings = { # Nix Settings
auto-optimise-store = true; # Auto Optimize nix store.
experimental-features = [ 
  "nix-command" "flakes" 
]; # Enable experimental features.
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

