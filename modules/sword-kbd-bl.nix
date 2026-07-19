# Sword 15 keyboard backlight: HID userspace tool + Windows RE capture staging.
# Never enables msi-ec kbd LED / EC writes (see hosts/nixos/sliceanddice patch).
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.swordKbdBl;
      swordKbdBl = pkgs.callPackage ./pkgs/_dendritic-sword-kbd-bl.nix { };
      stageKbdRe = pkgs.writeShellApplication {
        name = "dendritic-windows-stage-kbd-re";
        runtimeInputs = with pkgs; [ coreutils ];
        text = builtins.readFile ./pkgs/_dendritic-windows-stage-kbd-re.sh;
      };
      scriptsDir = pkgs.runCommand "sword-kbd-bl-capture-scripts" { } ''
        mkdir -p "$out"
        cp -a ${../scripts/sword-kbd-bl}/. "$out/"
      '';
    in
    {
      options.dendritic.swordKbdBl = {
        enable = lib.mkEnableOption "Sword 15 keyboard backlight HID tool + Windows RE capture staging";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          swordKbdBl
          stageKbdRe
        ];

        # uaccess for classic MSIKLM + SteelSeries MSI factory / KLC PIDs.
        services.udev.extraRules = ''
          # MSIKLM region RGB (prior art)
          KERNEL=="hidraw*", ATTRS{idVendor}=="1770", ATTRS{idProduct}=="ff00", MODE="0660", TAG+="uaccess"
          # SteelSeries VID — factory 20xx + KLC (narrower TAG; tool probes PIDs)
          KERNEL=="hidraw*", ATTRS{idVendor}=="1038", MODE="0660", TAG+="uaccess"
        '';

        systemd.services.dendritic-windows-stage-kbd-re = lib.mkIf config.dendritic.windows.enable {
          description = "Stage Sword kbd-backlight RE capture scripts onto Windows volume";
          wantedBy = [ "multi-user.target" ];
          after = [ "local-fs.target" ];
          unitConfig.ConditionPathExists = "${config.dendritic.windows.mountPoint}/Windows";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${stageKbdRe}/bin/dendritic-windows-stage-kbd-re";
          };
          environment = {
            DENDRITIC_WINDOWS_MOUNT = config.dendritic.windows.mountPoint;
            DENDRITIC_KBD_RE_SCRIPTS = "${scriptsDir}";
          };
        };
      };
    };
}
