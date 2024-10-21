{ config, pkgs, ... }:

let
  systemType = pkgs.stdenv.hostPlatform.system;
  homebrewPath = if systemType == "aarch64-darwin" then "/opt/homebrew/bin" else if systemType == "x86_64-darwin" then "/usr/local/bin" else throw "Homebrew Unsupported architecture: ${systemType}";
  yabai = "${pkgs.yabai}/bin/yabai";
  sketchybar = "${pkgs.sketchybar}/bin/sketchybar";
  borders = "~/JankyBorders/bin/borders";
  i3-msg = "${homebrewPath}/i3-msg";
  alacritty = "${homebrewPath}/alacritty";
  firefox = "${homebrewPath}/firefox";
  app_menu = "/Applications/unmenu.app/Contents/MacOS/unmenu";
  jq = "${pkgs.jq}/bin/jq";
  inherit (config.colorScheme) palette;

  desktoppr = "/usr/local/bin/desktoppr";
  wallpaper = "/Users/Shared/Wallpaper/wallpaper-nix-colors.png";
in
{
  services.skhd = {
    enable = true;
    package = pkgs.skhd;
    skhdConfig = let
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      mod1 = "alt";
      mod4 = "cmd";
      mod5 = "ctrl";
      modifier = mod1;
      smod = "shift";
    in ''
      # Launch shortcuts
      ${modifier} - return :                ${alacritty} msg create-window || open -na ${alacritty}
      ${mod1} + ${mod5} - space :             open -na ${firefox}
      ${mod1} + ${smod} + ${mod5} - space :   open -na ${firefox} --args -private-window
      ${mod4} + ${mod5} - 0x33 :            sudo reboot # using cmd ctrl backspace
      ${mod4} + ${mod5} + ${smod} - 0x33 :    sudo shutdown -h now # using cmd ctrl backspace
      ${mod4} + ${mod5} - delete :          sudo reboot
      ${mod4} + ${mod5} + ${smod} - delete :  sudo shutdown -h now
      ${modifier} + ${smod} - q :           ${yabai} -m window --close
      ${modifier} - f :                     ${yabai} -m window --toggle zoom-fullscreen 
      ${modifier} + ${smod} - f :             toggle-instant-fullscreen

      # # Move focused window to workspace N and follow focus
      ${modifier} + ${smod} - 1 : ${yabai} -m window --space 1; ${yabai} -m space --focus 1
      ${modifier} + ${smod} - 2 : ${yabai} -m window --space 2; ${yabai} -m space --focus 2
      ${modifier} + ${smod} - 3 : ${yabai} -m window --space 3; ${yabai} -m space --focus 3
      ${modifier} + ${smod} - 4 : ${yabai} -m window --space 4; ${yabai} -m space --focus 4
      ${modifier} + ${smod} - 5 : ${yabai} -m window --space 5; ${yabai} -m space --focus 5
      ${modifier} + ${smod} - 6 : ${yabai} -m window --space 6; ${yabai} -m space --focus 6
      ${modifier} + ${smod} - 7 : ${yabai} -m window --space 7; ${yabai} -m space --focus 7
      ${modifier} + ${smod} - 8 : ${yabai} -m window --space 8; ${yabai} -m space --focus 8
      ${modifier} + ${smod} - 9 : ${yabai} -m window --space 9; ${yabai} -m space --focus 9
      ${modifier} + ${smod} - 0 : ${yabai} -m window --space 10; ${yabai} -m space --focus 10
      
      # move focus to workspace n
      ${modifier} - 1 : ${yabai} -m space --focus 1
      ${modifier} - 2 : ${yabai} -m space --focus 2
      ${modifier} - 3 : ${yabai} -m space --focus 3
      ${modifier} - 4 : ${yabai} -m space --focus 4
      ${modifier} - 5 : ${yabai} -m space --focus 5
      ${modifier} - 6 : ${yabai} -m space --focus 6
      ${modifier} - 7 : ${yabai} -m space --focus 7
      ${modifier} - 8 : ${yabai} -m space --focus 8
      ${modifier} - 9 : ${yabai} -m space --focus 9
      ${modifier} - 0 : ${yabai} -m space --focus 10
      
      ${modifier} + ${smod} - y : ${yabai} -m space --mirror y-axis
      ${modifier} + ${smod} - x : ${yabai} -m space --mirror x-axis

      # send window to next/prev space and follow focus (use alt instead of cmd with arrows to maintian built-in insertion points https://github.com/aspauldingcode/.dotfiles/issues/11#issuecomment-2185355283)
      ${mod4} + ${smod} - ${left} :   ${yabai} -m window --space prev; ${yabai} -m space --focus prev
      ${mod4} + ${smod} - ${down} :   ${yabai} -m window --space next; ${yabai} -m space --focus next
      ${mod4} + ${smod} - ${up} :     ${yabai} -m window --space prev; ${yabai} -m space --focus prev
      ${mod4} + ${smod} - ${right} :  ${yabai} -m window --space next; ${yabai} -m space --focus next
      ${modifier} + ${smod} - left :      ${yabai} -m window --space prev; ${yabai} -m space --focus prev
      ${modifier} + ${smod} - down :      ${yabai} -m window --space next; ${yabai} -m space --focus next
      ${modifier} + ${smod} - up :        ${yabai} -m window --space prev; ${yabai} -m space --focus prev
      ${modifier} + ${smod} - right :     ${yabai} -m window --space next; ${yabai} -m space --focus next

      # focus window in stacked, else in bsp (use cmd instead of alt with arrows to maintian built-in insertion points https://github.com/aspauldingcode/.dotfiles/issues/11#issuecomment-2185355283)
      ${modifier} - ${left} :   if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus west; fi
      ${modifier} - ${down} :   if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus south; fi
      ${modifier} - ${up} :     if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus north; fi
      ${modifier} - ${right} :  if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus east; fi
      ${mod4} - left :      if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus west; fi
      ${mod4} - down :      if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus south; fi
      ${mod4} - up :        if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.next; else ${yabai} -m window --focus north; fi
      ${mod4} - right :     if [ "$(${yabai} -m query --spaces --space | jq -r '.type')" = "stack" ]; then ${yabai} -m window --focus stack.prev; else ${yabai} -m window --focus east; fi
      
      # swap managed window (or move if floating) (use cmd instead of alt with arrows to maintain built-in insertion points https://github.com/aspauldingcode/.dotfiles/issues/11#issuecomment-2185355283)
      ${modifier} + ${smod} - ${left} :   ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
      ${modifier} + ${smod} - ${down} :   ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
      ${modifier} + ${smod} - ${up} :     ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
      ${modifier} + ${smod} - ${right} :  ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0
      ${mod4} + ${smod} - left :      ${yabai} -m window --swap west ||  ${yabai} -m window --move rel:-30:0
      ${mod4} + ${smod} - down :      ${yabai} -m window --swap south || ${yabai} -m window --move rel:0:30
      ${mod4} + ${smod} - up :        ${yabai} -m window --swap north || ${yabai} -m window --move rel:0:-30
      ${mod4} + ${smod} - right :     ${yabai} -m window --swap east ||  ${yabai} -m window --move rel:30:0

      # increase window size
      ${modifier} + ctrl - ${left} :  ${yabai} -m window --resize left:-30:0
      ${modifier} + ctrl - ${down} :  ${yabai} -m window --resize bottom:0:30
      ${modifier} + ctrl - ${up} :    ${yabai} -m window --resize top:0:-30
      ${modifier} + ctrl - ${right} : ${yabai} -m window --resize right:30:0
      ${modifier} + ctrl - left :     ${yabai} -m window --resize left:-30:0
      ${modifier} + ctrl - down :     ${yabai} -m window --resize bottom:0:30
      ${modifier} + ctrl - up :       ${yabai} -m window --resize top:0:-30
      ${modifier} + ctrl - right :    ${yabai} -m window --resize right:30:0

      # decrease window size
      ${modifier} + ${smod} + ctrl - ${left} :  ${yabai} -m window --resize left:30:0
      ${modifier} + ${smod} + ctrl - ${down} :  ${yabai} -m window --resize bottom:0:-30
      ${modifier} + ${smod} + ctrl - ${up} :    ${yabai} -m window --resize top:0:30
      ${modifier} + ${smod} + ctrl - ${right} : ${yabai} -m window --resize right:-30:0
      ${modifier} + ${smod} + ctrl - left :     ${yabai} -m window --resize left:30:0
      ${modifier} + ${smod} + ctrl - down :     ${yabai} -m window --resize bottom:0:-30
      ${modifier} + ${smod} + ctrl - up :       ${yabai} -m window --resize top:0:30
      ${modifier} + ${smod} + ctrl - right :    ${yabai} -m window --resize right:-30:0

      # set insertion point in focused container
      ${modifier} - b : ${yabai} -m window --insert east
      ${modifier} - v : ${yabai} -m window --insert south

      # rotate tree
      ${modifier} - r : ${yabai} -m space --rotate 270
      ${modifier} - t : ${yabai} -m space --rotate 90

      # toggle layout
      ${modifier} - s : ${yabai} -m space --layout stack
      ${modifier} - e : ${yabai} -m space --layout bsp

      # float / unfloat window and center on screen
      ${modifier} + ${smod} - space : toggle-float

      # # toggle sticky(+float), topmost, picture-in-picture
      # ${modifier} - p : ${yabai} -m window --toggle sticky; \
      #           ${yabai} -m window --toggle topmost; \
      #           ${yabai} -m window --toggle pip

      # equalize windows
      # ${modifier} + ${smod} - u : ${yabai} -m space --balance

      # toggle sketchybar
      ${modifier} - m : toggle-sketchybar

      # toggle native macOS menubar, or dock
      #${modifier} + ${smod} - m : current=$(osascript -e 'tell application "System Events" to tell dock preferences to get autohide menu bar'); new_state=$(if [[ "$1" == "on" ]]; then echo false; elif [[ "$1" == "off" ]]; then echo true; else [[ "$current" == "true" ]] && echo false || echo true; fi); osascript -e "tell application \"System Events\" to tell dock preferences to set autohide menu bar to $new_state" && ${yabai} -m config menubar_opacity $(if [[ "$new_state" == "true" ]]; then echo 0.0; else echo 1.0; fi) && echo "Menu bar turned $(if [[ "$new_state" == "true" ]]; then echo OFF; else echo ON; fi)"
      ${modifier} + ${smod} - m : toggle-menubar

      ${modifier} - space : toggle-dock

      # toggle gaps
      ${modifier} - g : toggle-gaps

      # toggle-darkmode FIXME: NOT WORKING!
      ${modifier} - p : toggle-darkmode && toggle-theme && ${sketchybar} --reload 

      # send to scratchpad. (alt + shift + -)
      ${modifier} + ${smod} - 0x1B : highest_label=$(${yabai} -m query --windows | ${jq} '[.[] | select(.scratchpad != 0 and .scratchpad_label != null) | .scratchpad_label | select(test("^_\\d+$"))] | map(sub("^_"; "")) | map(tonumber) | max + 1') && new_label="_$highest_label" && ${yabai} -m window --scratchpad $new_label && ${yabai} -m window --toggle $new_label
          
      # recover latest from scratchpad. (alt + shift + =)
      ${modifier} + ${smod} - 0x18 : \
        highest_label=$(${yabai} -m query --windows | ${jq} '[.[] | select(.scratchpad_label != null) | .scratchpad_label] | sort | last') && \
        ${yabai} -m window --toggle $highest_label && \
        ${yabai} -m window --scratchpad ""
          
      # clear notifications 
      ${modifier} - c : dismiss-notifications

      # reload
      ${modifier} + ${smod} - r : fix-wm

      # Blacklist applications
      .blacklist [
        "terminal"
        "qutebrowser"
        "google chrome"
        "xquartz"
      ]
    '';
  };
}
