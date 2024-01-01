# { lib, buildInputs, fetchGitHub }:
#
# {

  #ADDING HARPOON PLUGIN TO ZELLIJ!!
# buildInputs = [ ];
#
# # Replace these values with the actual details of the GitHub repository and release
# src = fetchGitHub {
#   owner = "Nacho114";
#   repo = "harpoon";
#   rev = "9d50d10";
#   sha256 = "1qj7pymrq9z42qm69h6rqfda56kjf2yxzf7kz7hqmscp8n88mc1h";
# };

/* found by doing:
nix-prefetch-url --unpack https://github.com/Nacho114/harpoon/archive/refs/tags/v0.1.0.tar.gz


path is '/nix/store/yqkxagz1hr97x3k72v01l8amfwrjb0ds-v0.1.0.tar.gz'
1qj7pymrq9z42qm69h6rqfda56kjf2yxzf7kz7hqmscp8n88mc1h

*/

# Now you can use the source in your build process


# home.nix

{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.zellij
    # Add any other packages you need
  ];

  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    package = pkgs.zellij;
    settings = {
      # Your Zellij configuration goes here
      keybindings = {
        locked = {
          "C-g" = "toggle_locked_mode";
          "M-z" = "toggle_fullscreen";
          "M-Up" = "move_up";
          "M-Down" = "move_down";
          "M-Left" = "move_left";
          "M-Right" = "move_right";
          "M-t" = "toggle_floating_pane";
        };
      };

      options = {
        # Add any other options you have here
      };

      # Add any other sections of your configuration here
    };
  };
}

