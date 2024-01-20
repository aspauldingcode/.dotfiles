{ pkgs, ... }:
# NIXY-specific packages

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home.packages = with pkgs; [
    calcurse
    pfetch
    chatgpt-cli
    cowsay
    qemu
    discord
    spotify
    vscode
    utm 
    mas
    vscode
    audacity
    yazi #somehow it's back? what?
    nil #rnix-lsp apparently is vulnerable? 
    thefuck
    zsh-completions
    zoom-us
    # python39
    (pkgs.python311.withPackages(ps: [ 
      ps.pygame 
      ps.matplotlib 
    ]))
    
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

    #json2nix converter
    (pkgs.writeScriptBin "json2nix" ''
      ${pkgs.python3}/bin/python ${pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
      hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
      }} $@
    '')
    
    #fix-wm
    (pkgs.writeShellScriptBin "fix-wm" ''
      yabai --stop-service && yabai --start-service #helps with adding initial service
      skhd --stop-service && skhd --start-service #otherwise, I have to run manually first time.
      brew services restart felixkratz/formulae/sketchybar 
      launchctl stop org.pqrs.karabiner.karabiner_console_user_server && launchctl start org.pqrs.karabiner.karabiner_console_user_server
      echo -ne '\n' | sudo pkill "Background Music" && "/Applications/Background Music.app/Contents/MacOS/Background Music" > /dev/null 2>&1 &
      '')

    #analyze-output
    (pkgs.writeShellScriptBin "analyze-output" '' 
      # Counter for variable names
      count=1
      # Specify the output file path
      output_file=~/.dotfiles/users/alex/NIXY/sketchybar/cal-output.txt
      
    # Delimiter to replace spaces
    delimiter="⌇"

    # Read input from the pipe
    while IFS= read -r line; do
        # Replace spaces with the specified delimiter
        formatted_line=$(echo "$line" | tr ' ' "$delimiter")

        # Assign each formatted line to a numbered variable
        var_name="line_$count"
        declare "$var_name=$formatted_line"

        # Print the variable name and formatted value
        echo "$var_name: $formatted_line"

        # Increment the counter
        ((count++))
    done > "$output_file"

    echo "Output saved to: $output_file"

        '')

        #assign-inputs
        (pkgs.writeShellScriptBin "assign-inputs" ''
    # Specify the input file path
    input_file=~/.dotfiles/users/alex/NIXY/sketchybar/cal-output.txt

    # Read input from the file
    while IFS= read -r line; do
        # Extract variable name and content
        var_name=$(echo "$line" | cut -d ':' -f 1)
        var_content="$(echo "$line" | cut -d ':' -f 2- | sed 's/^[[:space:]]*//')"

        # Assign content to variable
        declare "$var_name=$var_content"

        # Print variable name and content
        echo "Variable: $var_name"
        echo "Content: $var_content"
    done < "$input_file"

    '')

   #toggle-sketchybar
   (pkgs.writeShellScriptBin "toggle-sketchybar" ''
   toggle_sketchybar() {
        local hidden_status=$(sketchybar --query bar | jq -r '.hidden')

        if [ "$hidden_status" == "off" ]; then
            STATE="on"
            sketchybar --bar hidden=on
        else
            STATE="off"
            sketchybar --bar hidden=off
        fi
    }

    # Example usage
    toggle_sketchybar
   '')
  ];
}
