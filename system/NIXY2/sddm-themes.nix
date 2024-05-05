{ pkgs }:

#You can use WhiteSur theme now btw,,,
# Sddm Sonoma theme!
let
  /* profile = pkgs.fetchurl {
       url =  "https://avatars.githubusercontent.com/u/10196826?v=4"; # https link to image
       sha256 = ""; # hash of image file
     };
  */
  #profile = 
  background = ./../../users/alex/extraConfig/wallpapers/ghibliwp.jpg; # background image?
in
pkgs.stdenv.mkDerivation {
  name = "sddm-theme-sonoma-v2";
  src = pkgs.fetchurl {
    url = "https://files04.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE3MDcwNjcxNzEiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6ImNlYjNlMDY1MDZhMWRlNWRkYWIzNWMzODM4YmUwMDMxOTQ2Zjg1NDM0M2RmZWEwNTM1OTQzNTRmZjk2NGQ4YjUyMThlMjRjNGZhZTZjN2YxZTNlNGJjYzAwMGZkYWJiOTNmMGM4OGQ4YjNmZmMwODMwODliOTEyNmVlNjA4YWU1IiwidCI6MTcwOTMzODkxNiwic3RmcCI6bnVsbCwic3RpcCI6bnVsbH0.tVNB03J5rYoFyHyEaiTAMCprZSwSXpE6L6u3oNqG3p0/Apple-Sonoma-v3.tar.xz";
    sha256 = "sha256-GISzO/xQQrl3PUlK8u1QtQ2iIdaO2lDKuOX+rKMbQGA=";
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

/* FOLDER OUTLINE:
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

# NEW NEW URL: Sonoma v3:
# https://ocs-dl.fra1.cdn.digitaloceanspaces.com/data/files/1704657395/Apple-Sonoma-v3.tar.xz?response-content-disposition=attachment%3B%2520Apple-Sonoma-v3.tar.xz&X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=RWJAQUNCHT7V2NCLZ2AL%2F20240302%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240302T001657Z&X-Amz-SignedHeaders=host&X-Amz-Expires=3600&X-Amz-Signature=3d7a82b4200cb46522627ae77b4227cd165427d95ac3973e1f3e586b14e4a377

# https://files04.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE3MDcwNjcxNzEiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6ImNlYjNlMDY1MDZhMWRlNWRkYWIzNWMzODM4YmUwMDMxOTQ2Zjg1NDM0M2RmZWEwNTM1OTQzNTRmZjk2NGQ4YjUyMThlMjRjNGZhZTZjN2YxZTNlNGJjYzAwMGZkYWJiOTNmMGM4OGQ4YjNmZmMwODMwODliOTEyNmVlNjA4YWU1IiwidCI6MTcwOTMzODkxNiwic3RmcCI6bnVsbCwic3RpcCI6bnVsbH0.tVNB03J5rYoFyHyEaiTAMCprZSwSXpE6L6u3oNqG3p0/Apple-Sonoma-v3.tar.xz

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
