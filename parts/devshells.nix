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
        ];

        shellHook = ''
          # Create the setup script
          setup_dotfiles_dev() {
            echo "🚀 Dotfiles Development Setup"
            echo "============================="
            echo ""
            
            # Check if git is configured
            if ! git config --global user.name >/dev/null 2>&1 || ! git config --global user.email >/dev/null 2>&1; then
              echo "📝 Setting up Git configuration..."
              
              # Get user name
              USER_NAME=$(dialog --inputbox "Enter your Git username:" 10 50 3>&1 1>&2 2>&3 3>&-)
              if [ $? -eq 0 ] && [ -n "$USER_NAME" ]; then
                git config --global user.name "$USER_NAME"
                echo "✅ Git username set to: $USER_NAME"
              else
                echo "❌ Git username setup cancelled"
                return 1
              fi
              
              # Get user email
              USER_EMAIL=$(dialog --inputbox "Enter your Git email:" 10 50 3>&1 1>&2 2>&3 3>&-)
              if [ $? -eq 0 ] && [ -n "$USER_EMAIL" ]; then
                git config --global user.email "$USER_EMAIL"
                echo "✅ Git email set to: $USER_EMAIL"
              else
                echo "❌ Git email setup cancelled"
                return 1
              fi
              
              clear
            fi
            
            # Check GitHub authentication
            if ! gh auth status >/dev/null 2>&1; then
              echo "🔐 GitHub authentication required..."
              echo "This will open Firefox for GitHub login."
              
              if dialog --yesno "Proceed with GitHub authentication using Firefox?" 10 50; then
                clear
                echo "🌐 Opening Firefox for GitHub authentication..."
                
                # Platform-specific Firefox launch
                if [[ "$OSTYPE" == "darwin"* ]]; then
                  export BROWSER="${pkgs.firefox-bin}/Applications/Firefox.app/Contents/MacOS/firefox"
                else
                  export BROWSER="${pkgs.firefox}/bin/firefox"
                fi
                
                # Authenticate with GitHub using Firefox
                gh auth login --web --git-protocol ssh
                
                if gh auth status >/dev/null 2>&1; then
                  echo "✅ GitHub authentication successful!"
                else
                  echo "❌ GitHub authentication failed"
                  return 1
                fi
              else
                echo "❌ GitHub authentication cancelled"
                return 1
              fi
            else
              echo "✅ Already authenticated with GitHub"
            fi
            
            # Check SSH key
            if ! gh ssh-key list | grep -q "ed25519"; then
              echo "🔑 Setting up SSH key..."
              
              # Generate SSH key if needed
              if [ ! -f ~/.ssh/id_ed25519 ]; then
                ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f ~/.ssh/id_ed25519 -N ""
                echo "✅ SSH key generated"
              fi
              
              # Add SSH key to GitHub
              gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(hostname)-$(date +%Y%m%d)"
              echo "✅ SSH key added to GitHub"
            else
              echo "✅ SSH key already configured"
            fi
            
            # Clone repository
            if [ ! -d ~/.dotfiles ]; then
              echo "📦 Cloning dotfiles repository..."
              
              if dialog --yesno "Clone aspauldingcode/.dotfiles to ~/.dotfiles?" 10 50; then
                clear
                echo "🔄 Cloning repository..."
                
                # Use nix shell to ensure git is available for the clone
                nix shell nixpkgs#git --command git clone git@github.com:aspauldingcode/.dotfiles.git ~/.dotfiles
                
                if [ $? -eq 0 ]; then
                  echo "✅ Repository cloned successfully to ~/.dotfiles"
                  echo ""
                  echo "🎉 Setup complete! You can now:"
                  echo "  cd ~/.dotfiles"
                  echo "  nix develop .#contribute  # Enter development shell"
                  echo "  # Make your changes and push to GitHub"
                else
                  echo "❌ Failed to clone repository"
                  return 1
                fi
              else
                echo "ℹ️  Repository clone skipped"
              fi
            else
              echo "✅ Repository already exists at ~/.dotfiles"
            fi
            
            echo ""
            echo "🎯 Development environment ready!"
            echo "Next steps:"
            echo "  - cd ~/.dotfiles (if not already there)"
            echo "  - Make your changes"
            echo "  - git add, commit, and push your changes"
            echo "  - Use 'nix run github:aspauldingcode/.dotfiles' to test builds"
          }
          
          echo "🛠️  Dotfiles Development & Contribution Shell"
          echo "=============================================="
          echo ""
          echo "This shell provides tools for developing the dotfiles flake:"
          echo "  - git: Version control"
          echo "  - gh: GitHub CLI"
          echo "  - firefox: Web browser for GitHub auth"
          echo "  - dialog: Interactive setup dialogs"
          echo ""
          echo "Commands:"
          echo "  setup_dotfiles_dev  # Run the complete setup process"
          echo ""
          echo "The setup will:"
          echo "  1. Configure git user settings"
          echo "  2. Authenticate with GitHub using Firefox"
          echo "  3. Set up SSH keys"
          echo "  4. Clone the repository to ~/.dotfiles"
          echo ""
          echo "Run 'setup_dotfiles_dev' to get started!"
        '';
      };
    };
  };
}
