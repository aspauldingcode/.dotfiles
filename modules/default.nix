{ config, lib, inputs, ... }:
let
  # Direct imports of modules
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
  microvm_mod = import ./microvm.nix { inherit inputs; };
  wallpaper = import ./apps/wallpaper.nix;
  mas = import ./apps/mas.nix;
  python = import ./python.nix;
  maintenance = import ./darwin-maintenance.nix;
  editor = import ./editor.nix { inherit inputs; };
  opencode = import ./opencode_dummy.nix { inherit inputs; };
  qt = import ./qt_dummy.nix { inherit inputs; };
  linux-desktop = import ./linux-desktop.nix;
in
{
  imports = [
    ./overlays.nix
    ./mobile.nix
  ];

  config = {
    flake = {
      nixosModules = {
        shell = shell.flake.modules.nixos.shell;
        wallpaper = wallpaper.flake.modules.nixos.wallpaper;
        styling = styling.flake.modules.nixos.styling;
        linux-desktop = linux-desktop.flake.modules.nixos.linux-desktop;
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
        microvm = microvm_mod.config.flake.modules.darwin.microvm;
        maintenance = maintenance.flake.modules.darwin.maintenance;
        python = python.flake.modules.darwin.python;
      };

      homeManagerModules = {
        shell = shell.flake.modules.homeManager.shell;
        terminal = terminal.flake.modules.homeManager.terminal;
        editor = editor;
        opencode = opencode;
        qt = qt;

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
        theme = import ./theme.nix;
        linux-desktop = linux-desktop.flake.modules.homeManager.linux-desktop;
      };

      darwinConfigurations.mba = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [ { nixpkgs.config.allowUnsupportedSystem = true; } ../hosts/darwin/mba ];
      };

      nixosConfigurations = {
        # microvm = microvm_mod.config.flake.nixosConfigurations.microvm;
      };

      homeConfigurations."8amps-linux" = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
          };
        };
        extraSpecialArgs = { inherit inputs; };
        modules = [ ../hosts/hm/8amps-linux ];
      };
    };
  };
}
