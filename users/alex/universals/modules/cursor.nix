{ config, pkgs, ... }:

let
  vscodeSettings = {
    security.workspace.trust.untrustedFiles = "open";
    editor.semanticTokenColorCustomizations = {
      enabled = true;
      rules = {
        "*.declaration" = {
          foreground = "#${config.colorScheme.palette.base0A}";
          fontStyle = "bold";
        };
        "*.readonly" = {
          foreground = "#${config.colorScheme.palette.base08}";
          fontStyle = "italic";
        };
      };
    };
    editor.tokenColorCustomizations = {
      textMateRules = [
        {
          scope = [
            "comment"
            "punctuation.definition.comment"
            "string.comment"
          ];
          settings = {
            foreground = "#${config.colorScheme.palette.base03}"; # Adjusted for comments
          };
        }
        {
          scope = "constant.numeric";
          settings = {
            foreground = "#${config.colorScheme.palette.base09}"; # Correct for integers, constants
          };
        }
        {
          scope = "entity.name.function";
          settings = {
            foreground = "#${config.colorScheme.palette.base0D}"; # Correct for functions, methods
          };
        }
        {
          scope = "keyword";
          settings = {
            foreground = "#${config.colorScheme.palette.base0E}"; # Correct for keywords
          };
        }
        {
          scope = "string.quoted.double";
          settings = {
            foreground = "#${config.colorScheme.palette.base0B}"; # Correct for strings
          };
        }
        {
          scope = "variable";
          settings = {
            foreground = "#${config.colorScheme.palette.base08}"; # Adjusted for variables
          };
        }
        {
          scope = "variable.parameter";
          settings = {
            foreground = "#${config.colorScheme.palette.base0A}"; # Correct for classes, markup bold
          };
        }
        {
          scope = "entity.name.type.class";
          settings = {
            foreground = "#${config.colorScheme.palette.base0C}"; # Added for classes
          };
        }
        {
          scope = "markup.inserted";
          settings = {
            foreground = "#${config.colorScheme.palette.base0F}"; # Added for inserted elements in version control
          };
        }
        {
          scope = "entity.name.tag";
          settings = {
            foreground = "#${config.colorScheme.palette.base0F}"; # Added for HTML/XML tags
          };
        }
        {
          scope = "storage";
          settings = {
            foreground = "#${config.colorScheme.palette.base0E}"; # Added for storage types and modifiers in languages
          };
        }
        {
          scope = "support.function";
          settings = {
            foreground = "#${config.colorScheme.palette.base0D}"; # Added for support functions
          };
        }
      ];
    };
    window.autoDetectColorScheme = true;
    "window.menuBarVisibility" = "classic";
    "workbench.colorTheme" = "Visual Studio Light";
    "workbench.preferredDarkColorTheme" = "Visual Studio Dark";
    "workbench.preferredHighContrastColorTheme" = "Default High Contrast";
    "workbench.preferredHighContrastLightColorTheme" = "Default High Contrast Light";
    "workbench.preferredLightColorTheme" = "Visual Studio Light";
    "editor.formatOnSave" = true;
    "git.autofetch" = true;
    "explorer.confirmDragAndDrop" = false;
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    workbench.colorCustomizations = {
      "titleBar.activeBackground" = "#${config.colorScheme.palette.base01}";
      "titleBar.inactiveBackground" = "#${config.colorScheme.palette.base02}";
      "activityBar.background" = "#${config.colorScheme.palette.base02}";
      "activityBar.foreground" = "#${config.colorScheme.palette.base0E}";
      "sideBar.background" = "#${config.colorScheme.palette.base01}";
      "sideBar.foreground" = "#${config.colorScheme.palette.base05}";
      "statusBar.background" = "#${config.colorScheme.palette.base00}";
      "statusBar.foreground" = "#${config.colorScheme.palette.base05}";
      "statusBar.noFolderBackground" = "#${config.colorScheme.palette.base01}";
      "statusBar.noFolderForeground" = "#${config.colorScheme.palette.base02}";
      "editor.background" = "#${config.colorScheme.palette.base00}";
      "editor.foreground" = "#${config.colorScheme.palette.base07}";
      "tab.activeBackground" = "#${config.colorScheme.palette.base01}";
      "tab.inactiveBackground" = "#${config.colorScheme.palette.base02}";
      "tab.activeForeground" = "#${config.colorScheme.palette.base07}";
      "tab.inactiveForeground" = "#${config.colorScheme.palette.base05}";
      "panel.background" = "#${config.colorScheme.palette.base01}";
      "panel.border" = "#${config.colorScheme.palette.base03}";
      "panelTitle.activeForeground" = "#${config.colorScheme.palette.base07}";
      "panelTitle.inactiveForeground" = "#${config.colorScheme.palette.base05}";
      "panelTitle.activeBorder" = "#${config.colorScheme.palette.base0D}";
      "badge.background" = "#${config.colorScheme.palette.base0E}";
      "badge.foreground" = "#${config.colorScheme.palette.base00}";
      "terminal.background" = "#${config.colorScheme.palette.base00}";
      "terminal.foreground" = "#${config.colorScheme.palette.base07}";
      "terminalCursor.background" = "#${config.colorScheme.palette.base01}";
      "terminalCursor.foreground" = "#${config.colorScheme.palette.base07}";
    };
  };
  cursorSettings = builtins.toJSON {
    security.workspace.trust.untrustedFiles = "open";
    editor.semanticTokenColorCustomizations = {
      enabled = true;
      rules = {
        "*.declaration" = {
          foreground = "#${config.colorScheme.palette.base0A}";
          fontStyle = "bold";
        };
        "*.readonly" = {
          foreground = "#${config.colorScheme.palette.base08}";
          fontStyle = "italic";
        };
      };
    };
    editor.tokenColorCustomizations = {
      textMateRules = [
        {
          scope = [
            "comment"
            "punctuation.definition.comment"
            "string.comment"
          ];
          settings = {
            foreground = "#${config.colorScheme.palette.base03}"; # Adjusted for comments
          };
        }
        {
          scope = "constant.numeric";
          settings = {
            foreground = "#${config.colorScheme.palette.base09}"; # Correct for integers, constants
          };
        }
        {
          scope = "entity.name.function";
          settings = {
            foreground = "#${config.colorScheme.palette.base0D}"; # Correct for functions, methods
          };
        }
        {
          scope = "keyword";
          settings = {
            foreground = "#${config.colorScheme.palette.base0E}"; # Correct for keywords
          };
        }
        {
          scope = "string.quoted.double";
          settings = {
            foreground = "#${config.colorScheme.palette.base0B}"; # Correct for strings
          };
        }
        {
          scope = "variable";
          settings = {
            foreground = "#${config.colorScheme.palette.base08}"; # Adjusted for variables
          };
        }
        {
          scope = "variable.parameter";
          settings = {
            foreground = "#${config.colorScheme.palette.base0A}"; # Correct for classes, markup bold
          };
        }
        {
          scope = "entity.name.type.class";
          settings = {
            foreground = "#${config.colorScheme.palette.base0C}"; # Added for classes
          };
        }
        {
          scope = "markup.inserted";
          settings = {
            foreground = "#${config.colorScheme.palette.base0F}"; # Added for inserted elements in version control
          };
        }
        {
          scope = "entity.name.tag";
          settings = {
            foreground = "#${config.colorScheme.palette.base0F}"; # Added for HTML/XML tags
          };
        }
        {
          scope = "storage";
          settings = {
            foreground = "#${config.colorScheme.palette.base0E}"; # Added for storage types and modifiers in languages
          };
        }
        {
          scope = "support.function";
          settings = {
            foreground = "#${config.colorScheme.palette.base0D}"; # Added for support functions
          };
        }
      ];
    };
    window.autoDetectColorScheme = true;
    "window.menuBarVisibility" = "classic";
    "workbench.colorTheme" = "Visual Studio Light";
    "workbench.preferredDarkColorTheme" = "Visual Studio Dark";
    "workbench.preferredHighContrastColorTheme" = "Default High Contrast";
    "workbench.preferredHighContrastLightColorTheme" = "Default High Contrast Light";
    "workbench.preferredLightColorTheme" = "Visual Studio Light";
    "editor.formatOnSave" = true;
    "git.autofetch" = true;
    "explorer.confirmDragAndDrop" = false;
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    "[javascript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode"; # could set to something else
    };
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
      # "editor.defaultFormatter" = "B4dM4n.nixpkgs-fmt";
    };
    workbench.colorCustomizations = {
      "titleBar.activeBackground" = "#${config.colorScheme.palette.base01}";
      "titleBar.inactiveBackground" = "#${config.colorScheme.palette.base02}";
      "activityBar.background" = "#${config.colorScheme.palette.base02}";
      "activityBar.foreground" = "#${config.colorScheme.palette.base0E}";
      "sideBar.background" = "#${config.colorScheme.palette.base01}";
      "sideBar.foreground" = "#${config.colorScheme.palette.base05}";
      "statusBar.background" = "#${config.colorScheme.palette.base00}";
      "statusBar.foreground" = "#${config.colorScheme.palette.base05}";
      "statusBar.noFolderBackground" = "#${config.colorScheme.palette.base01}";
      "statusBar.noFolderForeground" = "#${config.colorScheme.palette.base02}";
      "editor.background" = "#${config.colorScheme.palette.base00}";
      "editor.foreground" = "#${config.colorScheme.palette.base07}";
      "tab.activeBackground" = "#${config.colorScheme.palette.base01}";
      "tab.inactiveBackground" = "#${config.colorScheme.palette.base02}";
      "tab.activeForeground" = "#${config.colorScheme.palette.base07}";
      "tab.inactiveForeground" = "#${config.colorScheme.palette.base05}";
      "panel.background" = "#${config.colorScheme.palette.base01}";
      "panel.border" = "#${config.colorScheme.palette.base03}";
      "panelTitle.activeForeground" = "#${config.colorScheme.palette.base07}";
      "panelTitle.inactiveForeground" = "#${config.colorScheme.palette.base05}";
      "panelTitle.activeBorder" = "#${config.colorScheme.palette.base0D}";
      "badge.background" = "#${config.colorScheme.palette.base0E}";
      "badge.foreground" = "#${config.colorScheme.palette.base00}";
      "terminal.background" = "#${config.colorScheme.palette.base00}";
      "terminal.foreground" = "#${config.colorScheme.palette.base07}";
      "terminalCursor.background" = "#${config.colorScheme.palette.base01}";
      "terminalCursor.foreground" = "#${config.colorScheme.palette.base07}";
    };
  };
in
{
  home.file.cursorSettings = {
    target =
      if pkgs.stdenv.isDarwin then
        "Library/Application Support/Cursor/User/settings.json"
      else
        ".config/Cursor/User/settings.json";
    text = cursorSettings;
  };

  # extensions for vscode:
  programs.vscode.extensions = with pkgs.vscode-extensions; [
    # bbenoist.nix
    jnoortheen.nix-ide
    esbenp.prettier-vscode
  ];

  programs.vscode = {
    enable = true;
    userSettings = vscodeSettings;
  };

  home.packages = with pkgs; [
    unstable.code-cursor
  ];
}
