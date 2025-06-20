{ config, pkgs, ... }:

let
  systemType = pkgs.stdenv.hostPlatform.system;
  homebrewPath =
    if systemType == "aarch64-darwin" then
      "/opt/homebrew/bin"
    else if systemType == "x86_64-darwin" then
      "/usr/local/bin"
    else
      throw "Homebrew Unsupported architecture: ${systemType}";
  jq = "${pkgs.jq}/bin/jq";
  yabai = "${pkgs.yabai}/bin/yabai";
  sketchybar = "${pkgs.unstable.sketchybar}/bin/sketchybar";
  borders = "";
  skhd = "${pkgs.skhd}/bin/skhd";
  inherit (config.colorScheme) palette;
in
{
  home = {
    packages = with pkgs; [

      #json2nix converter
      #(pkgs.writeScriptBin "json2nix" ''
      #  ${pkgs.python3}/bin/python ${
      #    pkgs.fetchurl {
      #      url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
      #      hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
      #    }
      #  } $@
      #'')

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

      # print-spaces
      (pkgs.writeShellScriptBin "print-spaces" ''
        #!/bin/bash

        # Query for spaces with windows
        spaces_with_windows=($(${yabai} -m query --spaces | ${jq} -r '.[] | select(.windows | length > 0) | .index'))

        # Query for the active space
        active_space=$(${yabai} -m query --spaces --space | ${jq} -r '.index')

        # active space per display
        # Query for the total number of displays
        total_displays=$(${yabai} -m query --displays | ${jq} 'length')

        # Initialize an array to store active display spaces
        active_display_spaces=()

        # Loop through each display
        for ((display=1; display<=$total_displays; display++)); do
            # Query for spaces on the current display that are visible
            spaces=$(${yabai} -m query --spaces --display $display | ${jq} -r '.[] | select(.["is-visible"] == true) | .index')

            # Add visible spaces to the active_display_spaces array
            for space in $spaces; do
                active_display_spaces+=("$space")
            done
        done

        # Combine spaces with windows and active spaces on all displays
        print=($(echo "''${spaces_with_windows[@]}" "''${active_display_spaces[@]}" | tr ' ' '\n' | sort -nu))

        echo "''${print[@]}"
      '')

      # spaces-clear
      (pkgs.writeShellScriptBin "spaces-clear" ''
        #!/bin/bash

        # count all spaces.
        # all=length(spaces)
        max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')

        # Query for the highest space containing a window
        lastwindow=$(${yabai} -m query --spaces | ${jq} '[.[] | select(.windows | length > 0) | .index] | max')

        # remaining=max_spaces - last space with a window
        remaining=$((max_spaces - lastwindow))

        # from last to
        for ((i=1; i<=$remaining; i++))
        do
            ${yabai} -m space $(($lastwindow + 1)) --destroy
        done

      '')

      # spaces-focus
      (pkgs.writeShellScriptBin "spaces-focus" ''
        # Define variables
        # How many displays are there?
        max_displays=$(${yabai} -m query --displays | ${jq} 'max_by(.index) | .index')
        # How many spaces are there?
        max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
        # Current active space!
        current_space=$(${yabai} -m query --spaces --space | ${jq} -r '.index')
        # Current active display!
        current_display=$(${yabai} -m query --displays --display | ${jq} -r '.index')
        # Accept desired space number as input argument
        if [ $# -ne 1 ]; then
        echo "Usage: $0 <desired_space_number>"
        exit 1
        fi
        n=$1
        # Focus on a space
        # If space n is not created, create it
        if [ $n -gt $max_spaces ]; then
          iterations=$((n - max_spaces))
          for ((i=0; i<iterations; i++)); do
            ${yabai} -m space --create
            #reassign max_spaces:
            max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
          done
        fi
        # then, focus on space n
        ${yabai} -m space --focus $n
      '')

      # move-to-space
      (pkgs.writeShellScriptBin "move-to-space" ''
        # Define variables
        # How many displays are there?
        max_displays=$(${yabai} -m query --displays | ${jq} 'max_by(.index) | .index')
        # How many spaces are there?
        max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
        # Current active space!
        current_space=$(${yabai} -m query --spaces --space | ${jq} -r '.index')
        # Current active display!
        current_display=$(${yabai} -m query --displays --display | ${jq} -r '.index')
        # Accept desired space number as input argument
        if [ $# -ne 1 ]; then
        echo "Usage: $0 <desired_space_number>"
        exit 1
        fi
        n=$1
        # Focus on a space
        # If space n is not created, create it
        if [ $n -gt $max_spaces ]; then
          iterations=$((n - max_spaces))
          for ((i=0; i<iterations; i++)); do
            ${yabai} -m space --create
            #reassign max_spaces:
            max_spaces=$(${yabai} -m query --spaces | ${jq} 'max_by(.index) | .index')
          done
        fi
        # then, move window to space n
        ${yabai} -m window --space $n
        # then, focus on space n
        ${yabai} -m space --focus $n
      '')

      # statefile-reader
      (pkgs.writeShellScriptBin "statefile-reader" ''
        gaps_state_file="/tmp/gaps_state"
        sketchybar_state_file="/tmp/sketchybar_state"
        dock_state_file="/tmp/dock_state"
        menubar_state_file="/tmp/menubar_state"
        darkmode_state_file="/tmp/darkmode_state"

        # Function to read state from file
        read_state() {
            if [ -f "$1" ]; then
                cat "$1"
            else
                echo "off"
            fi
        }

        # Read the current state from the state files, if they exist
        gaps_state=$(read_state "$gaps_state_file")
        sketchybar_state=$(read_state "$sketchybar_state_file")
        dock_state=$(read_state "$dock_state_file")
        menubar_state=$(read_state "$menubar_state_file")
        darkmode_state=$(read_state "$darkmode_state_file")

        # Function to check dark mode status and update darkmode state file
        check_darkmode_status() {
            darkmode_status=$(osascript -e 'tell application "System Events" to tell appearance preferences to get dark mode')
            if [ "$darkmode_status" = "true" ]; then
                darkmode_state="on"
            else
                darkmode_state="off"
            fi
            echo "$darkmode_state" > "$darkmode_state_file"
        }

        # Call the function to check dark mode status
        check_darkmode_status

        # Update the sketchybar state
        sketchybar_hidden_status=$(${sketchybar} --query bar | ${jq} -r '.hidden')
        if [ "$sketchybar_hidden_status" = "on" ]; then
            sketchybar_state="off"
        elif [ "$sketchybar_hidden_status" = "off" ]; then 
            sketchybar_state="on"
        fi

        # Update the dock state
        dock_status=$(osascript -e 'tell application "System Events" to get autohide of dock preferences')
        if [ "$dock_status" = "true" ]; then
            dock_state="off"
        elif [ "$dock_status" = "false" ]; then
            dock_state="on"
        fi

        echo "Gaps is: $gaps_state"
        echo "Sketchybar is: $sketchybar_state"
        echo "Dock is: $dock_state"
        echo "Menubar is: $menubar_state"
        echo "Dark Mode is: $darkmode_state"
      '')

      #search
      (pkgs.writeShellScriptBin "search" ''
        # Check if an argument is provided
        if [ $# -ne 1 ]; then
            echo "Usage: $0 <search_term>"
            exit 1
        fi

        # Perform the search (in the current directory) using find and fzf with provided options
        search_term=$1
        echo "Searching for: $search_term"
        echo "Press Ctrl+C to cancel..."
        find . -iname "*$search_term*" 2>/dev/null | fzf --preview="bat --color=always {}" --preview-window="right:60%" --height=80%
      '')

      #search-rg
      (pkgs.writeShellScriptBin "search-rg" ''
        if [ $# -ne 1 ]; then
            echo "Usage: $0 <search_term>"
            exit 1
        fi

        # Perform the search using ripgrep and fzf with provided options
        search_term=$1
        echo "Searching for: $search_term"
        echo "Press Ctrl+C to cancel..."
        rg --ignore-case --context 3 --color=always "$search_term" | fzf --preview="bat --color=always --style=numbers,changes {}" --preview-window="right:60%" --height=80%
      '')

      #hexdiff_check
      (pkgs.writeShellScriptBin "hexdiff_check" ''
        #!/bin/sh

        # Function to pick a file using zenity and suppress GLib error messages
        pick_file() {
          zenity --file-selection --title="Select file to compare:" 2>/dev/null
        }

        # Function to format file path for display (splitting if longer than 60 characters)
        format_filepath() {
          local filepath=$1
          local max_length=60

          # Check if filepath length exceeds max_length
          if [ ''${#filepath} -le $max_length ]; then
            echo "$filepath"
          else
            # Split filepath into multiple lines
            local first_part="''${filepath:0:$max_length}"
            local remaining="''${filepath:$max_length}"

            echo "$first_part"
            while [ ''${#remaining} -gt $max_length ]; do
              echo "''${remaining:0:$max_length}"
              remaining="''${remaining:$max_length}"
            done

            # Print the remaining part or final line
            if [ -n "$remaining" ]; then
              echo "$remaining"
            fi
          fi
        }

        # Function to perform hex diff and format output
        hex_diff() {
          local file1=$1
          local file2=$2

          # Create temporary files for hex dumps
          temp1=$(mktemp)
          temp2=$(mktemp)

          # Create hex dumps of both files
          xxd "$file1" > "$temp1"
          xxd "$file2" > "$temp2"

          # Perform the comparison and format the output
          diff_output=$(diff -y --suppress-common-lines "$temp1" "$temp2")

          # Check if there are differences
          if [ -z "$diff_output" ]; then
            echo "The files are identical."
          else
            echo "Hexadecimal Differences:"
            echo "$diff_output" | while IFS= read -r line; do
              if [[ $line =~ ^[0-9a-f]+ ]]; then
                echo "$line"
              fi
            done
            # Save the diff output to a file
            echo "$diff_output" > /tmp/hex_differences.txt
            echo "For convenience, this diff output has been saved to /tmp/hex_differences.txt"
          fi

          # Clean up temporary files
          rm "$temp1" "$temp2"
        }

        # Pick the first file
        echo "Select the first file:"
        file1=$(pick_file)
        echo $(basename "$file1")

        # Check if a file was selected
        if [ -z "$file1" ]; then
          echo "No file selected. Exiting."
          exit 1
        fi

        # Pick the second file
        echo "Select the second file:"
        file2=$(pick_file)
        echo $(basename "$file2")

        # Check if a file was selected
        if [ -z "$file2" ]; then
          echo "No file selected. Exiting."
          exit 1
        fi


        echo "Comparing Files:"

        # Format file paths for display
        file1_formatted=$(format_filepath "$file1")
        file2_formatted=$(format_filepath "$file2")

        # Split formatted file paths into lines
        file1_lines=()
        file2_lines=()
        while IFS= read -r line; do
          file1_lines+=("$line")
        done <<< "$file1_formatted"

        while IFS= read -r line; do
          file2_lines+=("$line")
        done <<< "$file2_formatted"

        # Determine maximum number of lines
        max_lines=$((''${#file1_lines[@]} > ''${#file2_lines[@]} ? ''${#file1_lines[@]} : ''${#file2_lines[@]}))

        # Print the formatted output in a table format with left alignment
        for (( i=0; i<max_lines; i++ )); do
          file1_print="''${file1_lines[$i]:-}"
          file2_print="''${file2_lines[$i]:-}"

          printf "%-60s    |       %-60s\n" "$file1_print" "$file2_print"
        done

        # Perform hex diff between the selected files
        hex_diff "$file1" "$file2"


        echo "Compared Files:"
        # Print the formatted output in a table format with left alignment
        for (( i=0; i<max_lines; i++ )); do
          file1_print="''${file1_lines[$i]:-}"
          file2_print="''${file2_lines[$i]:-}"

          printf "%-60s    | %-60s\n" "$file1_print" "$file2_print"
        done
      '')

      # xvnc-iphone
      (pkgs.writeShellScriptBin "xvnc-iphone" ''
        #!/bin/sh

        echo "yeah not quite."
      '')

      # connect to school vms
      (pkgs.writeShellScriptBin "connect_to_vm" ''
        #!/bin/bash

        # Ensure an argument is passed (course name)
        if [ -z "$1" ]; then
          echo "Usage: $0 <course_name>"
          echo "Available vms: cybr_101, cscd_240"
          exit 1
        fi

        # Define course names and corresponding SSH details
        course="$1"

        case "$course" in
          cybr_101)
            clear
            echo "be sure to connect to GlobalProtect VPN first."
            sleep 1
            clear
            ssh aspaulding5@10.102.65.39
            ;;
          cscd_240)
            clear
            echo "be sure to connect to GlobalProtect VPN first."
            sleep 1
            clear
            ssh -i ~/Documents/School/cscd_240/cscd240_3.pem ubuntu@10.219.1.63
            ;;
          *)
            echo "Invalid course name. Please use 'cybr_101' or 'cscd_240'."
            exit 1
            ;;
        esac
      '')
    ];
  };
}
