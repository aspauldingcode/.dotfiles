{
  flake.modules.homeManager.beeper = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.dendritic.apps.beeper;
    colors = config.lib.stylix.colors;

    # Helper to convert hex to RGB components
    # Stylix colors are like "1a1b26"
    hexToRGBComponents = hex: let
      r = lib.strings.substring 0 2 hex;
      g = lib.strings.substring 2 2 hex;
      b = lib.strings.substring 4 2 hex;

      hexToDecMap = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
        "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
        "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
      };

      convertPair = pair: let
        v1 = hexToDecMap.${lib.strings.substring 0 1 pair};
        v2 = hexToDecMap.${lib.strings.substring 1 1 pair};
      in
        v1 * 16 + v2;
    in "${toString (convertPair r)}, ${toString (convertPair g)}, ${toString (convertPair b)}";

    # Generate the ultimate Beeper CSS
    beeperCSS = ''
      /* 
         Ultimate Beeper Theme (Stylix/Base16)
         Designed for 8amps with "tinting-only" approach
         This file is managed by Nix via Home Manager.
      */

      :root {
          /* Core Colors from Stylix */
          --color-bg: #${colors.base00};
          --color-bg-rgb: ${hexToRGBComponents colors.base00};
          --color-fg: #${colors.base05};
          --color-fg-rgb: ${hexToRGBComponents colors.base05};

          --color-primary: #${colors.base0D};
          --color-primary-rgb: ${hexToRGBComponents colors.base0D};

          /* Gray Scale Mapping using Stylix Base16 */
          --color-base-gray-10: #${colors.base00};
          --color-base-gray-10-rgb: ${hexToRGBComponents colors.base00};
          --color-base-gray-20: #${colors.base01};
          --color-base-gray-20-rgb: ${hexToRGBComponents colors.base01};
          --color-base-gray-30: #${colors.base01};
          --color-base-gray-30-rgb: ${hexToRGBComponents colors.base01};
          --color-base-gray-40: #${colors.base02};
          --color-base-gray-40-rgb: ${hexToRGBComponents colors.base02};
          --color-base-gray-50: #${colors.base02};
          --color-base-gray-50-rgb: ${hexToRGBComponents colors.base02};
          --color-base-gray-60: #${colors.base03};
          --color-base-gray-60-rgb: ${hexToRGBComponents colors.base03};
          --color-base-gray-70: #${colors.base03};
          --color-base-gray-70-rgb: ${hexToRGBComponents colors.base03};
          --color-base-gray-80: #${colors.base04};
          --color-base-gray-80-rgb: ${hexToRGBComponents colors.base04};
          --color-base-gray-100: #${colors.base04};
          --color-base-gray-100-rgb: ${hexToRGBComponents colors.base04};
          --color-base-gray-110: #${colors.base05};
          --color-base-gray-110-rgb: ${hexToRGBComponents colors.base05};
          --color-base-gray-120: #${colors.base06};
          --color-base-gray-120-rgb: ${hexToRGBComponents colors.base06};

          /* Message Bubbles */
          --color-background-message-bubble-received: #${colors.base01};
          --color-background-message-bubble-sent: #${colors.base0D};
          
          /* Sidebar and Panes */
          --color-background-sidebar: rgba(${hexToRGBComponents colors.base00}, 0.7);
          --color-background-sidebar-opaque: #${colors.base00};
          --left-pane-bg: transparent;
          --right-pane-bg: #${colors.base00};

          /* Selected States & Buttons */
          --color-background-selected-primary: #${colors.base0D};
          --color-background-button-primary: #${colors.base0D};
          --color-background-button-primary-active: #${colors.base0E};
          --color-background-button-secondary: #${colors.base02};

          /* Typography */
          --font-family: "${config.stylix.fonts.sansSerif.name}", system-ui, -apple-system, sans-serif;
          --font-weight-regular: 400;
          --font-weight-emphasized: 600;

          /* Borders and Dividers */
          --color-border-neutrals: #${colors.base01};
          --color-border-neutrals-strong: #${colors.base02};
          --color-border-translucent: rgba(${hexToRGBComponents colors.base05}, 0.1);

          /* Scrollbar Customization */
          --color-background-scrollbar: rgba(${hexToRGBComponents colors.base03}, 0.5);
          --color-background-scrollbar-hover: rgba(${hexToRGBComponents colors.base03}, 0.8);
      }

      /* Dark Mode Specific Overrides */
      @media (prefers-color-scheme: dark) {
          :root {
              --color-background-app: #${colors.base00};
              --color-background-app-weak: #${colors.base01};
              --color-background-elevated: #${colors.base01};
              --color-background-elevated-hover: #${colors.base02};
              --color-background-grouped: #${colors.base00};
              --color-background-input: #${colors.base01};
          }
      }

      /* Enhanced Visuals (Premium Feel) */
      
      /* Sidebar thread selection indicator */
      .thread-list-item {
          transition: background-color 0.2s ease, border-left 0.2s ease !important;
      }

      .thread-list-item.selected {
          background-color: rgba(${hexToRGBComponents colors.base0D}, 0.15) !important;
          position: relative;
      }
      
      .thread-list-item.selected::before {
          content: "";
          position: absolute;
          left: 0;
          top: 10%;
          bottom: 10%;
          width: 4px;
          background-color: #${colors.base0D};
          border-radius: 0 4px 4px 0;
          box-shadow: 0 0 10px rgba(${hexToRGBComponents colors.base0D}, 0.5);
      }

      /* Hover effects */
      .thread-list-item:hover:not(.selected) {
          background-color: rgba(${hexToRGBComponents colors.base05}, 0.08) !important;
      }

      /* Message bubble refinements */
      .message-bubble {
          border-radius: 16px !important;
          transition: transform 0.1s ease;
      }
      
      .message-bubble:active {
          transform: scale(0.98);
      }

      /* Composer area */
      .composer-container {
          background-color: rgba(${hexToRGBComponents colors.base00}, 0.8) !important;
          backdrop-filter: blur(10px);
          border-top: 1px solid rgba(${hexToRGBComponents colors.base05}, 0.1) !important;
      }

      /* Custom Scrollbars */
      ::-webkit-scrollbar {
          width: 6px;
          height: 6px;
      }
      ::-webkit-scrollbar-track {
          background: transparent;
      }
      ::-webkit-scrollbar-thumb {
          background: #${colors.base02};
          border-radius: 10px;
      }
      ::-webkit-scrollbar-thumb:hover {
          background: #${colors.base03};
      }
    '';
  in {
    options.dendritic.apps.beeper = {
      enable = lib.mkEnableOption "Beeper Desktop theme customization";
    };

    config = lib.mkIf cfg.enable {
      home.packages = [ pkgs.beeper ];

      home.file."Library/Application Support/BeeperTexts/custom.css" = {
        text = beeperCSS;
        force = true;
      };
    };
  };
}
