{ lib, config, pkgs, ... }:
# NIXY-specific packages

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home.packages = with pkgs; [
    calcurse
    chatgpt-cli
    cowsay
    qemu
    discord
    #spotify # Not available anymore?
    vscode
    utm 
    mas
    yazi #somehow it's back? what?
    nil #rnix-lsp apparently is vulnerable? 
    zoom-us
    (pkgs.python311.withPackages(ps: [ 
      ps.pygame 
      ps.matplotlib 
    ]))
    
    #json2nix converter
    (pkgs.writeScriptBin "json2nix" ''
      ${pkgs.python3}/bin/python ${pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
      hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
      }} $@
    '')
    
    #fix-wm
    (pkgs.writeShellScriptBin "fix-wm" ''
      yabai --stop-service && yabai --start-service #helps with adding initial service
      skhd --stop-service && skhd --start-service #otherwise, I have to run manually first time.
      brew services restart felixkratz/formulae/sketchybar 
    '')
  ];
}
