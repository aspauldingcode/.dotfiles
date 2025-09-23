{
  config,
  lib,
  ...
}:
# Config options for setting wallpaper on macOS.
# The wallpaper command is unavailable unless we source the wallpaper
# workflow.
# The workflow file is in this folder, ./setDesktopPicture.workflow
# the shell script contents that creates the alias of wallper command is:
# wallpaper () { automator -i "${1}" ~/Documents/setDesktopPicture.workflow
#Then, I want to run wallpaper FILENAME.EXT using nix to set the wallpaper.
# Config options for setting wallpaper on macOS.
{
  options = {
    wallpaper.filePath = lib.mkOption {
      type = lib.types.str;
      description = "The file path to the wallpaper image.";
    };
  };

  config = {
    # Define a shell script to set the wallpaper on macOS
    environment.etc."set-wallpaper.sh".text = ''
      #!/bin/sh
      wallpaper "${config.wallpaper.filePath}"
    '';

    # Optionally, you can create a launch agent to run the script at login
    # environment.etc."local.launchd.set-wallpaper.plist".text = ''
    #   <?xml version="1.0" encoding="UTF-8"?>
    #   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    #   <plist version="1.0">
    #   <dict>
    #     <key>Label</key>
    #     <string>com.example.set-wallpaper</string>
    #     <key>ProgramArguments</key>
    #     <array>
    #       <string>/etc/set-wallpaper.sh</string>
    #     </array>
    #     <key>RunAtLoad</key>
    #     <true/>
    #   </dict>
    #   </plist>
    # '';
  };
}
