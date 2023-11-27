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
    spotify
    vscode
    utm  
    mas
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

#hello
(pkgs.writeShellScriptBin "my-hello" ''
echo "Hello, ${config.home.username}!"
'')
    #lockscreen-motd
    (pkgs.writeShellScriptBin "lockscreen-motd" ''
    class_directory="/Users/alex/"

            # Run the Java program with the classpath option and 
            # capture its output in the 'what' variable
            what=$(java -cp "$class_directory" SineWaveASCII)

            # Use the captured output as 'LoginwindowText' directly
            sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "$what"
            '')
            #fix-wm
            (pkgs.writeShellScriptBin "fix-wm" ''
              yabai --restart-service
              skhd --restart-service
              brew services restart felixkratz/formulae/sketchybar 
            '')
          ];
        }
