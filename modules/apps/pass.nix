# Dendritic pass + GPG + SecretSpec feature (HM-only).
#
# Trust chain: SSH ed25519 → sops age → gpg_private_key/gpg_passphrase →
# gpg-agent preset (+ dendritic-pinentry, no GUI) → ~/.password-store → SecretSpec.
#
# Humans never type the GPG passphrase. pinentry-mac/Keychain is intentionally
# not used — it prompted for a secret the user is not meant to know.
#
# GUI: QtPass (macOS .app via HM linkApps + Dock pin; Linux desktop entry).
#
# Auto-sync:
#   - watchexec (FSEvents / inotify) → MODE=full pull/commit/push (local edits)
#   - after successful push → host-side ntfy wake (primary peer notify)
#   - curl ntfy JSON long-poll → MODE=pull (upstream-only; near-zero idle)
#   - GitHub Actions notify-sync → ntfy (backup if host wake fails)
# Not a periodic timer — kernel FS events + one sleeping HTTP stream.
#
# Activation is best-effort when sops material is missing (pre-genesis) so
# a fresh clone of public .dotfiles still evaluates/builds.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.pass;
      storeDir = "${config.home.homeDirectory}/.password-store";
      passPackage = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      passBin = "${passPackage}/bin/pass";
      gpgBin = "${pkgs.gnupg}/bin/gpg";
      gitBin = "${pkgs.git}/bin/git";
      pwgenBin = "${pkgs.pwgen}/bin/pwgen";
      secretspecToml = ../../home/secretspec.toml;
      materializeMap = ../../home/pass-materialize.json;
      materializeEnvMap = ../../home/pass-materialize-env.json;
      # GUI-less pinentry: GETPIN → sops gpg_passphrase file (fail closed).
      dendriticPinentry =
        let
          passPath = config.sops.secrets.gpg_passphrase.path;
          prevPassPath = config.sops.secrets.gpg_passphrase_previous.path;
          wrapper = pkgs.writeShellScript "dendritic-pinentry-wrap" ''
            export DENDRITIC_GPG_PASSPHRASE_FILE=${lib.escapeShellArg passPath}
            export DENDRITIC_GPG_PASSPHRASE_PREVIOUS_FILE=${lib.escapeShellArg prevPassPath}
            exec ${pkgs.bash}/bin/bash ${../../scripts/dendritic-pinentry.sh}
          '';
        in
        pkgs.runCommand "dendritic-pinentry" { } ''
          mkdir -p $out/bin
          ln -s ${wrapper} $out/bin/pinentry
          ln -s ${wrapper} $out/bin/pinentry-dendritic
        '';
      gpgPresetScript =
        let
          passPath = config.sops.secrets.gpg_passphrase.path;
          prevPassPath = config.sops.secrets.gpg_passphrase_previous.path;
        in
        pkgs.writeShellScript "gpg-preset-from-sops" ''
          export PATH=${
            lib.makeBinPath [
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gawk
              pkgs.gnupg
            ]
          }''${PATH:+:$PATH}
          export GPG=${lib.escapeShellArg gpgBin}
          export GPG_PRESET_PASSPHRASE=${lib.escapeShellArg "${pkgs.gnupg}/libexec/gpg-preset-passphrase"}
          export DENDRITIC_GPG_PASSPHRASE_FILE=${lib.escapeShellArg passPath}
          export DENDRITIC_GPG_PASSPHRASE_PREVIOUS_FILE=${lib.escapeShellArg prevPassPath}
          exec ${pkgs.bash}/bin/bash ${../../scripts/gpg-preset-from-sops.sh}
        '';
      syncPath = lib.makeBinPath [
        pkgs.git
        pkgs.coreutils
        pkgs.gnupg
        pkgs.findutils
        pkgs.gnugrep
        pkgs.curl
        pkgs.jq
        pkgs.secretspec
        passPackage
      ];
      materializeScript = pkgs.writeShellScript "pass-secretspec-materialize" ''
        export PATH="${syncPath}:$PATH"
        export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
        export PASS_MATERIALIZE_MAP=${lib.escapeShellArg "${materializeMap}"}
        export PASS_MATERIALIZE_ENV_MAP=${lib.escapeShellArg "${materializeEnvMap}"}
        export PASS_SECRETSPEC_TOML=${lib.escapeShellArg "${secretspecToml}"}
        export PASS_STORE_SYNC_STATUS=${lib.escapeShellArg "${config.home.homeDirectory}/.cache/pass-store-sync.status"}
        exec ${pkgs.bash}/bin/bash ${../../scripts/pass-secretspec-materialize.sh}
      '';
      syncScript = pkgs.writeShellScript "pass-store-sync" ''
        export PATH="${syncPath}:$PATH"
        export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
        export PASS_STORE_SYNC_MODE="''${PASS_STORE_SYNC_MODE:-full}"
        export PASS_STORE_SYNC_STATUS=${lib.escapeShellArg "${config.home.homeDirectory}/.cache/pass-store-sync.status"}
        export PASS_MATERIALIZE_SCRIPT=${materializeScript}
        export PASS_MATERIALIZE_MAP=${lib.escapeShellArg "${materializeMap}"}
        export PASS_MATERIALIZE_ENV_MAP=${lib.escapeShellArg "${materializeEnvMap}"}
        export PASS_SECRETSPEC_TOML=${lib.escapeShellArg "${secretspecToml}"}
        ${
          if cfg.enable then
            ''
              export PASS_STORE_NTFY_TOPIC_FILE=${lib.escapeShellArg config.sops.secrets.pass_store_ntfy_topic.path}
              export PASS_STORE_NTFY_SERVER=${lib.escapeShellArg cfg.autoSync.notify.server}
            ''
          else
            ""
        }
        exec ${pkgs.bash}/bin/bash ${../../scripts/pass-store-sync.sh}
      '';
      watchScript = pkgs.writeShellScript "pass-store-watch" ''
        export PASS_STORE_SYNC_MODE=full
        exec ${pkgs.watchexec}/bin/watchexec \
          --watch ${lib.escapeShellArg storeDir} \
          --debounce ${lib.escapeShellArg cfg.autoSync.debounce} \
          --ignore '.git' \
          --ignore '.git/**' \
          --ignore '**/.git/**' \
          --on-busy-update do-nothing \
          -- \
          ${syncScript}
      '';
      notifyScript = pkgs.writeShellScript "pass-store-sync-notify" ''
        export PATH="${syncPath}:$PATH"
        export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
        export PASS_STORE_SYNC_SCRIPT=${syncScript}
        export PASS_STORE_NTFY_SERVER=${lib.escapeShellArg cfg.autoSync.notify.server}
        export PASS_STORE_NOTIFY_DEBOUNCE_SEC=${lib.escapeShellArg (toString cfg.autoSync.notify.debounceSec)}
        # PASS_STORE_NTFY_TOPIC_FILE must be set by the agent (sops path).
        exec ${pkgs.bash}/bin/bash ${../../scripts/pass-store-sync-notify.sh}
      '';
      trayPkg = pkgs.rustPlatform.buildRustPackage {
        pname = "pass-store-tray";
        version = "0.3.3";
        src = ./pass-store-tray;
        cargoLock.lockFile = ./pass-store-tray/Cargo.lock;
        nativeBuildInputs = [
          pkgs.pkg-config
          pkgs.makeWrapper
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wrapGAppsHook3 ];
        buildInputs = lib.optionals pkgs.stdenv.isLinux [
          pkgs.gtk3
          pkgs.libayatana-appindicator
          pkgs.xdotool # libxdo — tray-icon/muda link dep
        ];
        doCheck = false;
        postInstall =
          let
            wrapLibPath = lib.optionalString pkgs.stdenv.isLinux ''
              --prefix LD_LIBRARY_PATH : ${
                lib.makeLibraryPath [
                  pkgs.gtk3
                  pkgs.libayatana-appindicator
                  pkgs.xdotool
                ]
              }
            '';
          in
          ''
            wrapProgram $out/bin/pass-store-tray \
              --set PASS_STORE_SYNC_SCRIPT ${syncScript} \
              --set PASS_MATERIALIZE_SCRIPT ${materializeScript} \
              --set PASSWORD_STORE_DIR ${lib.escapeShellArg storeDir} \
              --set PASS_STORE_SYNC_STATUS ${lib.escapeShellArg "${config.home.homeDirectory}/.cache/pass-store-sync.status"} \
              --set PASS_STORE_SYNC_LOCK ${lib.escapeShellArg "${config.home.homeDirectory}/.cache/pass-store-sync.lock"} \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.procps
                  pkgs.bash
                  pkgs.coreutils
                ]
              } \
              ${wrapLibPath}
          '';
        meta = {
          description = "Pass store sync native tray applet (Rust)";
          mainProgram = "pass-store-tray";
        };
      };
      syncLogDir = "${config.home.homeDirectory}/.cache";
      # Qt ini / QSettings keys (IJHack/QtPass).
      qtpassConf = ''
        [General]
        passStore=${storeDir}
        passExecutable=${passBin}
        gitExecutable=${gitBin}
        gpgExecutable=${gpgBin}
        pwgenExecutable=${pwgenBin}
        usePass=true
        useGit=true
        usePwgen=true
        useClipboard=true
        hideOnClose=false
        startMinimized=false
        autoPull=false
        autoPush=false
      '';
    in
    {
      options.dendritic.apps.pass = {
        enable = lib.mkEnableOption "pass password-store, GPG agent, QtPass, Browserpass, SecretSpec";

        gui = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Install and configure QtPass GUI for browsing/editing the password store.";
          };
        };

        storeRepo = lib.mkOption {
          type = lib.types.str;
          default = "aspauldingcode/.password-store";
          description = "GitHub owner/name of the private password-store repository.";
        };

        fingerprint = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            Primary GPG key fingerprint for PASSWORD_STORE_KEY. Empty means
            pass falls back to the store's `.gpg-id` (preferred after genesis).
          '';
        };

        secretspecProvider = lib.mkOption {
          type = lib.types.str;
          default = "pass://secretspec/shared/{profile}/{key}";
          description = "Default SecretSpec provider URI written to user config.";
        };

        rotationReminder = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Install a periodic reminder to run pass-rotate (annual cadence).";
        };

        autoSync = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Watch ~/.password-store with watchexec (FSEvents on macOS, inotify
              on Linux) and debounced git pull / commit / push to the private
              GitHub store. Not a calendar timer.
            '';
          };
          debounce = lib.mkOption {
            type = lib.types.str;
            default = "10sec";
            description = "watchexec --debounce duration before sync runs.";
          };
          notify = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Upstream-only sync via one curl JSON long-poll to ntfy (no ntfy
                CLI). Primary wake is host-side publish after git push; this
                agent receives those (and CI backup) pings for near-real-time
                peers. Catch-up pull on every subscribe/reconnect (ntfy does
                not retain missed events) so offline hosts converge when they
                return; MODE=pull on each message. Topic from sops secret
                pass_store_ntfy_topic.
              '';
            };
            server = lib.mkOption {
              type = lib.types.str;
              default = "https://ntfy.sh";
              description = "ntfy server base URL (no trailing slash required).";
            };
            debounceSec = lib.mkOption {
              type = lib.types.ints.positive;
              default = 1;
              description = "Minimum seconds between pull runs after ntfy messages.";
            };
          };
        };

        materialize = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Materialize SecretSpec keys listed in home/pass-materialize.json
              into $HOME paths (e.g. SHIT_PASSWORD → ~/.shit). Runs on HM
              activation and after pass-store sync when secretspec/ changes.
            '';
          };
        };

        # Deprecated alias — prefer materialize.enable.
        materializeShitFile = lib.mkOption {
          type = lib.types.bool;
          default = true;
          visible = false;
          description = "Deprecated; use dendritic.apps.pass.materialize.enable.";
        };

        tray = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Native Rust menubar/tray applet (tray-icon/muda) showing pass sync
              ↑/↓/idle in the menu — no windowed GUI (Darwin + Linux).
            '';
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          sops.secrets = {
            gpg_private_key = {
              sopsFile = ../../secrets/secrets.yaml;
            };
            gpg_passphrase = {
              sopsFile = ../../secrets/secrets.yaml;
            };
            gpg_private_key_previous = {
              sopsFile = ../../secrets/secrets.yaml;
            };
            gpg_passphrase_previous = {
              sopsFile = ../../secrets/secrets.yaml;
            };
            pass_store_ntfy_topic = {
              sopsFile = ../../secrets/secrets.yaml;
            };
          };

          home.packages =
            with pkgs;
            [
              passPackage
              browserpass
              secretspec
              gnupg
              pwgen
              jq
            ]
            ++ lib.optionals cfg.gui.enable [ qtpass ]
            ++ lib.optionals cfg.tray.enable [ trayPkg ]
            ++ lib.optionals cfg.materialize.enable [
              (pkgs.writeShellScriptBin "pass-materialize" ''
                exec ${materializeScript}
              '')
            ];

          programs.gpg = {
            enable = true;
            settings = {
              personal-cipher-preferences = "AES256 AES192 AES";
              personal-digest-preferences = "SHA512 SHA384 SHA256";
              cert-digest-algo = "SHA512";
            };
          };

          services.gpg-agent = {
            enable = true;
            enableSshSupport = false;
            defaultCacheTtl = 31536000;
            maxCacheTtl = 31536000;
            # Never pinentry-mac / curses — those ask humans for a sops secret.
            pinentry.package = dendriticPinentry;
            extraConfig = ''
              allow-preset-passphrase
              allow-loopback-pinentry
            '';
          };

          programs.password-store = {
            enable = true;
            package = passPackage;
            settings = {
              PASSWORD_STORE_DIR = storeDir;
            }
            // lib.optionalAttrs (cfg.fingerprint != "") {
              PASSWORD_STORE_KEY = cfg.fingerprint;
            };
          };

          programs.browserpass = {
            enable = true;
            browsers = [
              "firefox"
              "brave"
              "chrome"
              "chromium"
            ];
          };

          xdg.configFile."secretspec/config.toml".text = ''
            [defaults]
            provider = "${cfg.secretspecProvider}"

            [defaults.providers]
            pass = "${cfg.secretspecProvider}"
            shared = "${cfg.secretspecProvider}"
          '';

          home.activation.passBootstrap = lib.hm.dag.entryAfter [ "sops-nix" ] (
            let
              gpg = gpgBin;
              preset = "${pkgs.gnupg}/libexec/gpg-preset-passphrase";
              ghBin = "${pkgs.gh}/bin/gh";
              git = gitBin;
              keyPath = config.sops.secrets.gpg_private_key.path;
              passPath = config.sops.secrets.gpg_passphrase.path;
              prevKeyPath = config.sops.secrets.gpg_private_key_previous.path;
              prevPassPath = config.sops.secrets.gpg_passphrase_previous.path;
              repo = cfg.storeRepo;
            in
            ''
              _pass_import_and_preset() {
                _key_file="$1"
                _pass_file="$2"
                if [ ! -r "$_key_file" ]; then
                  return 0
                fi
                _key_content="$(tr -d '\r' < "$_key_file")"
                if [ -z "$_key_content" ] || [ "$_key_content" = "placeholder" ]; then
                  return 0
                fi
                if ! printf '%s\n' "$_key_content" | ${gpg} --batch --import 2>/dev/null; then
                  if [ -r "$_pass_file" ]; then
                    _pp="$(tr -d '\r\n' < "$_pass_file")"
                    if [ -n "$_pp" ] && [ "$_pp" != "placeholder" ]; then
                      printf '%s\n' "$_key_content" | ${gpg} --batch --yes \
                        --pinentry-mode loopback --passphrase "$_pp" --import 2>/dev/null || true
                    fi
                  fi
                fi
                if [ ! -r "$_pass_file" ]; then
                  return 0
                fi
                _pp="$(tr -d '\r\n' < "$_pass_file")"
                if [ -z "$_pp" ] || [ "$_pp" = "placeholder" ]; then
                  return 0
                fi
                ${gpg} --batch --with-colons --with-keygrip --list-secret-keys 2>/dev/null \
                  | ${pkgs.gawk}/bin/awk -F: '/^grp:/ { print $10 }' \
                  | while read -r _grip; do
                      [ -n "$_grip" ] || continue
                      printf '%s' "$_pp" | ${preset} --preset "$_grip" 2>/dev/null || true
                    done
              }

              _pass_import_and_preset ${lib.escapeShellArg keyPath} ${lib.escapeShellArg passPath}
              _pass_import_and_preset ${lib.escapeShellArg prevKeyPath} ${lib.escapeShellArg prevPassPath}

              # Keep agent + Keychain aligned with sops (idempotent).
              ${gpgPresetScript} || true

              export PASSWORD_STORE_DIR=${lib.escapeShellArg storeDir}
              mkdir -p "$PASSWORD_STORE_DIR"

              if [ ! -d "$PASSWORD_STORE_DIR/.git" ]; then
                if ${ghBin} auth status -h github.com >/dev/null 2>&1 \
                  || [ -n "''${GH_TOKEN:-}" ] || [ -n "''${GITHUB_TOKEN:-}" ]; then
                  ${ghBin} repo clone ${lib.escapeShellArg repo} "$PASSWORD_STORE_DIR" 2>/dev/null \
                    || ${git} clone "https://github.com/${repo}.git" "$PASSWORD_STORE_DIR" 2>/dev/null \
                    || true
                fi
              else
                ${git} -C "$PASSWORD_STORE_DIR" pull --rebase --autostash 2>/dev/null || true
              fi

              if [ -f "$PASSWORD_STORE_DIR/_bootstrap/ok.gpg" ]; then
                ${passBin} show _bootstrap/ok >/dev/null 2>&1 || true
              fi
            ''
          );
        })

        # SecretSpec → $HOME files (activation + post-sync share one script).
        (lib.mkIf (cfg.enable && cfg.materialize.enable) {
          home.activation.passMaterialize = lib.hm.dag.entryAfter [ "passBootstrap" ] ''
            ${materializeScript} || echo "pass: materialize skipped/failed" >&2
          '';
        })

        # QtPass GUI: Linux uses Qt .conf; macOS uses native preferences domain.
        (lib.mkIf (cfg.enable && cfg.gui.enable && pkgs.stdenv.isLinux) {
          xdg.configFile."IJHack/QtPass.conf".text = qtpassConf;
          xdg.desktopEntries.qtpass = {
            name = "QtPass";
            genericName = "Password Manager";
            comment = "GUI for the standard unix password manager (pass)";
            exec = "qtpass";
            icon = "qtpass-icon";
            terminal = false;
            categories = [
              "Utility"
              "Security"
            ];
          };
        })

        (lib.mkIf (cfg.enable && cfg.gui.enable && pkgs.stdenv.isDarwin) {
          # Seed native prefs so Spotlight/QtPass open pointed at our store + nix binaries.
          home.activation.configureQtPass = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /usr/bin/defaults write com.IJHack.QtPass passStore -string ${lib.escapeShellArg storeDir}
            /usr/bin/defaults write com.IJHack.QtPass passExecutable -string ${lib.escapeShellArg passBin}
            /usr/bin/defaults write com.IJHack.QtPass gitExecutable -string ${lib.escapeShellArg gitBin}
            /usr/bin/defaults write com.IJHack.QtPass gpgExecutable -string ${lib.escapeShellArg gpgBin}
            /usr/bin/defaults write com.IJHack.QtPass pwgenExecutable -string ${lib.escapeShellArg pwgenBin}
            /usr/bin/defaults write com.IJHack.QtPass usePass -bool true
            /usr/bin/defaults write com.IJHack.QtPass useGit -bool true
            /usr/bin/defaults write com.IJHack.QtPass usePwgen -bool true
            /usr/bin/defaults write com.IJHack.QtPass useClipboard -bool true
          '';
        })

        (lib.mkIf (cfg.enable && cfg.rotationReminder && pkgs.stdenv.isDarwin) {
          launchd.agents.pass-rotate-reminder = {
            enable = true;
            config = {
              Label = "com.aspaulding.pass-rotate-reminder";
              ProgramArguments = [
                "/usr/bin/osascript"
                "-e"
                "display notification \"Run: nix run .#pass-rotate (or --status)\" with title \"pass GPG rotation reminder\""
              ];
              StartCalendarInterval = {
                Month = 1;
                Day = 1;
                Hour = 10;
                Minute = 0;
              };
            };
          };
        })

        (lib.mkIf (cfg.enable && cfg.rotationReminder && pkgs.stdenv.isLinux) {
          home.packages = [ pkgs.libnotify ];
          systemd.user.services.pass-rotate-reminder = {
            Unit.Description = "Annual pass GPG rotation reminder";
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScript "pass-rotate-reminder" ''
                ${pkgs.libnotify}/bin/notify-send "pass GPG rotation" "Run: nix run .#pass-rotate (or --status)" || true
              ''}";
            };
          };
          systemd.user.timers.pass-rotate-reminder = {
            Unit.Description = "Annual pass GPG rotation reminder";
            Timer = {
              OnCalendar = "yearly";
              Persistent = true;
            };
            Install.WantedBy = [ "timers.target" ];
          };
        })

        # Kernel FS watcher → debounced git sync (not a calendar timer).
        (lib.mkIf (cfg.enable && cfg.autoSync.enable && pkgs.stdenv.isDarwin) {
          launchd.agents.pass-store-sync = {
            enable = true;
            config = {
              Label = "com.aspaulding.pass-store-sync";
              ProgramArguments = [ "${watchScript}" ];
              RunAtLoad = true;
              KeepAlive = true;
              ThrottleInterval = 10;
              StandardOutPath = "${syncLogDir}/pass-store-sync.log";
              StandardErrorPath = "${syncLogDir}/pass-store-sync.err.log";
              EnvironmentVariables = {
                HOME = config.home.homeDirectory;
                PASSWORD_STORE_DIR = storeDir;
                PASS_STORE_SYNC_MODE = "full";
              };
            };
          };
        })

        (lib.mkIf (cfg.enable && cfg.autoSync.enable && pkgs.stdenv.isLinux) {
          systemd.user.services.pass-store-sync = {
            Unit = {
              Description = "Watch ~/.password-store and sync to GitHub (watchexec)";
              After = [ "default.target" ];
            };
            Service = {
              ExecStart = "${watchScript}";
              Restart = "always";
              RestartSec = 10;
              Environment = [
                "PASSWORD_STORE_DIR=${storeDir}"
                "PASS_STORE_SYNC_MODE=full"
              ];
            };
            Install.WantedBy = [ "default.target" ];
          };
        })

        # ntfy JSON long-poll → MODE=pull (upstream-only; one sleeping curl).
        # Race: sops-nix may decrypt after RunAtLoad. WatchPaths restarts when
        # the secrets dir changes; the script also waits then exits 1 for KeepAlive.
        (lib.mkIf (cfg.enable && cfg.autoSync.enable && cfg.autoSync.notify.enable && pkgs.stdenv.isDarwin)
          {
            launchd.agents.pass-store-sync-notify = {
              enable = true;
              config = {
                Label = "com.aspaulding.pass-store-sync-notify";
                ProgramArguments = [ "${notifyScript}" ];
                RunAtLoad = true;
                KeepAlive = true;
                # Back off while waiting for sops; WatchPaths covers late decrypt.
                ThrottleInterval = 15;
                WatchPaths = [
                  "${config.home.homeDirectory}/.config/sops-nix/secrets"
                ];
                StandardOutPath = "${syncLogDir}/pass-store-sync-notify.log";
                StandardErrorPath = "${syncLogDir}/pass-store-sync-notify.err.log";
                EnvironmentVariables = {
                  HOME = config.home.homeDirectory;
                  PASSWORD_STORE_DIR = storeDir;
                  PASS_STORE_NTFY_TOPIC_FILE = config.sops.secrets.pass_store_ntfy_topic.path;
                  PASS_STORE_NTFY_WAIT_SEC = "120";
                };
              };
            };
          }
        )

        (lib.mkIf (cfg.enable && cfg.autoSync.enable && cfg.autoSync.notify.enable && pkgs.stdenv.isLinux) {
          systemd.user.services.pass-store-sync-notify = {
            Unit = {
              Description = "ntfy long-poll → pull ~/.password-store (upstream-only)";
              After = [ "default.target" ];
              # Soft dep: present when HM sops uses a user unit; ignored otherwise.
              Wants = [ "sops-nix.service" ];
            };
            Service = {
              ExecStart = "${notifyScript}";
              Restart = "always";
              RestartSec = 15;
              # Fail fast into Restart if topic still missing after script wait.
              Environment = [
                "PASSWORD_STORE_DIR=${storeDir}"
                "PASS_STORE_NTFY_TOPIC_FILE=${config.sops.secrets.pass_store_ntfy_topic.path}"
                "PASS_STORE_NTFY_WAIT_SEC=120"
              ];
            };
            Install.WantedBy = [ "default.target" ];
          };
        })

        # Keep gpg-agent passphrase preset from sops; purge Darwin Keychain
        # GnuPG items so pinentry-mac cannot reappear after a manual install.
        (lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
          launchd.agents.gpg-preset-from-sops = {
            enable = true;
            config = {
              Label = "com.dendritic.gpg-preset-from-sops";
              ProgramArguments = [ "${gpgPresetScript}" ];
              RunAtLoad = true;
              # Re-preset after sleep / agent restart; cheap idempotent op.
              StartInterval = 300;
              WatchPaths = [
                "${config.home.homeDirectory}/.config/sops-nix/secrets"
              ];
              StandardOutPath = "${syncLogDir}/gpg-preset-from-sops.log";
              StandardErrorPath = "${syncLogDir}/gpg-preset-from-sops.err.log";
              EnvironmentVariables = {
                HOME = config.home.homeDirectory;
                PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
              };
            };
          };
        })

        (lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
          systemd.user.services.gpg-preset-from-sops = {
            Unit = {
              Description = "Preset GPG passphrase from sops into gpg-agent";
              After = [
                "default.target"
                "gpg-agent.service"
              ];
              Wants = [ "gpg-agent.service" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${gpgPresetScript}";
            };
          };
          systemd.user.timers.gpg-preset-from-sops = {
            Unit.Description = "Re-preset GPG passphrase from sops every 5m";
            Timer = {
              OnBootSec = "30s";
              OnUnitActiveSec = "5m";
              Unit = "gpg-preset-from-sops.service";
            };
            Install.WantedBy = [ "timers.target" ];
          };
          systemd.user.paths.gpg-preset-from-sops = {
            Unit.Description = "Re-preset GPG when sops secrets change";
            Path = {
              PathModified = "${config.home.homeDirectory}/.config/sops-nix/secrets";
              PathExists = config.sops.secrets.gpg_passphrase.path;
            };
            Install.WantedBy = [ "default.target" ];
          };
        })

        # Unified pass sync tray (↑ / ↓ / green / rebuild).
        (lib.mkIf (cfg.enable && cfg.tray.enable && pkgs.stdenv.isDarwin) {
          launchd.agents.pass-store-tray = {
            enable = true;
            config = {
              Label = "com.aspaulding.pass-store-tray";
              ProgramArguments = [ "${trayPkg}/bin/pass-store-tray" ];
              RunAtLoad = true;
              KeepAlive = true;
              ThrottleInterval = 5;
              StandardOutPath = "${syncLogDir}/pass-store-tray.log";
              StandardErrorPath = "${syncLogDir}/pass-store-tray.err.log";
              EnvironmentVariables = {
                HOME = config.home.homeDirectory;
                PASSWORD_STORE_DIR = storeDir;
              };
            };
          };
        })

        (lib.mkIf (cfg.enable && cfg.tray.enable && pkgs.stdenv.isLinux) {
          systemd.user.services.pass-store-tray = {
            Unit = {
              Description = "Pass store sync tray (↑/↓/idle)";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${trayPkg}/bin/pass-store-tray";
              Restart = "on-failure";
              RestartSec = 5;
              Environment = [
                "PASSWORD_STORE_DIR=${storeDir}"
              ];
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };
        })
      ];
    };

  # Dock pin for QtPass on macOS (order 145 — after Ghostty, before JetBrains).
  flake.modules.darwin.dendritic =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      qtpassApp = "${pkgs.qtpass}/Applications/QtPass.app";
      anyPassGui = lib.any (
        u:
        (config.home-manager.users.${u}.dendritic.apps.pass.enable or false)
        && (config.home-manager.users.${u}.dendritic.apps.pass.gui.enable or true)
      ) (lib.attrNames (config.home-manager.users or { }));
    in
    {
      config = lib.mkIf anyPassGui {
        dendritic.dock.apps = lib.mkOrder 145 [ qtpassApp ];
      };
    };
}
