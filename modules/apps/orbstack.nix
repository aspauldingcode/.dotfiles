# OrbStack via nixpkgs (unfree .app) + NixOS guest used as a Wayland
# client farm for Wawona (waypipe-rs ≥ 0.11).
#
# Vendor /Applications/OrbStack.app and /Applications/UTM.app are retired
# on activate — Linux guests on this Mac go through OrbStack, not UTM.
# (iOS/iPadOS UTM SE in wwn-vms is a different product lane; leave it.)
# Create/apply the guest with: dendritic-orb-wawona-ensure
{
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.orbstack;
      userHome = config.users.users.${config.system.primaryUser}.home;
    in
    {
      options.dendritic.apps.orbstack = {
        enable = lib.mkEnableOption "OrbStack from nixpkgs (replaces vendor /Applications copy)";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.orbstack ];

        system.activationScripts.dendriticOrbstack.text = ''
          echo "dendritic.orbstack: retiring vendor /Applications/OrbStack.app if present"
          vendor="/Applications/OrbStack.app"
          if [ -e "$vendor" ]; then
            dest="$(readlink "$vendor" 2>/dev/null || true)"
            case "$dest" in
            /nix/store/*orbstack*) ;;
            *)
              /usr/bin/killall OrbStack "OrbStack Helper" 2>/dev/null || true
              rm -rf "$vendor"
              ;;
            esac
          fi
          for b in orb orbctl; do
            link="/usr/local/bin/$b"
            if [ -L "$link" ]; then
              t="$(readlink "$link" 2>/dev/null || true)"
              case "$t" in
              /Applications/OrbStack.app/*)
                rm -f "$link"
                ;;
              esac
            fi
          done

          echo "dendritic.orbstack: retiring UTM.app leftovers (OrbStack owns Linux guests)"
          /usr/bin/killall UTM utmctl 2>/dev/null || true
          for utm in /Applications/UTM.app "${userHome}/Applications/UTM.app"; do
            if [ -e "$utm" ]; then
              rm -rf "$utm"
            fi
          done
          for b in utmctl; do
            for link in "/usr/local/bin/$b" "/opt/homebrew/bin/$b"; do
              if [ -e "$link" ] || [ -L "$link" ]; then
                rm -f "$link"
              fi
            done
          done
          rm -rf \
            "${userHome}/Library/Containers/com.utmapp.UTM" \
            "${userHome}/Library/Containers/com.utmapp.QEMUHelper" \
            "${userHome}/Library/Containers/com.utmapp.UTM-SE" \
            "${userHome}/Library/Preferences/com.utmapp.UTM.plist" \
            "${userHome}/Library/Application Support/com.utmapp.UTM" \
            "${userHome}/Library/Caches/com.utmapp.UTM" \
            || true
        '';
      };
    };

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.orbstack;
      orbHelper = "${pkgs.orbstack}/Applications/OrbStack.app/Contents/Frameworks/OrbStack Helper.app/Contents/MacOS/OrbStack Helper";
      orbUid = "503";
      ensureBin = pkgs.writeShellApplication {
        name = "dendritic-orb-wawona-ensure";
        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          orbstack
        ];
        text = ''
          set -euo pipefail
          exec bash ${../../scripts/dendritic-orb-wawona-ensure.sh} "$@"
        '';
      };
    in
    {
      options.dendritic.apps.orbstack = {
        enable = lib.mkEnableOption "OrbStack CLI + wawona NixOS VM ensure";
        machineName = lib.mkOption {
          type = lib.types.str;
          default = "wawona";
          description = "OrbStack Linux machine name (DNS: <name>.orb.local).";
        };
        linuxUser = lib.mkOption {
          type = lib.types.str;
          default = "alex";
          description = "Linux username inside the OrbStack guest (not the Mac account).";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          pkgs.orbstack
          ensureBin
        ];

        home.sessionVariables.ORB_WAWONA_MACHINE = cfg.machineName;
        home.sessionVariables.ORB_WAWONA_USER = cfg.linuxUser;

        # OrbStack SSH is 127.0.0.1:32222 + Helper proxy, not *.orb.local:22.
        programs.ssh.enable = true;
        programs.ssh.includes = [ "${config.home.homeDirectory}/.orbstack/ssh/config" ];
        programs.ssh.settings."wawona wawona.orb.local orb-wawona" = {
          HostName = "127.0.0.1";
          Port = "32222";
          User = "${cfg.linuxUser}@${cfg.machineName}";
          IdentityFile = "${config.home.homeDirectory}/.orbstack/ssh/id_ed25519";
          IdentitiesOnly = true;
          UserKnownHostsFile = "${config.home.homeDirectory}/.orbstack/ssh/known_hosts";
          ProxyCommand = "'${orbHelper}' ssh-proxy-fdpass ${orbUid}";
          ProxyUseFdpass = "yes";
          ForwardAgent = true;
        };

        launchd.agents.dendritic-orbstack = {
          enable = true;
          config = {
            Label = "com.aspauldingcode.dendritic-orbstack";
            ProgramArguments = [
              "/usr/bin/open"
              "-a"
              "${pkgs.orbstack}/Applications/OrbStack.app"
            ];
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "${config.home.homeDirectory}/.cache/dendritic-orbstack.log";
            StandardErrorPath = "${config.home.homeDirectory}/.cache/dendritic-orbstack.err.log";
          };
        };
      };
    };
}
