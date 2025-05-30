{ osConfig, config, ... }:

# Configure ~/.xinitrc file! changes for x11App and i3 WM, Dmenu...
{
  home.file.xinitrc = {
    target = ".xinitrc";
    text = ''
      exec "xterm"
    '';
    # exec "orb -m nixos -u alex"
    # exec "◊"
    # exec "orb -m nixos -u alex"
    # ssh -Y -p 2222 alex@198.19.249.50
    # exec "/opt/local/bin/i3" # start i3 before xquartzwm does.`
    # exec "ssh -Y -p 2222 127.0.0.1 i3" # start i3 before xquartzwm does
    # exec "/opt/local/bin/python3.11 ~/.dotfiles/i3ipc-python-master/autotiling.py"
    # exec "xhost + ${osConfig.networking.hostName}" # https://gist.github.com/cschiewek/246a244ba23da8b9f0e7b11a68bf3285#to-forward-x11-from-inside-a-docker-container-to-a-host-running-macos
    # exec "export HOSTNAME=${osConfig.networking.hostName}"
  };

  home.file.Xresources = {
    enable = false; # FIXME: for now
    target = ".Xresources";
    text =
      let
        inherit (config.colorScheme) palette;
      in
      ''
        ! Use a truetype font and size.
        xterm*faceName: JetBrains Mono
        xterm*faceSize: 12

        ! Set the background color
        xterm*background: #${palette.base00}

        ! Set the foreground color
        xterm*foreground: #${palette.base05}

        ! Set the cursor color
        xterm*cursorColor: #${palette.base05}

        ! Set the bold color
        xterm*colorBD: #${palette.base0A}

        ! Set the underline color
        xterm*colorUL: #${palette.base0E}

        ! Set the highlight color
        xterm*highlightColor: #${palette.base0B}

        ! Define all base16 colors for xterm
        xterm*color0:  #${palette.base00}
        xterm*color1:  #${palette.base08}
        xterm*color2:  #${palette.base0B}
        xterm*color3:  #${palette.base0A}
        xterm*color4:  #${palette.base0D}
        xterm*color5:  #${palette.base0E}
        xterm*color6:  #${palette.base0C}
        xterm*color7:  #${palette.base05}
        xterm*color8:  #${palette.base03}
        xterm*color9:  #${palette.base08}
        xterm*color10: #${palette.base0B}
        xterm*color11: #${palette.base0A}
        xterm*color12: #${palette.base0D}
        xterm*color13: #${palette.base0E}
        xterm*color14: #${palette.base0C}
        xterm*color15: #${palette.base07}
        xterm*color16: #${palette.base09}
        xterm*color17: #${palette.base0F}
        xterm*color18: #${palette.base01}
        xterm*color19: #${palette.base02}
        xterm*color20: #${palette.base04}
        xterm*color21: #${palette.base06}

        ! Set the scrollbar to appear on the right side
        xterm*scrollBar: true
        xterm*scrollBar_right: true

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

        ! Define all base16 colors for URxvt
        URxvt*color0:  #${palette.base00}
        URxvt*color1:  #${palette.base08}
        URxvt*color2:  #${palette.base0B}
        URxvt*color3:  #${palette.base0A}
        URxvt*color4:  #${palette.base0D}
        URxvt*color5:  #${palette.base0E}
        URxvt*color6:  #${palette.base0C}
        URxvt*color7:  #${palette.base05}
        URxvt*color8:  #${palette.base03}
        URxvt*color9:  #${palette.base08}
        URxvt*color10: #${palette.base0B}
        URxvt*color11: #${palette.base0A}
        URxvt*color12: #${palette.base0D}
        URxvt*color13: #${palette.base0E}
        URxvt*color14: #${palette.base0C}
        URxvt*color15: #${palette.base07}
        URxvt*color16: #${palette.base09}
        URxvt*color17: #${palette.base0F}
        URxvt*color18: #${palette.base01}
        URxvt*color19: #${palette.base02}
        URxvt*color20: #${palette.base04}
        URxvt*color21: #${palette.base06}
      '';
  };
}
