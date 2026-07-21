{ lib, ... }:
let
  # ── Pure helpers (shared by HM + Darwin modules) ─────────────────────
  # Converts a 2-char lowercase hex string to an integer (0-255).
  hexDigits = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };

  hexToDec =
    hex:
    let
      chars = lib.stringToCharacters (lib.toLower hex);
    in
    builtins.foldl' (acc: ch: acc * 16 + hexDigits.${ch}) 0 chars;

  hexToRgb = hex: [
    (hexToDec (builtins.substring 0 2 hex))
    (hexToDec (builtins.substring 2 2 hex))
    (hexToDec (builtins.substring 4 2 hex))
  ];

  # Build a Chrome/Brave theme manifest.json with all base16 color slots.
  # `c` is a base16 palette: { base00 = "rrggbb"; ...; base0F = "rrggbb"; }
  # (lower-case hex without leading '#').
  #
  # `version` is a Chromium-valid version string ("X.Y[.Z[.W]]" with each
  # component 0–65535). Derive it from the palette hash via
  # `mkBraveThemeVersion` so each variant's CRX has a distinct version and
  # Brave's External Extensions loader installs/swaps it cleanly.
  mkBraveManifest =
    themeName: version: c:
    builtins.toJSON {
      manifest_version = 3;
      name = "Stylix ${themeName}";
      version = version;
      theme.colors = {
        frame = hexToRgb c.base00; # titlebar active
        frame_inactive = hexToRgb c.base00; # titlebar inactive
        toolbar = hexToRgb c.base01; # tab strip + omnibox bg
        tab_text = hexToRgb c.base06; # active tab text
        tab_background_text = hexToRgb c.base04; # inactive tab text
        background_tab_text = hexToRgb c.base04; # background tab text
        bookmark_text = hexToRgb c.base05; # bookmark bar text
        ntp_background = hexToRgb c.base00; # new tab page background
        ntp_text = hexToRgb c.base05; # new tab page text
        ntp_link = hexToRgb c.base0D; # new tab page links (accent)
        ntp_section = hexToRgb c.base01; # NTP card/section bg
        ntp_section_text = hexToRgb c.base05; # NTP card text
        ntp_section_link = hexToRgb c.base0D; # NTP card links
        omnibox_background = hexToRgb c.base01; # address bar background
        omnibox_text = hexToRgb c.base05; # address bar text
        button_background = hexToRgb c.base01; # toolbar button bg
        control_background = hexToRgb c.base01; # general control bg
      };
    };

  # ── Stable constants ───────────────────────────────────────────────
  braveDefaultUpdateUrl = "https://clients2.google.com/service/update2/crx";

  # Legacy Chromium extension IDs the activation cleanup loop wipes so
  # rebuilds from older revisions of this module don't leave dead
  # CRX/External Extensions artifacts behind. These come from previous
  # delivery paths (CRX-signed theme key rotations, the abandoned
  # `--load-extension=$HOME/.brave-stylix-theme` flow whose ID was
  # derived from the $HOME path, etc.). The current delivery path is
  # `--load-extension=<braveThemeSourceDir>` which derives a fresh,
  # path-based ID per Stylix palette, so no current ID needs to be
  # pinned here.
  braveLegacyThemeExtIds = [
    "hogbnhnlblglmhabmimehnofpnafnmle"
    "aepmofgifbmpldjgfgojkeiedalilblg"
    "ddkjecaebecekiijgeokobnjphlglake"
    "mnjggpindoocnndabpppocagnlbhbggn"
    "eimadpbcbfnmbkpkfnekohlhhenbhjje"
    # Last CRX-signed theme ID (pre-cleanup). Held here so a generation
    # rolled forward from that revision still scrubs its on-disk
    # artifacts; safe to remove once no rollback target references it.
    "lnemcieeceadiagiepafbahmiojdckln"
  ];

  # Derive a Chromium-valid 4-component version string ("1.A.B.C" with each
  # of A/B/C in [0, 65535]) from a content hash so light/dark variants
  # produce distinct, deterministic CRX versions. Brave's External
  # Extensions loader installs whichever version the JSON points at,
  # regardless of whether it's higher or lower than the previously
  # installed version (the file system is implicitly trusted).
  mkBraveThemeVersion =
    content:
    let
      h = builtins.hashString "sha256" content;
      a = hexToDec (builtins.substring 0 4 h);
      b = hexToDec (builtins.substring 4 4 h);
      c = hexToDec (builtins.substring 8 4 h);
    in
    "1.${toString a}.${toString b}.${toString c}";

  # Force-installed Brave extensions (uBlock Origin Lite, YT Windowed
  # Fullscreen, SponsorBlock, Dark Reader, Momentum). These are pulled from
  # the Chrome Web Store via `update_url` policy entries.
  braveExtensions = [
    {
      id = "ddkjiahejlhfcafbddmgiahcphecmpfh";
      updateUrl = braveDefaultUpdateUrl;
    } # uBlock Origin Lite
    {
      id = "gkkmiofalnjagdcjheckamobghglpdpm";
      updateUrl = braveDefaultUpdateUrl;
    } # YouTube Windowed Fullscreen
    {
      id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      updateUrl = braveDefaultUpdateUrl;
    } # SponsorBlock
    {
      id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
      updateUrl = braveDefaultUpdateUrl;
    } # Dark Reader
    {
      id = "laookkfknpbbblfpciffpaejjkokdgca";
      updateUrl = braveDefaultUpdateUrl;
    } # Momentum
  ];

  braveForcelist = map (ext: "${ext.id};${ext.updateUrl or braveDefaultUpdateUrl}") braveExtensions;
  braveExtensionIds = map (ext: ext.id) braveExtensions;

  # When ExtensionSettings is present, ALL other extension policies
  # (ExtensionInstallAllowlist, ExtensionInstallBlocklist, etc.) are
  # superseded. Extensions NOT listed here would be blocked by Brave's
  # default managed-mode behavior. The "*" wildcard with "allowed" sets
  # the permissive default for unlisted extensions.
  braveExtensionSettings = {
    "*" = {
      installation_mode = "allowed";
    };
  }
  // builtins.listToAttrs (
    map (ext: {
      name = ext.id;
      value = {
        installation_mode = "force_installed";
        update_url = ext.updateUrl or braveDefaultUpdateUrl;
      };
    }) braveExtensions
  );

  # Convert a Stylix palette (config.lib.stylix.colors.withHashtag) to the
  # lowercase-hex-without-hash format expected by `mkBraveManifest`.
  paletteFromStylix =
    stylixColors: lib.mapAttrs (_: value: lib.toLower (lib.removePrefix "#" value)) stylixColors;

  # ── Theme delivery rationale ────────────────────────────────────────
  # We *don't* write the theme directly into Brave's `Preferences` or
  # `Secure Preferences`: those files are HMAC-tracked, and any external
  # write Brave didn't make itself triggers the pref-tamper reset dialog
  # ("Brave reset these settings — Extension(s)") on every launch.
  #
  # We *don't* use `--load-extension=<unpacked dir>` either: Chromium 137+
  # only honors that flag when Developer Mode is on in brave://extensions,
  # and the corresponding enterprise policy (ExtensionDeveloperModeSettings)
  # only supports Allow (0) and Disallow (1) — there is no "force-enable"
  # value, so it can't be made fully declarative.
  #
  # Instead we pack the Stylix manifest into a signed CRX3 archive in the
  # Nix store and register it as a per-profile *external extension* (drop
  # `<id>.json` with `external_crx` into the profile's `External Extensions/`
  # directory). Brave treats it as a regularly-installed extension — no
  # Developer Mode banner, no policy gymnastics, no manual toggling.

  # ── Home Manager Brave module (let-bound; mirrored to flake-parts + den) ──
  braveHmModule =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      themePalette = paletteFromStylix config.lib.stylix.colors.withHashtag;

      # Version derived from the variant's palette so each light/dark flip
      # produces a distinct CRX/manifest version. Brave installs whichever
      # the External Extensions JSON points at — no upgrade gating.
      braveThemeVersion = mkBraveThemeVersion (builtins.toJSON themePalette);

      # Manifest content is built at eval time (it has no secrets — just
      # palette colors). Only the *signing* step needs the decrypted PEM,
      # which happens at activation time below.
      braveThemeManifestJson = mkBraveManifest config.dendritic.theme.name braveThemeVersion themePalette;
      braveThemeManifestFile = pkgs.writeText "manifest.json" braveThemeManifestJson;

      # Source tree handed to the CRX packer: just a manifest.json today,
      # but the layout supports adding images/icons later without touching
      # the packer.
      braveThemeSourceDir = pkgs.runCommand "brave-stylix-theme-src" { } ''
        mkdir -p $out
        cp ${braveThemeManifestFile} $out/manifest.json
      '';

      # ── Stylix theme delivery (declarative, via --load-extension) ───
      # We deliver the theme as an UNPACKED extension loaded by Brave at
      # launch via `--load-extension=<dir>`. This gives the extension
      # Chromium's `Location::COMMAND_LINE`, which:
      #
      #   1. Bypasses the side-load disable gate that External
      #      Extensions JSON (`Location::EXTERNAL_PREF`) hits — i.e.
      #      `disable_reasons: [8192]` (`DISABLE_EXTERNAL_EXTENSION`)
      #      and the "Brave reset these settings — Extension(s)" alert.
      #   2. Bypasses Chromium's `force_installed` + `update_url`
      #      policy path's silent rejection of `file://` URLs (the
      #      policy fetcher only honors `http://` / `https://`, so any
      #      attempt to point at a local CRX is dead on arrival).
      #   3. Doesn't require Chromium-internal signing keys, sops-managed
      #      PEMs, or local HTTP servers serving a gupdate XML manifest.
      #
      # `braveThemeSourceDir` is a content-addressed Nix derivation
      # whose path changes when the Stylix palette (light vs. dark)
      # changes; the Mach-O stub below bakes that exact path into the
      # binary at build time. The appearance system prebuilds dark/light
      # variants, each with their own wrapper baked at their respective
      # palette, so an appearance flip = swap-prebuilt + restart Brave
      # = new theme dir loaded.
      braveLoadExtensionArg = "--load-extension=${braveThemeSourceDir}";

      # Single source of truth for Brave command-line args. Used by:
      #   1. `programs.brave.commandLineArgs` — works on Linux (HM's
      #      override fires for the source-built brave package).
      #   2. `braveWrapperBin` below — bakes the same args into the
      #      Mach-O stub on Darwin, because nixpkgs Brave on Darwin
      #      silently no-ops `pkgs.brave.override { commandLineArgs = ...; }`
      #      (the prebuilt .app derivation accepts but discards the
      #      override argument).
      braveCommandLineArgs = [
        # Suppress browser update polling/scheduling.
        "--check-for-update-interval=31536000"
        "--disable-updater-scheduler"
        # Stylix theme delivery (see braveLoadExtensionArg comment above).
        braveLoadExtensionArg
      ];

      # Compiled Mach-O stub for the Brave wrapper .app.
      # macOS 16+ requires the main executable to be a Mach-O binary;
      # shell scripts cause kLSNotAnApplicationErr (-10669) in Launch Services.
      #
      # The stub execs the HM-wrapped Brave binary and INJECTS the args
      # from `braveCommandLineArgs` ahead of any user-passed args, since
      # the upstream nixpkgs Darwin Brave wrapper drops them.
      braveWrapperBin =
        pkgs.runCommand "brave-wrapper-bin"
          {
            nativeBuildInputs = [ pkgs.stdenv.cc ];
          }
          ''
            cat > stub.c << 'EOF'
            #include <unistd.h>
            #include <stdio.h>
            #include <stdlib.h>
            #include <string.h>

            static const char *extra_args[] = {
              ${lib.concatMapStringsSep "\n              " (a: ''"${a}",'') braveCommandLineArgs}
            };
            static const int n_extra = (int)(sizeof(extra_args) / sizeof(extra_args[0]));

            int main(int argc, char *argv[]) {
                const char *user = getenv("USER");
                if (!user) user = "unknown";

                /* Exec the HM-wrapped Brave binary; nixpkgs's Darwin wrapper
                 * doesn't honor the HM `commandLineArgs` override, so we
                 * splice them in here ourselves. */
                char brave[512];
                snprintf(brave, sizeof(brave),
                    "/etc/profiles/per-user/%s/bin/brave", user);

                char **new_argv = malloc((argc + n_extra + 1) * sizeof(char *));
                if (!new_argv) return 1;
                int j = 0;
                new_argv[j++] = brave;
                for (int i = 0; i < n_extra; i++) new_argv[j++] = (char *)extra_args[i];
                for (int i = 1; i < argc; i++) new_argv[j++] = argv[i];
                new_argv[j] = NULL;

                execv(brave, new_argv);
                perror("execv brave");
                return 1;
            }
            EOF
            $CC -o "$out" stub.c -O2
          '';

      bravePolicyJson = builtins.toJSON {
        AutoUpdateCheckPeriodMinutes = 0;
        DisableAutoUpdate = true;
        ComponentUpdatesEnabled = false;
        # NOTE on dev mode: Chromium's `ExtensionDeveloperModeSettings` policy
        # has only two values — `0 = Allow` (user CAN toggle dev mode) and
        # `1 = Disallow` (user CANNOT toggle dev mode, forced off). There is
        # NO "force enable" value (deliberately omitted from Chromium so an
        # enterprise admin can't silently force-sideload on a workstation).
        # We previously set this to 1 thinking it meant "force enable" — that
        # actively DISABLED dev mode and broke `--load-extension=` loading.
        # Omitting the key leaves dev mode at its default (Allow, user-toggleable).
        ExtensionInstallForcelist = braveForcelist;
        # ── New Tab Page footer suppression ──────────────────────────
        # Chromium's NTP footer renders when EITHER `managed_ntp` is true
        # (browser is managed AND `NTPFooterManagementNoticeEnabled` allows
        # showing the "managed by your organization" badge) OR when the
        # user pref `NewTabPage.FooterVisible` is true AND an extension is
        # eligible to show attribution there. Setting both Chromium policies
        # to false makes neither arm fire — the footer is fully suppressed
        # without touching the (HMAC-shaped) user pref. The user-facing
        # "Show footer on New Tab page" toggle becomes a no-op.
        NTPFooterManagementNoticeEnabled = false;
        NTPFooterExtensionAttributionEnabled = false;
        # The Stylix theme is delivered via `--load-extension=<dir>` in
        # the wrapper's command-line args (see `braveLoadExtensionArg`),
        # not via policy — so the theme's ID does NOT appear here. The
        # policy entries below are for the upstream-store extensions
        # only.
        ExtensionSettings = braveExtensionSettings;
      };

    in
    {
      options.dendritic.apps.brave = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable declarative Brave Browser with Stylix-driven theming.";
        };
      };

      config = lib.mkIf config.dendritic.apps.brave.enable {
        programs.brave = {
          enable = true;
          # Declarative source of truth for Brave extensions.
          extensions = braveExtensions;
          # Note: on Darwin this is silently dropped by nixpkgs's prebuilt
          # Brave wrapper; the same args are injected by `braveWrapperBin`
          # via the Mach-O stub. Kept here so Linux (where the override
          # DOES fire) and tooling that inspects HM config still see them.
          commandLineArgs = braveCommandLineArgs;
        };

        # ── Brave wrapper .app (Darwin only) ────────────────────────────
        # Provides a separate bundle ID so the HM-managed bundle and the
        # Nix-store bundle don't collide in Launch Services.
        #
        # Keychain compatibility note: macOS attributes Keychain ACL
        # ownership to the *responsible process* identity, which for an
        # `execv`-style wrapper stays bound to the wrapper's code
        # signature (not the post-exec target binary). The original
        # Brave (from nixpkgs and the Brave installer alike) is signed
        # with `Identifier=Brave Browser`, and any existing "Brave Safe
        # Storage" keychain entry's ACL accepts that designated
        # requirement. We therefore force the wrapper's *signing*
        # identifier to match — `--identifier "Brave Browser"` —
        # regardless of CFBundleIdentifier, which can stay distinct for
        # Launch Services. Without this, every flake switch re-signs
        # the wrapper with a fresh ad-hoc CDHash and a non-Brave
        # identifier, breaking Brave's keychain access and triggering
        # the "Keychain Not Found … Reset To Defaults" dialog (which
        # offers to wipe the user's entire login keychain — never click
        # it).
        home.activation.createBraveWrapperApp = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
                    BRAVE_REAL="${pkgs.brave}/Applications/Brave Browser.app"
                    BRAVE_WRAP="$HOME/Applications/Brave Browser.app"

                    rm -rf "$BRAVE_WRAP"
                    mkdir -p "$BRAVE_WRAP/Contents/MacOS"

                    cat > "$BRAVE_WRAP/Contents/Info.plist" << 'PLIST'
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
              <key>CFBundleExecutable</key>    <string>Brave Browser</string>
              <key>CFBundleIconFile</key>      <string>app.icns</string>
              <key>CFBundleIdentifier</key>    <string>org.dendritic.BraveWrapper</string>
              <key>CFBundleName</key>          <string>Brave Browser</string>
              <key>CFBundlePackageType</key>   <string>APPL</string>
              <key>CFBundleShortVersionString</key> <string>1.0</string>
              <key>CFBundleVersion</key>       <string>1</string>
              <key>NSHighResolutionCapable</key> <true/>
            </dict>
            </plist>
            PLIST

                    ln -sfn "$BRAVE_REAL/Contents/Resources" "$BRAVE_WRAP/Contents/Resources"
                    cp "${braveWrapperBin}" "$BRAVE_WRAP/Contents/MacOS/Brave Browser"
                    chmod +x "$BRAVE_WRAP/Contents/MacOS/Brave Browser"

                    /usr/bin/codesign \
                      --force \
                      --sign - \
                      --identifier "Brave Browser" \
                      "$BRAVE_WRAP" 2>/dev/null || true
                    /usr/bin/xattr -rd com.apple.quarantine "$BRAVE_WRAP" 2>/dev/null || true
          ''
        );

        # ── Brave keychain ACL repair (Darwin only) ──────────────────────
        # Belt-and-suspenders to keep the "Brave Safe Storage" entry
        # readable across wrapper rebuilds. macOS partitions keychain
        # items by code-signing CDHash; ad-hoc signatures get a fresh
        # CDHash on every codesign invocation. Even with a stable
        # signing *identifier* (above), some macOS versions still gate
        # on partition list. So if — and only if — the entry exists
        # and is NOT currently readable by this activation context, we
        # widen its partition list to accept "any apple-tool, any
        # apple-signed, any unsigned, any team-id'd app".
        #
        # The conditional avoids the GUI keychain password prompt on
        # every flake switch: when access already works, we touch
        # nothing. On the one switch after a fresh re-sign breaks
        # access, macOS will prompt for the login keychain password
        # exactly once to authorize the widening.
        home.activation.repairBraveKeychainAcl = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter
            [
              "writeBoundary"
              "createBraveWrapperApp"
            ]
            ''
              if /usr/bin/security find-generic-password -s 'Brave Safe Storage' >/dev/null 2>&1; then
                if ! /usr/bin/security find-generic-password -s 'Brave Safe Storage' -w >/dev/null 2>&1; then
                  /usr/bin/security set-generic-password-partition-list \
                    -s 'Brave Safe Storage' \
                    -S 'apple-tool:,apple:,unsigned:,teamid:' \
                    -k login.keychain-db \
                    >/dev/null 2>&1 || true
                fi
              fi
            ''
        );

        home.activation.disableBraveUpdates = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /usr/bin/defaults write com.brave.Browser AutoUpdate -bool false
            /usr/bin/defaults write com.brave.Browser AutoUpdateCheckPeriodMinutes -int 0
            /usr/bin/defaults write com.brave.Browser DisableAutoUpdate -bool true
            # Brave on macOS still uses Sparkle updater prefs for update checks/prompts.
            /usr/bin/defaults write com.brave.Browser SUEnableAutomaticChecks -bool false
            /usr/bin/defaults write com.brave.Browser SUAutomaticallyUpdate -bool false
            /usr/bin/defaults write com.brave.Browser SUScheduledCheckInterval -int 31536000
          ''
        );

        # Pre-clean stale managed paths so HM doesn't backup-clobber on writes.
        home.activation.prepareBraveManagedPaths = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
            BRAVE_ROOT="$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
            rm -f \
              "$BRAVE_ROOT/Managed Policies/policies.json" \
              "$BRAVE_ROOT/Managed Policies/policies.json.backup" \
              "$BRAVE_ROOT/Policies/Managed/policies.json" \
              "$BRAVE_ROOT/Policies/Managed/policies.json.backup"

            # Wipe External Extensions JSONs for all force-installed CWS
            # extensions — these are written by the activation script
            # below, not home.file, so they need explicit cleanup before
            # HM's link-target check runs.
            for EXT_ID in ${lib.concatStringsSep " " braveExtensionIds}; do
              rm -f \
                "$BRAVE_ROOT/External Extensions/$EXT_ID.json" \
                "$BRAVE_ROOT/External Extensions/$EXT_ID.json.backup"
            done

            # Wipe legacy theme extension IDs (see `braveLegacyThemeExtIds`
            # at the top of this file for context).
            for EXT_ID in ${lib.concatStringsSep " " braveLegacyThemeExtIds}; do
              rm -f \
                "$BRAVE_ROOT/External Extensions/$EXT_ID.json" \
                "$BRAVE_ROOT/External Extensions/$EXT_ID.json.backup"
              rm -rf "$BRAVE_ROOT/Default/Extensions/$EXT_ID"
            done

            # Legacy unpacked-theme directory from the abandoned
            # `--load-extension=$HOME/.brave-stylix-theme` flow. Current
            # delivery loads `braveThemeSourceDir` (a /nix/store path)
            # instead. Safe to nuke unconditionally.
            rm -rf "$HOME/.brave-stylix-theme"
          ''
        );

        # ── Materialize Brave policy + force-installed extensions ─────
        # Stylix theme delivery has moved to `--load-extension` baked
        # into the Mach-O wrapper (see `braveLoadExtensionArg`), so we
        # no longer pack a CRX, write a gupdate XML, or place an
        # External Extensions JSON here. This activation block now only
        # writes the upstream-store ExtensionInstallForcelist policy
        # and clears stale theme-side-load artifacts on disk.
        home.activation.materializeBraveStylixTheme =
          lib.hm.dag.entryAfter
            [
              "writeBoundary"
            ]
            ''
              BRAVE_ROOT="${
                if pkgs.stdenv.isDarwin then
                  "$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
                else
                  "$HOME/.config/BraveSoftware/Brave-Browser"
              }"
              mkdir -p "$BRAVE_ROOT/Default" "$BRAVE_ROOT/External Extensions"

              # Clear any side-loaded artifacts from prior CRX-based
              # iterations of this module. The theme is now loaded via
              # --load-extension; Brave doesn't need a CRX, an External
              # Extensions JSON, or a gupdate XML on disk. The legacy
              # ID list `braveLegacyThemeExtIds` handles the per-ID
              # `External Extensions/*.json` + `Default/Extensions/*`
              # paths (those run in prepareBraveManagedPaths above);
              # here we just nuke the activation-time CRX output dir.
              rm -rf "${config.xdg.dataHome}/brave-stylix"

              ${lib.optionalString pkgs.stdenv.isDarwin ''
                POLICY_MAIN="$BRAVE_ROOT/Managed Policies/policies.json"
                POLICY_ALT="$BRAVE_ROOT/Policies/Managed/policies.json"
                mkdir -p "$BRAVE_ROOT/Managed Policies" "$BRAVE_ROOT/Policies/Managed"
                rm -f "$POLICY_MAIN" "$POLICY_ALT"
                printf '%s\n' '${bravePolicyJson}' > "$POLICY_MAIN"
                # Prefer rewrite over cp — macOS can leave an undeletable
                # opaque "File exists" when Policies/Managed is root-owned.
                printf '%s\n' '${bravePolicyJson}' > "$POLICY_ALT" || true
                chmod 0644 "$POLICY_MAIN" "$POLICY_ALT" 2>/dev/null || true

                ${lib.concatMapStringsSep "\n" (ext: ''
                  rm -f "$BRAVE_ROOT/External Extensions/${ext.id}.json"
                  printf '%s\n' '{"external_update_url":"${
                    ext.updateUrl or braveDefaultUpdateUrl
                  }"}' > "$BRAVE_ROOT/External Extensions/${ext.id}.json"
                  chmod 0644 "$BRAVE_ROOT/External Extensions/${ext.id}.json" || true
                '') braveExtensions}
              ''}
            '';
      };
    };

  # ── nix-darwin Brave module (let-bound; mirrored to flake-parts + den) ──
  braveDarwinModule =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;

      systemPolicyJson = builtins.toJSON {
        AutoUpdateCheckPeriodMinutes = 0;
        DisableAutoUpdate = true;
        ComponentUpdatesEnabled = false;
        # NOTE on dev mode: Chromium's `ExtensionDeveloperModeSettings`
        # policy has only Allow=0 / Disallow=1 (no "force enable"). The
        # Stylix theme is loaded via `--load-extension` (see
        # `braveLoadExtensionArg`), which is honored at Brave startup
        # regardless of dev-mode UI state, so we leave this key omitted
        # (default: user-togglable from `brave://extensions/`).
        ExtensionInstallForcelist = braveForcelist;
        # See note in bravePolicyJson: these two Chromium policies fully
        # suppress the NTP footer (both the "managed by org" badge and
        # extension attribution), making the user-facing "Show footer on
        # New Tab page" toggle a no-op.
        NTPFooterManagementNoticeEnabled = false;
        NTPFooterExtensionAttributionEnabled = false;
        # Mirror of `bravePolicyJson`: theme is delivered via
        # --load-extension, not policy. Theme ID intentionally absent
        # from ExtensionSettings.
        ExtensionSettings = braveExtensionSettings;
      };

      # Variant hot-reload script invoked by darwin-appearance-sync after a
      # light/dark flip. HM has just rewritten the External Extensions JSON
      # to point at the new variant's CRX (different version, different
      # store path). Brave reads External Extensions only at startup, so to
      # see the new theme it has to be restarted — quit + relaunch is all
      # this script does. No Preferences mutation, no extension cache
      # tampering.
      braveStylixReload = pkgs.writeShellApplication {
        name = "brave-stylix-reload";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          set -u
          target_user="${user}"
          uid="$(id -u "$target_user")"
          home_dir="/Users/$target_user"
          wrapper_app="$home_dir/Applications/Brave Browser.app"

          # Quit Brave so it re-reads External Extensions on next launch.
          brave_was_running=0
          if /usr/bin/pgrep -x "Brave Browser" >/dev/null 2>&1; then
            brave_was_running=1
            /usr/bin/killall "Brave Browser" >/dev/null 2>&1 || true
            i=0
            while /usr/bin/pgrep -x "Brave Browser" >/dev/null 2>&1 && [ "$i" -lt 20 ]; do
              /bin/sleep 0.25
              i=$((i + 1))
            done
          fi

          if [ "$brave_was_running" -eq 1 ]; then
            /bin/sleep 0.4
            if [ -d "$wrapper_app" ]; then
              /bin/launchctl asuser "$uid" /usr/bin/sudo -u "$target_user" \
                /usr/bin/open "$wrapper_app" >/dev/null 2>&1 || true
            else
              /bin/launchctl asuser "$uid" /usr/bin/sudo -u "$target_user" \
                /usr/bin/open -a "Brave Browser" >/dev/null 2>&1 || true
            fi
          fi
        '';
      };
    in
    {
      options.dendritic.brave = {
        reloadScript = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "Variant-aware Brave reload script consumed by darwin-appearance-sync.";
        };
      };

      config = {
        dendritic.brave.reloadScript = braveStylixReload;

        # System-level Managed Preferences plist + machine policy JSON so
        # Brave shows "Managed by your organization" and accepts the unpacked
        # Stylix theme without user prompts.
        system.activationScripts.postActivation.text = lib.mkAfter ''
                    /bin/mkdir -p "/Library/Managed Preferences"
                    /bin/mkdir -p "/Library/Application Support/BraveSoftware/Brave-Browser/Policies/Managed"
                    /bin/mkdir -p "/Library/Application Support/BraveSoftware/Brave-Browser/External Extensions"
                    ${pkgs.python3}/bin/python3 - <<'PY'
          import json
          import plistlib
          from pathlib import Path

          policy_path = Path("/Library/Managed Preferences/com.brave.Browser.plist")
          policy_json_path = Path("/Library/Application Support/BraveSoftware/Brave-Browser/Policies/Managed/policies.json")
          policy = json.loads("""${systemPolicyJson}""")

          with policy_path.open("wb") as f:
              plistlib.dump(policy, f, sort_keys=True)
          policy_json_path.write_text(json.dumps(policy, separators=(",", ":")))
          PY
                    /usr/sbin/chown root:wheel "/Library/Managed Preferences/com.brave.Browser.plist" || true
                    /bin/chmod 0644 "/Library/Managed Preferences/com.brave.Browser.plist" || true
                    /usr/sbin/chown root:wheel "/Library/Application Support/BraveSoftware/Brave-Browser/Policies/Managed/policies.json" || true
                    /bin/chmod 0644 "/Library/Application Support/BraveSoftware/Brave-Browser/Policies/Managed/policies.json" || true
        '';

        # Dock registration: Brave owns its dock entry (order 110 in `dock.nix`).
        dendritic.dock.apps = lib.mkOrder 110 [
          "/Users/${user}/Applications/Brave Browser.app"
        ];
      };
    };
in
{
  # ── Flake-parts dendritic exports (consumed by embedded HM + Darwin users) ──
  # The four darwin/nixos host files import `inputs.self.modules.<class>.dendritic`
  # which merges every contribution to `flake.modules.<class>.dendritic`. The
  # brave modules below get picked up via that path.
  flake.modules.homeManager.dendritic = braveHmModule;
  flake.modules.darwin.dendritic = braveDarwinModule;

  # ── Den aspect (future-proofing for den.homes / aspect includes) ────────
  # Same modules exposed as a named aspect so any future `den.homes.*`
  # consumer or host aspect can `includes = [ config.den.aspects.brave ]`
  # to pick up brave declaratively without going through the dendritic
  # monolith.
  den.aspects.brave = {
    homeManager = braveHmModule;
    darwin = braveDarwinModule;
  };
}
