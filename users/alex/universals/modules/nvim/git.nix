{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # Git integration
    gitsigns.enable = true;
  };
}
