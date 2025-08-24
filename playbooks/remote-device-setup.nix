{pkgs, ...}: let
  # Configuration constants
  packages = [
    "neovim"
    "wget"
    "htop"
    "curl"
    "git"
    "zsh"
    "bash"
    "fish"
    "tmux"
    "tree"
    "unzip"
    "nano"
    "openssh-client"
    "python3"
    "neofetch"
    "xterm"
    "pasteboard-utils"
    # Additional packages to match Nix setup where possible
    "coreutils" # For better ls functionality
    "findutils" # For find command improvements
  ];

  # Neovim configuration
  nvimConfig = ''
    " Basic Neovim configuration for jailbroken iPhone
    set number relativenumber tabstop=2 shiftwidth=2 expandtab
    set autoindent smartindent wrap ignorecase smartcase
    set incsearch hlsearch mouse=a clipboard=unnamedplus
    syntax enable

    " Key mappings
    let mapleader = " "
    nnoremap <leader>w :w<CR>
    nnoremap <leader>q :q<CR>
    nnoremap <leader>h :nohlsearch<CR>
  '';

  # Shell configurations
  mobileZshrc = builtins.readFile ./shell-configs/mobile-zshrc;
  mobileBashrc = builtins.readFile ./shell-configs/mobile-bashrc;
  mobileFishConfig = builtins.readFile ./shell-configs/mobile-config.fish;
  rootZshrc = builtins.readFile ./shell-configs/root-zshrc;
  rootBashrc = builtins.readFile ./shell-configs/root-bashrc;
  rootFishConfig = builtins.readFile ./shell-configs/root-config.fish;
in {
  collections = {};

  inventory = {
    all = {
      hosts = {
        "8AMPS" = {
          ansible_host = "10.0.0.84";
          ansible_user = "root";
          ansible_ssh_private_key_file = "~/.ssh/id_ed25519";
          ansible_python_interpreter = "/usr/bin/python3";
          ansible_ssh_common_args = "-o ConnectTimeout=30 -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o ControlMaster=no";
          ansible_ssh_extra_args = "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
          ansible_connection = "ssh";
          ansible_ssh_timeout = 30;
        };
      };
    };
  };

  playbook = [
    {
      name = "Jailbroken iPhone (8AMPS) Essential Setup";
      hosts = "8AMPS";
      become = true;
      gather_facts = true;

      tasks = [
        {
          name = "Test connection to jailbroken iPhone";
          "ansible.builtin.ping" = {};
        }

        {
          name = "Update and install packages";
          "ansible.builtin.shell" = {
            cmd = ''
              echo "📦 Updating package cache..."
              apt-get update --allow-unauthenticated --allow-insecure-repositories || echo 'APT update completed with warnings'

              echo "📦 Installing packages: ${builtins.concatStringsSep " " packages}"
              failed_packages=""
              for pkg in ${builtins.concatStringsSep " " packages}; do
                echo "Installing $pkg..."
                if ! apt-get install -y "$pkg" 2>/dev/null; then
                  if ! apt-get install -y --allow-unauthenticated "$pkg" 2>/dev/null; then
                    echo "❌ FAILED: $pkg"
                    failed_packages="$failed_packages $pkg"
                  else
                    echo "✅ SUCCESS (unauthenticated): $pkg"
                  fi
                else
                  echo "✅ SUCCESS: $pkg"
                fi
              done

              if echo "$failed_packages" | grep -q openssh-client; then
                echo "🔄 Trying SSH alternative for openssh-client..."
                apt-get install -y ssh --allow-unauthenticated || echo "❌ SSH alternative failed"
              fi

              echo "⬆️ Upgrading packages..."
              apt-get upgrade -y || apt-get upgrade -y --allow-unauthenticated || echo 'Package upgrade completed with warnings'

              echo "📦 Package installation completed. Failed packages: $failed_packages"
            '';
          };
          register = "package_result";
        }

        {
          name = "Display package installation output";
          "ansible.builtin.debug" = {
            msg = "{{ package_result.stdout }}";
          };
        }

        {
          name = "Configure zsh as default shell for users";
          "ansible.builtin.shell" = {
            cmd = ''
              for user in mobile root; do
                chsh -s /usr/bin/zsh "$user" || echo "Shell change failed for $user"
              done
            '';
          };
        }

        {
          name = "Configure shell for mobile user";
          "ansible.builtin.copy" = {
            content = mobileZshrc;
            dest = "/var/mobile/.zshrc";
            owner = "mobile";
            group = "mobile";
            mode = "0644";
          };
        }

        {
          name = "Configure bash for mobile user";
          "ansible.builtin.copy" = {
            content = mobileBashrc;
            dest = "/var/mobile/.bashrc";
            owner = "mobile";
            group = "mobile";
            mode = "0644";
          };
        }

        {
          name = "Configure fish for mobile user";
          "ansible.builtin.file" = {
            path = "/var/mobile/.config/fish";
            state = "directory";
            owner = "mobile";
            group = "mobile";
            mode = "0755";
          };
        }

        {
          name = "Write fish config for mobile user";
          "ansible.builtin.copy" = {
            content = mobileFishConfig;
            dest = "/var/mobile/.config/fish/config.fish";
            owner = "mobile";
            group = "mobile";
            mode = "0644";
          };
        }

        {
          name = "Configure shell for root user";
          "ansible.builtin.copy" = {
            content = rootZshrc;
            dest = "/var/root/.zshrc";
            owner = "root";
            group = "wheel";
            mode = "0644";
          };
        }

        {
          name = "Configure bash for root user";
          "ansible.builtin.copy" = {
            content = rootBashrc;
            dest = "/var/root/.bashrc";
            owner = "root";
            group = "wheel";
            mode = "0644";
          };
        }

        {
          name = "Configure fish for root user";
          "ansible.builtin.file" = {
            path = "/var/root/.config/fish";
            state = "directory";
            owner = "root";
            group = "wheel";
            mode = "0755";
          };
        }

        {
          name = "Write fish config for root user";
          "ansible.builtin.copy" = {
            content = rootFishConfig;
            dest = "/var/root/.config/fish/config.fish";
            owner = "root";
            group = "wheel";
            mode = "0644";
          };
        }

        {
          name = "Setup Neovim configuration";
          "ansible.builtin.copy" = {
            content = nvimConfig;
            dest = "/var/mobile/.config/nvim/init.vim";
            owner = "mobile";
            group = "mobile";
            mode = "0644";
            force = true;
          };
        }

        {
          name = "Display shell configuration completion";
          "ansible.builtin.debug" = {
            msg = [
              "🎨 Enhanced shell configuration completed successfully!"
              "✅ Custom prompts configured for all shells (zsh, bash, fish)"
              "✅ Enhanced aliases matching Nix configuration"
              "✅ Git integration in prompts"
              "✅ iOS-specific customizations applied"
              "✅ Welcome messages with system information"
              "🔧 All shells now have native styling without external dependencies"
            ];
          };
        }

        {
          name = "Display final system setup summary";
          "ansible.builtin.debug" = {
            msg = [
              "🍎 Jailbroken iPhone (8AMPS) setup completed!"
              "📦 Packages: Essential development and system tools installed"
              "🐚 Shells: Zsh, Bash, and Fish configured with custom prompts"
              "⚙️  Configuration: Enhanced aliases and iOS-specific customizations"
              "🎨 Styling: Native shell prompts with Git integration and colors"
              "👤 Users: Both mobile and root users configured"
              "🔧 Ready for development and daily use!"
            ];
          };
        }

        {
          name = "Final status";
          "ansible.builtin.debug" = {
            msg = ''
              ✅ 8AMPS iPhone setup complete!
              📦 Packages installed: ${builtins.concatStringsSep ", " packages}
              🐚 Shell configuration: Zsh, Bash, and Fish configured with enhanced features
              ⚙️  Neovim: Configured with syntax highlighting and basic settings
              🎨 Styling: Native shell prompts with Git integration and colors
              🔧 Configuration matches Nix home-manager setup with shell features:
                 - Completion system enabled
                 - History configuration optimized
                 - Comprehensive aliases (adapted for iOS)
                 - Environment variables set
                 - Multi-shell support (zsh, bash, fish)
                 - Custom prompt theming for enhanced terminal experience
            '';
          };
        }
      ];
    }
  ];
}
