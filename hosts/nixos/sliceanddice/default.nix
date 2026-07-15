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

      # The NixOS + Home Manager option manuals build their reference via
      # `nixosOptionsDoc`, which embeds the flake's nixpkgs source path as a
      # context-less string — the source of the `builtins.derivation ...
      # options.json ... without a proper context` eval warning. Regular man
      # pages (`man 1 ...`) stay enabled; only the generated NixOS options
      # manual / `man configuration.nix` is dropped.
      documentation.nixos.enable = false;

      # Bootloader
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Latest mainline kernel from nixpkgs 26.05 (>= 7.0). The NVIDIA open
      # kernel modules track new kernels closely, so this builds cleanly on
      # Ampere; if a future bump ever breaks the nvidia module, pin back to
      # `pkgs.linuxPackages`.
      boot.kernelPackages = pkgs.linuxPackages_latest;

      # Hybrid graphics: Intel Tiger Lake UHD (PCI:0:2:0) + NVIDIA RTX 3050 Ti
      # Mobile / GA107 Ampere (PCI:1:0:0). The internal panel is driven by the
      # Intel iGPU; the NVIDIA GPU is used via PRIME render offload.
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
      hardware.nvidia = {
        modesetting.enable = true;
        # Keep the dGPU powered but idle (no finegrained runtime-PM): finegrained
        # aggressively suspends the GPU and has been a black-screen source here.
        # CPU/fan quiet policy lives in dendritic.power (RAPL/EPP), not here.
        powerManagement.enable = true;
        powerManagement.finegrained = false;
        # dynamicBoost/nvidia-powerd fights quiet EPP/RAPL — leave default (off).
        # Ampere (RTX 30xx) → the open kernel modules are recommended and build
        # cleanly against mainline kernels; the proprietary blob lags new kernels.
        open = true;
        nvidiaSettings = true;
        prime = {
          # Render offload: compositor runs on Intel, apps opt into NVIDIA via
          # `nvidia-offload <cmd>` (NVIDIA_* env vars).
          offload.enable = true;
          offload.enableOffloadCmd = true;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };

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

      # ── Dendritic desktop features ─────────────────────────────────────
      dendritic.apps.niri.enable = true;
      dendritic.apps.linux-desktop.enable = true;

      # Quiet-first power: RAPL/EPP feedback controller, zswap, lid/idle suspend.
      # Owns CPU power policy — do not enable TLP / auto-cpufreq / PPD alongside.
      # NVIDIA finegrained stays off (black-screen history); dGPU already runtime-suspends.
      dendritic.power.enable = true;

      # NVIDIA drm for Xwayland/offload. videoDrivers pulls in the driver even
      # though niri itself is a native Wayland compositor on Intel.
      services.xserver.videoDrivers = [ "nvidia" ];

      console.keyMap = "us";
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # MSI Sword 15 A11UD (board MS-1582): single-color blue keyboard backlight.
      # Same EC family as Katana GF66 11UC/UD — force that profile until the exact
      # EC string for BIOS E1582IMS.315 is upstreamed in msi-ec.
      # Exposes /sys/class/leds/msiacpi::kbd_backlight (0–3). Requires reboot.
      boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
      boot.kernelModules = [ "msi-ec" ];
      boot.extraModprobeConfig = ''
        options msi-ec firmware=1582EMS1.107
      '';

      users.users.alex = {
        isNormalUser = true;
        description = "Alex Spaulding";
        extraGroups = [
          "networkmanager"
          "wheel"
          "video" # brightnessctl: panel + msiacpi::kbd_backlight
        ];
        shell = pkgs.zsh;
      };

      programs.firefox.enable = true;

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
        git
        android-tools
        waypipe
        # NOTE: cursor + antigravity are installed via Home Manager
        # (dendritic.apps.cursor/antigravity → the FHS builds on Linux), so they
        # are intentionally NOT listed here to avoid a non-FHS PATH duplicate.
        # niri plumbing pkgs come from modules/apps/niri.nix.
      ];
    }

    inputs.home-manager.nixosModules.home-manager
    inputs.self.modules.nixos.dendritic

    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "hm-bak";
      # Plasma rewrites ~/.gtkrc-2.0 as a plain file; allow replacing stale hm-bak backups.
      home-manager.backupCommand = "rm -f -- \"$2\" && mv -- \"$1\" \"$2\"";
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

        # Same rationale as `documentation.nixos.enable = false` above: the HM
        # options manpage is built with `nixosOptionsDoc` and triggers the
        # context-less `options.json` warning. Drop the generated HM manual.
        manual.manpages.enable = false;

        dendritic.secrets.enable = true;
        dendritic.secrets.ageKeyPath = "/home/alex/.ssh/id_ed25519";
        dendritic.secrets.defaultSopsFile = ../../../secrets/sliceanddice-secrets.yaml;

        dendritic.apps.ghostty.enable = true;
        dendritic.apps.cursor.enable = true;
        dendritic.apps.antigravity.enable = true;
        dendritic.apps.beeper.enable = true;
        dendritic.apps.pass.enable = true;
        dendritic.apps.pass.fingerprint = "80AB4D8EFE29CE2ABD3BD0445C04154FC8950A8B";
        dendritic.wifi.enable = true;
        dendritic.eduroam.enable = true;
        dendritic.ssh.enable = true;
        # Host already defines programs.ssh Host blocks below.
        dendritic.ssh.manageClientConfig = false;
        dendritic.fleet.enable = true;
        dendritic.fleet.hostId = "sliceanddice";
        dendritic.fleet.dotfilesRoot = "/etc/nixos/.dotfiles";
        dendritic.python.enable = true;
        dendritic.wallpaper.enable = true;

        # niri user config: terminal → ghostty, launcher → fuzzel.
        dendritic.apps.niri.enable = true;
        dendritic.apps.niri.terminal = "ghostty";

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
          # HM 26.05 deprecated `matchBlocks` (use `settings`) and the implicit
          # default block (`enableDefaultConfig`). Opt out and restate the
          # upstream defaults explicitly under `settings."*"`.
          enableDefaultConfig = false;
          settings = {
            "*" = {
              ForwardAgent = false;
              AddKeysToAgent = "no";
              Compression = false;
              ServerAliveInterval = 0;
              ServerAliveCountMax = 3;
              HashKnownHosts = false;
              UserKnownHostsFile = "~/.ssh/known_hosts";
              ControlMaster = "no";
              ControlPath = "~/.ssh/master-%r@%n:%p";
              ControlPersist = "no";
            };
            "github.com" = {
              User = "git";
              IdentityFile = "~/.ssh/id_ed25519";
            };
          };
        };

      };
    }
  ];
}
