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
    ./disko.nix

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

      # Bootloader — 511M EFI; each generation can add ~50MB initrd when it
      # changes. Cap generations so /boot cannot fill and block switches.
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 5;
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

      # Local free LLMs (Ollama CUDA). Models from scripts/local-ai-bench winners.
      # Cloud OpenAI / Cursor stay available; helpers never force OPENAI_API_BASE globally.
      dendritic.local-ai.enable = true;
      dendritic.local-ai.loadModels = [
        "gemma3:1b" # fastest (outperform)
        "llama3.2:3b" # best coding among fast (outperform)
        "qwen2.5-coder:3b" # coder specialist
        "qwen2.5-coder:7b" # quality coder (usable; role diversity over llama3.2:1b)
      ];

      # On-disk NixOS installer (nixinstall) + vault. See docs/nixinstall.md.
      dendritic.nixinstall.enable = true;
      dendritic.nixinstall.autoBootstrap = true;

      # After dendritic-reinstall (btrfs). Keep true only while still on live ext4.
      dendritic.disk.liveExt4Compat = false;

      # System Stylix ← wallpaper pack (gtkgreet). gtklock picks a different pack entry at lock time.
      dendritic.wallpaper.enable = true;

      # Immutable account + gtk auth avatar (assets/profile_square.jpg).
      dendritic.profilePhoto.enable = true;

      # Wayland session RDP (lamco) + Bonjour/mDNS `_rdp._tcp` → sliceanddice.local
      dendritic.apps.rdp.enable = true;
      dendritic.apps.rdp.bonjourName = "sliceanddice";

      # WireGuard overlay ↔ mba (pass/SecretSpec keys; see docs/wireguard.md).
      dendritic.wireguard.enable = true;

      # Shared NixOS + Windows local login from private pass (LOGIN_PASSWORD).
      dendritic.identity.enable = true;
      dendritic.identity.username = "alex";
      dendritic.identity.passwordFile = "/home/alex/.config/dendritic/identity/login.password";

      # Windows dual-boot: IoT Enterprise LTSC (bloatless). Partitions already
      # carved (ESP→nixos→windows→wininstall→swap→nixinstall). Bootstrap
      # downloads ISO → wininstall → BootNext silent Setup → LBA windows part.
      dendritic.windows.enable = true;
      dendritic.windows.autoBootstrap = true;
      # Sword 15 A11UD: pin NVIDIA notebook INF tree; drop Intel/MSI packs into
      # /var/cache/dendritic-windows/drivers-extra when CDN fetchurl is blocked.
      dendritic.windows.drivers.enable = true;
      dendritic.windows.drivers.packs = [
        {
          name = "nvidia-notebook";
          url = "https://us.download.nvidia.com/Windows/572.60/572.60-notebook-win10-win11-64bit-international-dch-whql.exe";
          sha256 = "1c6i92x71ygz7g9677xaxby2rbha60hk1xf7pyg293953yf8wkvw";
        }
        # MSI Sword keyboard backlight: ACPI MSI0007 (ssps2.inf) + SteelSeries Engine /S.
        {
          name = "steelseries-engine";
          url = "https://download.msi.com/uti_exe/nb/SteelSeriesEngine3.19.2Setup_3.19.2_0xeec30749.zip";
          sha256 = "1w5x3p8ly685983xvll0wwz1ndcg8fgbc9m638vabiaw7qkm7kqs";
        }
      ];

      # NVIDIA drm for Xwayland/offload. videoDrivers pulls in the driver even
      # though niri itself is a native Wayland compositor on Intel.
      services.xserver.videoDrivers = [ "nvidia" ];

      console.keyMap = "us";
      services.xserver.xkb = {
        layout = "us";
        variant = "";
      };

      # MSI Sword 15 A11UD: Fn+backlight is AT scancode 0x8e (unknown to atkbd).
      # Map it for compositors; Fn firmware already cycles EC 0xd3 itself.
      services.udev.extraHwdb = ''
        evdev:atkbd:dmi:bvn*:bvr*:bd*:svnMicro-Star*:pnSword*
         KEYBOARD_KEY_8e=kbdillumtoggle
      '';

      # MSI Sword 15 A11UD (MS-1582): EC firmware 1582EMS1.107.
      # HARD RULE: never Linux-write EC 0xd3, 0xf3, or kbd mode 0x2c on this
      # board — each has hard-hung the EC (no oops; forced reboot). Fn firmware
      # still cycles 0xd3; LEDs stay dark under Linux. Patch marks kbd_bl
      # unsupported so msiacpi::kbd_backlight is never registered. Do not
      # live-reload msi-ec; do not modprobe ec_sys write_support=1 for BL tests.
      # Lighting path: Windows SteelSeries HID — see docs/re/sword-kbd-bl/.
      dendritic.swordKbdBl.enable = true;
      boot.extraModulePackages = [
        (config.boot.kernelPackages.msi-ec.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./msi-ec-sword-kbd-disable.patch
          ];
        }))
      ];
      boot.kernelModules = [ "msi-ec" ];
      boot.extraModprobeConfig = ''
        options msi-ec firmware=1582EMS1.107
        # Read-only EC dumps only; writes hang this Sword's EC.
        options ec_sys write_support=0
      '';
      # Belt-and-suspenders if an old generation still registers the LED.
      systemd.services."systemd-backlight@leds:msiacpi::kbd_backlight".enable = false;
      # Keep ec_sys out unless explicitly needed for a read-only dump.
      boot.blacklistedKernelModules = [ "ec_sys" ];

      users.users.alex = {
        isNormalUser = true;
        description = "Alex Spaulding";
        extraGroups = [
          "networkmanager"
          "wheel"
          "video" # brightnessctl: panel backlight
        ];
        shell = pkgs.zsh;
        # Password: pass LOGIN_PASSWORD → materialize → dendritic.identity.
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
        # Interactive Yes/No for keyboard-backlight probe cycles.
        (import ./kbd-bl-ask.nix { inherit pkgs; })
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
        # Always-on nix-android converge (shared with mba; phone lease).
        dendritic.androidConverge.enable = true;
        dendritic.python.enable = true;
        dendritic.wallpaper.enable = true;
        dendritic.profilePhoto.enable = true;
        dendritic.apps.rdp.enable = true;
        dendritic.wireguard.enable = true;
        dendritic.wireguard.peerId = "sliceanddice";

        # niri user config: terminal → ghostty, launcher → fuzzel.
        dendritic.apps.niri.enable = true;
        dendritic.apps.niri.terminal = "ghostty";

        dendritic.local-ai.enable = true;
        dendritic.local-ai.defaultLocalModel = "qwen2.5-coder:3b";

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
