{ config, pkgs, lib, ... }:

let
  swap = from: to: {
    type = "basic";
    from = {
      key_code = from;
      modifiers = { optional = [ "any" ]; };
    };
    to = [{ key_code = to; }];
    conditions = [{
      type = "frontmost_application_if";
      bundle_identifiers = [
        "^com\\.apple\\.Terminal$"
        "^com\\.utmapp\\.utm$"
        "^org\\.alacritty$"
      ];
      file_paths = [ "~/.nix-profile/bin/alacritty" ];
    }];
  };
in {
  home.file.karabiner = {
    target = ".config/karabiner/assets/complex_modifications/windows-shortcuts.json";
    text = builtins.toJSON {
      title = "Windows Shortcuts";
      rules = [{
        description = "Windows Keyboard Shortcuts for mac.";
        manipulators = [
          (swap "left_command" "left_control")
          (swap "left_control" "left_command")
        ];
      }];
    };
  };
}
