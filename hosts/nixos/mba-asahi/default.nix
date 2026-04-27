{ inputs, pkgs, lib, ... }:

{
  imports = [
    # 1. Base identity and platform
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "24.11";
      
      # Stub kernel for CI to avoid building Asahi kernel in QEMU
      boot.kernelPackages = lib.mkIf (pkgs.stdenv.buildPlatform.system != pkgs.stdenv.hostPlatform.system) (lib.mkForce pkgs.linuxPackages_latest);

      users.users."8amps" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };

      fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "ext4"; };
      fileSystems."/boot" = { device = "/dev/disk/by-label/boot"; fsType = "vfat"; };
      fileSystems."/boot/asahi" = { device = "/dev/disk/by-label/asahi"; fsType = "vfat"; };
      hardware.asahi.extractPeripheralFirmware = false; # Bypass check for evaluation
    }

    # 2. Support modules
    inputs.apple-silicon.nixosModules.apple-silicon-support
    inputs.home-manager.nixosModules.home-manager

    # 3. Pull in Feature Modules from the Hub
    inputs.self.modules.nixos.shell
    inputs.self.modules.nixos.secrets
    inputs.self.modules.nixos.styling
    inputs.self.modules.nixos.linux-desktop
    inputs.self.modules.nixos.microvm

    # 4. Configure Home Manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users."8amps" = { pkgs, lib, ... }: {
        imports = [
          inputs.self.modules.homeManager.shell
          inputs.self.modules.homeManager.editor
          inputs.self.modules.homeManager.secrets
          inputs.self.modules.homeManager.styling
          inputs.self.modules.homeManager.ghostty
          inputs.self.modules.homeManager.antigravity
          inputs.self.modules.homeManager.wallpaper
          inputs.self.modules.homeManager.spotify
          # zen-browser's stylix integration unconditionally references
          # stylix.generated.palette (an IFD), which forces palette-generator
          # to be built under QEMU emulation. Skip apps on cross-compile.
        ] ++ pkgs.lib.optional
          (pkgs.stdenv.buildPlatform.system == pkgs.stdenv.hostPlatform.system)
          inputs.self.modules.homeManager.apps;
        home.username = "8amps";
        home.homeDirectory = "/home/8amps";
        home.stateVersion = "24.11";

        # ── Feature Toggles ─────────────────────────────────────────
        dendritic.apps.ghostty.enable = true;
        dendritic.apps.antigravity.enable = true;

        # When cross-compiling (e.g. x86 CI building ARM), bypass stylix palette
        # IFD by providing the base16 scheme directly. This prevents palette-generator
        # (a Haskell binary) from being built under QEMU, which always fails.
        stylix.image = lib.mkIf
          (pkgs.stdenv.buildPlatform.system != pkgs.stdenv.hostPlatform.system)
          (lib.mkForce null);
        stylix.base16Scheme = lib.mkIf
          (pkgs.stdenv.buildPlatform.system != pkgs.stdenv.hostPlatform.system)
          (lib.mkForce "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml");
        # ─────────────────────────────────────────────────────────────
      };
    }
  ];
}
