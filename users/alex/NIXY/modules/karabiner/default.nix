{ ... }:
# nix-configured karabiner config allows for commenting!
# Karabiner is a powerful tool for customizing keyboard shortcuts and behaviors. I treasure it.
{
  home.file.karabiner = {
    force = true;
    target = ".config/karabiner/karabiner.json";
    text =
      builtins.toJSON # json

        {
          global = {
            "ask_for_confirmation_before_quitting" = false;
            "check_for_updates_on_startup" = true;
            "show_in_menu_bar" = true;
            "show_profile_name_in_menu_bar" = false;
            "unsafe_ui" = false;
          };
          profiles = [
            {
              "complex_modifications" = {
                parameters = {
                  "basic.simultaneous_threshold_milliseconds" = 50;
                  "basic.to_delayed_action_delay_milliseconds" = 500;
                  "basic.to_if_alone_timeout_milliseconds" = 1000;
                  "basic.to_if_held_down_threshold_milliseconds" = 500;
                  "mouse_motion_to_scroll.speed" = 100;
                };
                rules = [
                  {
                    description = "System controls and application launchers";
                    manipulators = [
                      # Launch Alacritty
                      {
                        type = "basic";
                        from = {
                          key_code = "return_or_enter";
                          modifiers = {
                            mandatory = [ "left_alt" ];
                          };
                        };
                        to = [
                          {
                            shell_command = "open -a Alacritty";
                          }
                        ];
                      }
                      # Launch Firefox
                      {
                        type = "basic";
                        from = {
                          key_code = "spacebar";
                          modifiers = {
                            mandatory = [
                              "left_alt"
                              "left_control"
                            ];
                          };
                        };
                        to = [
                          {
                            shell_command = "open -na Firefox";
                          }
                        ];
                      }
                      # Launch Firefox Private Window
                      {
                        type = "basic";
                        from = {
                          key_code = "spacebar";
                          modifiers = {
                            mandatory = [
                              "left_alt"
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            shell_command = "open -na Firefox --args -private-window";
                          }
                        ];
                      }
                      # System reboot
                      {
                        type = "basic";
                        from = {
                          key_code = "delete_or_backspace";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_control"
                            ];
                          };
                        };
                        to = [
                          {
                            shell_command = "sudo reboot";
                          }
                        ];
                      }
                      # System shutdown
                      {
                        type = "basic";
                        from = {
                          key_code = "delete_or_backspace";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            shell_command = "sudo shutdown -h now";
                          }
                        ];
                      }
                      # Toggle sketchybar
                      {
                        type = "basic";
                        from = {
                          key_code = "m";
                          modifiers = {
                            mandatory = [ "left_alt" ];
                          };
                        };
                        to = [
                          {
                            shell_command = "sketchybar --toggle";
                          }
                        ];
                      }
                      # Toggle menubar
                      {
                        type = "basic";
                        from = {
                          key_code = "m";
                          modifiers = {
                            mandatory = [
                              "left_alt"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            shell_command = "defaults write -g _HIHideMenuBar -bool true; killall SystemUIServer";
                          }
                        ];
                      }
                      # Toggle dock
                      {
                        type = "basic";
                        from = {
                          key_code = "spacebar";
                          modifiers = {
                            mandatory = [ "left_alt" ];
                          };
                        };
                        to = [
                          {
                            shell_command = "defaults write com.apple.dock autohide -bool true; killall Dock";
                          }
                        ];
                      }
                      # Toggle dark mode
                      {
                        type = "basic";
                        from = {
                          key_code = "p";
                          modifiers = {
                            mandatory = [ "left_alt" ];
                          };
                        };
                        to = [
                          {
                            shell_command = "osascript -e 'tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode'";
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Swap Control+C/X, Command+C/X, Control+Shift+C/X, and Command+Shift+C/X in Tiger VNC Viewer";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers = {
                            mandatory = [ "left_control" ];
                          };
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [ "left_command" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [ "left_control" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers = {
                            mandatory = [
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers = {
                            mandatory = [ "left_control" ];
                          };
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [ "left_command" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [ "left_control" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers = {
                            mandatory = [
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "com.tigervnc.tigervnc" ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Lock screen with Alt+L";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "l";
                          modifiers = {
                            mandatory = [ "left_alt" ];
                          };
                        };
                        to = [
                          {
                            key_code = "q";
                            modifiers = [
                              "left_control"
                              "left_command"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Swap Control+Shift+3/4/5 with Command+Shift+3/4/5";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "3";
                          modifiers = {
                            mandatory = [
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "3";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "3";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "3";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "4";
                          modifiers = {
                            mandatory = [
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "4";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "4";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "4";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "5";
                          modifiers = {
                            mandatory = [
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "5";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "5";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "5";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Swap Command+Tab and Control+Tab";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          "key_code" = "tab";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            "key_code" = "tab";
                            modifiers = [ "left_control" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          "key_code" = "tab";
                          modifiers = {
                            mandatory = [ "left_control" ];
                          };
                        };
                        to = [
                          {
                            "key_code" = "tab";
                            modifiers = [ "left_command" ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Swap Command+Shift+Tab and Control+Shift+Tab";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          "key_code" = "tab";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            "key_code" = "tab";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          "key_code" = "tab";
                          modifiers = {
                            mandatory = [
                              "left_control"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            "key_code" = "tab";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Alt+Q with Command+W to close tabs";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          "key_code" = "q";
                          modifiers = {
                            mandatory = [ "left_option" ];
                          };
                        };
                        to = [
                          {
                            "key_code" = "w";
                            modifiers = [ "left_command" ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Command+H with Command+Y in web browsers";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          "key_code" = "h";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            "key_code" = "y";
                            modifiers = [ "left_command" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            "bundle_identifiers" = [
                              "^com.brave.Browser$"
                              "^org.mozilla.firefox$"
                              "^com.google.Chrome$"
                              "^org.chromium.Chromium$"
                              "^com.microsoft.Edge$"
                              "^com.operasoftware.Opera$"
                              "^com.apple.Safari$"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Command+J with Command+Option+L in Chromium-based browsers";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          "key_code" = "j";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            "key_code" = "l";
                            modifiers = [
                              "left_command"
                              "left_option"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            "bundle_identifiers" = [
                              "^com.brave.Browser$"
                              "^com.google.Chrome$"
                              "^org.chromium.Chromium$"
                              "^com.microsoft.Edge$"
                              "^com.operasoftware.Opera$"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Alt+Shift+F with Command+Control+F in Alacritty for fullscreen";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "f";
                          modifiers = {
                            mandatory = [
                              "left_option"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "f";
                            modifiers = [
                              "left_command"
                              "left_control"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Swap Command+C/X and Control+C/X in Alacritty";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers.mandatory = [ "left_command" ];
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [ "left_control" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers.mandatory = [ "left_control" ];
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [ "left_command" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers.mandatory = [ "left_command" ];
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [ "left_control" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers.mandatory = [ "left_control" ];
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [ "left_command" ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers.mandatory = [
                            "left_command"
                            "left_shift"
                          ];
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "c";
                          modifiers.mandatory = [
                            "left_control"
                            "left_shift"
                          ];
                        };
                        to = [
                          {
                            key_code = "c";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers.mandatory = [
                            "left_command"
                            "left_shift"
                          ];
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [
                              "left_control"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "x";
                          modifiers.mandatory = [
                            "left_control"
                            "left_shift"
                          ];
                        };
                        to = [
                          {
                            key_code = "x";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            bundle_identifiers = [ "^org\\.alacritty$" ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Command + Arrow Keys/Backspace with Option + Arrow Keys/Backspace globally";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "left_arrow";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "left_arrow";
                            modifiers = [ "left_option" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "right_arrow";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "right_arrow";
                            modifiers = [ "left_option" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "up_arrow";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "up_arrow";
                            modifiers = [ "left_option" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "down_arrow";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "down_arrow";
                            modifiers = [ "left_option" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "delete_or_backspace";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "delete_or_backspace";
                            modifiers = [ "left_option" ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Command + Shift + Arrow Keys/Backspace with Option + Shift + Arrow Keys/Backspace globally";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "left_arrow";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "left_arrow";
                            modifiers = [
                              "left_option"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "right_arrow";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "right_arrow";
                            modifiers = [
                              "left_option"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "up_arrow";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "up_arrow";
                            modifiers = [
                              "left_option"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "down_arrow";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "down_arrow";
                            modifiers = [
                              "left_option"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "delete_or_backspace";
                          modifiers = {
                            mandatory = [
                              "left_command"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "delete_or_backspace";
                            modifiers = [
                              "left_option"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Option + Arrow Keys with Command + Arrow Keys globally";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "left_arrow";
                          modifiers = {
                            mandatory = [ "left_option" ];
                          };
                        };
                        to = [
                          {
                            key_code = "left_arrow";
                            modifiers = [ "left_command" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "right_arrow";
                          modifiers = {
                            mandatory = [ "left_option" ];
                          };
                        };
                        to = [
                          {
                            key_code = "right_arrow";
                            modifiers = [ "left_command" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "up_arrow";
                          modifiers = {
                            mandatory = [ "left_option" ];
                          };
                        };
                        to = [
                          {
                            key_code = "up_arrow";
                            modifiers = [ "left_command" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "down_arrow";
                          modifiers = {
                            mandatory = [ "left_option" ];
                          };
                        };
                        to = [
                          {
                            key_code = "down_arrow";
                            modifiers = [ "left_command" ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Replace Option + Shift + Arrow Keys with Command + Shift + Arrow Keys globally";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "left_arrow";
                          modifiers = {
                            mandatory = [
                              "left_option"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "left_arrow";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "right_arrow";
                          modifiers = {
                            mandatory = [
                              "left_option"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "right_arrow";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "up_arrow";
                          modifiers = {
                            mandatory = [
                              "left_option"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "up_arrow";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "down_arrow";
                          modifiers = {
                            mandatory = [
                              "left_option"
                              "left_shift"
                            ];
                          };
                        };
                        to = [
                          {
                            key_code = "down_arrow";
                            modifiers = [
                              "left_command"
                              "left_shift"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Swap Command and Control in Screen Sharing and X11";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "left_command";
                        };
                        to = [
                          {
                            key_code = "left_control";
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            "bundle_identifiers" = [
                              "^com\\.apple\\.ScreenSharing$"
                              "^org\\.xquartz\\.X11$"
                            ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "left_control";
                        };
                        to = [
                          {
                            key_code = "left_command";
                          }
                        ];
                        conditions = [
                          {
                            type = "frontmost_application_if";
                            "bundle_identifiers" = [
                              "^com\\.apple\\.ScreenSharing$"
                              "^org\\.xquartz\\.X11$"
                            ];
                          }
                        ];
                      }
                    ];
                  }
                  {
                    description = "Disable Spotlight by swapping Command+Space with Control+Space";
                    manipulators = [
                      {
                        type = "basic";
                        from = {
                          key_code = "spacebar";
                          modifiers = {
                            mandatory = [ "left_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "spacebar";
                            modifiers = [ "left_control" ];
                          }
                        ];
                      }
                      {
                        type = "basic";
                        from = {
                          key_code = "spacebar";
                          modifiers = {
                            mandatory = [ "right_command" ];
                          };
                        };
                        to = [
                          {
                            key_code = "spacebar";
                            modifiers = [ "right_control" ];
                          }
                        ];
                      }
                    ];
                  }
                ];
              };
              devices = [
                {
                  "disable_built_in_keyboard_if_exists" = false;
                  "fn_function_keys" = [ ];
                  "game_pad_swap_sticks" = false;
                  identifiers = {
                    "is_game_pad" = false;
                    "is_keyboard" = true;
                    "is_pointing_device" = false;
                    "product_id" = 641;
                    "vendor_id" = 1452;
                  };
                  ignore = false;
                  "manipulate_caps_lock_led" = true;
                  "mouse_flip_horizontal_wheel" = false;
                  "mouse_flip_vertical_wheel" = false;
                  "mouse_flip_x" = false;
                  "mouse_flip_y" = false;
                  "mouse_swap_wheels" = false;
                  "mouse_swap_xy" = false;
                  "simple_modifications" = [
                    # Fn key remapping (commented out to keep Fn as Fn)
                    # {
                    #   from = {
                    #     "apple_vendor_top_case_key_code" = "keyboard_fn";
                    #   };
                    #   to = [ { "key_code" = "left_command"; } ];
                    # }
                    # {
                    #   from = {
                    #     "key_code" = "right_command";
                    #   };
                    #   to = [ { "apple_vendor_top_case_key_code" = "keyboard_fn"; } ];
                    # }
                  ];
                  "treat_as_built_in_keyboard" = false;
                }
                {
                  "disable_built_in_keyboard_if_exists" = false;
                  "fn_function_keys" = [ ];
                  "game_pad_swap_sticks" = false;
                  identifiers = {
                    "is_game_pad" = false;
                    "is_keyboard" = false;
                    "is_pointing_device" = true;
                    "product_id" = 641;
                    "vendor_id" = 1452;
                  };
                  ignore = true;
                  "manipulate_caps_lock_led" = false;
                  "mouse_flip_horizontal_wheel" = false;
                  "mouse_flip_vertical_wheel" = false;
                  "mouse_flip_x" = false;
                  "mouse_flip_y" = false;
                  "mouse_swap_wheels" = false;
                  "mouse_swap_xy" = false;
                  "simple_modifications" = [ ];
                  "treat_as_built_in_keyboard" = false;
                }
                {
                  "disable_built_in_keyboard_if_exists" = false;
                  "fn_function_keys" = [ ];
                  "game_pad_swap_sticks" = false;
                  identifiers = {
                    "is_game_pad" = false;
                    "is_keyboard" = true;
                    "is_pointing_device" = false;
                    "product_id" = 38390;
                    "vendor_id" = 6700;
                  };
                  ignore = false;
                  "manipulate_caps_lock_led" = true;
                  "mouse_flip_horizontal_wheel" = false;
                  "mouse_flip_vertical_wheel" = false;
                  "mouse_flip_x" = false;
                  "mouse_flip_y" = false;
                  "mouse_swap_wheels" = false;
                  "mouse_swap_xy" = false;
                  "simple_modifications" = [
                    {
                      from = {
                        "key_code" = "left_option";
                      };
                      to = [ { "key_code" = "left_control"; } ];
                    }
                    {
                      from = {
                        "key_code" = "left_command";
                      };
                      to = [ { "key_code" = "left_option"; } ];
                    }
                  ];
                  "treat_as_built_in_keyboard" = false;
                }
              ];
              "fn_function_keys" = [
                {
                  from = {
                    "key_code" = "f1";
                  };
                  to = [ { "consumer_key_code" = "display_brightness_decrement"; } ];
                }
                {
                  from = {
                    "key_code" = "f2";
                  };
                  to = [ { "consumer_key_code" = "display_brightness_increment"; } ];
                }
                {
                  from = {
                    "key_code" = "f3";
                  };
                  to = [ { "apple_vendor_keyboard_key_code" = "mission_control"; } ];
                }
                {
                  from = {
                    "key_code" = "f4";
                  };
                  to = [ { "apple_vendor_keyboard_key_code" = "spotlight"; } ];
                }
                {
                  from = {
                    "key_code" = "f5";
                  };
                  to = [ { "consumer_key_code" = "dictation"; } ];
                }
                {
                  from = {
                    "key_code" = "f6";
                  };
                  to = [ { "key_code" = "f6"; } ];
                }
                {
                  from = {
                    "key_code" = "f7";
                  };
                  to = [ { "consumer_key_code" = "rewind"; } ];
                }
                {
                  from = {
                    "key_code" = "f8";
                  };
                  to = [ { "consumer_key_code" = "play_or_pause"; } ];
                }
                {
                  from = {
                    "key_code" = "f9";
                  };
                  to = [ { "consumer_key_code" = "fast_forward"; } ];
                }
                {
                  from = {
                    "key_code" = "f10";
                  };
                  to = [ { "consumer_key_code" = "mute"; } ];
                }
                {
                  from = {
                    "key_code" = "f11";
                  };
                  to = [ { "consumer_key_code" = "volume_decrement"; } ];
                }
                {
                  from = {
                    "key_code" = "f12";
                  };
                  to = [ { "consumer_key_code" = "volume_increment"; } ];
                }
              ];
              name = "Default profile";
              parameters = {
                "delay_milliseconds_before_open_device" = 1000;
              };
              selected = true;
              "simple_modifications" = [
                {
                  from = {
                    "key_code" = "left_control";
                  };
                  to = [ { "key_code" = "left_command"; } ];
                }
                {
                  from = {
                    "key_code" = "left_command";
                  };
                  to = [ { "key_code" = "left_control"; } ];
                }
              ];
              "virtual_hid_keyboard" = {
                "country_code" = 0;
                "keyboard_type" = "ansi";
                "keyboard_type_v2" = "ansi";
                "indicate_sticky_modifier_keys_state" = true;
                "mouse_key_xy_scale" = 100;
              };
            }
          ];
        };
  };
}
