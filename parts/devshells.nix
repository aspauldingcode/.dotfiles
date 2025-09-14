# Development Shells Module
{inputs, ...}: {
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
    devShells = {
      default = pkgs.mkShell {
        name = "dotfiles-dev";

        packages = with pkgs;
          [
            # Nix development tools
            nixpkgs-fmt
            statix
            deadnix
            alejandra
            nil
            nix-tree
            nix-diff

            # General development tools
            bat
            tree
            git
            jq
            yq

            # Mobile development (for Mobile NixOS)
            android-tools # includes fastboot

            # System tools
            htop
            neofetch
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # macOS specific tools
            m-cli
            mas
            terminal-notifier
          ];

        shellHook = ''
          echo "🚀 Welcome to the dotfiles development environment!"
          echo "Available tools:"
          echo "  - nixpkgs-fmt: Format Nix files"
          echo "  - statix: Lint Nix files"
          echo "  - deadnix: Find dead Nix code"
          echo "  - alejandra: Alternative Nix formatter"
          echo "  - nix flake check: Validate flake"
          echo ""
          echo "Mobile NixOS tools:"
          echo "  - fastboot: Flash mobile devices"
          echo "  - android-tools: Android development tools"
          echo ""
        '';
      };

      # Secrets management development shell
      secrets = pkgs.mkShell {
        name = "secrets-dev";

        packages = with pkgs; [
          # Core secrets management tools
          sops
          age
          dialog
          yq-go
          jq

          # Development and debugging tools
          bat
          tree
          git
          gnused
          gnugrep
          gawk
          coreutils
          findutils

          # Custom secrets manager
          self'.packages.secrets-manager
        ];

        shellHook = ''
          echo "🔐 Secrets Management Development Environment"
          echo "============================================="
          echo ""
          echo "Available tools:"
          echo "  - secrets-manager: Dialog-based secrets UI"
          echo "  - sops: Encrypt/decrypt secrets"
          echo "  - age: Key management"
          echo "  - dialog: Terminal UI framework"
          echo ""
          echo "Quick start:"
          echo "  secrets-manager          # Launch dialog UI"
          echo "  sops secrets/dev/secrets.yaml  # Edit secrets directly"
          echo ""
          echo "Environment variables:"
          echo "  DOTFILES_DIR=''${DOTFILES_DIR:-$(pwd)}"
          echo ""
        '';

        # Set environment variables for secrets management
        DOTFILES_DIR = "${placeholder "out"}";
      };

      # Development contribution shell with GitHub setup
      contribute = pkgs.mkShell {
        name = "dotfiles-contribute";

        packages = with pkgs; [
          # Core development tools
          git
          gh
          dialog
          
          # Browser - platform specific
          (if pkgs.stdenv.isDarwin then firefox-bin else firefox)
          
          # Development utilities
          openssh
          coreutils
          gnused
          gnugrep
          jq
        ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
          # macOS specific tools
          defaultbrowser
        ];

        shellHook = ''
          # Automated setup function
          setup_dotfiles_dev() {
            clear
            echo "🚀 Setting up dotfiles development environment..."
            
            # Set Firefox as default browser on macOS
            if [[ "$OSTYPE" == "darwin"* ]] && command -v defaultbrowser >/dev/null 2>&1; then
              defaultbrowser firefox >/dev/null 2>&1 || true
            fi
            
            # Check if git is configured
            if ! git config --global user.name >/dev/null 2>&1 || ! git config --global user.email >/dev/null 2>&1; then
              # Get user name
              USER_NAME=$(dialog --inputbox "Enter your Git username:" 10 50 3>&1 1>&2 2>&3 3>&-)
              if [ $? -eq 0 ] && [ -n "$USER_NAME" ]; then
                git config --global user.name "$USER_NAME"
              else
                echo "Setup cancelled."
                return 1
              fi
              
              # Get user email
              USER_EMAIL=$(dialog --inputbox "Enter your Git email:" 10 50 3>&1 1>&2 2>&3 3>&-)
              if [ $? -eq 0 ] && [ -n "$USER_EMAIL" ]; then
                git config --global user.email "$USER_EMAIL"
              else
                echo "Setup cancelled."
                return 1
              fi
              clear
            fi
            
            # Prompt about SSH key setup for GitHub auth
            if ! gh auth status >/dev/null 2>&1; then
              if dialog --yesno "Set up SSH key for GitHub authentication?\n\nThis will:\n- Generate an SSH key (if needed)\n- Authenticate with GitHub via browser\n- Add SSH key to your GitHub account" 12 60; then
                clear
                echo "Setting up GitHub authentication..."
                
                # Generate SSH key silently if needed
                if [ ! -f ~/.ssh/id_ed25519 ]; then
                  mkdir -p ~/.ssh
                  ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f ~/.ssh/id_ed25519 -N "" -q
                fi
                
                # Start SSH agent and add key
                eval "$(ssh-agent -s)" >/dev/null 2>&1
                ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
                
                # Authenticate with GitHub
                gh auth login --web --git-protocol ssh --skip-ssh-key
                
                # Add SSH key to GitHub after auth
                if gh auth status >/dev/null 2>&1; then
                  gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)-$(date +%Y%m%d)" >/dev/null 2>&1 || true
                fi
              else
                echo "GitHub authentication skipped."
                return 1
              fi
            fi
            
            # Clone repository if needed
            if [ ! -d ~/.dotfiles ]; then
              if dialog --yesno "Clone aspauldingcode/.dotfiles to ~/.dotfiles?" 8 50; then
                clear
                echo "Cloning repository..."
                git clone git@github.com:aspauldingcode/.dotfiles.git ~/.dotfiles
                if [ $? -eq 0 ]; then
                  echo "✅ Setup complete! Repository cloned to ~/.dotfiles"
                else
                  echo "❌ Failed to clone repository"
                  return 1
                fi
              fi
            fi
            
            clear
            echo "🎉 Development environment ready!"
            echo "You can now make changes and push to GitHub."
          }
          
          # Auto-run setup
          setup_dotfiles_dev
        '';
      };
    };
  };
}
