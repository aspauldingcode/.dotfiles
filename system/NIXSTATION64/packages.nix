# Configure included packages for NixOS.

{ lib, config, nixpkgs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    wl-clipboard
    neofetch
    yazi ueberzugpp 
    pcmanfm			
    wofi-emoji htop fim
    gparted killall tree
    zsh curl lazygit
    wget git
    pstree
    zoxide
    dnsmasq
    udftools
    element appimage-run
    tree-sitter
<<<<<<< HEAD
    python312
    jdk20
    libsForQt5.dolphin
    cinnamon.nemo
    xfce.thunar
    gnome.gnome-disk-utility
    gnome.nautilus
    gnome.sushi
    libsForQt5.breeze-qt5
    libsForQt5.breeze-gtk
    libsForQt5.breeze-icons
    libsForQt5.breeze-plymouth
    libsForQt5.breeze-grub
=======
    python311
>>>>>>> 6183b2707b730103bcab024d7611b9f030645a67
    nodejs
    flex bison
    gnumake gcc
    openssl dtc gnome-themes-extra
    cargo nodePackages_latest.npm
    perl 
    hexedit virt-manager
        #rebuild
        (pkgs.writeShellScriptBin "rebuild" ''
        # NIXSTATION64(x86_64-linux)
        cd ~/.dotfiles
        sudo nixos-rebuild switch --flake .#NIXSTATION64 
        home-manager switch --flake .#alex@NIXSTATION64
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
        #screenshot
        (pkgs.writeShellScriptBin "screenshot" ''
          # Specify the full path to your desktop directory
          output_directory="$HOME/Desktop"

          # Get the list of output names
          output_names=$(swaymsg -t get_outputs | jq -r '.[].name')

          # Loop through each output and save its contents to the desktop directory
          for output_name in $output_names
          do
          output_file="$output_directory/$output_name.png"
          grim -o $output_name "$output_file"
          done
          '')
          
          (pkgs.writeShellScriptBin  "screenshot-selection-toggle" ''
            # This is a Bash script that runs a Node.js program.
            # Define the JavaScript program as a string
JS_PROGRAM='
function handleKeyPress(event) {
  if (event.key === "a") {
    console.log("Command 1 triggered");
  } else if (event.key === "A" && event.shiftKey) {
    console.log("Command 2 triggered");
  }
}

document.addEventListener("keydown", handleKeyPress);
'

# Save the JavaScript program to a temporary file
TEMP_JS_FILE="$(mktemp)"
echo "$JS_PROGRAM" > "$TEMP_JS_FILE"

# Run the JavaScript program using Node.js
node "$TEMP_JS_FILE"

# Clean up the temporary file
rm "$TEMP_JS_FILE"            
          '')
        #maximize (maximize sway windows to window size rather than fullscreen)
        (pkgs.writeShellScriptBin "maximize" ''
       
# un/maximize script for i3 and sway
# bindsym $mod+m exec ~/.config/i3/maximize.sh

WRKSPC_FILE=~/.config/wrkspc
RESERVED_WORKSPACE=10
MSG=swaymsg
if [ "$XDG_SESSION_TYPE" == "x11"]
then
	MSG=i3-msg
fi

# using xargs to remove quotes
CURRENT_WORKSPACE=$($MSG -t get_workspaces | jq '.[] | select(.focused==true) | .name' | xargs)

if [ -f "$WRKSPC_FILE" ]
then # restore window back
  if [ "$CURRENT_WORKSPACE" != "$RESERVED_WORKSPACE" ]
  then
    RESERVED_WORKSPACE_EXISTS=$($MSG -t get_workspaces | jq '.[] .num' | grep "^$RESERVED_WORKSPACE$")
    if [ -z "$RESERVED_WORKSPACE_EXISTS" ]
    then
      notify-send "Reserved workspace $RESERVED_WORKSPACE does not exist. Noted."
      rm -f $WRKSPC_FILE
    else
      notify-send "Clean your workspace $RESERVED_WORKSPACE first."
    fi
  else
    # move the window back
    $MSG move container to workspace number $(cat $WRKSPC_FILE)
    $MSG workspace number $(cat $WRKSPC_FILE)
    notify-send "Returned back to workspace $(cat $WRKSPC_FILE)."
    rm -f $WRKSPC_FILE
  fi
else # send window to the reserved workspace
  if [ "$CURRENT_WORKSPACE" == "$RESERVED_WORKSPACE" ]
  then
    notify-send "You're already on reserved workspace $RESERVED_WORKSPACE."
  else
    # remember current workspace
    echo $CURRENT_WORKSPACE > $WRKSPC_FILE
    $MSG move container to workspace number $RESERVED_WORKSPACE
    $MSG workspace number $RESERVED_WORKSPACE
    notify-send "Saved workspace $CURRENT_WORKSPACE and moved to workspace $RESERVED_WORKSPACE."
  fi
  fi
  '') 
         ]; 
}
