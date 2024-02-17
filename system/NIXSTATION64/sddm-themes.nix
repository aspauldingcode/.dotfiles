{ pkgs }:

#You can use WhiteSur theme now btw,,,
# Sddm Sonoma theme!
let
  /*
  profile = pkgs.fetchurl {
    url =  "https://avatars.githubusercontent.com/u/10196826?v=4"; # https link to image
    sha256 = ""; # hash of image file
  };
  */
  #profile = 
  background = ./../../users/alex/extraConfig/wallpapers/ghibliwp.jpg; #background image?
in
pkgs.stdenv.mkDerivation {
  name = "sddm-theme-sonoma-v2";
  src = pkgs.fetchurl {
    url = "https://files04.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE3MDQwNTEwOTYiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6IjMxNTE5NDdkZTAxZTkxY2M2MjUxN2NjNDljNTRjMGVlZWU4ZjBhMTg0NTllNTE2NWE0MmE1ZmEyNWNhODBmZjQzOTM4MDIzMTg3OTU1OGUwYmFhNjVmODZjZmViMWQ4M2E2ZWI5NGZlNDAxZWMwYzIxNjE2MTc5NmU1MWZiNzZmIiwidCI6MTcwNzcxNjQzMCwic3RmcCI6bnVsbCwic3RpcCI6bnVsbH0.UYsXQF_ucC6NiBvYuKzdMX5FHELoYNzx7qEgQqLOhx8/Apple-Sonoma-v2.tar.xz";
    sha256 = "sha256-j6L4KwtTObF+3Ff0AKQlB/KyTJe4Ut39QRXo/VulXsg=";
  };

  installPhase = ''
  mkdir -p $out
  cp -R ./* $out/

  # replace background wallpaper!
  cd $out/
  rm background.jpg
  cp -r ${background} $out/background.jpg

  # replace profile picture for alex?
  #rm 
  #cp
  '';
}



/*
FOLDER OUTLINE:
nix/store...w4pxwif-sddm-theme-sonoma-v2
 images                                                                                                                             │  VirtualKeyboard.qml
 fonts                                                                                                                              │  TextConstants.qml
 components                                                                                                                         │  ShutdownToolTip.qml
 theme.conf.user                                                                                                                    │  RebootToolTip.qml
 theme.conf                                                                                                                         │  Clock.qml
 screenshot.png                                                                                                                     │
 metadata.desktop                                                                                                                   │
 background.jpg                                                                                                                     │
 SessionButton.qml                                                                                                                  │
 Main.qml                                                                                                                           │
 LICENSE                                                                                                                            │
 AUTHORS                                                                                                                            │
*/

#Main.qml contains info on the sizing of profile photo, the name of the "Enter Password" greeting, etc.

# Sonoma V2 theme URL found via inspector
# Request download URL:
# https://www.pling.com/dl?file_id=1704051096&file_type=application/x-xz&file_name=Apple-Sonoma-v2.tar.xz&file_size=2023496&has_torrent=0&project_id=2059021&link_type=download&is_external=false&external_link=null

#new url:
# https://files04.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE3MDQwNTEwOTYiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6IjMxNTE5NDdkZTAxZTkxY2M2MjUxN2NjNDljNTRjMGVlZWU4ZjBhMTg0NTllNTE2NWE0MmE1ZmEyNWNhODBmZjQzOTM4MDIzMTg3OTU1OGUwYmFhNjVmODZjZmViMWQ4M2E2ZWI5NGZlNDAxZWMwYzIxNjE2MTc5NmU1MWZiNzZmIiwidCI6MTcwNzcxNjQzMCwic3RmcCI6bnVsbCwic3RpcCI6bnVsbH0.UYsXQF_ucC6NiBvYuKzdMX5FHELoYNzx7qEgQqLOhx8/Apple-Sonoma-v2.tar.xz


/* WORKING
{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "sddm-theme";
  src = pkgs.fetchFromGitHub {
    owner = "MarianArlt";
    repo = "sddm-sugar-dark";
    rev = "ceb2c455663429be03ba62d9f898c571650ef7fe";
    sha256 = "0153z1kylbhc9d12nxy9vpn0spxgrhgy36wy37pk6ysq7akaqlvy";
  };

  installPhase = ''
  mkdir -p $out
  cp -R ./* $out/
  '';
} 
*/
