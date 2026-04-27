{ inputs, ... }:

{
  imports = [
    # 1. Base identity and platform
    {
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [ inputs.self.overlays.default ];
      system.stateVersion = 5;
      
      nix.enable = false; # Let determinate manage it
      nix.settings = {
        experimental-features = [ "nix-command" "flakes" ];
        warn-dirty = false;
        substituters = [ "https://cache.nixos.org" "https://cache.flakehub.com" ];
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
      };
      
      security.pam.services.sudo_local.touchIdAuth = true;
      security.pam.services.sudo_local.reattach = true;
      
      users.users."8amps" = {
        name = "8amps";
        home = "/Users/8amps";
      };
    }

    # 2. Import Home Manager
    inputs.home-manager.darwinModules.home-manager

    # 3. Pull in Feature Modules from the Hub (inputs.self.modules)
    inputs.self.modules.darwin.shell
    inputs.self.modules.darwin.secrets
    inputs.self.modules.darwin.styling
    inputs.self.modules.darwin.mas
    inputs.self.modules.darwin.wallpaper

    # 4. Configure Home Manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" = {
        imports = [
          inputs.self.modules.homeManager.shell
          inputs.self.modules.homeManager.editor
          inputs.self.modules.homeManager.secrets
          inputs.self.modules.homeManager.styling
          inputs.self.modules.homeManager.apps
          inputs.self.modules.homeManager.ghostty
          inputs.self.modules.homeManager.antigravity
          inputs.self.modules.homeManager.cursor
          inputs.self.modules.homeManager.beeper
          inputs.self.modules.homeManager.jetbrains
          inputs.self.modules.homeManager.wallpaper
          inputs.self.modules.homeManager.spotify
        ];
        home.username = "8amps";
        home.homeDirectory = "/Users/8amps";
        home.stateVersion = "24.11";
        
        # ── App Linking ─────────────────────────────────────────────
        targets.darwin.copyApps.enable = true;
        targets.darwin.linkApps.enable = false;

        # ── Feature Toggles ─────────────────────────────────────────
        dendritic.apps.ghostty.enable = true;
        dendritic.apps.antigravity.enable = true;
        dendritic.apps.cursor.enable = true;
        dendritic.apps.beeper.enable = true;
        dendritic.apps.jetbrains.enable = true;

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
          { name = "uBlock Origin Lite"; id = 6745342698; }
        ];
      };
    }
  ];
}
