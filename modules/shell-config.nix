{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      options,
      ...
    }:
    let
      # GUI password prompt for sudo when no controlling tty (IDE agents, etc.).
      # Parallels macOS Touch ID via fprintd below; askpass covers headless/GUI cases.
      # Uses zenity (GTK) so it works under any Wayland compositor without pulling
      # in KDE/Plasma.
      sudoAskpass = pkgs.writeShellScriptBin "sudo-askpass" ''
        exec ${pkgs.zenity}/bin/zenity \
          --password \
          --title "Authenticate"
      '';

      # Elevates via systemd when PR_SET_NO_NEW_PRIVS blocks sudo (Cursor/Electron).
      dendriticOsSwitch = pkgs.writeShellScriptBin "dendritic-os-switch" ''
        set -euo pipefail
        host="''${1:-$(${pkgs.coreutils}/bin/hostname -s)}"
        flake="''${DENDRITIC_FLAKE:-/etc/nixos/.dotfiles}"
        unit="dendritic-os-switch@''${host}.service"

        if grep -q 'NoNewPrivs:[[:space:]]*1' /proc/self/status 2>/dev/null; then
          echo "dendritic-os-switch: NoNewPrivs set — starting ''${unit}"
          if ! systemctl start --wait "$unit"; then
            echo "dendritic-os-switch: failed; recent logs:" >&2
            journalctl -u "$unit" -n 80 --no-pager >&2 || true
            exit 1
          fi
          journalctl -u "$unit" -n 40 --no-pager || true
          exit 0
        fi

        exec ${lib.getExe pkgs.nh} os switch "''${flake}#''${host}"
      '';
    in
    {
      programs.zsh.enable = true;

      users = lib.optionalAttrs (options ? users && options.users ? defaultUserShell) {
        defaultUserShell = pkgs.zsh;
      };

      # Linux fingerprint sudo — closest equivalent to macOS Touch ID (pam_tid).
      services.fprintd.enable = lib.mkDefault true;
      security.pam.services.sudo.fprintAuth = lib.mkDefault true;
      security.pam.services.sudo-i.fprintAuth = lib.mkDefault true;

      programs.ssh.enableAskPassword = lib.mkDefault true;

      environment = {
        systemPackages = [
          pkgs.nh
          pkgs.yazi
          pkgs.fh # FlakeHub CLI (Determinate Systems)
          sudoAskpass
          dendriticOsSwitch
        ];
        sessionVariables = {
          SUDO_ASKPASS = "${sudoAskpass}/bin/sudo-askpass";
        };
        etc."sudo.conf".text = ''
          # Dendritic: graphical sudo when no controlling tty (IDE agents, etc.).
          Path askpass ${sudoAskpass}/bin/sudo-askpass
        '';
      }
      // (lib.optionalAttrs (options ? environment && options.environment ? shells) {
        shells = [ pkgs.zsh ];
      });

      security.sudo.extraConfig = ''
        # 120 min: authenticate once, then reuse for a long session.
        Defaults timestamp_timeout=120
        Defaults env_keep += "SUDO_ASKPASS SSH_ASKPASS DISPLAY WAYLAND_DISPLAY XAUTHORITY"
        # nh elevates via `sudo env … switch-to-configuration` (not bare stc).
        Defaults!/run/current-system/sw/bin/env !requiretty
        Defaults!/run/current-system/sw/bin/nh !requiretty
        Defaults!/run/current-system/sw/bin/nixos-rebuild !requiretty
        Defaults!/nix/store/*/bin/switch-to-configuration !requiretty
        Defaults!/nix/var/nix/profiles/system/bin/switch-to-configuration !requiretty
      '';

      # Passwordless wheel: required for headless `nh os switch` / Cursor Remote.
      # nh does `sudo env VAR=… /nix/store/…/bin/switch-to-configuration`, so
      # NOPASSWD on switch-to-configuration alone never matches — env is the argv0.
      security.sudo.wheelNeedsPassword = false;

      # ── Cursor / IDE NoNewPrivs escape hatch ────────────────────────────
      # Electron (Cursor) sets PR_SET_NO_NEW_PRIVS on its process tree, so
      # `sudo`/`nh` elevation is impossible from integrated or agent terminals
      # even with wheelNeedsPassword=false. systemctl→systemd (root) does not
      # need setuid in the client — verified workable under Cursor's sandbox.
      # After one external activate of this unit, agents use:
      #   dendritic-os-switch [host]
      systemd.services."dendritic-os-switch@" = {
        description = "NixOS switch for flake host %i (NoNewPrivs / Cursor safe)";
        # Manual only — never restart/stop mid-activation (nested switch deadlock).
        restartIfChanged = false;
        stopIfChanged = false;
        path = [
          pkgs.nh
          pkgs.nix
          pkgs.git
          pkgs.coreutils
          pkgs.bash
          pkgs.util-linux
        ];
        serviceConfig = {
          Type = "oneshot";
          TimeoutStartSec = "2h";
        };
        # Instance name = flake attribute (e.g. sliceanddice).
        scriptArgs = "%i";
        script = ''
          set -euo pipefail
          host="$1"
          flake="''${DENDRITIC_FLAKE:-/etc/nixos/.dotfiles}"
          # System unit runs as root. nh refuses root; nh-as-user cannot
          # activate (polkit). Build as the flake owner (libgit2 ownership),
          # then activate as root via switch-to-configuration.
          echo "dendritic-os-switch: build ''${flake}#''${host} as alex; activate as root"
          out="$(${pkgs.util-linux}/bin/runuser -u alex -- ${pkgs.nix}/bin/nix build \
            --extra-experimental-features 'nix-command flakes' \
            --print-out-paths --no-link \
            "''${flake}#nixosConfigurations.''${host}.config.system.build.toplevel")"
          # switch-to-configuration alone does NOT advance /nix/var/nix/profiles/system
          # or systemd-boot's default entry — without this, the next reboot falls back
          # to an older generation (seen after Windows Setup BootNext).
          echo "dendritic-os-switch: setting system profile → $out"
          ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$out"
          # Install boot entries before switch so a mid-activation reboot (e.g.
          # dendritic-windows-continue-setup) still lands on this generation.
          echo "dendritic-os-switch: installing bootloader for $out"
          "$out/bin/switch-to-configuration" boot
          echo "dendritic-os-switch: activating $out"
          # Activation may stop this unit (definition changed) — ignore TERM so
          # switch-to-configuration can finish; otherwise USB/etc fixes never land.
          trap true TERM INT HUP
          exec "$out/bin/switch-to-configuration" switch
        '';
      };

      # Allow wheel to start/stop Cursor-safe units without an interactive polkit agent
      # (NoNewPrivs sessions have no auth prompt — StartUnit otherwise times out).
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (!subject.isInGroup("wheel")) return;
          if (action.id !== "org.freedesktop.systemd1.manage-units") return;
          var unit = action.lookup("unit");
          if (!unit) return;
          if (unit.indexOf("dendritic-os-switch@") === 0) {
            return polkit.Result.YES;
          }
          if (unit.indexOf("dendritic-windows-") === 0) {
            return polkit.Result.YES;
          }
        });
      '';
    };

  flake.modules.darwin.dendritic =
    { pkgs, inputs, ... }:
    {
      programs.zsh.enable = true;
      environment.shells = [ pkgs.zsh ];

      environment.systemPackages = [
        pkgs.nh
        pkgs.yazi
        pkgs.fh # FlakeHub CLI (Determinate Systems)
        inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

      system.activationScripts.postActivation.text = ''
        # Symlink the JDK into the system JavaVirtualMachines directory
        # This allows macOS apps and /usr/libexec/java_home to find the Nix JDK
        echo "Configuring /Library/Java/JavaVirtualMachines..."
        sudo mkdir -p /Library/Java/JavaVirtualMachines
        sudo ln -sfn ${pkgs.jdk21}/Library/Java/JavaVirtualMachines/zulu-21.jdk /Library/Java/JavaVirtualMachines/nix-jdk-21.jdk
      '';

      security.sudo.extraConfig = ''
        # 120 min: authenticate once, then reuse for a long session.
        Defaults timestamp_timeout=120
      '';
    };

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      lib,
      inputs,
      ...
    }:
    {
      # Always-on Cursor rule: rebuild via systemd when sudo is blocked.
      # Inline text (not `source`) so flakes don't require an untracked path.
      home.file.".cursor/rules/nixos-os-switch.mdc" = lib.mkIf pkgs.stdenv.isLinux {
        force = true;
        text = ''
          ---
          description: Rebuild NixOS from Cursor without sudo (NoNewPrivs)
          alwaysApply: true
          ---

          # NixOS switch from Cursor

          Cursor/Electron sets `PR_SET_NO_NEW_PRIVS`, so `sudo` and `nh os switch` fail in agent and integrated terminals (`sudo: The "no new privileges" flag is set`).

          **Do not** tell the user to use an external terminal for routine switches.

          Use the systemd-backed wrapper (runs `nh` as root via `systemctl`, no setuid in the client):

          ```bash
          dendritic-os-switch sliceanddice
          ```

          Host defaults to `hostname -s` if omitted. Flake path defaults to `/etc/nixos/.dotfiles` (`DENDRITIC_FLAKE` overrides).

          If the unit is missing (`Unit … not found`), the machine still needs **one** external bootstrap:

          ```bash
          nh os switch /etc/nixos/.dotfiles#sliceanddice
          ```

          After that, prefer `dendritic-os-switch` for all subsequent rebuilds from Cursor.
        '';
      };

      programs.eza = {
        enable = true;
        enableZshIntegration = true;
        git = true;
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
          "--header"
          "--all"
        ];
      };

      programs.zsh = {
        enable = true;
        enableCompletion = false; # We'll manage compinit manually for micro-optimization
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        # Use zsh from nixpkgs to override macOS default
        package = pkgs.zsh;

        shellAliases = {
          # Shortcuts built on top of programs.eza's native aliases
          l = "eza -a";
          lt = "eza --tree";
          tree = "eza --tree";
          llt = "eza -l --tree";
          lS = "eza -l -s size";
          ltm = "eza -l -s modified";
          # Cursor/NoNewPrivs-safe rebuild (see dendritic-os-switch@.service)
          nhos = "dendritic-os-switch";
        };

        # History substring search (replaces basic up-line-or-search)
        historySubstringSearch = {
          enable = true;
          # Keybindings set below in initContent
        };

        history = {
          size = 10000;
          path = "${config.home.homeDirectory}/.zsh_history";
        };

        initContent = lib.mkMerge [

          # ── Guard nix-darwin HM profile on PATH (before tmux auto-exec) ──
          # Ghostty→tmux can inject a PATH that only has ~/.nix-profile/bin,
          # where nixvim/nvim is NOT installed (it lives under /etc/profiles).
          (lib.mkOrder 40 ''
            typeset -U path
            _dendritic_hm_bin="/etc/profiles/per-user/${config.home.username}/bin"
            _dendritic_sw_bin="/run/current-system/sw/bin"
            [[ -d $_dendritic_hm_bin ]] && path=("$_dendritic_hm_bin" $path)
            [[ -d $_dendritic_sw_bin ]] && path=("$_dendritic_sw_bin" $path)
            unset _dendritic_hm_bin _dendritic_sw_bin
            export PATH
          '')

          # ── zsh-defer (must be loaded incredibly early) ──
          (lib.mkOrder 100 ''
            source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
          '')

          # ── Micro-optimized compinit ──
          (lib.mkOrder 200 ''
            # Load completions but only compile the cache if older than 24 hours
            autoload -Uz compinit
            if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
              compinit -C
            else
              compinit
              # Compile to zsh native bytecode in the background
              zsh-defer zcompile "''${ZDOTDIR:-$HOME}/.zcompdump"
            fi

            # Load the natively compiled bytecode cache
            autoload -Uz bashcompinit && bashcompinit
          '')

          # ── fzf-tab (must load after compinit, before other plugins) ──
          (lib.mkOrder 550 ''
            zsh-defer source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
          '')

          # ── Core plugins & integrations ──
          (lib.mkOrder 1000 ''
            # History substring search keybindings
            bindkey '^[[A' history-substring-search-up
            bindkey '^[[B' history-substring-search-down

            # ── zsh-you-should-use ──
            zsh-defer source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh

            # ── zsh-vi-mode ──
            zsh-defer source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

            # ── forgit (interactive git via fzf) ──
            zsh-defer source ${pkgs.zsh-forgit}/share/zsh/zsh-forgit/forgit.plugin.zsh

            # ── any-nix-shell (stay in zsh inside nix-shell/nix develop) ──
            zsh-defer eval "$(${pkgs.any-nix-shell}/bin/any-nix-shell zsh --info-right)"

            # ── fzf explicit deferred loading ──
            zsh-defer source ${pkgs.fzf}/share/fzf/key-bindings.zsh
            zsh-defer source ${pkgs.fzf}/share/fzf/completion.zsh

            # ── sudo toggle (ESC ESC) ──
            function _sudo_toggle() {
              if [[ -z "$BUFFER" ]]; then
                LBUFFER="sudo !!"
                zle expand-history
              elif [[ "$BUFFER" == sudo\ * ]]; then
                LBUFFER="''${LBUFFER#sudo }"
              else
                LBUFFER="sudo $LBUFFER"
              fi
            }
            zle -N _sudo_toggle
            bindkey '\e\e' _sudo_toggle

            # ── sudo: askpass when no controlling tty (IDE agents, etc.) ──
            sudo() {
              if [[ ! -t 0 ]] && [[ -n "''${SUDO_ASKPASS:-}" ]]; then
                command sudo -A "$@"
              else
                command sudo "$@"
              fi
            }

            # ── colored-man-pages ──
            export LESS_TERMCAP_mb=$'\e[1;31m'
            export LESS_TERMCAP_md=$'\e[1;36m'
            export LESS_TERMCAP_me=$'\e[0m'
            export LESS_TERMCAP_so=$'\e[01;33m'
            export LESS_TERMCAP_se=$'\e[0m'
            export LESS_TERMCAP_ue=$'\e[0m'
            export LESS_TERMCAP_us=$'\e[1;32m'

            # ── extract (smart archive extraction) ──
            function extract() {
              if [[ -f "$1" ]]; then
                case "$1" in
                  *.tar.bz2) tar xjf "$1" ;;
                  *.tar.gz)  tar xzf "$1" ;;
                  *.tar.xz)  tar xJf "$1" ;;
                  *.bz2)     bunzip2 "$1" ;;
                  *.rar)     unrar x "$1" ;;
                  *.gz)      gunzip "$1" ;;
                  *.tar)     tar xf "$1" ;;
                  *.tbz2)    tar xjf "$1" ;;
                  *.tgz)     tar xzf "$1" ;;
                  *.zip)     unzip "$1" ;;
                  *.Z)       uncompress "$1" ;;
                  *.7z)      7z x "$1" ;;
                  *.zst)     zstd -d "$1" ;;
                  *)         echo "extract: unknown format '$1'" ;;
                esac
              else
                echo "extract: '$1' is not a valid file"
              fi
            }
          '')
        ];
      };

      # ── fzf (fuzzy finder with Ctrl+R, Ctrl+T, Alt+C) ──
      programs.fzf = {
        enable = true;
        enableZshIntegration = false; # We defer it manually!
        defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
        changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git";
        defaultOptions = [
          "--height=40%"
          "--layout=reverse"
          "--border"
          "--info=inline"
        ];
      };

      # ── zoxide (smart cd) ──
      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
        options = [
          "--cmd"
          "cd"
        ]; # Replace cd entirely
      };

      # ── direnv + nix-direnv (auto-load devShells) ──
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
        # Silence the verbose loading messages
        config.global.hide_env_diff = true;
      };

      # ── bat (cat replacement with syntax highlighting) ──
      programs.bat = {
        enable = true;
        config = {
          theme = lib.mkDefault "ansi"; # Stylix may override this
          style = "numbers,changes,header";
        };
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batgrep
        ];
      };

      # ── nix-index (command-not-found integration) ──
      programs.nix-index = {
        enable = true;
        enableZshIntegration = false; # Too heavy to run synchronously
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          # Keep Docker disabled as it was confirmed to cause noise
          docker_context.disabled = true;
          # Don't leak personal Google account email into every prompt.
          gcloud.disabled = true;

          # Restore other modules
          git_status.disabled = false;
          nix_shell.disabled = false;

          # Performance optimizations
          command_timeout = 2000; # Increased to 2s to prevent Swift/Swiftly timeouts
          scan_timeout = 100; # Default 30ms is too low for dirs with nix store symlinks

          # Clean up the directory module
          directory = {
            read_only = "";
            truncation_length = 3;
            truncate_to_repo = true;
          };
        };
      };

      home.sessionVariables = lib.mkMerge [
        {
          NH_FLAKE = (
            if pkgs.stdenv.isDarwin then
              "/etc/nix-darwin/.dotfiles#mba"
            else
              "/etc/nixos/.dotfiles#sliceanddice"
          );
        }
        (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
          NH_OS_FLAKE = "/etc/nixos/.dotfiles#sliceanddice";
        })
      ];

      # Yazi minimal configuration with ANSI inheritance
      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
        settings = {
          mgr = {
            show_hidden = true;
            sort_by = "natural";
          };
        };
        # Use the nixpkgs-packaged plugin instead of fetching the yazi-rs
        # `main` branch tarball, whose hash drifts and broke every HM build.
        plugins = {
          mount = pkgs.yaziPlugins.mount;
        };
        keymap = {
          mgr.prepend_keymap = [
            {
              on = [ "M" ];
              run = "plugin mount";
              desc = "Mount disk";
            }
          ];
        };
      };

      # Btop (themed by Stylix)
      programs.btop = {
        enable = true;
        settings = {
          theme_background = false;
          truecolor = true;
        };
      };

      programs.htop.enable = true;

      home.packages = with pkgs; [
        nh
        zsh-defer
        zsh-completions
        nix-zsh-completions # Tab completions for nix CLI
        comma # Run any nixpkgs binary without installing: , cowsay hello
        manix # Fast CLI docs search for NixOS/home-manager options
        fd # find replacement, used by fzf
        # (import ./pkgs/_fancy-cat.nix { inherit pkgs; }) # Takes too long
      ];
    };
}
