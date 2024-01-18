{ lib, pkgs, config, inputs, ... }:

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
    zellij
    home-manager
    neovim
    neofetch
    htop
    btop
    git
    tree
    ifstat-legacy 
    discord
    ranger
    ncurses6
    hexedit
    # javaPackages.openjfx19
    #inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk20
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
    lolcat
    tree-sitter
    nodejs_20
    #lspconfig
    fd #find tool
    ripgrep
    
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
    darwin-rebuild switch --flake .#NIXY
    home-manager switch --flake .#alex@NIXY
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
    (pkgs.writeShellScriptBin "mic_click" ''
    MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')
    if [[ $MIC_VOLUME -eq 0 ]]; then
    osascript -e 'set volume input volume 25'
    sketchybar -m --set mic icon=
    elif [[ $MIC_VOLUME -gt 0 ]]; then
    osascript -e 'set volume input volume 0'
    sketchybar -m --set mic icon=
    fi 
    '')
    
    # #singleusermode on ##FIXME: Totally broken atm.
    # (pkgs.writeShellScriptBin "sumode" ''
    # if [[ "$1" == "on" ]]; then
    #   echo "User entered 'on' argument."
    #   echo "Turning on Single User Mode..."
    #   sudo nvram boot-args="-arm64e_preview_abi -v -s"
    # elif [[ "$1" == "off" ]]; then
    #   echo "User entered 'off' argument."
    #   echo "Turning off Single User Mode..."
    #   sudo nvram boot-args="-arm64e_preview_abi -v"
    # fi
    # if [[ "$1" == "on" || "$1" == "off" ]]; then
    #   echo "Completed. Your boot args are listed below:"
    #   nvram -p | grep boot-args
    #   echo "Done. Rebooting..."
    #   sleep 2
    #   sudo reboot
    # else
    #   echo "No argument provided. Please add arguments 'on' or 'off' for this command."
    #   echo "Your current boot args are listed below:"
    #   nvram -p | grep boot-args
    # fi
    # '')
  ];

  system.activationScripts.extraActivation.text = '' 
  ln -sf "${inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk20}/zulu-20.jdk" "/Library/Java/JavaVirtualMachines/"
  '';
}
