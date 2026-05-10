{
  flake.modules.homeManager.terminal = { pkgs, config, lib, ... }: {
    programs.tmux = {
      enable = true;
      shortcut = "a"; # Ctrl-a prefix
      baseIndex = 1;
      keyMode = "vi";
      mouse = true;
      terminal = "screen-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      
      plugins = with pkgs.tmuxPlugins; [
        sensible
        vim-tmux-navigator
        yank
        resurrect
        continuum
        tmux-which-key
        fzf-tmux-url
      ];

      extraConfig = ''
        # ── Ergonomics ────────────────────────────────────────────────
        # Split panes using | and -
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '"'
        unbind %

        # Smart pane resizing (prefix + H, J, K, L)
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Vim-like copy mode (prefix + [)
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

        # ── Keybinding Hints (the "Tutorial") ────────────────────────
        # Open tmux-which-key with prefix + ? 
        # This provides a searchable menu of all your keybindings.
        bind-key ? run-shell "tmux-which-key"

        # ── Optimizations ─────────────────────────────────────────────
        set -sg escape-time 0      # No delay for escape key (crucial for vim)
        set -g focus-events on     # Pass focus events to apps like vim
        setw -g aggressive-resize on # Useful when multiple clients are attached
        set -g history-limit 50000  # More history
        set -g status-interval 5    # Refresh status line more often

        # ── Session Management ────────────────────────────────────────
        set -g @continuum-restore 'on' # Automatically restore session on start
        
        # ── Aesthetics ───────────────────────────────────────────────
        # Stylix targets tmux automatically, but we add some polish
        set -g status-position top
        set -g pane-border-status off
        
        # Use tmux-which-key XDG path to ensure it's writable (needed for Nix)
        set -g @tmux-which-key-xdg-plugin-path "$XDG_CONFIG_HOME/tmux/plugins/tmux-which-key"
      '';
    };
  };
}
