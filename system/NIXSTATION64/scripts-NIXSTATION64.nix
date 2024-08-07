{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    #rebuild #sudo nixos-rebuild switch --show-trace --option eval-cache false --flake .#NIXSTATION64
    (pkgs.writeShellScriptBin "rebuild" ''
      # NIXSTATION64(x86_64-linux)
      cd ~/.dotfiles
      sudo nixos-rebuild switch --show-trace --flake .#NIXSTATION64 
      #home-manager switch --flake .#alex@NIXSTATION64
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
