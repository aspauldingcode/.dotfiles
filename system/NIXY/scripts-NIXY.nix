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
      reset_launchpad=false
      run_fix_wm=false

      while [[ $# -gt 0 ]]; do
        case "$1" in
          -r)
            echo "User entered -r argument."
            echo "Will reset Launchpad after rebuild."
            reset_launchpad=true
            ;;
          -f)
            echo "User entered -f argument."
            echo "Will run 'fix-wm' after rebuild."
            run_fix_wm=true
            ;;
          *)
            echo "Unknown argument: $1"
            ;;
        esac
        shift
      done

      if [ "$reset_launchpad" = true ]; then
        echo "Resetting Launchpad!"
        defaults write com.apple.dock ResetLaunchPad -bool true
      fi

      echo "Rebuilding..."
      cd ~/.dotfiles
      darwin-rebuild switch --show-trace --flake .#NIXY
      #home-manager switch --show-trace --flake .#alex@NIXY
      echo "Done."

      if [ "$run_fix_wm" = true ]; then
        echo "Running 'fix-wm'..."
        fix-wm
        echo "Completed 'fix-wm'."
      else
        echo "Skipping 'fix-wm' as -f argument not provided."
      fi

      date +"%I:%M:%S %p"
    '')

    #update
    (pkgs.writeShellScriptBin "update" ''
      cd ~/.dotfiles
      git fetch
      git pull
      git merge origin/main
      echo "Enter a commit message:"
      read commit_message
      git add .
      git commit -m "$commit_message"
      git push origin main
    '')
  ];
}