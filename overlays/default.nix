# Custom overlays for package modifications and additions
{inputs}: final: prev: {
  # Custom package modifications can go here

  # Fix for air-formatter - make it available in stable pkgs by pulling from unstable
  # This ensures compatibility with nixvim and other tools that expect it in pkgs
  air-formatter =
    if prev ? unstable && prev.unstable ? air-formatter
    then prev.unstable.air-formatter
    else if final ? unstable && final.unstable ? air-formatter
    then final.unstable.air-formatter
    else throw "air-formatter not found in unstable packages";

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
