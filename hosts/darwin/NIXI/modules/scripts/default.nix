{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "rebuild" ''
      echo "Rebuilding..."
      cd ~/.dotfiles
      sudo darwin-rebuild switch --show-trace --flake .#NIXI

      echo "Fetching latest erase-install pkg."
      ${bash}/bin/bash ${../../../erase-install-fetcher.sh}

      echo "Updating README with code statistics..."
      update-readme

      echo "Done."
      date +"%I:%M:%S %p"
    '')
  ];
}