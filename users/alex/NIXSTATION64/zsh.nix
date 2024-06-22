{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -l";
      ifstat = "ifstat-legacy";
      firefox = "firefox-esr";
      # cat =             "lolcat";
      tf = "thefuck";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "thefuck"
      ];
      theme = "cypher";
    };
  };
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
  };

  home.file.".zshrc" = {
    text = ''
      # Add your custom Zsh configurations here
      # For example, you can set aliases, customize prompts, etc.

      # Zsh history settings
      HISTFILE=~/.zsh_history
      HISTSIZE=1000
      SAVEHIST=1000
      setopt APPEND_HISTORY

      # Add the mobile-nixos variable to $NIX_PATH
      # export NIX_PATH="$NIX_PATH:mobile-nixos=~/mobile-nixos"

      # Add classpaths for school.
      export CLASSPATH=~/Desktop/hw/csci232/jars/algs4.jar:$CLASSPATH
      export CLASSPATH=~/Desktop/hw/csci232/jars/stdlib.jar:$CLASSPATH

      # Set default editor in zsh shell
      export EDITOR=nvim
      export VISUAL="$EDITOR"
    '';
  };
}
