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
         Ultimate Beeper Theme (Stylix/Base16) - Solid Edition
         Managed by Nix via Home Manager.
      */

      :root {
          /* Core Colors from Stylix */
          --color-bg: #${colors.base00};
          --color-bg-rgb: ${hexToRGBComponents colors.base00};
          --color-fg: #${colors.base05};
          --color-fg-rgb: ${hexToRGBComponents colors.base05};

          --color-primary: #${colors.base0D};
          --color-primary-rgb: ${hexToRGBComponents colors.base0D};

          /* Beeper UI Specific Overrides - SOLID */
          --color-surface-bg: #${colors.base00};
          --color-surface-elevated: #${colors.base01};
          --color-surface-active: #${colors.base02};
          --color-surface-hover: #${colors.base01};
          
          --color-border: #${colors.base01};
          --color-border-strong: #${colors.base02};

          /* Sidebar and Panes - SOLID */
          --color-background-sidebar: #${colors.base01};
          --color-background-sidebar-opaque: #${colors.base01};
          --left-pane-bg: #${colors.base01};
          --right-pane-bg: #${colors.base00};
          
          /* Chat Bar (Composer) - SOLID */
          --color-background-input: #${colors.base01};
          --color-background-composer: #${colors.base00};

          /* FORCE BACKGROUND OVERRIDES (Banishing Black) */
          --color-background-app: #${colors.base00} !important;
          --color-background-app-weak: #${colors.base01} !important;
          --color-background-message-list: #${colors.base00} !important;
          --color-surface-background: #${colors.base00} !important;
          --color-background-elevated: #${colors.base01} !important;

          /* Message Bubbles */
          --color-background-message-bubble-received: #${colors.base01};
          --color-background-message-bubble-sent: #${colors.base0D};
          --color-text-message-bubble-sent: #${colors.base00};
          
          /* Typography */
          --font-family: "${config.stylix.fonts.sansSerif.name}", system-ui, -apple-system, sans-serif;
      }

      /* Global App Background */
      body, #matrixchat, .mx_MatrixChat, .mx_RoomView, .mx_RoomView_messageList, .mx_MainSplit {
          background-color: var(--color-bg) !important;
          background: var(--color-bg) !important;
      }

      /* Sidebar Refinements */

      .mx_LeftPanel, .thread-list {
          background-color: var(--color-background-sidebar) !important;
          border-right: 1px solid var(--color-border-strong) !important;
      }

      /* Thread list items */
      .thread-list-item {
          margin: 4px 8px !important;
          border-radius: 8px !important;
          transition: background-color 0.2s ease !important;
      }

      .thread-list-item.selected {
          background-color: var(--color-surface-active) !important;
          box-shadow: none !important; /* Remove shadows for flat look */
      }

      /* Indicators */
      .thread-list-item .unread-indicator {
          background-color: var(--color-primary) !important;
          box-shadow: none !important;
      }

      /* Chat Header */
      .mx_RoomHeader, .mx_RoomView_header {
          background-color: var(--color-bg) !important;
          border-bottom: 1px solid var(--color-border) !important;
      }

      /* ── Chat Conversation View (Timeline) ────────────────────── */
      .mx_RoomView_messageList, .mx_MainSplit {
          background-color: var(--color-bg) !important;
      }

      /* Individual message tiles */
      .mx_EventTile {
          background-color: transparent !important;
      }

      /* Date separators */
      .mx_DateSeparator {
          background-color: transparent !important;
          border-bottom: 1px solid var(--color-border) !important;
      }

      .mx_DateSeparator_content {
          background-color: var(--color-surface-elevated) !important;
          color: var(--color-fg) !important;
          border-radius: 4px !important;
          padding: 2px 8px !important;
          font-size: 0.8rem !important;
      }

      /* "New Message" line */
      .mx_NewMessageSeparator {
          border-top: 2px solid var(--color-primary) !important;
      }


      /* Composer (Chat Bar) - SOLID FLAT */
      .mx_SendMessageComposer, .composer-container {
          background-color: var(--color-surface-elevated) !important;
          border: 1px solid var(--color-border-strong) !important;
          border-radius: 8px !important;
          margin: 12px 20px !important;
          padding: 4px 8px !important;
          box-shadow: none !important; /* No shadows */
          backdrop-filter: none !important; /* NO GLASSMORPHISM */
      }

      /* Scrollbars */
      ::-webkit-scrollbar {
          width: 4px;
          height: 4px;
      }
      ::-webkit-scrollbar-thumb {
          background: var(--color-border-strong);
          border-radius: 0px; /* Flat scrollbars */
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
