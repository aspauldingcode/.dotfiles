{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Basic system tools
    git
    curl
    wget
    
    # Text editors
    vim
    neovim
    
    # Shell
    zsh
    oh-my-zsh
    
    # Development tools
    gcc
    gnumake
    
    # Nix-specific tools
    # nixos-rebuild
    
    # Encryption tools (for secret management)
    gnupg
    
    # Additional useful tools
    jq  # For JSON processing
    yq  # For YAML processing
    
    # Flakes-related
    nix
  ];


  SSH CLONE:
  git@github.com:aspauldingcode/.dotfiles.git
  HTTPS CLONE:
  https://github.com/aspauldingcode/.dotfiles.git

  usual nixos configuration for the flake to be cloned to:
  $HOME/.dotfiles/
  

  shellHook = ''
    echo "temp dotfiles environment!"
    echo "To clone the repo: git clone https://github.com/your-username/your-dotfiles-repo.git"
    echo "To rebuild NixOS: nixos-rebuild switch --use-remote-sudo --flake /path/to/your/flake#yourDesiredNixosConfiguration"
    echo "If flakes are not enabled: nixos-rebuild switch --use-remote-sudo --flake /path/to/your/flake#yourDesiredNixosConfiguration --extra-experimental-features 'flakes nix-command'"
    echo "For secret management, consider using GPG to encrypt sensitive files."
  '';
}
