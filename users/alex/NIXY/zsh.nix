{ ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll =      "ls -l";
      ifstat =  "ifstat-legacy";
      cat =     "lolcat";
    };
    oh-my-zsh = {
      enable =  true;
      plugins = [ "git" "thefuck" ];
      theme =   "funky";
    };
    initExtra = "disable-hud\n"; # DISABLE volume/brightness HUD!
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
      export CLASSPATH=~/Desktop/hw/csci232/jars/algs4.jar:$CLASSPATH
      export CLASSPATH=~/Desktop/hw/csci232/jars/stdlib.jar:$CLASSPATH

      # add ruby 2.6 to PATH because it doesn't build ffi 1.9.25 required gem for nixvim otherwise.
      export PATH="/Users/alex/.gem/ruby/2.6.0/bin:$PATH"
    '';
  };
}
