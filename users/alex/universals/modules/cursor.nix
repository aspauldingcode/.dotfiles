{ config, pkgs, ... }:

let
  commonSettings = builtins.toJSON {
    security.workspace.trust.untrustedFiles = "open";
    editor.semanticTokenColorCustomizations = {
      enabled = true;
      rules = {
        "*.declaration" = { foreground = "#${config.colorScheme.colors.base0A}"; fontStyle = "bold"; };
        "*.readonly" = { foreground = "#${config.colorScheme.colors.base08}"; fontStyle = "italic"; };
      };
    };
    editor.tokenColorCustomizations = {
      textMateRules = [
        {
          scope = [ "comment" "punctuation.definition.comment" "string.comment" ];
          settings = {
            foreground = "#${config.colorScheme.colors.base03}"; # Adjusted for comments
          };
        }
        {
          scope = "constant.numeric";
          settings = {
            foreground = "#${config.colorScheme.colors.base09}"; # Correct for integers, constants
          };
        }
        {
          scope = "entity.name.function";
          settings = {
            foreground = "#${config.colorScheme.colors.base0D}"; # Correct for functions, methods
          };
        }
        {
          scope = "keyword";
          settings = {
            foreground = "#${config.colorScheme.colors.base0E}"; # Correct for keywords
          };
        }
        {
          scope = "string.quoted.double";
          settings = {
            foreground = "#${config.colorScheme.colors.base0B}"; # Correct for strings
          };
        }
        {
          scope = "variable";
          settings = {
            foreground = "#${config.colorScheme.colors.base08}"; # Adjusted for variables
          };
        }
        {
          scope = "variable.parameter";
          settings = {
            foreground = "#${config.colorScheme.colors.base0A}"; # Correct for classes, markup bold
          };
        }
        {
          scope = "entity.name.type.class";
          settings = {
            foreground = "#${config.colorScheme.colors.base0C}"; # Added for classes
          };
        }
        {
          scope = "markup.inserted";
          settings = {
            foreground = "#${config.colorScheme.colors.base0F}"; # Added for inserted elements in version control
          };
        }
        {
          scope = "entity.name.tag";
          settings = {
            foreground = "#${config.colorScheme.colors.base0F}"; # Added for HTML/XML tags
          };
        }
        {
          scope = "storage";
          settings = {
            foreground = "#${config.colorScheme.colors.base0E}"; # Added for storage types and modifiers in languages
          };
        }
        {
          scope = "support.function";
          settings = {
            foreground = "#${config.colorScheme.colors.base0D}"; # Added for support functions
          };
        }
      ];
    };
    window.autoDetectColorScheme = true;
    "workbench.colorTheme" = "Visual Studio Light";
    "workbench.preferredDarkColorTheme" = "Visual Studio Dark";
    "workbench.preferredHighContrastColorTheme" = "Default High Contrast";
    "workbench.preferredHighContrastLightColorTheme" = "Default High Contrast Light";
    "workbench.preferredLightColorTheme" = "Visual Studio Light";
    "git.autofetch" = true;
    "explorer.confirmDragAndDrop" = false;
    workbench.colorCustomizations = {
      "titleBar.activeBackground" = "#${config.colorScheme.colors.base01}";
      "titleBar.inactiveBackground" = "#${config.colorScheme.colors.base02}";
      "activityBar.background" = "#${config.colorScheme.colors.base02}";
      "activityBar.foreground" = "#${config.colorScheme.colors.base0E}";
      "sideBar.background" = "#${config.colorScheme.colors.base01}";
      "sideBar.foreground" = "#${config.colorScheme.colors.base05}";
      "statusBar.background" = "#${config.colorScheme.colors.base00}";
      "statusBar.foreground" = "#${config.colorScheme.colors.base01}";
      "statusBar.noFolderBackground" = "#${config.colorScheme.colors.base01}";
      "statusBar.noFolderForeground" = "#${config.colorScheme.colors.base02}";
      "editor.background" = "#${config.colorScheme.colors.base00}";
      "editor.foreground" = "#${config.colorScheme.colors.base07}";
      "tab.activeBackground" = "#${config.colorScheme.colors.base01}";
      "tab.inactiveBackground" = "#${config.colorScheme.colors.base02}";
      "tab.activeForeground" = "#${config.colorScheme.colors.base07}";
      "tab.inactiveForeground" = "#${config.colorScheme.colors.base05}";
      "panel.background" = "#${config.colorScheme.colors.base01}";
      "panel.border" = "#${config.colorScheme.colors.base03}";
      "panelTitle.activeForeground" = "#${config.colorScheme.colors.base07}";
      "panelTitle.inactiveForeground" = "#${config.colorScheme.colors.base05}";
      "panelTitle.activeBorder" = "#${config.colorScheme.colors.base0D}";
      "badge.background" = "#${config.colorScheme.colors.base0E}";
      "badge.foreground" = "#${config.colorScheme.colors.base00}";
      "terminal.background" = "#${config.colorScheme.colors.base00}";
      "terminal.foreground" = "#${config.colorScheme.colors.base07}";
      "terminalCursor.background" = "#${config.colorScheme.colors.base01}";
      "terminalCursor.foreground" = "#${config.colorScheme.colors.base07}";
    };
  };
in
{
  home.file.cursorSettings = {
    target = if pkgs.stdenv.isDarwin then "Library/Application Support/Cursor/User/settings.json" else ".config/Cursor/User/settings.json";
    text = commonSettings;
  };

  home.file.vscodeSettings = {
    target = if pkgs.stdenv.isDarwin then "Library/Application Support/Code/User/settings.json" else ".config/Code/User/settings.json";
    text = commonSettings;
  };
}
