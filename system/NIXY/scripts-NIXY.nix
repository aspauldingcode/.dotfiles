{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # rebuild
    (pkgs.writeShellScriptBin "rebuild" ''
      # NIXY(aarch64-darwin)
      echo "Rebuilding..."
      cd ~/.dotfiles
      darwin-rebuild switch --show-trace --flake .#NIXY

      echo "Formatting all nix files..."
      ${pkgs.bash}/bin/bash ${../../treefmt_nix.sh}

      echo "fetching latest erase-install pkg."
      ${pkgs.bash}/bin/bash ${../../erase-install-fetcher.sh}
      echo "Updating readme.md."
      ${pkgs.bash}/bin/bash ${../../count_lines_of_code.sh}
      echo "Done."
      date +"%I:%M:%S %p"
    '')
  ];
}
