{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:

{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  imports = [
    inputs.determinate-nix.darwinModules.default
    "${inputs.nix-darwin-fork}/modules/services/plugin-playground"
    {
      config = {
        services.plugin-playground = {
          enable = false;
          package = inputs.plugin-playground.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.overlays = [
          inputs.self.overlays.default
        ];
        system.primaryUser = "8amps";
        networking.hostName = "mba";
        system.stateVersion = 5;
        system.defaults.dock.show-recents = false;
        system.defaults.finder.AppleShowAllFiles = true;
        system.defaults.finder.ShowPathbar = true;
        system.defaults.finder.ShowStatusBar = true;
        dendritic.theme.variant = lib.mkDefault "dark";

        documentation.enable = lib.mkForce false;
        documentation.man.enable = lib.mkForce false;
        documentation.doc.enable = lib.mkForce false;
        documentation.info.enable = false;

        environment.systemPackages = [
          pkgs.socat
        ];

        nix.enable = false;
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          warn-dirty = false;
          substituters = [
            "https://cache.nixos.org"
            "https://cache.flakehub.com"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
            "cache.flakehub.com-4:Asi8qIv291s0aYLyH6IOnr5Kf6+OF14WVjkE6t3xMio="
            "cache.flakehub.com-5:zB96CRlL7tiPtzA9/WKyPkp3A2vqxqgdgyTVNGShPDU="
            "cache.flakehub.com-6:W4EGFwAGgBj3he7c5fNh9NkOXw0PUVaxygCVKeuvaqU="
            "cache.flakehub.com-7:mvxJ2DZVHn/kRxlIaxYNMuDG1OvMckZu32um1TadOR8="
            "cache.flakehub.com-8:moO+OVS0mnTjBTcOUh2kYLQEd59ExzyoW1QgQ8XAARQ="
            "cache.flakehub.com-9:wChaSeTI6TeCuV/Sg2513ZIM9i0qJaYsF+lZCXg0J6o="
            "cache.flakehub.com-10:2GqeNlIp6AKp4EF2MVbE1kBOp9iBSyo0UPR9KoR0o1Y="
          ];
          netrc-file = "/nix/var/determinate/netrc";
          trusted-users = [
            "@wheel"
            "root"
            "8amps"
          ];
        };

        security.pam.services.sudo_local.touchIdAuth = true;
        security.pam.services.sudo_local.reattach = true;

        # Disable Gatekeeper declaratively
        system.activationScripts.disableGatekeeper.text = ''
          echo "Disabling Gatekeeper..."
          /usr/sbin/spctl --master-disable
        '';

        users.users."8amps" = {
          name = "8amps";
          home = "/Users/8amps";
          shell = pkgs.zsh;
        };
      };
    }

    # 2. Import Home Manager
    inputs.home-manager.darwinModules.home-manager

    # 3. Pull in the merged Dendritic feature module
    inputs.self.modules.darwin.dendritic

    # 4. Configure Home Manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = lib.mkForce "backup";

      # Stylix evaluates GNOME targets inside HM by default, which throws an
      # evaluation error on nix-darwin because `services.displayManager.generic`
      # doesn't exist. Disable it globally for all HM profiles.
      home-manager.sharedModules = [
        {
          stylix.targets.gnome.enable = lib.mkForce false;
        }
        {
          dendritic.theme.variant = lib.mkDefault config.dendritic.theme.variant;
        }
      ];
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" =
        { config, ... }:
        {
          gtk.gtk4.theme = null;
          manual.manpages.enable = false;
          manual.html.enable = false;
          manual.json.enable = false;

          # Wawona LaunchAgent
          # launchd.agents.wawona = {
          #   enable = true;
          #   config = {
          #     Label = "com.aspaulding.wawona";
          #     ProgramArguments = [ "${pkgs.wawona}/bin/wawona" ];
          #     KeepAlive = true;
          #     RunAtLoad = true;
          #     StandardOutPath = "${config.home.homeDirectory}/.cache/wawona.log";
          #     StandardErrorPath = "${config.home.homeDirectory}/.cache/wawona.err";
          #   };
          # };

          # Waypipe LaunchAgent (Host-side proxy for Wawona)
          # launchd.agents.waypipe = {
          #   enable = true;
          #   config = {
          #     Label = "com.aspaulding.waypipe";
          #     ProgramArguments = [
          #       "${inputs.wawona.packages.${pkgs.stdenv.hostPlatform.system}.wawona-macos}/Applications/Wawona.app/Contents/MacOS/waypipe"
          #       "--display"
          #       "/tmp/wawona-503/wayland-0"
          #       "-s"
          #       "/etc/nix-darwin/.dotfiles/waypipe-wawona.sock"
          #       "client"
          #     ];
          #     EnvironmentVariables = {
          #       WAYLAND_DISPLAY = "wayland-0";
          #       XDG_RUNTIME_DIR = "/tmp/wawona-503";
          #     };
          #     KeepAlive = true;
          #     RunAtLoad = true;
          #     StandardOutPath = "${config.home.homeDirectory}/.cache/waypipe.log";
          #     StandardErrorPath = "${config.home.homeDirectory}/.cache/waypipe.err";
          #   };
          # };

          # Bridge LaunchAgent: connects the VSOCK socket from vfkit to the Waypipe socket
          # launchd.agents.waypipe-bridge = {
          #   enable = true;
          #   config = {
          #     Label = "com.aspaulding.waypipe-bridge";
          #     ProgramArguments = [
          #       "${pkgs.socat}/bin/socat"
          #       "UNIX-CONNECT:/etc/nix-darwin/.dotfiles/dendritic-vm-vsock.sock"
          #       "UNIX-CONNECT:/etc/nix-darwin/.dotfiles/waypipe-wawona.sock"
          #     ];
          #     KeepAlive = {
          #       SuccessfulExit = false;
          #     };
          #     RunAtLoad = true;
          #     StandardOutPath = "${config.home.homeDirectory}/.cache/waypipe-bridge.log";
          #     StandardErrorPath = "${config.home.homeDirectory}/.cache/waypipe-bridge.err";
          #   };
          # };

          imports = [
            inputs.self.modules.homeManager.dendritic
          ];
          home.username = "8amps";
          home.homeDirectory = "/Users/8amps";
          home.stateVersion = "24.11";

          # ── App Linking ─────────────────────────────────────────────
          targets.darwin.copyApps.enable = false;
          targets.darwin.linkApps.enable = true;

          # ── Feature Toggles ─────────────────────────────────────────
          dendritic.apps.ghostty.enable = true;
          dendritic.apps.antigravity.enable = true;
          dendritic.apps.cursor.enable = true;
          dendritic.apps.beeper.enable = true;
          dendritic.apps.jetbrains.enable = true;
          dendritic.apps.pass.enable = true;
          dendritic.apps.pass.fingerprint = "80AB4D8EFE29CE2ABD3BD0445C04154FC8950A8B";
          dendritic.mobile.enable = true;
          dendritic.wallpaper.enable = true;
          dendritic.python.enable = true;

          # programs.zsh.shellAliases = {
          #   microvm-run = "${inputs.self.nixosConfigurations.microvm.config.microvm.runner.vfkit}/bin/microvm-run";
          # };

          # ─────────────────────────────────────────────────────────────
        };
    }

    # 5. Mac App Store — declarative apps via mas CLI
    {
      dendritic.mas = {
        enable = true;

        # ── App Store Applications ──────────────────────────────────
        apps = {
          Xcode = 497799835;
        };

        # ── Safari Extensions ───────────────────────────────────────
        # Installed via mas, just like Brave/Firefox extensions but
        # for Safari. Enable them in: Safari → Settings → Extensions
        safari.extensions = [
          {
            name = "Momentum";
            id = 1564329434;
          }
          {
            name = "uBlock Origin Lite";
            id = 6745342698;
          }
          {
            name = "SponsorBlock for Safari";
            id = 1573461917;
          }
          {
            name = "Dark Reader for Safari";
            id = 1438243180;
          }
        ];
      };
    }
  ];
}
