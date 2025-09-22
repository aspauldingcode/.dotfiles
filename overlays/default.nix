# Custom overlays for package modifications and additions
{inputs}: final: prev: {
  # Mobile-specific packages
  mobile = {
    # Mobile development tools
    inherit
      (prev)
      android-tools
      fastboot
      heimdall
      ;
  };

  # Development tools with custom configurations
  dev = {
    inherit
      (prev)
      git
      neovim
      tmux
      ;
  };
}
