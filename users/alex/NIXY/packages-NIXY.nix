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
    #delta
    #sshpass
    #git-crypt
    cowsay
    qemu
    #discord # not installed?!?!??
    utm  
    mas
    #virt-manager #omg it installs? (crashes tho...)
    rnix-lsp
    #davinci-resolve # Mesa 23.1.7 marked broken - NEEDS TO BE MAS APP? 
    zoom-us
    (pkgs.python311.withPackages(ps: [ 
      ps.pygame 
      ps.matplotlib 
    ]))
# #TODO
# macports?
# orbstack?
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
            #fix-skhd
            (pkgs.writeShellScriptBin "fix-skhd" ''
            sudo pkill skhd && skhd -c /etc/skhdrc -V 
            '')
            #fix-bar
            (pkgs.writeShellScriptBin "fix-bar" ''
            sudo pkill sketchybar && sketchybar &
            '')
            /*#shutdown without params FIXME
            (pkgs.writeShellScriptBin "shutdown" ''
            sudo shutdown -h now
            '')*/
          ];
        }
