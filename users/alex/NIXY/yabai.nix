{ lib, config, pkgs, ...}:
{
services.yabai = {
		enable = true;
		package = pkgs.yabai;
		enableScriptingAddition = true;
		config = {
			focus_follows_mouse          = "autoraise";
			mouse_follows_focus          = "off";
			window_placement             = "second_child";
			window_opacity               = "off";
			window_opacity_duration      = "0.1";
			window_topmost               = "off";
			window_shadow                = "float";
			active_window_opacity        = "1.0";
			normal_window_opacity        = "0.3";
			split_ratio                  = "0.50";
			auto_balance                 = "on";
			mouse_modifier               = "alt";
			mouse_action1                = "move";
			mouse_action2                = "resize";
			layout                       = "bsp";
			top_padding                  = 36;
			bottom_padding               = 10;
			left_padding                 = 10;
			right_padding                = 10;
			window_gap                   = 10;
		};

		extraConfig = ''
# rules
			yabai -m rule --add app='System Preferences' manage=off
			yabai -m rule --add app='zoom.us' manage=off
# Any other arbitrary config here

			yabai -m window_border	              on
			yabai -m window_border_blur   	      on
			yabai -m window_border_radius	      0
			yabai -m window_border_width   	      0
			#yabai -m active_window_border_color   0x0000000000
			#yabai -m normal_window_border_color   0xff555555
			#yabai -m window_origin_display        default

# Toggle test
#yabai -m query --windows --space |
#jq '.[].id' |
#xargs -I{} yabai -m window {} --toggle border

			echo "yabai config loaded...
			'';
	};
}
