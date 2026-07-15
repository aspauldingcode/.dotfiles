# Dendritic tmux — unified multiplexer for Darwin + NixOS.
#
# Goals (popular modern defaults across macOS/Linux):
#   - Ctrl-a prefix, vi keys, mouse, truecolor
#   - | / - splits, vim-tmux-navigator, yank → system clipboard
#   - resurrect + continuum session persistence
#   - which-key interactive menu (prefix+Space / prefix+?) — Nix-safe prebuild
#   - Interactive tutorial: `tmux-learn` or prefix+F1
#
# which-key note: do NOT run upstream plugin.sh.tmux. On macOS, BSD realpath
# lacks --relative-to (XDG probe fails); the Nix store is also read-only.
# We prebuild init.tmux in Nix and source it directly.
{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.dendritic.apps.tmux;
      whichKeySrc = "${pkgs.tmuxPlugins.tmux-which-key}/share/tmux-plugins/tmux-which-key";

      tutorialBin = pkgs.writeShellScriptBin "tmux-tutorial" ''
        exec ${pkgs.bash}/bin/bash ${../../scripts/tmux-tutorial.sh}
      '';

      learnBin = pkgs.writeShellScriptBin "tmux-learn" ''
        set -euo pipefail
        TMUX_BIN=${pkgs.tmux}/bin/tmux
        TUTORIAL=${tutorialBin}/bin/tmux-tutorial
        # run-shell does not export TMUX; probe the server instead.
        if "$TMUX_BIN" display-message -p '#S' >/dev/null 2>&1; then
          exec "$TMUX_BIN" display-popup -w 90% -h 90% -E "$TUTORIAL"
        fi
        exec "$TMUX_BIN" new-session -A -s tutorial \
          "$TUTORIAL; $TMUX_BIN kill-session -t tutorial 2>/dev/null || true"
      '';

      # Stock example + a Tutorial entry at the top of the root menu.
      whichKeyConfig =
        pkgs.runCommand "tmux-which-key-config.yaml"
          {
            nativeBuildInputs = [
              pkgs.python3
              pkgs.python3Packages.pyyaml
            ];
          }
          ''
            ${pkgs.python3}/bin/python3 - "${whichKeySrc}/config.example.yaml" "$out" "${tutorialBin}/bin/tmux-tutorial" <<'PY'
            import sys, pathlib, yaml
            src, dest, tutorial = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
            data = yaml.safe_load(src.read_text())
            data.setdefault("keybindings", {})
            data["keybindings"]["prefix_table"] = "Space"
            data["keybindings"]["root_table"] = "C-Space"
            tutorial_item = {
                "name": "Tutorial",
                "key": "t",
                "command": f'display-popup -w 90% -h 90% -E "{tutorial}"',
            }
            items = data.get("items") or []
            items = [i for i in items if not (isinstance(i, dict) and i.get("name") == "Tutorial")]
            data["items"] = [tutorial_item, {"separator": True}] + items
            dest.write_text(yaml.safe_dump(data, sort_keys=False))
            PY
          '';

      whichKeyInit =
        pkgs.runCommand "tmux-which-key-init"
          {
            nativeBuildInputs = [
              pkgs.python3
              pkgs.python3Packages.pyyaml
            ];
          }
          ''
            mkdir -p $out
            cp ${whichKeyConfig} $out/config.yaml
            ${whichKeySrc}/plugin/build.py $out/config.yaml $out/init.tmux
            # Quiet the chatty display -p banners on every attach/reload.
            sed -i.bak \
              -e '/display -p .*Loading plugin/d' \
              -e '/display -p .*Binding /d' \
              -e '/display -p .*Done/d' \
              $out/init.tmux
            rm -f $out/init.tmux.bak
          '';
    in
    {
      options.dendritic.apps.tmux = {
        enable = lib.mkEnableOption "dendritic tmux (Ctrl-a, which-key, tutorial)" // {
          default = true;
        };
        autoStart = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Auto-attach session "main" from interactive shells and Ghostty.
            Escape hatch: DENDRITIC_NO_TMUX=1. Skips Cursor/VS Code terminals.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          tutorialBin
          learnBin
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard ];

        # Keep YAML discoverable for humans; runtime uses the Nix-built init.
        xdg.configFile."tmux/plugins/tmux-which-key/config.yaml".source = whichKeyConfig;
        xdg.dataFile."tmux/plugins/tmux-which-key/init.tmux".source = "${whichKeyInit}/init.tmux";

        # Ghostty: land in tmux immediately (no bare-zsh flash).
        programs.ghostty.settings.command = lib.mkIf (
          cfg.autoStart && (config.programs.ghostty.enable or false)
        ) (lib.mkForce "${pkgs.tmux}/bin/tmux new-session -A -s main");

        # Other terminals / SSH: exec into tmux before heavy zsh init.
        programs.zsh.initContent = lib.mkIf cfg.autoStart (
          lib.mkOrder 50 ''
            # Dendritic tmux auto-start (Ghostty uses command=tmux; this covers the rest)
            if [[ -z ''${TMUX:-} && -z ''${DENDRITIC_NO_TMUX:-} && -z ''${STY:-} && -z ''${ZELLIJ:-} && $- == *i* ]]; then
              case ''${TERM_PROGRAM:-} in
                vscode|cursor) ;;
                *)
                  case ''${TERM:-} in
                    dumb|linux) ;;
                    *)
                      exec ${pkgs.tmux}/bin/tmux new-session -A -s main
                      ;;
                  esac
                  ;;
              esac
            fi
          ''
        );

        programs.tmux = {
          enable = true;
          shortcut = "a";
          baseIndex = 1;
          keyMode = "vi";
          mouse = true;
          clock24 = true;
          escapeTime = 0;
          historyLimit = 50000;
          focusEvents = true;
          aggressiveResize = true;
          terminal = "tmux-256color";
          shell = "${pkgs.zsh}/bin/zsh";
          sensibleOnTop = true;

          plugins = with pkgs.tmuxPlugins; [
            sensible
            vim-tmux-navigator
            yank
            resurrect
            continuum
            fzf-tmux-url
            # tmux-which-key: sourced below (plugin.sh.tmux is broken on macOS/Nix)
          ];

          extraConfig = ''
            # Truecolor for Ghostty / Kitty / Alacritty / foot
            set -ag terminal-overrides ",*:RGB"
            set -ag terminal-features ",*:RGB"
            # So Ctrl-Tab / Ctrl-Shift-Tab reach tmux (Ghostty, Kitty, etc.)
            set -s extended-keys on
            set -as terminal-features '*:extkeys'

            # Ghostty/macOS hands tmux a tiny PATH; run-shell needs Nix bins.
            set-environment -g PATH "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:${
              lib.makeBinPath [
                pkgs.tmux
                pkgs.bash
                pkgs.coreutils
                pkgs.zsh
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin"

            # which-key (Nix-prebuilt — skip upstream plugin.sh.tmux)
            source-file ${whichKeyInit}/init.tmux

            # Ergonomic splits
            bind -N "Split vertical"   | split-window -h -c "#{pane_current_path}"
            bind -N "Split horizontal" - split-window -v -c "#{pane_current_path}"
            unbind '"'
            unbind %

            bind -r -N "Resize left"  H resize-pane -L 5
            bind -r -N "Resize down"  J resize-pane -D 5
            bind -r -N "Resize up"    K resize-pane -U 5
            bind -r -N "Resize right" L resize-pane -R 5

            bind -T copy-mode-vi v send-keys -X begin-selection
            bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
            bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

            set -g renumber-windows on
            setw -g pane-base-index 1
            set -g status-interval 5
            set -g display-time 2500
            set -g status-position top

            # Windows-as-tabs (status bar). Click with mouse; C-a c = new tab.
            set -g status-style "bg=default,fg=default"
            set -g status-left-length 24
            set -g status-right-length 48
            set -g status-left "#[bold]#S "
            set -g status-right " %H:%M "
            set -g status-justify left
            set -g window-status-separator ""
            set -g window-status-format "#[fg=brightblack] #I:#W "
            set -g window-status-current-format "#[reverse,bold] #I:#W #[noreverse]"
            set -g window-status-activity-style "fg=yellow"
            setw -g monitor-activity on
            set -g visual-activity off

            # Tab-ish navigation (windows)
            bind -N "New tab (window)" c new-window -c "#{pane_current_path}"
            bind -N "Next tab" -n C-Tab next-window
            bind -N "Previous tab" -n C-S-Tab previous-window
            bind -N "Next tab" -r n next-window
            bind -N "Previous tab" -r p previous-window
            bind -N "Last tab" -r Tab last-window

            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
            set -g @resurrect-capture-pane-contents 'on'

            # Discoverability
            #   C-a Space / C-a ?  → which-key menu (Tutorial is first entry: t)
            #   C-a T / C-a F1     → interactive tutorial popup
            bind -N "Which-key menu" ? show-wk-menu-root
            bind -N "Interactive tmux tutorial" T display-popup -w 90% -h 90% -E "${tutorialBin}/bin/tmux-tutorial"
            bind -N "Interactive tmux tutorial" F1 display-popup -w 90% -h 90% -E "${tutorialBin}/bin/tmux-tutorial"

            # First attach ever: open the tutorial (don't rely on remembering keys).
            set-hook -g client-attached {
              if-shell '[ ! -f "$HOME/.cache/tmux-tutorial-seen" ]' {
                run-shell -d 1 'tmux display-popup -w 90% -h 90% -E "${tutorialBin}/bin/tmux-tutorial"'
              }
            }
          '';
        };

        programs.zsh.shellAliases = {
          t = "tmux new-session -A -s main";
          tmuxhelp = "tmux-learn";
          "tmux-help" = "tmux-learn";
        };
      };
    };
}
