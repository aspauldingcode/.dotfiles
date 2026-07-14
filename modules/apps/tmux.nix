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
            ${pkgs.python3}/bin/python3 - "${whichKeySrc}/config.example.yaml" "$out" <<'PY'
            import sys, pathlib, yaml
            src, dest = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
            data = yaml.safe_load(src.read_text())
            data.setdefault("keybindings", {})
            data["keybindings"]["prefix_table"] = "Space"
            data["keybindings"]["root_table"] = "C-Space"
            tutorial = {
                "name": "Tutorial",
                "key": "t",
                "command": 'run-shell "tmux-learn"',
            }
            items = data.get("items") or []
            items = [i for i in items if not (isinstance(i, dict) and i.get("name") == "Tutorial")]
            data["items"] = [tutorial, {"separator": True}] + items
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

      tutorialBin = pkgs.writeShellScriptBin "tmux-tutorial" ''
        exec ${pkgs.bash}/bin/bash ${../../scripts/tmux-tutorial.sh}
      '';

      learnBin = pkgs.writeShellScriptBin "tmux-learn" ''
        set -euo pipefail
        if [[ -n ''${TMUX:-} ]]; then
          exec tmux display-popup -w 90% -h 90% -E ${tutorialBin}/bin/tmux-tutorial
        fi
        exec tmux new-session -A -s tutorial \
          "${tutorialBin}/bin/tmux-tutorial; tmux kill-session -t tutorial 2>/dev/null || true"
      '';
    in
    {
      options.dendritic.apps.tmux = {
        enable = lib.mkEnableOption "dendritic tmux (Ctrl-a, which-key, tutorial)" // {
          default = true;
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

            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '15'
            set -g @resurrect-capture-pane-contents 'on'

            # Discoverability (after which-key registers show-wk-menu-root)
            bind -N "Which-key menu" ? show-wk-menu-root
            bind -N "Interactive tmux tutorial" F1 run-shell "tmux-learn"

            set-hook -g client-attached {
              if-shell '[ ! -f "$HOME/.cache/tmux-tutorial-seen" ]' {
                display-message -d 6000 "tmux tip: Ctrl-a then Space = menu · Ctrl-a then F1 = tutorial · or run: tmux-learn"
              }
            }
          '';
        };

        programs.zsh.shellAliases = {
          t = "tmux new-session -A -s main";
        };
      };
    };
}
