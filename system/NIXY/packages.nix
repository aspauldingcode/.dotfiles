{ lib, pkgs, config,  ... }:

{
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config = {
      allowUnfree = true;
      allowUnfreePredictate = (_: true);
    };
  };
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [ 
        ## macosINSTANTView?
        home-manager
        skhd
        neovim
        neofetch
        htop
        git
        tree
        discord
        ranger
        hexedit
        #alacritty
        iterm2
        python311
        python311Packages.pygame
        oh-my-zsh #zsh shell framework
        oh-my-fish #fish shell framework
        #oh-my-git #git learning game
        dmenu
        dwm
        zoom-us
        android-tools
        jq
        libusb
        asdf-vm
        lolcat
        tree-sitter
        nodejs_20
        fd #find tool
        ripgrep
        #rebuild
        (pkgs.writeShellScriptBin "rebuild" ''
        # NIXY(aarch64-darwin)
        if [[ "$1" == "-r" ]]; then
          echo "User entered -r argument."
          echo "Will reset Launchpad after rebuild."
        else
          echo "No -r argument provided."
          echo "Rebuilding..."
        fi
        cd ~/.dotfiles
        darwin-rebuild switch --flake .#NIXY
        home-manager switch --flake .#alex@NIXY
        if [[ "$1" == "-r" ]]; then
          echo "Resetting Launchpad!"
          defaults write com.apple.dock ResetLaunchPad -bool true
        fi 
        echo "Done."
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
          #mic (for sketchybar!)
          (pkgs.writeShellScriptBin "mic" ''
          MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

          if [[ $MIC_VOLUME -eq 0 ]]; then
          sketchybar -m --set mic icon=
          elif [[ $MIC_VOLUME -gt 0 ]]; then
          sketchybar -m --set mic icon=
          fi 
          '')
          #mic_click (for sketchybar!)
          (pkgs.writeShellScriptBin "mic_click" ''MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

          if [[ $MIC_VOLUME -eq 0 ]]; then
          osascript -e 'set volume input volume 25'
          sketchybar -m --set mic icon=
          elif [[ $MIC_VOLUME -gt 0 ]]; then
          osascript -e 'set volume input volume 0'
          sketchybar -m --set mic icon=
          fi 
          '')

        ];
      }
