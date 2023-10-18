{ lib, pkgs, config, ... }:
{
services.yabai = {
		enable = true;
		package = pkgs.yabai;
		enableScriptingAddition = true;
		config = {
			focus_follows_mouse          = "autofocus"; # <- autofocus | autoraise
			mouse_follows_focus          = "off"; #FIXME: Configure apps so I can turn this on.
			window_placement             = "second_child";
			window_opacity               = "off";
			window_border                = "on";
			window_border_placement      = "inset";
			window_border_blur	     = "off"; 	# <- on | off
			#window_border_blur_radius    = "10";

			# OPTIONS for BORDERS
			# Coffee active, Gray inactive
			active_window_border_color   = "0xffA34A28";
			normal_window_border_color   = "0xff808080";
			insert_feedback_color	     = "0xff808080";
			window_border_width	     = 1;
			#window_border_radius	     = 10; #keep commented
			
			/*
			# Try to hide borders!
			active_window_border_color   = "0x00100000";
			normal_window_border_color   = "0x00100000";
			insert_feedback_color	     = "0x00100000";
			window_border_width	     = 1; #!! 0 sets to thick default.
			#window_border_radius	     = 10; #keep commented
			*/

			window_opacity_duration      = "0.1";
			window_topmost               = "off";
			window_shadow                = "float";
			active_window_opacity        = "1.0";
			normal_window_opacity        = "0.3";
			split_ratio                  = "0.50";
			auto_balance                 = "off";
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
			yabai -m rule --add app='System Settings' manage=off
			yabai -m rule --add app='System Information' manage=off
			yabai -m rule --add app='zoom.us' manage=off
			yabai -m rule --add app='Dock' manage=off
			yabai -m rule --add app='Finder' manage=off
			yabai -m rule --add app='Alacritty' opacity=0.8
			yabai -m rule --add app='Alacritty' window_opacity='on'
# Any other arbitrary config here
			#yabai -m config window_border     on
			yabai -m config active_window_border_topmost on

			#echo "yabai config loaded..."
			'';
	};
}
