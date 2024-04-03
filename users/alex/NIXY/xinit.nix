{ config, ... }:

# Configure ~/.xinitrc file! changes for x11App and i3 WM, Dmenu...
{
  home.file.xinitrc = {
    target = ".xinitrc";
    text = ''
    exec /opt/local/bin/i3 #start i3 before xquartzwm does.
    exec sleep 3
    exec /usr/X11R6/bin/xrdb -merge ~/.Xresources #merge Xresources settings to x11
    '';
  };

  home.file.Xresources = {
    target = ".Xresources";
    text = let inherit (config.colorScheme) colors; in /* bash */ ''
    ! Use a truetype font and size.
    xterm*faceName: JetBrains Mono
    xterm*faceSize: 12

    ! Set the background color to black
    xterm*background: #${colors.base00}

    ! Set the foreground color to white
    xterm*foreground: #${colors.base05}

    ! Set the cursor color to green
    ! xterm*cursorColor: green

    ! Set the scrollbar to appear on the right side
    ! xterm*scrollBar: true
    ! xterm*scrollBar_right: true

    ! Set the geometry of the terminal window
    xterm*geometry: 80x24

    ! Enable UTF-8 support
    xterm*utf8: true

    ! Use Standard Ctrl+shift+c and Ctrl+Shift+v
    xterm*VT100.Translations: #override \
	Shift <KeyPress> Insert: insert-selection(CLIPBOARD) \n\
	Ctrl Shift <Key>V:	 insert-selection(CLIPBOARD) \n\
	Ctrl Shift <Key>C:	 copy-selection(CLIPBOARD) \n\
	Ctrl <Btn1Up>: exec-formatted("xdg-open '%t'", PRIMARY)

    ! scroll back to the bottom on keypress
    URxvt*scrollTtyKeypress: true

    ! Set Font for URXVT terminal
    URxvt.font: xft:JetBrains Mono:size=12
    '';
  };
}
