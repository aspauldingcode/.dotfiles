# ── Dendritic profile photo (macOS + NixOS) ─────────────────────────────
#
# Single source: assets/profile_square.jpg (copied from portfolio).
# When enabled:
#   • NixOS  — AccountsService icon + ~/.face (gtk auth)
#   • macOS  — root launchd enforces Picture + JPEGPhoto so reboot cannot forget
#   • Auth UI — gtkgreet/gtklock glass CSS shows the same circular avatar
#
let
  mkProcessed =
    pkgs: source:
    pkgs.runCommand "dendritic-profile.jpg"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
        # Keep path context so flakes copy assets/ into the builder.
        src = source;
      }
      ''
        magick "$src" \
          -auto-orient \
          -resize '512x512^' \
          -gravity center -extent 512x512 \
          -strip \
          -quality 92 \
          JPEG:"$out"
      '';
in
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.profilePhoto;
      processed = mkProcessed pkgs cfg.source;
      appearanceBin = lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { });
    in
    {
      options.dendritic.profilePhoto = {
        enable = lib.mkEnableOption "Declarative profile photo (OS account + gtk auth)";

        source = lib.mkOption {
          type = lib.types.path;
          default = ../../assets/profile_square.jpg;
          description = "Square profile photo (repo-relative). Copied from portfolio.";
        };
      };

      config = lib.mkIf cfg.enable {
        xdg.configFile."dendritic/profile.jpg".source = processed;

        home.file.".face" = lib.mkIf pkgs.stdenv.isLinux { source = processed; };
        home.file.".face.icon" = lib.mkIf pkgs.stdenv.isLinux { source = processed; };

        home.sessionVariables.DENDRITIC_PROFILE_IMAGE = "${processed}";

        home.activation.dendriticProfilePhoto = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          echo "dendritic-appearance: avatar (user)"
          export DENDRITIC_HOME="${config.home.homeDirectory}"
          export DENDRITIC_USER="${config.home.username}"
          export DENDRITIC_PROFILE_IMAGE="${processed}"
          mkdir -p "${config.home.homeDirectory}/Library/Application Support/dendritic" 2>/dev/null || true
          mkdir -p "${config.home.homeDirectory}/.local/state/dendritic" 2>/dev/null || true
          $DRY_RUN_CMD ${appearanceBin} avatar apply \
            --user "${config.home.username}" \
            --image "${processed}" || true
        '';
      };
    };

  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.profilePhoto;
      processed = mkProcessed pkgs cfg.source;
      users = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser or false) config.users.users);
      appearanceBin = lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { });
    in
    {
      options.dendritic.profilePhoto = {
        enable = lib.mkEnableOption "Declarative profile photo (AccountsService + gtk auth)";

        source = lib.mkOption {
          type = lib.types.path;
          default = ../../assets/profile_square.jpg;
        };
      };

      config = lib.mkIf cfg.enable {
        services.accounts-daemon.enable = true;

        environment.etc."dendritic/profile.jpg".source = processed;

        system.activationScripts.dendriticProfilePhoto = lib.stringAfter [ "users" ] ''
          install -Dm644 ${processed} /etc/dendritic/profile.jpg
          ${lib.concatMapStrings (u: ''
            install -Dm644 ${processed} /var/lib/AccountsService/icons/${u}
            mkdir -p /var/lib/AccountsService/users
            printf '%s\n' '[User]' 'Session=' 'Icon=/var/lib/AccountsService/icons/${u}' 'SystemAccount=false' \
              > /var/lib/AccountsService/users/${u}
            DENDRITIC_HOME=/home/${u} DENDRITIC_USER=${u} ${appearanceBin} avatar apply \
              --user ${u} --image ${processed} || true
          '') users}
        '';
      };
    };

  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.profilePhoto;
      processed = mkProcessed pkgs cfg.source;
      appearanceBin = lib.getExe (pkgs.callPackage ./dendritic-appearance/_package.nix { });
      user = config.system.primaryUser or "";
    in
    {
      options.dendritic.profilePhoto = {
        enable = lib.mkEnableOption "Declarative macOS profile photo (Picture + JPEGPhoto)";

        source = lib.mkOption {
          type = lib.types.path;
          default = ../../assets/profile_square.jpg;
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = user != "";
            message = "dendritic.profilePhoto requires system.primaryUser on darwin";
          }
        ];

        environment.etc."dendritic/profile.jpg".source = processed;

        launchd.daemons.dendritic-avatar = {
          script = ''
            set -euo pipefail
            export PATH="/usr/bin:/bin:/usr/sbin:/sbin"
            export DENDRITIC_USER="${user}"
            export DENDRITIC_HOME="/Users/${user}"
            export DENDRITIC_PROFILE_IMAGE="/etc/dendritic/profile.jpg"
            ${appearanceBin} avatar apply --user "${user}" --image "/etc/dendritic/profile.jpg"
          '';
          serviceConfig = {
            Label = "com.aspauldingcode.dendritic-avatar";
            RunAtLoad = true;
            StartInterval = 1800;
            StandardOutPath = "/var/log/dendritic-avatar.log";
            StandardErrorPath = "/var/log/dendritic-avatar.err.log";
          };
        };
      };
    };
}
