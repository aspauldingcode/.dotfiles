{
  inputs,
  pkgs,
  lib,
  user,
  ...
}:

{
  imports = [
    ./home
    ./scripts
    ./modules
  ];
}
