{ ... }:

{
  programs.zsh = {
    enable = true;

    shellAliases = {
      ll =      "ls -l";
      ifstat =  "ifstat-legacy";
      # cat =     "lolcat";
      tf = 	"thefuck";
      yazi = 	"kitty --single-instance yazi &";
    };
    oh-my-zsh = {
      enable =  true;
      plugins = [ "git" "thefuck" ];
      theme =   "funky";
    };
    initExtra = "disable-hud\nsudo spctl --master-disable\n"; # DISABLE volume/brightness HUD! Disable GATEKEEPER
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

      # Princeton Jar files!
      export CLASSPATH=~/Desktop/hw/csci232/jars/algs4.jar:$CLASSPATH
      export CLASSPATH=~/Desktop/hw/csci232/jars/stdlib.jar:$CLASSPATH

      # add gyr to path
      export PATH="/Users/alex/.cargo/bin:$PATH"

      # add x11 to path
      export PATH=/opt/X11/bin:$PATH
      export PATH=/usr/X11R6/bin:$PATH
      export MANPATH=/usr/X11R6/man:$MANPATH
      export DISPLAY=:0            # Required!

      # add missing paths for i3 to work
      export PATH=/opt/local/bin:$PATH
      export PATH=/opt/local/sbin:$PATH

      # Set default editor in zsh shell
      export EDITOR=nvim
      export VISUAL="$EDITOR"
    '';
  };
}
