{pkgs, hostname, ...}: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "rebuild" ''
      echo "Rebuilding ${hostname}..."
      cd ~/.dotfiles
      sudo darwin-rebuild switch --show-trace --flake .#${hostname}

      # Removed: erase-install fetcher script

      echo "Updating README with code statistics..."
      update-readme

      echo "Done."
      date +"%I:%M:%S %p"
    '')
  ];
}
