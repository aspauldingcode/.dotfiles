{ lib, pkgs, config, ... }:

{
services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = ''
			alt - return : open -n /Applications/Alacritty.app;

			alt - h : yabai -m window --focus west
			alt - j : yabai -m window --focus south
			alt - k : yabai -m window --focus north
			alt - l : yabai -m window --focus east
			alt - left  : yabai -m window --focus west
			alt - down  : yabai -m window --focus south
			alt - up    : yabai -m window --focus north
			alt - right : yabai -m window --focus east

# shift window in current workspace
			alt + shift - h : yabai -m window --swap west || $(yabai -m window --display west; yabai -m display --focus west)
			alt + shift - j : yabai -m window --swap south || $(yabai -m window --display south; yabai -m display --focus south)
			alt + shift - k : yabai -m window --swap north || $(yabai -m window --display north; yabai -m display --focus north)
			alt + shift - l : yabai -m window --swap east || $(yabai -m window --display east; yabai -m display --focus east)
			alt + shift - left : yabai -m window --swap west || $(yabai -m window --display west; yabai -m display --focus west)
			alt + shift - down : yabai -m window --swap south || $(yabai -m window --display south; yabai -m display --focus south)
			alt + shift - up : yabai -m window --swap north || $(yabai -m window --display north; yabai -m display --focus north)
			alt + shift - right : yabai -m window --swap east || $(yabai -m window --display east; yabai -m display --focus east)
# set insertion point in focused container
			alt + ctrl - h : yabai -m window --insert west
			alt + ctrl - j : yabai -m window --insert south
			alt + ctrl - k : yabai -m window --insert north
			alt + ctrl - l : yabai -m window --insert east
			alt + ctrl - left  : yabai -m window --insert west
			alt + ctrl - down  : yabai -m window --insert south
			alt + ctrl - up    : yabai -m window --insert north
			alt + ctrl - right : yabai -m window --insert east

# go back to previous workspace (kind of like back_and_forth in i3)
			alt - b : yabai -m space --focus recent

# move focused window to previous workspace
			alt + shift - b : yabai -m window --space recent; \
			yabai -m space --focus recent

# move focused window to next/prev workspace
			alt + shift - 1 : yabai -m window --space 1
			alt + shift - 2 : yabai -m window --space 2
			alt + shift - 3 : yabai -m window --space 3
			alt + shift - 4 : yabai -m window --space 4
			alt + shift - 5 : yabai -m window --space 5
			alt + shift - 6 : yabai -m window --space 6
			alt + shift - 7 : yabai -m window --space 7
			alt + shift - 8 : yabai -m window --space 8
			alt + shift - 9 : yabai -m window --space 9
			alt + shift - 0 : yabai -m window --space 10

			alt + shift - y : yabai -m space --mirror y-axis
			alt + shift - x : yabai -m space --mirror x-axis

# balance size of windows
			alt + shift - 0 : yabai -m space --balance
			alt - e : yabai -m space --layout bsp
			alt - l : yabai -m space --layout float
			alt - s : yabai -m space --layout stack
			
# toggle borders
	#alt - y : yabai -m window --toggle border

# cycle through stack windows
			alt - p : yabai -m window --focus stack.next || yabai -m window --focus south
			alt - n : yabai -m window --focus stack.prev || yabai -m window --focus north

# forwards
			alt - p : yabai -m query --spaces --space \
			| jq -re ".index" \
			| xargs -I{} yabai -m query --windows --space {} \
			| jq -sre "add | map(select(.minimized != 1)) | sort_by(.display, .frame.y, .frame.x, .id) | reverse | nth(index(map(select(.focused == 1))) - 1).id" \
			| xargs -I{} yabai -m window --focus {}

# backwards
		alt - n : yabai -m query --spaces --space \
			| jq -re ".index" \
			| xargs -I{} yabai -m query --windows --space {} \
			| jq -sre "add | map(select(.minimized != 1)) | sort_by(.display, .frame.y, .frame.y, .id) | nth(index(map(select(.focused == 1))) - 1).id" \
			| xargs -I{} yabai -m window --focus {}

			alt + shift - q : yabai -m window --close
			alt - f : yabai -m window --toggle zoom-fullscreen
			alt + shift - f : yabai -m window --toggle native-fullscreen
			echo "skhd config loaded...
			'';
	};

}