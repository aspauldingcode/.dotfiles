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
    "coreutils"  # For better ls functionality
    "findutils"  # For find command improvements
  ];

  # Common shell configuration matching Nix home-manager setup
  commonShellConfig = ''
    # Environment variables
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    export EDITOR=nvim
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    
    # Aliases matching Nix configuration
    alias l='ls --color=auto --group-directories-first 2>/dev/null || ls -G'
    alias ls='ls --color=auto --group-directories-first 2>/dev/null || ls -G'
    alias ll='ls --color=auto --group-directories-first -al 2>/dev/null || ls -Gal'
    alias la='ls --color=auto --group-directories-first -a 2>/dev/null || ls -Ga'
    alias tree='find . -type d | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"'
    alias lsdir='ls -d */'
    alias nu='echo "Nushell not available on iOS"'
    
    # System aliases (iOS specific)
    alias reboot='echo "Use: sudo reboot" && sudo reboot'
    alias rb='echo "Use: sudo reboot" && sudo reboot'
    alias shutdown='echo "Use: sudo shutdown -h now" && sudo shutdown -h now'
    alias sd='echo "Use: sudo shutdown -h now" && sudo shutdown -h now'
    
    # Additional iOS-specific aliases
    alias respring='killall SpringBoard'
    alias ..='cd ..'
    alias ...='cd ../..'
    alias grep='grep --color=auto'
    
    # Git aliases
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git log --oneline'
    
    # Oh My Posh disable notice (matching Nix config)
    oh-my-posh disable notice 2>/dev/null || true
  '';

  # Zsh-specific configuration
  zshConfig = commonShellConfig + ''
    # Zsh options
    setopt APPEND_HISTORY
    
    # Completion settings
    autoload -U compinit && compinit
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
  '';

  # Bash-specific configuration
  bashConfig = commonShellConfig + ''
    # Bash options
    shopt -s histappend
    bind "set completion-ignore-case on"
    export BASH_SILENCE_DEPRECATION_WARNING=1
  '';

  # Fish-specific configuration
  fishConfig = commonShellConfig + ''
    # Fish options
    set fish_greeting ""
    set -g fish_completion_ignore_case 1
  '';

  # User-specific shell configurations
  mobileZshrc = zshConfig + ''
    # iOS-specific aliases for mobile user
    alias neofetch='neofetch --ascii_distro iOS'
    alias safemode='touch /var/mobile/.safemode && reboot'
    
    # Welcome message
    echo "Welcome to jailbroken iPhone: $(hostname)"
    echo "System: $(uname -sr)"
    if command -v neofetch >/dev/null 2>&1; then
      neofetch --ascii_distro iOS
    fi
  '';

  mobileBashrc = bashConfig + ''
    # iOS-specific aliases for mobile user
    alias neofetch='neofetch --ascii_distro iOS'
    alias safemode='touch /var/mobile/.safemode && reboot'
    
    # Welcome message
    echo "Welcome to jailbroken iPhone: $(hostname)"
    echo "System: $(uname -sr)"
    if command -v neofetch >/dev/null 2>&1; then
      neofetch --ascii_distro iOS
    fi
  '';

  mobileFishrc = fishConfig + ''
    # iOS-specific aliases for mobile user
    alias neofetch='neofetch --ascii_distro iOS'
    alias safemode='touch /var/mobile/.safemode && reboot'
    
    # Welcome message
    echo "Welcome to jailbroken iPhone: $(hostname)"
    echo "System: $(uname -sr)"
    if command -v neofetch >/dev/null 2>&1
      neofetch --ascii_distro iOS
    end
  '';

  rootZshrc = zshConfig + ''
    # Root-specific aliases
    alias ldrestart='launchctl stop com.apple.mobile.lockdown && launchctl start com.apple.mobile.lockdown'
    
    # Root warning
    echo "⚠️  You are logged in as ROOT on jailbroken iPhone: $(hostname)"
    echo "🔧 System: $(uname -sr)"
  '';

  rootBashrc = bashConfig + ''
    # Root-specific aliases
    alias ldrestart='launchctl stop com.apple.mobile.lockdown && launchctl start com.apple.mobile.lockdown'
    
    # Root warning
    echo "⚠️  You are logged in as ROOT on jailbroken iPhone: $(hostname)"
    echo "🔧 System: $(uname -sr)"
  '';

  rootFishrc = fishConfig + ''
    # Root-specific aliases
    alias ldrestart='launchctl stop com.apple.mobile.lockdown && launchctl start com.apple.mobile.lockdown'
    
    # Root warning
    echo "⚠️  You are logged in as ROOT on jailbroken iPhone: $(hostname)"
    echo "🔧 System: $(uname -sr)"
  '';

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

  playbook = [{
    name = "Jailbroken iPhone (8AMPS) Essential Setup";
    hosts = "8AMPS";
    become = true;
    gather_facts = true;

    tasks = [
      # Connection test
      {
        name = "Test connection to jailbroken iPhone";
        "ansible.builtin.ping" = {};
      }

      # Package management
      {
        name = "Update and install packages";
        "ansible.builtin.shell" = {
          cmd = ''
            # Update package cache
            echo "📦 Updating package cache..."
            apt-get update --allow-unauthenticated --allow-insecure-repositories || echo 'APT update completed with warnings'
            
            # Install packages with fallback to unauthenticated
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
            
            # Try SSH alternative if openssh-client failed
            if echo "$failed_packages" | grep -q openssh-client; then
              echo "🔄 Trying SSH alternative for openssh-client..."
              apt-get install -y ssh --allow-unauthenticated || echo "❌ SSH alternative failed"
            fi
            
            # Upgrade packages
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

      # Shell configuration for all shells
      {
        name = "Configure zsh as default shell for users";
        "ansible.builtin.shell" = {
          cmd = ''
            for user in mobile root; do
              chsh -s /usr/bin/zsh "$user" || usermod -s /usr/bin/zsh "$user" || echo "Shell change failed for $user"
            done
          '';
        };
      }

      {
        name = "Create zsh configuration for mobile user";
        "ansible.builtin.copy" = {
          dest = "/var/mobile/.zshrc";
          content = "# Mobile user zsh configuration\n${mobileZshrc}";
          owner = "mobile";
          group = "mobile";
          mode = "0644";
        };
      }

      {
        name = "Create bash configuration for mobile user";
        "ansible.builtin.copy" = {
          dest = "/var/mobile/.bashrc";
          content = "# Mobile user bash configuration\n${mobileBashrc}";
          owner = "mobile";
          group = "mobile";
          mode = "0644";
        };
      }

      {
        name = "Create fish configuration for mobile user";
        "ansible.builtin.shell" = {
          cmd = ''
            mkdir -p /var/mobile/.config/fish
            cat > /var/mobile/.config/fish/config.fish << 'EOF'
# Mobile user fish configuration
${mobileFishrc}
EOF
            chown -R mobile:mobile /var/mobile/.config/fish
          '';
        };
      }

      {
        name = "Create zsh configuration for root user";
        "ansible.builtin.copy" = {
          dest = "/var/root/.zshrc";
          content = "# Root user zsh configuration\n${rootZshrc}";
          owner = "root";
          group = "wheel";
          mode = "0644";
        };
      }

      {
        name = "Create bash configuration for root user";
        "ansible.builtin.copy" = {
          dest = "/var/root/.bashrc";
          content = "# Root user bash configuration\n${rootBashrc}";
          owner = "root";
          group = "wheel";
          mode = "0644";
        };
      }

      {
        name = "Create fish configuration for root user";
        "ansible.builtin.shell" = {
          cmd = ''
            mkdir -p /var/root/.config/fish
            cat > /var/root/.config/fish/config.fish << 'EOF'
# Root user fish configuration
${rootFishrc}
EOF
            chown -R root:wheel /var/root/.config/fish
          '';
        };
      }

      # Neovim configuration
      {
        name = "Setup Neovim configuration";
        "ansible.builtin.copy" = {
          dest = "/var/mobile/.config/nvim/init.vim";
          content = nvimConfig;
          owner = "mobile";
          group = "mobile";
          mode = "0644";
        };
      }

      {
        name = "Create Neovim config directory";
        "ansible.builtin.file" = {
          path = "/var/mobile/.config/nvim";
          state = "directory";
          owner = "mobile";
          group = "mobile";
          mode = "0755";
        };
      }

      # Oh My Posh installation and configuration
      {
        name = "Install Oh My Posh for iOS";
        "ansible.builtin.shell" = {
          cmd = ''
            # Create installation directory
            mkdir -p /usr/local/bin
            
            # Download Oh My Posh binary for ARM64 (iOS compatible)
            echo "📦 Downloading Oh My Posh for iOS/ARM64..."
            curl -L -o /usr/local/bin/oh-my-posh https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64
            
            # Make it executable
            chmod +x /usr/local/bin/oh-my-posh
            
            # Add to PATH for current session
            export PATH="/usr/local/bin:$PATH"
            
            # Verify installation
            if /usr/local/bin/oh-my-posh --version >/dev/null 2>&1; then
              echo "✅ Oh My Posh installed successfully: $(/usr/local/bin/oh-my-posh --version)"
            else
              echo "⚠️ Oh My Posh binary downloaded but may not be compatible with iOS"
            fi
          '';
        };
        register = "ohmyposh_install_result";
      }

      {
        name = "Display Oh My Posh installation output";
        "ansible.builtin.debug" = {
          msg = "{{ ohmyposh_install_result.stdout }}";
        };
      }

      {
        name = "Add Oh My Posh to PATH permanently";
        "ansible.builtin.shell" = {
          cmd = ''
            # Add PATH export to shell profiles
            for shell_file in /var/mobile/.zshrc /var/mobile/.bashrc /var/root/.zshrc /var/root/.bashrc; do
              if [ -f "$shell_file" ]; then
                # Remove existing PATH entries for oh-my-posh
                sed -i '/export PATH.*usr\/local\/bin/d' "$shell_file" 2>/dev/null || true
                # Add new PATH entry at the beginning
                echo 'export PATH="/usr/local/bin:$PATH"' | cat - "$shell_file" > temp && mv temp "$shell_file"
              fi
            done
            
            # For fish shell
            for fish_config in /var/mobile/.config/fish/config.fish /var/root/.config/fish/config.fish; do
              if [ -f "$fish_config" ]; then
                # Remove existing PATH entries
                sed -i '/set.*PATH.*usr\/local\/bin/d' "$fish_config" 2>/dev/null || true
                # Add new PATH entry at the beginning
                echo 'set -gx PATH /usr/local/bin $PATH' | cat - "$fish_config" > temp && mv temp "$fish_config"
              fi
            done
          '';
        };
      }

      {
        name = "Configure Oh My Posh for zsh (mobile user)";
        "ansible.builtin.shell" = {
          cmd = ''
            # Add Oh My Posh initialization to mobile user's .zshrc
            echo "" >> /var/mobile/.zshrc
            echo '# Oh My Posh initialization' >> /var/mobile/.zshrc
            echo 'if command -v oh-my-posh >/dev/null 2>&1; then' >> /var/mobile/.zshrc
            echo '  eval "$(oh-my-posh init zsh)"' >> /var/mobile/.zshrc
            echo 'fi' >> /var/mobile/.zshrc
            chown mobile:mobile /var/mobile/.zshrc
          '';
        };
      }

      {
        name = "Configure Oh My Posh for bash (mobile user)";
        "ansible.builtin.shell" = {
          cmd = ''
            # Add Oh My Posh initialization to mobile user's .bashrc
            echo "" >> /var/mobile/.bashrc
            echo '# Oh My Posh initialization' >> /var/mobile/.bashrc
            echo 'if command -v oh-my-posh >/dev/null 2>&1; then' >> /var/mobile/.bashrc
            echo '  eval "$(oh-my-posh init bash)"' >> /var/mobile/.bashrc
            echo 'fi' >> /var/mobile/.bashrc
            chown mobile:mobile /var/mobile/.bashrc
          '';
        };
      }

      {
        name = "Configure Oh My Posh for fish (mobile user)";
        "ansible.builtin.shell" = {
          cmd = ''
            # Add Oh My Posh initialization to mobile user's fish config
            echo "" >> /var/mobile/.config/fish/config.fish
            echo '# Oh My Posh initialization' >> /var/mobile/.config/fish/config.fish
            echo 'if command -v oh-my-posh >/dev/null 2>&1' >> /var/mobile/.config/fish/config.fish
            echo '  oh-my-posh init fish | source' >> /var/mobile/.config/fish/config.fish
            echo 'end' >> /var/mobile/.config/fish/config.fish
            chown -R mobile:mobile /var/mobile/.config/fish
          '';
        };
      }

      {
        name = "Configure Oh My Posh for zsh (root user)";
        "ansible.builtin.shell" = {
          cmd = ''
            # Add Oh My Posh initialization to root user's .zshrc
            echo "" >> /var/root/.zshrc
            echo '# Oh My Posh initialization' >> /var/root/.zshrc
            echo 'if command -v oh-my-posh >/dev/null 2>&1; then' >> /var/root/.zshrc
            echo '  eval "$(oh-my-posh init zsh)"' >> /var/root/.zshrc
            echo 'fi' >> /var/root/.zshrc
            chown root:wheel /var/root/.zshrc
          '';
        };
      }

      {
        name = "Configure Oh My Posh for bash (root user)";
        "ansible.builtin.shell" = {
          cmd = ''
            # Add Oh My Posh initialization to root user's .bashrc
            echo "" >> /var/root/.bashrc
            echo '# Oh My Posh initialization' >> /var/root/.bashrc
            echo 'if command -v oh-my-posh >/dev/null 2>&1; then' >> /var/root/.bashrc
            echo '  eval "$(oh-my-posh init bash)"' >> /var/root/.bashrc
            echo 'fi' >> /var/root/.bashrc
            chown root:wheel /var/root/.bashrc
          '';
        };
      }

      {
        name = "Configure Oh My Posh for fish (root user)";
        "ansible.builtin.shell" = {
          cmd = ''
            # Add Oh My Posh initialization to root user's fish config
            echo "" >> /var/root/.config/fish/config.fish
            echo '# Oh My Posh initialization' >> /var/root/.config/fish/config.fish
            echo 'if command -v oh-my-posh >/dev/null 2>&1' >> /var/root/.config/fish/config.fish
            echo '  oh-my-posh init fish | source' >> /var/root/.config/fish/config.fish
            echo 'end' >> /var/root/.config/fish/config.fish
            chown -R root:wheel /var/root/.config/fish
          '';
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
            🎨 Oh My Posh: Installed and configured for all shells (zsh, bash, fish) for both users
            🔧 Configuration matches Nix home-manager setup with shell features:
               - Completion system enabled
               - History configuration optimized
               - Comprehensive aliases (adapted for iOS)
               - Environment variables set
               - Multi-shell support (zsh, bash, fish)
               - Oh My Posh prompt theming for enhanced terminal experience
          '';
        };
      }
    ];
  }];
}