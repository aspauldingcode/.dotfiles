{ config, lib, pkgs, ... }:

{
  environment = {
    sessionVariables.NIXOS_OZONE_WL = "1";
    systemPackages = with pkgs; [
      #rebuild #sudo nixos-rebuild switch --show-trace --option eval-cache false --flake .#NIXY2
      (pkgs.writeShellScriptBin "rebuild" ''
        # NIXY2(aarch64-linux)
        cd ~/.dotfiles
        sudo nixos-rebuild switch --show-trace --impure --flake .#NIXY2 
        #home-manager switch --flake .#alex@NIXY2
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
      #screenshot
      (pkgs.writeShellScriptBin "screenshot" ''
        # Specify the full path to your desktop directory
        output_directory="$HOME/Desktop"

        # Get the list of output names
        output_names=$(swaymsg -t get_outputs | jq -r '.[].name')

        # Loop through each output and save its contents to the desktop directory
        for output_name in $output_names
        do
            output_file="$output_directory/Screenshot $(date '+%Y-%m-%d at %I.%M.%S %p') $output_name.png"
            grim -o $output_name "$output_file"
        done      
      '')
      #maximize (FIXME maximize sway windows to window size rather than fullscreen)
      (pkgs.writeShellScriptBin "maximize" ''
        # un/maximize script for i3 and sway
        # bindsym $mod+m exec ~/.config/i3/maximize.sh

        WRKSPC_FILE=~/.config/wrkspc
        RESERVED_WORKSPACE=f
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
            $MSG move container to workspace $(cat $WRKSPC_FILE)
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
            $MSG move container to workspace $RESERVED_WORKSPACE
            $MSG workspace $RESERVED_WORKSPACE
            notify-send "Saved workspace $CURRENT_WORKSPACE and moved to workspace $RESERVED_WORKSPACE."
          fi
        fi
      '')
    ];
  };
}