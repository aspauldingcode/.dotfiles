{
  inputs,
  lib,
  config,
  pkgs,
  user,
  hostname,
  ...
}: {
  imports = [
    ./home
    ./modules
    ./scripts
  ];
}
