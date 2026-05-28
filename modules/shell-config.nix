{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      options,
      ...
    }:
    {
      programs.zsh.enable = true;

      users = lib.optionalAttrs (options ? users && options.users ? defaultUserShell) {
        defaultUserShell = pkgs.zsh;
      };

      environment = {
        systemPackages = [
          pkgs.nh
          pkgs.yazi
        ];
      }
      // (lib.optionalAttrs (options ? environment && options.environment ? shells) {
        shells = [ pkgs.zsh ];
      });

      security.sudo.extraConfig = ''
        # 120 min: authenticate once, then reuse for a long session.
        Defaults timestamp_timeout=120
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

      home.sessionVariables = {
        NH_FLAKE = (if pkgs.stdenv.isDarwin then "/etc/nix-darwin/.dotfiles#mba" else "/etc/nixos");
      };

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
        plugins = {
          mount =
            pkgs.fetchzip {
              url = "https://github.com/yazi-rs/plugins/archive/main.tar.gz";
              sha256 = "197j219p7x2lxf4fdpdmp9ycd16yl8p22bv5a4257d9yc4ikpxxj";
            }
            + "/mount.yazi";
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
