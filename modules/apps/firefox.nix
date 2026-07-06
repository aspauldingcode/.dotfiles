{ lib, ... }:
let
  # ── Home Manager Firefox module (let-bound; mirrored to flake-parts + den) ──
  firefoxHmModule =
    {
      pkgs,
      inputs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.dendritic.apps.firefox;

      # Firefox maps each install path to a profile via installs.ini. The hash
      # is the first 16 uppercase hex chars of SHA-256 over the install dir
      # (Darwin: .../Firefox.app/Contents/MacOS, Linux: .../bin).
      pathInstallHash = path: lib.toUpper (lib.substring 0 16 (builtins.hashString "sha256" path));
    in
    {
      options.dendritic.apps.firefox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable declarative Firefox (HM + Darwin dock + signing).";
        };
      };

      config = lib.mkIf cfg.enable {
        # We precompute hashes for all known path variants and map each to the
        # single declarative `Profiles/default` profile with Locked=1.
        home.activation.setupFirefoxProfile =
          let
            ffDir = if pkgs.stdenv.isDarwin then "Library/Application Support/Firefox" else ".mozilla/firefox";
            profilePath = "Profiles/default";
            packageInstallDir =
              if pkgs.stdenv.isDarwin then
                "${config.programs.firefox.package}/Applications/Firefox.app/Contents/MacOS"
              else
                "${config.programs.firefox.package}/bin";
            packageInstallHash = pathInstallHash packageInstallDir;
            overlayInstallHash =
              if pkgs.stdenv.isDarwin then
                pathInstallHash "${(inputs.firefox-darwin.overlay pkgs pkgs).firefox-bin}/Applications/Firefox.app/Contents/MacOS"
              else
                "";
            precomputedHashes =
              lib.concatStringsSep " " (lib.filter (h: h != "") [
                packageInstallHash
                overlayInstallHash
              ]);
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                      _ffDir="$HOME/${ffDir}"
                      _installsIni="$_ffDir/installs.ini"
                      _hashesFile="$(${pkgs.coreutils}/bin/mktemp)"
                      mkdir -p "$_ffDir"

                      _add_hash_for_path() {
                        _candidate="$1"
                        [ -n "$_candidate" ] || return 0
                        ${pkgs.python3}/bin/python3 - "$_candidate" >> "$_hashesFile" <<'PY'
            import hashlib
            import sys
            path = sys.argv[1]
            print(hashlib.sha256(path.encode("utf-8")).hexdigest()[:16].upper())
            PY
                      }

                      # Pin the declarative HM package (and Darwin overlay bundle).
                      for _hash in ${precomputedHashes}; do
                        printf '%s\n' "$_hash" >> "$_hashesFile"
                      done

                      ${lib.optionalString pkgs.stdenv.isDarwin ''
                      # HM app bundle: hash both the user-facing path and the store target.
                      _ffApp="$HOME/Applications/Home Manager Apps/Firefox.app"
                      if [ -e "$_ffApp" ]; then
                        _add_hash_for_path "$_ffApp/Contents/MacOS"
                        if [ -L "$_ffApp" ]; then
                          _ffTarget="$(${pkgs.coreutils}/bin/readlink "$_ffApp")"
                          _add_hash_for_path "$_ffTarget/Contents/MacOS"
                        fi
                      fi
                      ''}

                      if command -v firefox >/dev/null 2>&1; then
                        _ffBin="$(command -v firefox)"
                        _add_hash_for_path "$(${pkgs.coreutils}/bin/dirname "$_ffBin")"

                        _ffBinReal="$(${pkgs.coreutils}/bin/readlink -f "$_ffBin" 2>/dev/null || true)"
                        if [ -n "$_ffBinReal" ]; then
                          _add_hash_for_path "$(${pkgs.coreutils}/bin/dirname "$_ffBinReal")"
                        fi

                        # Nix firefox wrappers usually exec a store binary; include that path.
                        _execTarget="$(${pkgs.gawk}/bin/awk -F'"' '/^exec "/ { print $2; exit }' "$_ffBin" 2>/dev/null || true)"
                        if [ -n "$_execTarget" ]; then
                          _add_hash_for_path "$(${pkgs.coreutils}/bin/dirname "$_execTarget")"
                        fi
                      fi

                      if [ -s "$_hashesFile" ]; then
                        {
                          ${pkgs.coreutils}/bin/sort -u "$_hashesFile" \
                            | ${pkgs.gawk}/bin/awk '
                              {
                                printf("[%s]\nDefault=${profilePath}\nLocked=1\n\n", $1)
                              }
                            '
                        } > "$_installsIni"
                      fi

                      rm -f "$_hashesFile"

                      # Remove stale lock files left by crashes → prevents "profile inaccessible"
                      find "$_ffDir/Profiles" -maxdepth 2 \
                        \( -name ".parentlock" -o -name "lock" \) \
                        -delete 2>/dev/null || true
          '';

        programs.firefox = {
          # Avoid forcing Linux Firefox builds from a Darwin builder for the embedded microvm.
          # Native Linux/NixOS systems still get the declarative Firefox setup.
          enable =
            pkgs.stdenv.isDarwin || (pkgs.stdenv.buildPlatform.system == pkgs.stdenv.hostPlatform.system);
          package =
            if pkgs.stdenv.isDarwin then
              pkgs.firefox-bin.overrideAttrs (old: {
                src = (inputs.firefox-darwin.overlay pkgs pkgs).firefox-bin.src;
              })
            else if pkgs.stdenv.hostPlatform.isAarch64 then
              pkgs.firefox
            else
              pkgs.firefox-bin;

          # Pin the profile directory to the current effective location on each
          # platform. HM 26.05 flips the Linux default to
          # `$XDG_CONFIG_HOME/mozilla/firefox` for stateVersion >= 26.05; we
          # stay on the legacy `.mozilla/firefox` (matching the activation
          # script's `ffDir`) and set it explicitly to silence the warning.
          configPath =
            if pkgs.stdenv.isDarwin then "Library/Application Support/Firefox" else ".mozilla/firefox";

          profiles.default = {
            id = 0;
            name = "default";
            path = "default";
            isDefault = true;
            settings = {
              # Firefox updates are managed by nixpkgs only.
              "app.update.auto" = false;
              "app.update.enabled" = false;
              "app.update.service.enabled" = false;
              "app.update.silent" = false;

              "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
              "browser.tabs.drawInTitlebar" = true;
              "svg.context-properties.content.enabled" = true;

              # Disable Telemetry
              "datareporting.healthreport.uploadEnabled" = false;
              "datareporting.policy.dataSubmissionEnabled" = false;
              "toolkit.telemetry.enabled" = false;
              "toolkit.telemetry.unified" = false;
              "toolkit.telemetry.server" = "data:,";
              "toolkit.telemetry.archive.enabled" = false;
              "toolkit.telemetry.newProfilePing.enabled" = false;
              "toolkit.telemetry.shutdownPingSender.enabled" = false;
              "toolkit.telemetry.updatePing.enabled" = false;
              "toolkit.telemetry.bhrPing.enabled" = false;
              "toolkit.telemetry.firstShutdownPing.enabled" = false;
              "toolkit.telemetry.coverage.opt-out" = true;
              "toolkit.coverage.opt-out" = true;
              "toolkit.coverage.endpoint.base" = "";
              "browser.ping-centre.telemetry" = false;
              "browser.newtabpage.activity-stream.feeds.telemetry" = false;
              "browser.newtabpage.activity-stream.telemetry" = false;
            };
          };
          policies = {
            DisableAppUpdate = true;
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            DisablePocket = true;
            ExtensionSettings = {
              "uBlock0@raymondhill.net" = {
                installation_mode = "force_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
              };
              "youtube-windowed-fullscreen@navi-jador" = {
                installation_mode = "force_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-windowed-fullscreen/latest.xpi";
              };
              "sponsorBlocker@ajay.app" = {
                installation_mode = "force_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
              };
              "addon@darkreader.org" = {
                installation_mode = "force_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
              };
              "momentum@momentumdash.com" = {
                installation_mode = "force_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/momentumdash/latest.xpi";
              };
            }
            # iCloud Passwords requires the macOS Keychain bridge (Apple's
            # native messaging host shipped with macOS Sonoma+), so the
            # extension is useful only on Darwin. Force-installed via
            # Firefox enterprise policy, the same way every other extension
            # in this profile is delivered.
            // lib.optionalAttrs pkgs.stdenv.isDarwin {
              "password-manager-firefox-extension@apple.com" = {
                installation_mode = "force_installed";
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/icloud-passwords/latest.xpi";
              };
            };
          };
        };

        # Adhoc-sign the HM-managed Firefox.app on Darwin when it is a writable
        # local bundle. HM usually symlinks into /nix/store; those bundles are
        # already adhoc-signed at build time and `--deep` re-signing fails on
        # read-only store Mach-O (e.g. XUL, stale `.firefox-old` backups).
        home.activation.signFirefoxApp = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            _ffApp="$HOME/Applications/Home Manager Apps/Firefox.app"
            if [ ! -e "$_ffApp" ]; then
              :
            elif [ -L "$_ffApp" ]; then
              _ffTarget="$(${pkgs.coreutils}/bin/readlink "$_ffApp")"
              case "$_ffTarget" in
                /nix/store/*) ;;
                *)
                  rm -f "$_ffTarget/Contents/MacOS/.firefox-old" 2>/dev/null || true
                  /usr/bin/codesign --force --sign - "$_ffTarget"
                  ;;
              esac
            elif [ -d "$_ffApp" ]; then
              rm -f "$_ffApp/Contents/MacOS/.firefox-old" 2>/dev/null || true
              /usr/bin/codesign --force --sign - "$_ffApp"
            fi
          ''
        );
      };
    };

  # ── nix-darwin Firefox module (let-bound; mirrored to flake-parts + den) ──
  # Pins Firefox.app into the dock at order 100 when the HM toggle is on.
  firefoxDarwinModule =
    {
      inputs,
      lib,
      pkgs,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      firefoxEnabled = config.home-manager.users.${user}.dendritic.apps.firefox.enable or true;
      firefoxPackage = config.home-manager.users.${user}.programs.firefox.package;
    in
    lib.mkIf firefoxEnabled {
      # Use the same HM-managed package as installs.ini so dock launches match
      # the pinned profile hash instead of a separate overlay store path.
      dendritic.dock.apps = lib.mkOrder 100 [
        "${firefoxPackage}/Applications/Firefox.app"
      ];
    };
in
{
  # ── Flake-parts dendritic exports (consumed by embedded HM + Darwin users) ──
  # The darwin/nixos host files import `inputs.self.modules.<class>.dendritic`
  # which merges every contribution to `flake.modules.<class>.dendritic`. The
  # firefox modules below get picked up via that path.
  flake.modules.homeManager.dendritic = firefoxHmModule;
  flake.modules.darwin.dendritic = firefoxDarwinModule;

  # ── Den aspect (future-proofing for den.homes / aspect includes) ────────
  # Same modules exposed as a named aspect so any future `den.homes.*`
  # consumer or host aspect can `includes = [ config.den.aspects.firefox ]`
  # to pick up firefox declaratively without going through the dendritic
  # monolith.
  den.aspects.firefox = {
    homeManager = firefoxHmModule;
    darwin = firefoxDarwinModule;
  };
}
