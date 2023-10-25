# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs, ... }: 

{
  imports = [ # Include the results of the hardware scan
# If you want to use modules from other flakes (such as nixos-hardware):
# inputs.hardware.nixosModules.common-cpu-amd
# inputs.hardware.nixosModules.common-ssd
./hardware-configuration.nix
./sway-configuration.nix #FIXME: NOT USING!
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

# Enable networking
networking = {
  hostName = "NIXSTATION64"; # Which machine are we on?
  networkmanager.enable = true;
};


# time settings
time.timeZone = "America/Denver"; # FIXME

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
        #sway #FIXME: CONFIGURE SWAY HERE
        pipewire = { # fix for pipewire audio:
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
      };

        # PRETTY LOGIN SCREEN! (FIXME needs to be configured with osx sddm theme)
        xserver = {
          enable = true;
          layout = "us";
          libinput.enable = true;  # Enable this if using libinput for input device management.
          displayManager.sddm = {
            enable = true;
            theme = "abstractdark-sddm-theme"; #FIXME NOTWORKING?
                #anything else?
              };
            };
        #getty.autologinUser = "alex"; # Enable automatic login for the user.

# This setups a SSH server. Very important if you're setting up a headless system.
openssh = {
  enable = true;
  settings = {PermitRootLogin = "no"; # Forbid root login through SSH.
  PasswordAuthentication = false; # Use keys only. Remove if you want to SSH using password (not recommended)
};
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

# programs
programs = {
  fish.enable = true;
  ssh.enableAskPassword = false;
  adb.enable = true; # Enable Android De-Bugging.
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

