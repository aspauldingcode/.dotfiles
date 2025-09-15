{
  config,
  lib,
  pkgs,
  hostname,
  ...
}: {
  environment.systemPackages = with pkgs; [
    #rebuild #sudo nixos-rebuild switch --show-trace --option eval-cache false --flake .#HOSTNAME
    (pkgs.writeShellScriptBin "rebuild" ''
      # ${hostname}(x86_64-linux)
      cd ~/.dotfiles
      sudo nixos-rebuild switch --show-trace --flake .#${hostname}
      #home-manager switch --flake .#alex@${hostname}

      echo "Updating README with code statistics..."
      update-readme

      echo "Done. Running 'fix-wm'..."
      fix-wm
      echo "Completed."
      date +"%r"
    '')
    #update
    (pkgs.writeShellScriptBin "update" ''
      cd ~/.dotfiles
      git fetch
      git pull
      git merge origin/main
        # Prompt the user for a commit message
        echo "Enter a commit message:"
        read commit_message
        git add .
        git commit -m "$commit_message"
        git push origin main
    '')
  ];
}
