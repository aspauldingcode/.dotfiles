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
            
            # Generate SSH key silently before GitHub auth
            if [ ! -f ~/.ssh/id_ed25519 ]; then
              mkdir -p ~/.ssh
              ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f ~/.ssh/id_ed25519 -N "" -q
            fi
            
            # Start SSH agent and add key
            eval "$(ssh-agent -s)" >/dev/null 2>&1
            ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
            
            # GitHub authentication
            if ! gh auth status >/dev/null 2>&1; then
              echo "Setting up GitHub authentication..."
              gh auth login --web --git-protocol ssh || {
                echo "⚠️  GitHub authentication failed or was cancelled"
                echo "You can authenticate later with: gh auth login"
                return 1
              }
              # Add SSH key if not present
              if ! gh ssh-key list | grep -q "$(awk '{print $2}' ~/.ssh/id_ed25519.pub 2>/dev/null)"; then
                gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)-$(date +%Y%m%d)" \
                  && echo "✅ SSH key added to GitHub" \
                  || echo "⚠️  Failed to add SSH key (may already exist)"
              else
                echo "✅ SSH key already exists on GitHub"
              fi
              echo "✅ GitHub authentication successful"
            else
              echo "✅ Already authenticated with GitHub"
            fi
            
            # Ask for clone location and clone repository
            CLONE_PATH=$(dialog --inputbox "Enter clone destination:" 10 50 "$HOME/.dotfiles" 3>&1 1>&2 2>&3 3>&-)
            if [ $? -eq 0 ] && [ -n "$CLONE_PATH" ]; then
              # Expand tilde if present
              CLONE_PATH=$(eval echo "$CLONE_PATH")
              
              if [ ! -d "$CLONE_PATH" ]; then
                clear
                echo "Cloning repository to $CLONE_PATH..."
                
                # Create parent directory if needed
                mkdir -p "$(dirname "$CLONE_PATH")"
                
                git clone git@github.com:aspauldingcode/.dotfiles.git "$CLONE_PATH"
                if [ $? -eq 0 ]; then
                  echo "✅ Setup complete! Repository cloned to $CLONE_PATH"
                else
                  echo "❌ Failed to clone repository"
                  return 1
                fi
              else
                echo "✅ Repository already exists at $CLONE_PATH"
              fi
            else
              echo "Clone cancelled."
            fi
            
            clear
            echo "🎉 Development environment ready!"
            echo "You can now make changes and push to GitHub."
            
            # Change to the cloned repository directory
            if [ -n "$CLONE_PATH" ] && [ -d "$CLONE_PATH" ]; then
              echo "📁 Changing to repository directory..."
              cd "$CLONE_PATH"
            fi
          }
          
          # Auto-run setup
          setup_dotfiles_dev
        '';
      };
    };
  };
}
