_:
#create a theme for xcode!?
{
  # FIXME: convert to actually use nix-colors!
  # FIXME 2: send to the right folder!
  home.file."Applications/Xcode.app/Contents/SharedFrameworks/DVTUserInterfaceKit.framework/Versions/A/Resources/FontAndColorThemes/Default (Dark).xccolortheme".source =
    ./base16.xccolortheme;
  home.file."Applications/Xcode.app/Contents/SharedFrameworks/DVTUserInterfaceKit.framework/Versions/A/Resources/FontAndColorThemes/Default (Light).xccolortheme".source =
    ./base16.xccolortheme;
}
