{ ... }:

# Configure ~/.xinitrc file! changes for x11App and i3 WM, Dmenu...
{
  home.file.xinitrc = {
    target = ".xinitrc";
    text = ''
    exec /opt/local/bin/i3 #start i3 before xquartzwm does.
    '';
  };

  home.file.Xresources = {
    target = ".Xresources";
    text = ''
    ! Use a truetype font and size.
    xterm*faceName: JetBrains Mono
    xterm*faceSize: 12

    ! Set the background color to black
    xterm*background: black

    ! Set the foreground color to white
    xterm*foreground: white

    ! Set the cursor color to green
    xterm*cursorColor: green

    ! Set the scrollbar to appear on the right side
    xterm*scrollBar: true
    xterm*scrollBar_right: true

    ! Set the geometry of the terminal window
    xterm*geometry: 80x24

    ! Enable UTF-8 support
    xterm*utf8: true
    '';
  };
}
