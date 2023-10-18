{ pkgs, config, ... }:

{
 neovim = {
        enable = true;
        #extraConfig = lib.fileContents ./extraConfig/nvim/init.lua;
};
}
