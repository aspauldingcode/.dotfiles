{ config, lib, inputs, ... }:
let
  # Verifying that each file exists and is correctly imported
  shell = import ./shell.nix;
  terminal = import ./terminal.nix;

  secrets = import ./secrets.nix;
  styling = import ./styling.nix;
  apps = import ./apps/common.nix;
  cursor = import ./apps/cursor.nix;
  antigravity = import ./apps/antigravity.nix;
  ghostty = import ./apps/ghostty.nix;
  beeper = import ./apps/beeper.nix;
  jetbrains = import ./apps/jetbrains.nix;
  vscode = import ./apps/vscode.nix;
  spotify = import ./apps/spotify.nix;
  vesktop = import ./apps/vesktop.nix;
  dock = import ./dock.nix;
  microvm = import ./microvm.nix { inherit inputs; };
  wallpaper = import ./apps/wallpaper.nix;
  mas = import ./apps/mas.nix;
  python = import ./python.nix;
  maintenance = import ./darwin-maintenance.nix;
  editor = import ./editor.nix { inherit inputs; };
  opencode_dummy = import ./opencode_dummy.nix { inherit inputs; };
  qt_dummy = import ./qt_dummy.nix { inherit inputs; };
in
{
  # ── Options ──────────────────────────────────────────────────
  options.flake.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.unspecified);
    default = {};
  };

  # ── Manual Module Imports (Bypassing Ghost Files) ───────────
  imports = [
    ./dock.nix
    ./microvm.nix
    ./terminal.nix

    ./linux-desktop.nix
    ./shell.nix
    ./python.nix
    ./overlays.nix
    ./secrets.nix
    ./mobile.nix
    ./apps/common.nix
    ./apps/jetbrains.nix
    ./apps/vscode.nix
    ./apps/cursor.nix
    ./apps/antigravity.nix
    ./apps/ghostty.nix
    ./apps/spotify.nix
    ./apps/vesktop.nix
    ./apps/beeper.nix
    ./apps/mas.nix
    ./apps/wallpaper.nix
    ./darwin-maintenance.nix
    ./editor.nix
  ];

  config = {
    flake = {
      # ── Module Exports ────────────────────────────────────────
      # These must match exactly what inputs.self.modules expects in host configs
      nixosModules = {
        shell = shell.flake.modules.nixos.shell;
        wallpaper = wallpaper.flake.modules.nixos.wallpaper;
        styling = styling.flake.modules.nixos.styling;
        linux-desktop = (import ./linux-desktop.nix).flake.modules.nixos.linux-desktop;
        python = python.flake.modules.nixos.python;
      };

      darwinModules = {
        dock = dock.flake.modules.darwin.dock;
        shell = shell.flake.modules.darwin.shell;
        secrets = secrets.flake.modules.darwin.secrets;
        styling = styling.flake.modules.darwin.styling;
        apps = apps.flake.modules.darwin.apps;
        wallpaper = wallpaper.flake.modules.darwin.wallpaper;
        mas = mas.flake.modules.darwin.mas;
        microvm = microvm.config.flake.modules.darwin.microvm;
        maintenance = maintenance.flake.modules.darwin.maintenance;
        python = python.flake.modules.darwin.python;
      };

      homeManagerModules = {
        shell = shell.flake.modules.homeManager.shell;
        terminal = terminal.flake.modules.homeManager.terminal;
        editor = editor.flake.modules.homeManager.editor;
        opencode = opencode_dummy.flake.modules.homeManager.opencode;
        qt = qt_dummy.flake.modules.homeManager.qt;

        secrets = secrets.flake.modules.homeManager.secrets;
        styling = styling.flake.modules.homeManager.styling;
        apps = apps.flake.modules.homeManager.apps;
        cursor = cursor.flake.modules.homeManager.cursor;
        antigravity = antigravity.flake.modules.homeManager.antigravity;
        ghostty = ghostty.flake.modules.homeManager.ghostty;
        beeper = beeper.flake.modules.homeManager.beeper;
        jetbrains = jetbrains.flake.modules.homeManager.jetbrains;
        vscode = vscode.flake.modules.homeManager.vscode;
        spotify = spotify.flake.modules.homeManager.spotify;
        vesktop = vesktop.flake.modules.homeManager.vesktop;
        wallpaper = wallpaper.flake.modules.homeManager.wallpaper;
        python = python.flake.modules.homeManager.python;
        linux-desktop = (import ./linux-desktop.nix).flake.modules.homeManager.linux-desktop;
      };

      # ── Host Configurations (Dendritic Composition) ───────────
      darwinConfigurations = {
        mba = inputs.nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; };
          modules = [ 
            { nixpkgs.config.allowUnsupportedSystem = true; }
            ../hosts/darwin/mba 
          ];
        };
      };

      nixosConfigurations = {
        nixos-test = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ../hosts/nixos/nixos-test ];
        };

        mba-asahi = inputs.nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [ ../hosts/nixos/mba-asahi ];
        };
      };

      homeConfigurations = {
        "8amps-linux" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
          };
          extraSpecialArgs = { inherit inputs; };
          modules = [ ../hosts/hm/8amps-linux ];
        };
      };

      systemConfigs = {
        linux-generic = inputs.system-manager.lib.makeSystemConfig {
          specialArgs = { inherit inputs; };
          modules = [ ../hosts/system-manager/linux-generic ];
        };
      };
    };
  };
}
