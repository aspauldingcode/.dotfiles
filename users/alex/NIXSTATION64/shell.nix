# ~/.config/nixpkgs/home.nix

{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.zsh
    # Add more packages as needed
  ];

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enablePromptInit = true;
    extraInit = ''
      # Add your custom Zsh configurations here
      # For example, you can set aliases, customize prompts, etc.
    '';
  };

  # Example of configuring oh-my-zsh
  home.file."oh-my-zsh".source = builtins.fetchGit {
    url = "https://github.com/ohmyzsh/ohmyzsh.git";
    rev = "master"; # Use a specific revision if needed
    ref = "master";
  };

  home.file."zshrc".text = ''
    # Add your custom Zsh configurations here
    # For example, you can set aliases, customize prompts, etc.

    # Source oh-my-zsh
    source "${config.home.file."oh-my-zsh".source}/oh-my-zsh.sh"

    # Zsh history settings
    HISTFILE=~/.zsh_history
    HISTSIZE=1000
    SAVEHIST=1000
    setopt APPEND_HISTORY

    # Add the mobile-nixos variable to $NIX_PATH
    export NIX_PATH="$NIX_PATH:mobile-nixos=~/mobile-nixos"
  '';

  # Set the default shell to Zsh
  programs.shell.enable = true;
  programs.shell.interpreter = "${pkgs.zsh}/bin/zsh";
}
