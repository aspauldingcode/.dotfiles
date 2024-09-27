{ config, pkgs, inputs, ... }:

{
  # enable macforge:
  # programs.macforge.enable = true;

  # configure plugins for MacForge.
  system.activationScripts.extraActivation.text = ''
    # adds MacForge Plugins (could use gnu stow moving forward)..
    cd ${./../../../../users/alex/extraConfig/macforge-plugins} # cd into the directory where the plugins are. idk why we need to do this.
    find . -type d ! -name '.*' -exec mkdir -p /Library/Application\ Support/MacEnhance/Plugins/{} \; # create directories. These must not be symlinks.
    find . -type f ! -name '.*' -exec ln -sf ${./../../../../users/alex/extraConfig/macforge-plugins}/{} /Library/Application\ Support/MacEnhance/Plugins/{} \; # create symlinks for files
  '';
}
