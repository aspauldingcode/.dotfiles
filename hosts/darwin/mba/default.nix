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
    inputs.nixos-update-notify.darwinModules.default
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
        # HM owns apply; system flag documents intent (darwin wallpaper module is a stub).
        dendritic.wallpaper.enable = true;
        # Root launchd enforces Picture + JPEGPhoto across reboot.
        dendritic.profilePhoto.enable = true;

        # Notify when nixos-26.05 (this flake's nixpkgs-darwin input) moves
        # past the running system. Prometheus `nixpkgs-26.05-darwin` is a
        # different commit stream than `nixos-26.05`.
        services.nixos-update-notify = {
          enable = true;
          channel = "nixos-26.05";
        };

        # Root helper: one-time trust for privileged ops (no osascript passwords).
        dendritic.helper.enable = true;

        # Apple Screen Sharing (VNC :5900) + Bonjour `_rfb._tcp` (mba.local).
        dendritic.apps.vnc.enable = true;

        # WireGuard overlay ↔ sliceanddice (pass/SecretSpec keys; see docs/wireguard.md).
        dendritic.wireguard.enable = true;

        # OrbStack retired — no Linux guests on this Mac.
        dendritic.apps.orbstack.enable = false;

        # Local Ollama (Metal) + same Rust CLI as sliceanddice (ai-local / chat).
        dendritic.local-ai.enable = true;
        # From scripts/local-ai-bench (mba Metal Ollama, 2026-07-19).
        dendritic.local-ai.loadModels = [
          "qwen2.5-coder:3b" # best overall (outperform)
          "llama3.2:3b" # general / coding (outperform)
          "gemma3:1b" # fastest
          "llama3.2:1b" # ultra-light
        ];
        # llama-server (Metal, :8080) for local agents. Local GGUF (HF -hf 401s with
        # bad cached hub creds on this machine — prefer modelFile).
        dendritic.local-ai.llamaCpp.enable = true;
        dendritic.local-ai.llamaCpp.modelFile = "/Users/8amps/.cache/llama.cpp/models/qwen2.5-0.5b-instruct-q4_k_m.gguf";
        dendritic.local-ai.llamaCpp.alias = "qwen2.5-0.5b";
        dendritic.local-ai.llamaCpp.hfRepo = null;
        # Cap KV packing — Agent was sending 67k into 32k n_ctx.
        dendritic.local-ai.llamaCpp.ctxSize = 8192;

        documentation.enable = lib.mkForce false;
        documentation.man.enable = lib.mkForce false;
        documentation.doc.enable = lib.mkForce false;
        documentation.info.enable = false;

        environment.systemPackages = [
          pkgs.socat
        ];

        # Determinate owns /etc/nix/nix.conf (`nix.enable = false`). Custom
        # knobs must go through determinateNix.customSettings → nix.custom.conf.
        # Plain `nix.settings` is a no-op here and never silenced warn-dirty.
        determinateNix.customSettings = {
          warn-dirty = false;
          trusted-users = [
            "@wheel"
            "root"
            "8amps"
          ];
          # Keep cache.nixos.org explicit; FlakeHub is already in Determinate's
          # base nix.conf as extra-substituters / extra-trusted-*.
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
        };

        security.pam.services.sudo_local.touchIdAuth = true;
        security.pam.services.sudo_local.reattach = true;

        # Disable Gatekeeper declaratively
        system.activationScripts.disableGatekeeper.text = ''
          echo "Disabling Gatekeeper..."
          /usr/sbin/spctl --master-disable
        '';

        # Vendor copies (not Nix) the user asked gone. Re-run on every switch
        # so they stay deleted if something drops them back in /Applications.
        system.activationScripts.purgeUnwantedApps.text = ''
          echo "purging unwanted vendor apps"
          /usr/bin/killall \
            CrystalFetch Kiru krita Linear "Muse Hub" Obsidian okular Okular \
            Wireshark RustRover CLion Zed OrbStack 2>/dev/null || true
          for app in \
            CrystalFetch Kiru krita Linear "Muse Hub" Obsidian okular Okular \
            Wireshark RustRover CLion Zed OrbStack
          do
            rm -rf "/Applications/$app.app" "/Users/8amps/Applications/$app.app" || true
          done
          rm -rf /Applications/TeX /usr/local/texlive /Library/TeX || true
          rm -f /etc/paths.d/TeX /etc/manpaths.d/TeX || true
          /bin/launchctl bootout system/org.wireshark.ChmodBPF >/dev/null 2>&1 || true
          /bin/launchctl bootout system/com.muse.authservice >/dev/null 2>&1 || true
          rm -f /Library/LaunchDaemons/org.wireshark.ChmodBPF.plist || true
          rm -f /Library/LaunchDaemons/com.muse.authservice.plist || true
          rm -f /Library/PrivilegedHelperTools/com.muse.authservice || true
          rm -rf "/Library/Application Support/Wireshark" || true
          rm -rf \
            /Users/8amps/.orbstack \
            /Users/8amps/.config/zed \
            /Users/8amps/.zed \
            "/Users/8amps/Library/Application Support/Kiru" \
            "/Users/8amps/Library/Application Support/krita" \
            "/Users/8amps/Library/Application Support/Krita" \
            "/Users/8amps/Library/Application Support/Muse Hub" \
            "/Users/8amps/Library/Application Support/obsidian" \
            "/Users/8amps/Library/Application Support/Obsidian" \
            "/Users/8amps/Library/Application Support/Linear" \
            "/Users/8amps/Library/Application Support/Wireshark" \
            "/Users/8amps/Library/Application Support/Zed" \
            /Users/8amps/Library/Caches/Zed \
            /Users/8amps/Library/Logs/Zed \
            /Users/8amps/Library/Application\ Support/JetBrains/CLion* \
            /Users/8amps/Library/Application\ Support/JetBrains/RustRover* \
            /Users/8amps/Library/Caches/JetBrains/CLion* \
            /Users/8amps/Library/Caches/JetBrains/RustRover* \
            /Users/8amps/Library/Logs/JetBrains/CLion* \
            /Users/8amps/Library/Logs/JetBrains/RustRover* \
            || true
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
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          gtk.gtk4.theme = null;
          manual.manpages.enable = false;
          manual.html.enable = false;
          manual.json.enable = false;

          # Wawona login agents (compositorhost/menubar) were KeepAlive crash loops
          # from Xcode Debug installs. Keep them unloaded across rebuilds.
          home.activation.disableWawonaAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            uid="$(${pkgs.coreutils}/bin/id -u)"
            domain="gui/$uid"
            agentsDir="${config.home.homeDirectory}/Library/LaunchAgents"
            for agent in \
              com.aspauldingcode.wawona.compositorhost \
              com.aspauldingcode.wawona.menubar \
              com.aspauldingcode.wawona.applaunch \
              com.aspauldingcode.wawona \
              com.aspaulding.wawona
            do
              /bin/launchctl bootout "$domain/$agent" >/dev/null 2>&1 || true
              /bin/rm -f "$agentsDir/$agent.plist" >/dev/null 2>&1 || true
            done
          '';

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
          dendritic.apps.zed.enable = false;
          dendritic.apps.beeper.enable = true;
          dendritic.apps.jetbrains.enable = true;
          dendritic.apps.pass.enable = true;
          dendritic.apps.pass.fingerprint = "80AB4D8EFE29CE2ABD3BD0445C04154FC8950A8B";
          dendritic.wifi.enable = true;
          dendritic.eduroam.enable = true;
          dendritic.ssh.enable = true;
          dendritic.fleet.enable = true;
          dendritic.fleet.hostId = "mba";
          dendritic.fleet.dotfilesRoot = "/etc/nix-darwin/.dotfiles";
          dendritic.mobile.enable = true;
          # Always-on nix-android converge (shared with sliceanddice; phone lease).
          dendritic.androidConverge.enable = true;
          dendritic.wallpaper.enable = true;
          dendritic.profilePhoto.enable = true;
          dendritic.helper.enable = true;
          dendritic.apps.vnc.enable = true;
          dendritic.apps.vnc.bonjourName = "mba";
          dendritic.wireguard.enable = true;
          dendritic.wireguard.peerId = "mba";
          dendritic.apps.orbstack.enable = false;
          dendritic.python.enable = true;

          # Same Rust helpers as sliceanddice (scoped OPENAI_* only when wrapping).
          dendritic.local-ai.enable = true;
          dendritic.local-ai.defaultLocalModel = "qwen2.5-coder:3b";

          # programs.zsh.shellAliases = {
          #   microvm-run = "${inputs.self.nixosConfigurations.microvm.config.microvm.runner.vfkit}/bin/microvm-run";
          # };

          # ─────────────────────────────────────────────────────────────
        };
    }

    # 5. Mac App Store — upstream programs.mas (nix-darwin master module)
    {
      programs.mas = {
        enable = true;
        # pkgs.mas is overlaid from nixpkgs-unstable (7.x)
        update = true;
        cleanup = true;

        packages = {
          Xcode = 497799835;

          # Safari extensions (mas installs them like apps; enable in
          # Safari → Settings → Extensions)
          Momentum = 1564329434;
          "uBlock Origin Lite" = 6745342698;
          "SponsorBlock for Safari" = 1573461917;
          "Dark Reader for Safari" = 1438243180;
        };
      };
    }
  ];
}
