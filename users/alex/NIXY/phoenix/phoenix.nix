{ ... }:

# macOS Pheonix Window Manager Config
{

 # Note: to use phoenix typescript, learn of phoenix typings: https://github.com/mafredri/phoenix-typings/
 #home.file.phoenix = {
 #  target = ".config/phoenix/phoenix.js"; # javascript first.
 #  text = /* javascript */ '' #inline js config
 #  '';
 #};

 home.file.".config/phoenix/phoenix.js".source = ./phoenix.js;
}