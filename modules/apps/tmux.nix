# Dendritic tmux — unified multiplexer for Darwin + NixOS.
#
# Goals (popular modern defaults across macOS/Linux):
#   - Ctrl-a prefix, vi keys, mouse, truecolor
#   - Single status row: window tabs + session badge (sessions via sessionx, not a 2nd bar)
#   - | / - splits, vim-tmux-navigator, yank → system clipboard
#   - resurrect + continuum, sessionx fuzzy sessions (prefix+o)
#   - which-key interactive menu (prefix+Space / prefix+?) — Nix-safe prebuild
#   - Interactive tutorial: `tmuxhelp` / prefix+T (zsh tip until first complete)
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

      # Seed theme from Stylix (wallpaper-derived base16). Runtime wallpaper /
      # appearance flips rewrite ~/.config/tmux/theme.conf from ~/colors.toml.
      c = config.lib.stylix.colors.withHashtag;
      themeConf = ''
        # Seeded by HM from stylix.base16Scheme; overwritten at runtime by
        # dendritic-appearance from ~/colors.toml (same palette as wallpaper).
        set -g status-style "fg=${c.base05},bg=${c.base00}"
        set -g message-style "fg=${c.base06},bg=${c.base02}"
        set -g message-command-style "fg=${c.base06},bg=${c.base02}"
        set -g pane-border-style "fg=${c.base02}"
        set -g pane-active-border-style "fg=${c.base04}"
        set -g mode-style "fg=${c.base04},bg=${c.base02}"

        set -g window-status-style "fg=${c.base05},bg=${c.base00}"
        set -g window-status-current-style "fg=${c.base0A},bg=${c.base00}"
        set -g window-status-activity-style "fg=${c.base05},bg=${c.base00}"
        set -g window-status-bell-style "fg=${c.base00},bg=${c.base08}"
        set -g window-status-separator ""
        set -g window-status-format "#[fg=${c.base00},bg=${c.base02},noitalics]#[fg=${c.base06},bg=${c.base02}] #I  #W#{?window_zoomed_flag,*Z,} #[fg=${c.base02},bg=${c.base00},noitalics]"
        set -g window-status-current-format "#[fg=${c.base00},bg=${c.base0A},nobold,noitalics,nounderscore]#[fg=${c.base02},bg=${c.base0A}] #I #[fg=${c.base02},bg=${c.base0A},bold] #W#{?window_zoomed_flag,*Z,} #[fg=${c.base0A},bg=${c.base00},nobold,noitalics,nounderscore]"

        set -g status-left "#[fg=${c.base05},bg=${c.base02}] #S #[fg=${c.base02},bg=${c.base00},nobold,noitalics,nounderscore]"
        set -g status-right "#[fg=${c.base03}]#{prefix_highlight}#[fg=${c.base02},bg=${c.base00}]#[fg=${c.base04},bg=${c.base02}] %H:%M #[range=right fg=${c.base00},bg=${c.base0B},bold] + #[norange]"

        set -g @prefix_highlight_fg '${c.base00}'
        set -g @prefix_highlight_bg '${c.base0E}'
      '';

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
        # We own theming via theme.conf (Stylix seed + runtime colors.toml).
        # Stylix's tinted-tmux target would double-source a build-time-only theme.
        stylix.targets.tmux.enable = false;

        home.packages = [
          tutorialBin
          learnBin
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.wl-clipboard ];

        # Keep YAML discoverable for humans; runtime uses the Nix-built init.
        xdg.configFile."tmux/plugins/tmux-which-key/config.yaml".source = whichKeyConfig;
        xdg.dataFile."tmux/plugins/tmux-which-key/init.tmux".source = "${whichKeyInit}/init.tmux";
        # Force so wallpaper/appearance rewrites aren't blocked by HM backup clash.
        xdg.configFile."tmux/theme.conf" = {
          text = themeConf;
          force = true;
        };

        # Ghostty: land in tmux immediately (no bare-zsh flash).
        programs.ghostty.settings.command = lib.mkIf (
          cfg.autoStart && (config.programs.ghostty.enable or false)
        ) (lib.mkForce "${pkgs.tmux}/bin/tmux new-session -A -s main");

        programs.zsh.initContent = lib.mkMerge [
          # Other terminals / SSH: exec into tmux before heavy zsh init.
          (lib.mkIf cfg.autoStart (
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
          ))

          # One-shot banner until the tutorial has been completed once.
          (lib.mkOrder 1200 ''
            if [[ $- == *i* && -n ''${TMUX:-} && ! -f "$HOME/.cache/tmux-tutorial-seen" ]]; then
              print -P '%F{8}tmux tip:%f  %Btmuxhelp%b  or  %BCtrl-a T%b  → interactive tutorial'
            fi
          '')
        ];

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
            prefix-highlight
            better-mouse-mode
            tmux-sessionx
            # tmux-which-key: sourced below (plugin.sh.tmux is broken on macOS/Nix)
          ];

          extraConfig = ''
            # Truecolor for Ghostty / Kitty / Alacritty / foot
            set -ag terminal-overrides ",*:RGB"
            set -ag terminal-features ",*:RGB"
            set -s extended-keys on
            set -as terminal-features '*:extkeys'

            # Ghostty/macOS hands tmux a tiny PATH; run-shell needs Nix bins.
            set-environment -g PATH "${config.home.profileDirectory}/bin:/nix/var/nix/profiles/default/bin:${
              lib.makeBinPath [
                pkgs.tmux
                pkgs.bash
                pkgs.coreutils
                pkgs.zsh
                pkgs.fzf
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin"

            source-file ${whichKeyInit}/init.tmux

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
            set -g status-interval 2
            set -g display-time 2500
            set -g status-position top
            set -g status-justify left

            # One status row. NEVER `set -gu status-format[0]` — that deletes the
            # window-list renderer and leaves a blank/white bar (tmux does not
            # restore defaults on unset). Heal [0] explicitly for live servers.
            set -g status on
            set -g status-format[0] "#[align=left range=left #{E:status-left-style}]#[push-default]#{T;=/#{status-left-length}:status-left}#[pop-default]#[norange default]#[list=on align=#{status-justify}]#[list=left-marker]<#[list=right-marker]>#[list=on]#{W:#[range=window|#{window_index} #{E:window-status-style}#{?#{&&:#{window_last_flag},#{!=:#{E:window-status-last-style},default}}, #{E:window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{E:window-status-bell-style},default}}, #{E:window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{E:window-status-activity-style},default}}, #{E:window-status-activity-style},}}]#[push-default]#{T:window-status-format}#[pop-default]#[norange default]#{?loop_last_flag,,#{window-status-separator}},#[range=window|#{window_index} list=focus #{?#{!=:#{E:window-status-current-style},default},#{E:window-status-current-style},#{E:window-status-style}}#{?#{&&:#{window_last_flag},#{!=:#{E:window-status-last-style},default}}, #{E:window-status-last-style},}#{?#{&&:#{window_bell_flag},#{!=:#{E:window-status-bell-style},default}}, #{E:window-status-bell-style},#{?#{&&:#{||:#{window_activity_flag},#{window_silence_flag}},#{!=:#{E:window-status-activity-style},default}}, #{E:window-status-activity-style},}}]#[push-default]#{T:window-status-current-format}#[pop-default]#[norange list=on default]#{?loop_last_flag,,#{window-status-separator}}}#[nolist align=right range=right #{E:status-right-style}]#[push-default]#{T;=/#{status-right-length}:status-right}#[pop-default]#[norange default]"

            set -g status-left-length 40
            set -g status-right-length 60

            # Base16 colors from Stylix (wallpaper scheme) — live file rewritten
            # by dendritic-appearance when wallpaper / light-dark flips.
            source-file -q ~/.config/tmux/theme.conf

            setw -g monitor-activity on
            set -g visual-activity off

            # Mouse: click tab; middle-click kill; "+" new window; session badge → picker
            bind -n MouseDown2Status kill-window
            bind -n MouseDown1StatusRight new-window -c "#{pane_current_path}"
            bind -n MouseDown1StatusLeft choose-tree -Zs
            bind -n MouseDown3StatusLeft display-menu -T "session #S" -x M -y W \
              "Switch session…" o { choose-tree -Zs } \
              "Next session" n { switch-client -n } \
              "Previous session" p { switch-client -p } \
              "" \
              "New session" s { command-prompt -p 'new session:' { new-session -A -s "%%" } } \
              "Rename session" r { command-prompt -I "#S" { rename-session "%%" } } \
              "Kill session" X { confirm-before -p "Kill #S?" kill-session }

            bind -N "New window (tab)" c new-window -c "#{pane_current_path}"
            bind -N "New session" C command-prompt -p 'new session:' { new-session -A -s "%%" }
            bind -N "Kill session" X confirm-before -p "Kill session #S?" kill-session
            bind -N "Next window" -n C-Tab next-window
            bind -N "Previous window" -n C-S-Tab previous-window
            bind -N "Next window" -r n next-window
            bind -N "Previous window" -r p previous-window
            bind -N "Last window" -r Tab last-window
            bind -N "Next session" -r ) switch-client -n
            bind -N "Previous session" -r ( switch-client -p

            set -g @sessionx-bind 'o'
            set -g @sessionx-zoxide-mode 'off'
            set -g @sessionx-filter-current 'false'
            set -g @sessionx-window-mode 'off'

            set -g @prefix_highlight_show_copy_mode 'on'

            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
            set -g @resurrect-capture-pane-contents 'on'

            bind -N "Which-key menu" ? show-wk-menu-root
            bind -N "Interactive tmux tutorial" T display-popup -w 90% -h 90% -E "${tutorialBin}/bin/tmux-tutorial"
            bind -N "Interactive tmux tutorial" F1 display-popup -w 90% -h 90% -E "${tutorialBin}/bin/tmux-tutorial"
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
