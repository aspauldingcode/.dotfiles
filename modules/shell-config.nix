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

      # Elevates via systemd when PR_SET_NO_NEW_PRIVS blocks sudo (legacy
      # code-cursor-fhs session, or any parent that set the flag).
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
          pkgs.jflap
          pkgs.texliveFull
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

      # ── NoNewPrivs escape hatch ────────────────────────────────────────
      # If this process still has PR_SET_NO_NEW_PRIVS (old FHS Cursor, or a
      # parent set the flag), sudo/nh cannot elevate. systemctl→systemd does
      # not need setuid in the client. Agents use: dendritic-os-switch [host]
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
          # or the bootloader default entry — without this, the next reboot falls back
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
        pkgs.jflap
        pkgs.texliveFull
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

        # Passwordless sudo for CLI / Cursor agents (no tty for Touch ID).
        # Matches NixOS security.sudo.wheelNeedsPassword = false.
        Defaults:8amps !requiretty
        8amps ALL=(ALL) NOPASSWD: ALL
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
          description: Rebuild NixOS from Cursor (sudo or dendritic-os-switch)
          alwaysApply: true
          ---

          # NixOS switch from Cursor

          Linux Cursor is the patchelf'd `code-cursor` package (not FHS/bwrap), so `sudo` and `nh os switch` should work in the agent and integrated terminal.

          Prefer:

          ```bash
          nh os switch /etc/nixos/.dotfiles#sliceanddice
          ```

          Host defaults to `hostname -s`. Flake path defaults to `/etc/nixos/.dotfiles`.

          If `/proc/self/status` still has `NoNewPrivs: 1` (old FHS session, or a parent set the flag), `sudo` fails with *The "no new privileges" flag is set*. Then use:

          ```bash
          dendritic-os-switch sliceanddice
          ```

          That starts a systemd unit so elevation happens outside this process tree. **Do not** tell the user to open an external terminal for routine switches.
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
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        package = pkgs.zsh;

        shellAliases = {
          l = "eza -a";
          tree = "eza --tree";
          nhos = "dendritic-os-switch";
        };

        historySubstringSearch.enable = true;

        history = {
          size = 10000;
          path = "${config.home.homeDirectory}/.zsh_history";
        };

        initContent = lib.mkMerge [
          (lib.mkOrder 40 ''
            typeset -U path
            _dendritic_hm_bin="/etc/profiles/per-user/${config.home.username}/bin"
            _dendritic_sw_bin="/run/current-system/sw/bin"
            [[ -d $_dendritic_hm_bin ]] && path=("$_dendritic_hm_bin" $path)
            [[ -d $_dendritic_sw_bin ]] && path=("$_dendritic_sw_bin" $path)
            # NixOS setuid sudo lives in wrappers. Prepending sw/bin above
            # would otherwise shadow it and Cursor agents get:
            #   sudo must be owned by uid 0 and have the setuid bit set
            _dendritic_wrappers="/run/wrappers/bin"
            [[ -d $_dendritic_wrappers ]] && path=("$_dendritic_wrappers" $path)
            unset _dendritic_hm_bin _dendritic_sw_bin _dendritic_wrappers
            export PATH
          '')

          (lib.mkOrder 550 ''
            source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
          '')

          (lib.mkOrder 1000 ''
            source ${pkgs.fzf}/share/fzf/completion.zsh

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

            sudo() {
              local sudo_bin=/run/wrappers/bin/sudo
              [[ -x $sudo_bin ]] || sudo_bin=sudo
              if [[ ! -t 0 ]] && [[ -n "''${SUDO_ASKPASS:-}" ]]; then
                command "$sudo_bin" -A "$@"
              else
                command "$sudo_bin" "$@"
              fi
            }

            function zvm_after_init() {
              source ${pkgs.fzf}/share/fzf/key-bindings.zsh
              bindkey -M viins '^[[A' history-substring-search-up
              bindkey -M viins '^[[B' history-substring-search-down
              bindkey -M vicmd '^[[A' history-substring-search-up
              bindkey -M vicmd '^[[B' history-substring-search-down
              bindkey -M viins '\e\e' _sudo_toggle
            }
            source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
          '')

          (lib.mkOrder 1200 ''
            function y() {
              local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
              command yazi "$@" --cwd-file="$tmp"
              cwd="$(tr -d '\0' <"$tmp")"
              [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
              command rm -f -- "$tmp"
            }
          '')
        ];
      };

      # ── fzf (fuzzy finder with Ctrl+R, Ctrl+T, Alt+C) ──
      programs.fzf = {
        enable = true;
        enableZshIntegration = false; # Keybinds wait for zsh-vi-mode (zvm_after_init)
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

      # Own Starship palette (not stylix.targets.starship): wallpaper / light-dark
      # hot-writes ~/.config/starship.toml from ~/.colors.toml via
      # dendritic-appearance — same live path as Ghostty + Yazi.
      stylix.targets.starship.enable = lib.mkForce false;

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
        settings =
          let
            c = config.lib.stylix.colors.withHashtag;
          in
          {
            add_newline = false;
            command_timeout = 1000;
            scan_timeout = 100;
            format = "$directory$git_branch$git_status$nix_shell$character";
            palette = "base16";
            character = {
              success_symbol = "[❯](bold green)";
              error_symbol = "[❯](bold red)";
            };
            directory = {
              truncation_length = 3;
              truncate_to_repo = true;
              style = "bold cyan";
            };
            git_branch = {
              style = "bold purple";
            };
            git_status = {
              style = "bold yellow";
            };
            nix_shell = {
              style = "bold blue";
            };
            # Seed until first wallpaper / appearance apply.
            palettes.base16 = {
              black = c.base00;
              bright-black = c.base03;
              white = c.base05;
              bright-white = c.base07;
              red = c.base08;
              bright-red = c.base08;
              orange = c.base09;
              yellow = c.base0A;
              bright-yellow = c.base0A;
              green = c.base0B;
              bright-green = c.base0B;
              cyan = c.base0C;
              bright-cyan = c.base0C;
              blue = c.base0D;
              bright-blue = c.base0D;
              purple = c.base0E;
              magenta = c.base0E;
              bright-magenta = c.base0E;
              bright-purple = c.base0E;
              brown = c.base0F;
              base00 = c.base00;
              base01 = c.base01;
              base02 = c.base02;
              base03 = c.base03;
              base04 = c.base04;
              base05 = c.base05;
              base06 = c.base06;
              base07 = c.base07;
              base08 = c.base08;
              base09 = c.base09;
              base0A = c.base0A;
              base0B = c.base0B;
              base0C = c.base0C;
              base0D = c.base0D;
              base0E = c.base0E;
              base0F = c.base0F;
              base10 = c.base00;
              base11 = c.base00;
              base12 = c.base08;
              base13 = c.base0A;
              base14 = c.base0B;
              base15 = c.base0C;
              base16 = c.base0D;
              base17 = c.base0E;
            };
          };
      };

      home.sessionVariables = lib.mkMerge [
        {
          # Never let starship [WARN] hit the TTY during prompt render.
          STARSHIP_LOG = "error";
          NH_FLAKE = lib.mkDefault (
            if pkgs.stdenv.isDarwin then
              "/etc/nix-darwin/.dotfiles#mba"
            else
              "/etc/nixos/.dotfiles#sliceanddice"
          );
        }
        (lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
          NH_OS_FLAKE = lib.mkDefault "/etc/nixos/.dotfiles#sliceanddice";
        })
      ];

      # Yazi: `y` wrapper lives in programs.zsh.initContent (not HM's stock
      # snippet) so cwd-file NUL handling works with zoxide-as-cd. Pin
      # shellWrapperName — stateVersion < 26.05 defaults to "yy".
      # Own the theme (not stylix.targets.yazi): wallpaper rotation hot-writes
      # ~/.config/yazi/theme.toml from ~/.colors.toml via dendritic-appearance,
      # same pattern as Ghostty's dendritic-wallpaper theme.
      stylix.targets.yazi.enable = lib.mkForce false;

      programs.yazi = {
        enable = true;
        enableZshIntegration = false; # Custom `y` in zsh.initContent above
        enableBashIntegration = true;
        shellWrapperName = "y";
        settings = {
          mgr = {
            show_hidden = true;
            sort_by = "natural";
          };
        };
        # Seed until first wallpaper apply (matches live colors.toml palette).
        theme =
          let
            c = config.lib.stylix.colors.withHashtag;
          in
          {
            mgr = {
              overall = {
                bg = c.base00;
              };
              cwd = {
                fg = c.base0C;
              };
              find_keyword = {
                fg = c.base0B;
                bold = true;
              };
              find_position = {
                fg = c.base0E;
              };
              marker_copied = {
                fg = c.base0B;
                bg = c.base0B;
              };
              marker_cut = {
                fg = c.base08;
                bg = c.base08;
              };
              marker_selected = {
                fg = c.base0A;
                bg = c.base0A;
              };
              border_style = {
                fg = c.base04;
              };
              count_copied = {
                fg = c.base00;
                bg = c.base0B;
              };
              count_cut = {
                fg = c.base00;
                bg = c.base08;
              };
              count_selected = {
                fg = c.base00;
                bg = c.base0A;
              };
            };
            indicator = {
              current = {
                bg = c.base02;
                bold = true;
              };
              preview = {
                bg = c.base02;
                bold = true;
              };
            };
            tabs = {
              active = {
                fg = c.base00;
                bg = c.base0D;
                bold = true;
              };
              inactive = {
                fg = c.base0D;
                bg = c.base01;
              };
            };
            mode = {
              normal_main = {
                fg = c.base00;
                bg = c.base0D;
                bold = true;
              };
              normal_alt = {
                fg = c.base0D;
                bg = c.base00;
              };
              select_main = {
                fg = c.base00;
                bg = c.base0B;
                bold = true;
              };
              select_alt = {
                fg = c.base0B;
                bg = c.base00;
              };
              unset_main = {
                fg = c.base00;
                bg = c.base0F;
                bold = true;
              };
              unset_alt = {
                fg = c.base0F;
                bg = c.base00;
              };
            };
            status = {
              overall = {
                bg = c.base01;
                fg = c.base05;
              };
              progress_label = {
                fg = c.base05;
                bg = c.base00;
              };
              progress_normal = {
                fg = c.base05;
                bg = c.base00;
              };
              progress_error = {
                fg = c.base08;
                bg = c.base00;
              };
              perm_type = {
                fg = c.base0D;
              };
              perm_read = {
                fg = c.base0A;
              };
              perm_write = {
                fg = c.base08;
              };
              perm_exec = {
                fg = c.base0B;
              };
              perm_sep = {
                fg = c.base0C;
              };
            };
            filetype.rules = [
              {
                mime = "image/*";
                fg = c.base0C;
              }
              {
                mime = "video/*";
                fg = c.base0A;
              }
              {
                mime = "audio/*";
                fg = c.base0A;
              }
              {
                mime = "application/{zip,gzip,tar,bzip,bzip2,7z-compressed,rar,xz}";
                fg = c.base0E;
              }
              {
                mime = "application/{doc,pdf,rtf,vnd.*}";
                fg = c.base0B;
              }
              {
                url = "*/";
                fg = c.base0D;
                bold = true;
              }
              {
                mime = "*";
                fg = c.base05;
              }
            ];
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
        zsh-completions
        nix-zsh-completions
        comma
        manix
        fd
        jflap
        texliveFull
      ];
    };
}
