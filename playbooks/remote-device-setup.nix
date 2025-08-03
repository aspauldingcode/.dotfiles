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
    
    # Zsh options
    setopt APPEND_HISTORY
    
    # Completion settings
    autoload -U compinit && compinit
    zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
    
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
  '';

  # User-specific shell configurations
  mobileZshrc = commonShellConfig + ''
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

  rootZshrc = commonShellConfig + ''
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

      # Shell configuration
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
        name = "Create zsh configuration for root user";
        "ansible.builtin.copy" = {
          dest = "/var/root/.zshrc";
          content = "# Root user zsh configuration\n${rootZshrc}\n\n# Oh My Zsh configuration (if available)\nif [ -d \"/var/root/.oh-my-zsh\" ]; then\n  export ZSH=\"/var/root/.oh-my-zsh\"\n  oh-my-posh disable notice 2>/dev/null || true\n  source $ZSH/oh-my-zsh.sh\nfi";
          owner = "root";
          group = "wheel";
          mode = "0644";
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

      # Oh My Zsh installation and configuration
      {
        name = "Install Oh My Zsh for mobile user";
        "ansible.builtin.shell" = {
          cmd = ''
            rm -rf /var/mobile/.oh-my-zsh
            export HOME=/var/mobile USER=mobile
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || echo "Oh My Zsh installation completed with warnings"
          '';
        };
        register = "ohmyzsh_result";
      }

      {
        name = "Display Oh My Zsh installation output";
        "ansible.builtin.debug" = {
          msg = "{{ ohmyzsh_result.stdout }}";
        };
      }

      {
        name = "Configure Oh My Zsh to match Nix setup";
        "ansible.builtin.shell" = {
          cmd = ''
            # Update .zshrc to include Oh My Zsh configuration matching Nix setup
            cat > /var/mobile/.zshrc << 'EOF'
# Mobile user zsh configuration
${mobileZshrc}

# Oh My Zsh configuration (matching Nix home-manager setup)
export ZSH="/var/mobile/.oh-my-zsh"

# Disable Oh My Posh notice (matching Nix config)
oh-my-posh disable notice 2>/dev/null || true

# Enable Oh My Zsh
source $ZSH/oh-my-zsh.sh
EOF
            chown mobile:mobile /var/mobile/.zshrc
          '';
        };
      }

      # Final status
      {
        name = "Display setup completion status";
        "ansible.builtin.shell" = {
          cmd = ''
            echo "🎉 Setup completed for $(hostname)!"
            echo "📦 Installed packages:"
            dpkg -l | grep -E '(${builtins.concatStringsSep "|" packages})' | awk '{print "  " $2, $3}' || echo "  Package list unavailable"
            echo "✅ Configured: Neovim, Zsh (with Oh My Zsh), matching Nix home-manager setup"
            echo "🔧 Shell features: completion, history, aliases, environment variables"
          '';
        };
        register = "final_status";
      }

      {
        name = "Show final status";
        "ansible.builtin.debug" = {
          msg = "{{ final_status.stdout }}";
        };
      }
    ];
  }];
}