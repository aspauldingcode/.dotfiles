{
  pkgs,
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

      echo "fetching latest erase-install pkg."
      ${pkgs.bash}/bin/bash ${../../erase-install-fetcher.sh}
      echo "Updating readme.md."
      ${pkgs.bash}/bin/bash ${../../count_lines_of_code.sh}
      echo "Formatting all nix files..."
      ${pkgs.treefmt2}/bin/treefmt ${
        if pkgs.stdenv.isDarwin then "/Users/alex/.dotfiles" else "/home/alex/.dotfiles"
      }

      echo "Done."
      date +"%I:%M:%S %p"
    '')
  ];
}
