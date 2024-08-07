{ osConfig, config, ... }:

# Configure ~/.xinitrc file! changes for x11App and i3 WM, Dmenu...
{
  home.file.xinitrc = {
    target = ".xinitrc";
    text = ''
    '';
      # exec "/opt/local/bin/i3" # start i3 before xquartzwm does.`
      # exec "ssh -Y -p 2222 127.0.0.1 i3" # start i3 before xquartzwm does
      # exec "/opt/local/bin/python3.11 ~/.dotfiles/i3ipc-python-master/autotiling.py"
      # exec "xhost + ${osConfig.networking.hostName}" # https://gist.github.com/cschiewek/246a244ba23da8b9f0e7b11a68bf3285#to-forward-x11-from-inside-a-docker-container-to-a-host-running-macos
      # exec "export HOSTNAME=${osConfig.networking.hostName}"
  };

  home.file.Xresources = {
    target = ".Xresources";
    text =
      let
        inherit (config.colorScheme) colors;
      in
      ''
        ! Use a truetype font and size.
        xterm*faceName: JetBrains Mono
        xterm*faceSize: 12

        ! Set the background color
        xterm*background: #${colors.base00}

        ! Set the foreground color
        xterm*foreground: #${colors.base05}

        ! Set the cursor color
        xterm*cursorColor: #${colors.base05}

        ! Set the bold color
        xterm*colorBD: #${colors.base0A}

        ! Set the underline color
        xterm*colorUL: #${colors.base0E}

        ! Set the highlight color
        xterm*highlightColor: #${colors.base0B}

        ! Define all base16 colors for xterm
        xterm*color0:  #${colors.base00}
        xterm*color1:  #${colors.base08}
        xterm*color2:  #${colors.base0B}
        xterm*color3:  #${colors.base0A}
        xterm*color4:  #${colors.base0D}
        xterm*color5:  #${colors.base0E}
        xterm*color6:  #${colors.base0C}
        xterm*color7:  #${colors.base05}
        xterm*color8:  #${colors.base03}
        xterm*color9:  #${colors.base08}
        xterm*color10: #${colors.base0B}
        xterm*color11: #${colors.base0A}
        xterm*color12: #${colors.base0D}
        xterm*color13: #${colors.base0E}
        xterm*color14: #${colors.base0C}
        xterm*color15: #${colors.base07}
        xterm*color16: #${colors.base09}
        xterm*color17: #${colors.base0F}
        xterm*color18: #${colors.base01}
        xterm*color19: #${colors.base02}
        xterm*color20: #${colors.base04}
        xterm*color21: #${colors.base06}

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
        URxvt*color0:  #${colors.base00}
        URxvt*color1:  #${colors.base08}
        URxvt*color2:  #${colors.base0B}
        URxvt*color3:  #${colors.base0A}
        URxvt*color4:  #${colors.base0D}
        URxvt*color5:  #${colors.base0E}
        URxvt*color6:  #${colors.base0C}
        URxvt*color7:  #${colors.base05}
        URxvt*color8:  #${colors.base03}
        URxvt*color9:  #${colors.base08}
        URxvt*color10: #${colors.base0B}
        URxvt*color11: #${colors.base0A}
        URxvt*color12: #${colors.base0D}
        URxvt*color13: #${colors.base0E}
        URxvt*color14: #${colors.base0C}
        URxvt*color15: #${colors.base07}
        URxvt*color16: #${colors.base09}
        URxvt*color17: #${colors.base0F}
        URxvt*color18: #${colors.base01}
        URxvt*color19: #${colors.base02}
        URxvt*color20: #${colors.base04}
        URxvt*color21: #${colors.base06}
      '';
  };
}
