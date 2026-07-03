{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    inputs.determinate-nix.nixosModules.default

    {
      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.self.overlays.default
        (final: prev: {
          electron_39 = prev.electron-bin;
        })
      ];
      system.stateVersion = "24.11";

      networking.hostName = "sliceanddice";

      # Bootloader
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # NVIDIA Optimus (Intel iGPU + NVIDIA dGPU)
      hardware.graphics.enable = true;
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        prime = {
          sync.enable = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:01:0:0";
        };
      };

      networking.networkmanager.enable = true;
      services.avahi.enable = true;
      time.timeZone = "America/Los_Angeles";

      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
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

      # KDE Plasma desktop (override dendritic Sway defaults)
      services.displayManager.ly.enable = lib.mkForce false;
      programs.sway.enable = lib.mkForce false;
      services.xserver.enable = true;
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      services.printing.enable = true;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      users.users.alex = {
        isNormalUser = true;
        description = "Alex Spaulding";
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
        shell = pkgs.zsh;
      };

      services.displayManager.autoLogin.enable = true;
      services.displayManager.autoLogin.user = "alex";

      programs.firefox.enable = true;
      services.openssh.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 ];

      programs.nh = {
        enable = true;
        flake = "/etc/nixos/.dotfiles#sliceanddice";
      };

      environment.variables = {
        NH_FLAKE = "/etc/nixos/.dotfiles#sliceanddice";
        NH_OS_FLAKE = "/etc/nixos/.dotfiles#sliceanddice";
      };

      environment.interactiveShellInit = ''
        export NH_FLAKE="/etc/nixos/.dotfiles#sliceanddice"
        export NH_OS_FLAKE="/etc/nixos/.dotfiles#sliceanddice"
      '';

      environment.systemPackages = with pkgs; [
        heroic
        vesktop
        prismlauncher
        code-cursor
        git
        kdePackages.kwallet-pam
        android-tools
        waypipe
        antigravity
      ];
    }

    inputs.home-manager.nixosModules.home-manager
    inputs.self.modules.nixos.dendritic

    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "hm-bak";
      home-manager.sharedModules = [
        {
          dendritic.theme.variant = lib.mkDefault config.dendritic.theme.variant;
        }
      ];
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users.alex = {
        imports = [
          inputs.self.modules.homeManager.dendritic
        ];
        home.username = "alex";
        home.homeDirectory = "/home/alex";
        home.stateVersion = "24.11";

        dendritic.secrets.enable = true;
        dendritic.secrets.ageKeyPath = "/home/alex/.ssh/id_ed25519";
        dendritic.secrets.defaultSopsFile = ../../../secrets/sliceanddice-secrets.yaml;

        dendritic.apps.ghostty.enable = true;
        dendritic.apps.cursor.enable = true;
        dendritic.apps.antigravity.enable = true;
        dendritic.python.enable = true;

        programs.nh = {
          enable = true;
          flake = "/etc/nixos/.dotfiles#sliceanddice";
          osFlake = "/etc/nixos/.dotfiles#sliceanddice";
        };

        programs.git = {
          enable = true;
          settings.url."git@github.com:" = {
            insteadOf = "https://github.com/";
            pushInsteadOf = "https://github.com/";
          };
        };

        programs.ssh = {
          enable = true;
          matchBlocks."github.com" = {
            user = "git";
            identityFile = "~/.ssh/id_ed25519";
          };
        };

        # Konsole/Cursor often start non-login bash; without this, NH_FLAKE is unset.
        programs.bash = {
          enable = true;
          bashrcExtra = ''
            export NH_FLAKE="/etc/nixos/.dotfiles#sliceanddice"
            export NH_OS_FLAKE="/etc/nixos/.dotfiles#sliceanddice"
          '';
        };
      };
    }
  ];
}
