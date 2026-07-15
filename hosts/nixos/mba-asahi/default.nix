{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

# Soft stack mirrors sliceanddice (niri + iwd + pass/eduroam).
# Differs only where hardware/platform requires it: aarch64-linux, Asahi
# drivers, this Mac's disks/user (8amps), no NVIDIA/x86 bits.
{
  imports = [
    # 1. Base identity and platform
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [ ];
      system.stateVersion = "24.11";

      networking.hostName = "mba-asahi";

      documentation.nixos.enable = false;

      users.users."8amps" = {
        isNormalUser = true;
        description = "Alex Spaulding";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = pkgs.zsh;
      };

      # Filesystem labels from the Asahi install. If you reinstall onto btrfs,
      # update these; dendritic soft config does not care about the fs type.
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
      };
      fileSystems."/boot/asahi" = {
        device = "/dev/disk/by-label/asahi";
        fsType = "vfat";
      };
      hardware.asahi.extractPeripheralFirmware = false;

      time.timeZone = "America/Los_Angeles";
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";

      # NetworkManager + iwd come from modules/linux-desktop.nix (dendritic).
      networking.networkmanager.enable = true;
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          addresses = true;
          domain = true;
          workstation = true;
        };
      };

      # ── Wayland desktop: niri (same as sliceanddice) ───────────────────
      services.displayManager.ly.enable = lib.mkForce false;
      programs.sway.enable = lib.mkForce false;
      programs.niri.enable = true;

      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd niri-session";
          user = "greeter";
        };
      };

      services.printing.enable = true;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };

      programs.firefox.enable = true;
      services.openssh.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 ];

      programs.nh = {
        enable = true;
        flake = "/etc/nixos/.dotfiles#mba-asahi";
      };

      environment.variables = {
        NH_FLAKE = "/etc/nixos/.dotfiles#mba-asahi";
        NH_OS_FLAKE = "/etc/nixos/.dotfiles#mba-asahi";
        NIXOS_OZONE_WL = "1";
      };

      environment.interactiveShellInit = ''
        export NH_FLAKE="/etc/nixos/.dotfiles#mba-asahi"
        export NH_OS_FLAKE="/etc/nixos/.dotfiles#mba-asahi"
      '';

      environment.systemPackages = with pkgs; [
        git
        waypipe
        libnotify
        swaybg
        wl-clipboard
        cliphist
        brightnessctl
        playerctl
        pavucontrol
        grim
        slurp
        xwayland-satellite
        foot
      ];
    }

    # 2. Support modules
    inputs.apple-silicon.nixosModules.apple-silicon-support
    inputs.home-manager.nixosModules.home-manager
    inputs.self.modules.nixos.dendritic

    # 3. Home Manager — soft toggles aligned with sliceanddice
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "hm-bak";
      home-manager.backupCommand = "rm -f -- \"$2\" && mv -- \"$1\" \"$2\"";
      home-manager.sharedModules = [
        {
          dendritic.theme.variant = lib.mkDefault config.dendritic.theme.variant;
        }
      ];
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" = {
        imports = [
          inputs.self.modules.homeManager.dendritic
        ];
        home.username = "8amps";
        home.homeDirectory = "/home/8amps";
        home.stateVersion = "24.11";
        manual.manpages.enable = false;

        dconf.settings = {
          "org/gtk/settings/file-chooser" = {
            show-hidden = true;
          };
          "org/gtk/v4/settings/file-chooser" = {
            show-hidden = true;
          };
        };

        # Shared secrets.yaml (GPG for pass) — same recipients as mba Darwin.
        dendritic.secrets.enable = true;
        dendritic.secrets.ageKeyPath = "/home/8amps/.ssh/id_ed25519";
        dendritic.secrets.defaultSopsFile = ../../../secrets/secrets.yaml;

        dendritic.apps.ghostty.enable = true;
        dendritic.apps.cursor.enable = true;
        dendritic.apps.antigravity.enable = true;
        dendritic.apps.beeper.enable = true;
        dendritic.apps.pass.enable = true;
        dendritic.apps.pass.fingerprint = "80AB4D8EFE29CE2ABD3BD0445C04154FC8950A8B";
        dendritic.wifi.enable = true;
        dendritic.eduroam.enable = true;
        dendritic.ssh.enable = true;
        dendritic.fleet.enable = true;
        dendritic.fleet.hostId = "mba-asahi";
        dendritic.fleet.dotfilesRoot = "/etc/nixos/.dotfiles";
        dendritic.python.enable = true;

        dendritic.apps.niri.enable = true;
        dendritic.apps.niri.terminal = "ghostty";

        programs.nh = {
          enable = true;
          flake = "/etc/nixos/.dotfiles#mba-asahi";
          osFlake = "/etc/nixos/.dotfiles#mba-asahi";
        };

        programs.git = {
          enable = true;
          settings.url."git@github.com:" = {
            insteadOf = "https://github.com/";
            pushInsteadOf = "https://github.com/";
          };
        };
      };
    }
  ];
}
