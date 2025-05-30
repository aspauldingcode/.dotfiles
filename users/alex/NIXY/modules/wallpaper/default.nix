{
  pkgs,
  user,
  ...
}:

let
  wallpaper_input =
    if pkgs.stdenv.isDarwin then
      ./../../../users/${user}/extraConfig/wallpapers/nix-colors-wallpaper-darwin.png
    else
      ./../../../users/${user}/extraConfig/wallpapers/nix-colors-wallpaper.png;
  wallpaper_output =
    if pkgs.stdenv.isDarwin then
      "/var/root/Pictures/gowall/nix-colors-wallpaper-darwin.png"
    else
      "/var/root/Pictures/gowall/nix-colors-wallpaper.png";
  gowall = "${pkgs.unstable.gowall}/bin/gowall";
in
{
  home.file.".config/wallpaper/config.json".text = ''
    {
    "wallpaper": "/Users/alex/.dotfiles/users/alex/extraConfig/wallpapers/galaxy.png"
    }
  '';

  # "wallpaper": "${wallpaper_output}"

}
