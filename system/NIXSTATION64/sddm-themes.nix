{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "sddm-theme";
  src = pkgs.fetchurl {
    url = "https://files04.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE3MDQwNTEwOTYiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6IjVmYmYyMmYzMjNjZmZkNGU1NWU5MGM3MmU5YzFhNDVlZjcyYzgzY2FhYmRmNzFhMzJlZTYyMTVlN2U0NzM5MzE2ZTlmZDg0MzBjYzE2NjdlM2JiMjkxMzM4MzQ2OGY0Mjk1YTdkNjFkN2YyOTlkZTAzODE5YmMyZjlmOTIzNWY4IiwidCI6MTcwNjc2NTQ4MSwic3RmcCI6bnVsbCwic3RpcCI6bnVsbH0.sUEPOprrJM2cuQo9CvSyRnaIRL94CQbRH-zHhTHBxR4/Apple-Sonoma-v2.tar.xz";
    sha256 = "sha256-j6L4KwtTObF+3Ff0AKQlB/KyTJe4Ut39QRXo/VulXsg=";
  };

  installPhase = ''
  mkdir -p $out
  cp -R ./* $out/
  '';
}
# Sonoma V2 theme URL found via inspector
# Request URL:
# https://www.pling.com/dl?file_id=1704051096&file_type=application/x-xz&file_name=Apple-Sonoma-v2.tar.xz&file_size=2023496&has_torrent=0&project_id=2059021&link_type=download&is_external=false&external_link=null
# https://files04.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE3MDQwNTEwOTYiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6IjE0ZDJkMTU4MmUwZDkwZWZlZmVjMGE3NzQwYTY2ZjUzMjYzZDcwM2UyNjkxZTgxOWU3OTRmMGUyMTA3ZDE1MzcxMWNiZTk5NmU4OTQ5MWQyYjVlNWE5NGVjYWFhNzM4ZDQyNDY4YjI1ODEzZDcwOTk5NjVlNzAwNThhODcyZDZiIiwidCI6MTcwNDUxNDUxMCwic3RmcCI6bnVsbCwic3RpcCI6bnVsbH0.j_SLoCJJQtmiXTbHinZ2WPfgXCHr5A6J-l41xwa3fQY/Apple-Sonoma-v2.tar.xz

#new url:
# https://files04.pling.com/api/files/download/j/eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6IjE3MDQwNTEwOTYiLCJ1IjpudWxsLCJsdCI6ImRvd25sb2FkIiwicyI6IjVmYmYyMmYzMjNjZmZkNGU1NWU5MGM3MmU5YzFhNDVlZjcyYzgzY2FhYmRmNzFhMzJlZTYyMTVlN2U0NzM5MzE2ZTlmZDg0MzBjYzE2NjdlM2JiMjkxMzM4MzQ2OGY0Mjk1YTdkNjFkN2YyOTlkZTAzODE5YmMyZjlmOTIzNWY4IiwidCI6MTcwNjc2NTQ4MSwic3RmcCI6bnVsbCwic3RpcCI6bnVsbH0.sUEPOprrJM2cuQo9CvSyRnaIRL94CQbRH-zHhTHBxR4/Apple-Sonoma-v2.tar.xz


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
