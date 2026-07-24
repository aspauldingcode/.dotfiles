{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.beeper;
      colors = config.lib.stylix.colors;

      # Generate the ultimate Beeper CSS
      beeperCSS = ''
        /* 
           Ultimate Beeper Theme (Stylix/Base16) - Solid Edition
           Managed by Nix via Home Manager.
        */

        :root {
            /* ── Base16 Polarity-Aware Core ── */
            --color-bg: #${colors.base00};
            --color-fg: #${colors.base05};
            --color-primary: #${colors.base0D};
            
            /* Grayscale Surface Stack (Darkest to Lighter) */
            --bg-0: #${colors.base00};
            --bg-1: #${colors.base01};
            --bg-2: #${colors.base02};
            --bg-3: #${colors.base03};

            /* Text & Content Stack (Muted to Brightest) */
            --fg-0: #${colors.base04};
            --fg-1: #${colors.base05};
            --fg-2: #${colors.base06};
            --fg-3: #${colors.base07};

            /* ── Beeper Variable Mapping ── */

            /* UI Backgrounds */
            --color-background-app: var(--bg-0);
            --color-background-app-weak: var(--bg-1);
            --color-background-elevated: var(--bg-1);
            --color-background-elevated-hover: var(--bg-2);
            --color-background-grouped: var(--bg-1);
            --color-background-grouped-weak: var(--color-base-gray-10);
            --color-background-object: var(--bg-2);

            /* Buttons */
            --color-background-button-primary: var(--color-primary);
            --color-background-button-primary-active: #${colors.base0C};
            --color-background-button-primary-disabled: var(--bg-3);
            --color-background-button-secondary: var(--bg-2);
            --color-background-button-secondary-active: var(--bg-3);
            --color-background-button-secondary-disabled: var(--bg-1);
            --color-background-button-translucent: rgba(var(--color-bg-rgb), 0.1);
            --color-background-button-translucent-active: rgba(var(--color-bg-rgb), 0.15);
            --color-background-button-translucent-disabled: rgba(var(--color-bg-rgb), 0.05);

            /* Sidebar */
            --color-background-sidebar: var(--bg-1);
            --color-background-sidebar-opaque: var(--bg-1);
            --color-background-sidebar-thread-focus: var(--bg-2);
            --color-background-sidebar-thread-selected: var(--color-primary);
            --color-background-sidebar-thread-selected-unfocused: var(--bg-2);

            /* Messages */
            --color-background-message-active: var(--bg-1);
            --color-background-message-bubble-received: var(--bg-1);
            --color-background-message-bubble-sent: var(--color-primary);
            --color-background-message-bubble-linked: var(--bg-0);

            /* Inputs */
            --color-background-input: var(--bg-1);
            --color-background-kbd: var(--bg-2);

            /* Header/Menu */
            --color-background-header-right: var(--bg-1);
            --color-background-header-right-opaque: var(--bg-1);
            --color-background-menu: var(--bg-2);
            --color-background-menu-opaque: var(--bg-2);
            --color-background-menu-option-hover: var(--color-primary);

            /* Borders */
            --color-border-neutrals: var(--bg-2);
            --color-border-neutrals-strong: var(--bg-3);
            --color-border-neutrals-weak: var(--bg-1);
            --color-border-input: var(--bg-2);
            --color-border-input-active: var(--bg-3);

            /* Text */
            --color-text-neutrals: var(--fg-1);
            --color-text-neutrals-subtle: var(--fg-0);
            --color-text-neutrals-weak: var(--fg-0);
            --color-text-on-accent: var(--bg-0);
            --color-text-on-accent-weak: var(--bg-1);
            --color-text-translucent: var(--fg-1);

            /* Icons */
            --color-icon-neutrals: var(--fg-0);
            --color-icon-neutrals-strong: var(--fg-1);
            --color-icon-neutrals-subtle: var(--bg-3);

            /* Typography */
            --font-family: "${config.stylix.fonts.sansSerif.name}", system-ui, -apple-system, BlinkMacSystemFont, Twemoji, "Segoe UI", "Helvetica Neue", sans-serif;
            --font-family-mono: "${config.stylix.fonts.monospace.name}", monospace;

            /* Functional Colors mapping */
            --functional-red: #${colors.base08};
            --functional-orange: #${colors.base09};
            --functional-green: #${colors.base0B};
            --functional-cyan: #${colors.base0C};
            --functional-purple: #${colors.base0E};

            /* Matrix/Element Aliases */
            --primary-content: var(--fg-1) !important;
            --secondary-content: var(--fg-0) !important;
            --tertiary-content: var(--fg-0) !important;
            --accent: var(--color-primary) !important;
            --background: var(--bg-0) !important;
            --timeline-background: var(--bg-0) !important;
            --composer-background: var(--bg-1) !important;

            /* Audio Bar */
            --audio-bar-bg: var(--color-background-elevated);
            --audio-bar-border: var(--color-border-neutrals);
            --audio-bar-button: var(--color-icon-neutrals);

            /* Keyboard Keys */
            --key-bg: var(--color-background-elevated);
            --key-border: var(--color-border-neutrals);

            /* ANSI Colors (Stylix base00-base0F) */
            --ansi-black: #${colors.base00};
            --ansi-red: #${colors.base08};
            --ansi-green: #${colors.base0B};
            --ansi-yellow: #${colors.base0A};
            --ansi-blue: #${colors.base0D};
            --ansi-magenta: #${colors.base0E};
            --ansi-cyan: #${colors.base0C};
            --ansi-white: #${colors.base05};
            --ansi-bright-black: #${colors.base03};
            --ansi-bright-red: #${colors.base08};
            --ansi-bright-green: #${colors.base0B};
            --ansi-bright-yellow: #${colors.base0A};
            --ansi-bright-blue: #${colors.base0D};
            --ansi-bright-magenta: #${colors.base0E};
            --ansi-bright-cyan: #${colors.base0C};
            --ansi-bright-white: #${colors.base07};

            /* Layout & Spacing Variables */
            --header-height: 48px;
            --filters-pane-width: 220px;
            --min-sidebar-width: 280px;
            --max-sidebar-width: 800px;
            --threads-list-item-height: 54px;
            --pinned-thread-base-size: 64px;

            --margin-50: 2px;
            --margin-75: 3px;
            --margin-100: 4px;
            --margin-200: 6px;
            --margin-300: 8px;
            --margin-400: 10px;
            --margin-500: 12px;
            --margin-700: 16px;
            --margin-900: 22px;
            --margin-1000: 24px;

            --border-radius-25: 4px;
            --border-radius-50: 8px;
            --border-radius-100: 12px;
            --border-radius-200: 20px;
            --border-radius-conversation-bubble: 17px;

            /* Detailed Typography */
            --font-weight-regular: 400;
            --font-weight-emphasized: 600;
            --font-size-body-medium: 0.875rem;
            --line-height-body-medium: 1.125rem;
            --font-size-label-medium: 0.75rem;
            --line-height-label-medium: 0.9375rem;

            /* Sizes & Dimensions */
            --inbox-avatar-size: 28px;
            --cv-avatar-size: 28px;
            --inbox-icon-size: 20px;
            --inbox-search-icon-size: 15px;
            --account-switcher-width: 54px;
            --composer-attachment-max-height: 66px;
            --message-padding-horizontal: 12px;
            --message-padding-vertical: 5px;

            /* JetBrains Dark Purple inspired additions */
            --color-background-preferences-option-selected: var(--color-primary);
            --color-background-commandbar-opaque: var(--color-background-sidebar);
            --color-background-commandbar-command-highlighted: var(--color-primary);
            --color-background-selected: var(--color-primary);

            /* ── Beeper 4.x Material You Surface Variables ──────────────
               Beeper 4.x uses --color-surface (defaults to white in light
               mode) for nearly every background. Override them here so the
               left panel, thread list, and secondary containers inherit the
               Stylix palette instead of the default browser white.       */
            --color-surface:                          var(--bg-0);
            --color-surface-bright:                   var(--bg-0);
            --color-surface-dim:                      var(--bg-1);
            --color-on-surface:                       var(--fg-1);
            --color-on-surface-variant:               var(--fg-0);

            /* Secondary / tertiary containers (sidebar sections, list rows) */
            --color-secondary-container:              var(--bg-1);
            --color-tertiary-container:               var(--bg-1);
            --color-container-inside-secondary-container: var(--bg-2);
            --color-on-secondary-container:           var(--fg-0);
            --color-on-tertiary-container:            var(--fg-0);
            --color-primary-container:                var(--bg-0);

            /* Outline / border tokens */
            --color-outline:                          var(--bg-3);
            --color-outline-variant:                  var(--bg-2);

            /* Backing shade (used under avatars, activity dots, etc.) */
            --color-backing-shade:                    var(--bg-2);

            /* Scrim / glass overlays */
            --color-scrim:                            rgba(0,0,0,0.4);
            --color-glass-surface:                    var(--bg-1);
            --color-glass-container:                  var(--bg-1);

            /* Misc aliases that some Beeper builds still use */
            --color-bg:                               var(--bg-0);
        }

        body {
            -webkit-font-smoothing: auto;
            --margin-50: 2px;
            --margin-75: 3px;
            --margin-100: 4px;
            --margin-200: 6px;
            --margin-300: 8px;
            --margin-400: 10px;
            --margin-500: 12px;
            --margin-700: 16px;
            --margin-900: 22px;
            --margin-1000: 24px;
        }

        /* JetBrains Dark Purple & Advanced UI Refinements */
        .command.command.highlighted .command-children {
            background: var(--color-primary) !important;
        }

        .panes, .compose-message-container > * {
            background: var(--bg-0) !important;
            backdrop-filter: none !important;
        }

        .linked-message {
            color: inherit !important;
        }

        .sidebar-thread.isSelected > section:before {
            background: var(--bg-0) !important;
        }

        /* Sidebar Conversation Titles (Fixing Ghost Backgrounds) */
        .mx_RoomTile_name,
        .mx_RoomTile_title,
        .mx_RoomTile_messagePreview,
        [class*="RoomTile_name"],
        [class*="RoomTile_title"] {
            background: transparent !important;
            background-color: transparent !important;
            color: var(--color-fg) !important;
        }

        /* Global App Styles */
        body, #matrixchat, .mx_MatrixChat, .mx_RoomView, .mx_RoomView_messageList, .mx_MainSplit, .mx_EventTile_content {
            background-color: var(--color-bg) !important;
            background: var(--color-bg) !important;
            color: var(--color-fg) !important;
        }

        input, textarea, [contenteditable="true"] {
            color: var(--color-fg) !important;
            background-color: var(--color-surface-elevated) !important;
        }

        /* ── Comprehensive Text Color Overrides ── */

        /* Global text fallback */
        #matrixchat, .mx_MatrixChat, .mx_RoomView_messageList, .mx_MainSplit {
            color: var(--color-fg) !important;
        }

        /* Specific Matrix/Element/Beeper classes */
        .mx_EventTile_body, 
        .mx_EventTile_senderDetails, 
        .mx_RoomTile_name, 
        .mx_RoomTile_messagePreview,
        .mx_GenericEventListSummary_summary,
        .mx_TextualEvent,
        .mx_RoomHeader_nametext,
        .mx_RoomHeader_topic,
        .mx_LeftPanel_section_header,
        .thread-list-item .title,
        .thread-list-item .preview,
        .thread-list-item .timestamp,
        .mx_MessageComposer_editor,
        .mx_EventTile_timestamp,
        .mx_RoomTile_subtitle,
        .mx_SecondaryText,
        .mx_MTextBody,
        .mx_ReplyTile .mx_MTextBody,
        .mx_EventTile_receiptSent,
        .mx_EventTile_receiptSending,
        .mx_RoomSubList_label,
        .mx_BaseCard_header_title,
        .mx_SettingsTab_heading,
        .mx_SettingsFlag_label,
        .mx_LabelledCheckbox_label,
        .mx_Heading_h1, .mx_Heading_h2, .mx_Heading_h3, .mx_Heading_h4,
        .mx_Dialog_title,
        .mx_Dialog_content,
        .mx_MainSplit_searchResultHeader,
        .mx_SearchStatus,
        .mx_GenericEventListSummary_summary,
        .mx_MemberStatus_online,
        .mx_MemberStatus_offline,
        .mx_MemberStatus_away,
        .mx_MessageActionBar_icon,
        .mx_NotificationBadge,
        .mx_SpaceButton_label,
        .mx_GroupFilterPanel_item_label,
        .mx_InviteDialog_tile_name,
        .mx_UserMenu_name,
        .mx_RoomView_empty_title,
        .mx_RoomView_empty_text,
        .mx_RoomTile_messagePreview_line,
        .mx_RoomDropTarget_label,
        a {
            color: var(--color-fg) !important;
        }

        /* Handle generic text elements within the chat area */
        .mx_RoomView_messageList div,
        .mx_RoomView_messageList span,
        .mx_RoomView_messageList p,
        .mx_RoomView_messageList li {
            color: var(--color-fg) !important;
        }

        a:hover {
            color: var(--color-primary) !important;
        }

        /* Code Blocks & Inline Code */
        code, pre, .mx_EventTile_body code, .mx_EventTile_body pre {
            background-color: var(--color-surface-elevated) !important;
            color: var(--color-primary) !important;
            border: 1px solid var(--color-border-strong) !important;
            border-radius: 4px !important;
            font-family: var(--font-family-mono) !important;
            padding: 2px 4px !important;
        }

        pre {
            padding: 10px !important;
            margin: 8px 0 !important;
            display: block !important;
            overflow-x: auto !important;
        }

        /* Reactions */
        .mx_ReactionsRow_item {
            background-color: var(--color-surface-elevated) !important;
            border: 1px solid var(--color-border) !important;
            border-radius: 8px !important;
            color: var(--color-fg) !important;
        }

        .mx_ReactionsRow_item.mx_ReactionsRow_item_selected {
            background-color: var(--color-surface-active) !important;
            border-color: var(--color-primary) !important;
            color: var(--color-primary) !important;
        }

        /* Mentions and Pills */
        .mx_Pill, .mx_Mention, .mx_UserPill {
            background-color: var(--color-surface-active) !important;
            color: var(--color-primary) !important;
            border-radius: 4px !important;
            padding: 0 4px !important;
        }

        /* ── Deep Dive Component Fixes (Attribute & Structural) ── */

        /* 1. Inbox Header & Filter Buttons */
        [aria-label="Filter"], 
        [aria-label="Inbox"],
        [aria-label*="filter" i],
        [aria-label*="inbox" i],
        [role="button"][aria-label*="filter" i],
        .inbox-filter,
        .filter-button,
        .mx_FilterButton {
            color: var(--color-fg) !important;
            fill: var(--color-fg) !important; /* Catch icons */
        }

        /* 2. Inbox Text & Headings */
        h1, h2, h3, h4,
        [role="heading"],
        .mx_RoomList_header,
        .mx_LeftPanel_roomList_header,
        .mx_Heading_h1,
        .mx_Heading_h2 {
            color: var(--color-fg) !important;
            background-color: var(--color-bg) !important;
        }

        /* 3. Date Labels & Timestamps (Banishing Dark/Light Confusion) */
        .mx_DateSeparator_content,
        .mx_EventTile_timestamp,
        .mx_MessageTimestamp,
        .thread-list-item .timestamp,
        [class*="DateSeparator"],
        [class*="timestamp"],
        [class*="date-label"] {
            color: var(--color-fg) !important;
            background-color: transparent !important;
            opacity: 0.8 !important;
        }

        /* 4. Links Fix (Flipped Colors) */
        a, .mx_Link, .mx_EventTile_body a {
            color: var(--color-primary) !important;
            text-decoration: underline !important;
        }

        a:hover {
            color: #${colors.base0C} !important; /* Brightest accent on hover */
        }

        /* 5. Message Bubbles & Replies (The "Dark-on-Dark" and "Light-on-Light" Killer) */

        /* Received Messages */
        .mx_EventTile_received,
        .mx_EventTile_received *,
        .mx_EventTile_bubble,
        .mx_EventTile_bubble *,
        .mx_EventTile_line,
        .mx_EventTile_content {
            background-color: var(--color-base-gray-20) !important;
            color: var(--color-fg) !important;
        }

        /* Reply Tiles & Previews */
        .mx_ReplyTile,
        .mx_ReplyTile *,
        .mx_ReplyChain,
        .mx_ReplyChain *,
        .mx_EventTile_reply {
            background-color: var(--color-base-gray-10) !important;
            color: var(--color-fg) !important;
            border-left: 2px solid var(--color-primary) !important;
        }

        /* 6. Inbox / Archive Switcher & Space Panel */
        .mx_SpacePanel,
        .mx_SpacePanel *,
        .mx_SpaceButton,
        .mx_SpaceButton *,
        .mx_RoomList_header_switcher,
        .mx_RoomList_header_switcher *,
        [class*="SpaceButton"],
        [class*="SpacePanel"],
        [class*="header_switcher"] {
            background-color: var(--color-background-sidebar) !important;
            color: var(--color-fg) !important;
        }

        .mx_SpaceButton_active,
        .mx_SpaceButton_selected {
            background-color: var(--color-surface-active) !important;
        }

        /* 7. Generic Button & Icon Protection */
        button, [role="button"] {
            color: var(--color-fg) !important;
        }

        svg, [class*="icon"], [class*="Icon"] {
            fill: currentColor !important;
        }

        /* ── Problem Area Overrides (Titlebar, Sidebar, Composer) ── */

        /* 1. Titlebar & Header */
        .mx_RoomHeader, 
        .mx_RoomHeader *,
        .mx_TitleBar,
        .mx_TitleBar *,
        .mx_RoomHeader_wrapper,
        .mx_RoomHeader_name,
        .mx_RoomHeader_nametext,
        .mx_RoomHeader_topic {
            color: var(--color-fg) !important;
            background-color: var(--color-bg) !important;
        }

        /* 2. Sidebar (Message List / Room List) */
        .mx_LeftPanel,
        .mx_LeftPanel *,
        .thread-list,
        .thread-list *,
        .mx_RoomList,
        .mx_RoomList *,
        .mx_RoomTile,
        .mx_RoomTile *,
        .mx_RoomTile_name,
        .mx_RoomTile_messagePreview,
        .mx_RoomTile_subtitle,
        .mx_LeftPanel_section_header,
        .mx_LeftPanel_section_header * {
            color: var(--color-fg) !important;
        }

        /* Sidebar Backgrounds (Consistency) */
        .mx_LeftPanel, .thread-list, .mx_RoomList, .mx_SpacePanel {
            background-color: var(--color-background-sidebar) !important;
        }

        /* ── Beeper 4.x left panel / surface fallback ──────────────────
           Beeper 4.x renders the left panel with background:var(--color-surface).
           The :root override above handles the CSS variable, but we also
           apply a direct rule to catch any element using a hardcoded white. */
        [class*="surface"],
        [class*="Surface"],
        [class*="leftPanel"],
        [class*="LeftPanel"],
        [class*="sideBar"],
        [class*="sidebar"],
        [class*="Sidebar"],
        [class*="inbox"],
        [class*="Inbox"] {
            background-color: var(--bg-0) !important;
            color: var(--fg-1) !important;
        }

        /* 3. Chat Box (Composer / Input Area) */
        .mx_SendMessageComposer,
        .mx_SendMessageComposer *,
        .composer-container,
        .composer-container *,
        .mx_MessageComposer,
        .mx_MessageComposer *,
        .mx_MessageComposer_editor,
        .mx_MessageComposer_editor *,
        .mx_Composer_input,
        .mx_Composer_input *,
        [contenteditable="true"],
        [contenteditable="true"] * {
            color: var(--color-fg) !important;
        }

        /* Composer Background Fixes */
        .mx_SendMessageComposer, 
        .composer-container, 
        .mx_MessageComposer_editor,
        .mx_MessageComposer_wrapper {
            background-color: var(--color-surface-elevated) !important;
            background: var(--color-surface-elevated) !important;
        }

        /* Specific Fix for Placeholder text in Composer */
        .mx_MessageComposer_editor:empty:before,
        .mx_Composer_input:empty:before,
        [data-placeholder]:empty:before {
            color: var(--color-fg) !important;
            opacity: 0.5 !important;
        }

        /* ── Global Scrollbars ────────────────────────────────────── */
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
    in
    {
      options.dendritic.apps.beeper = {
        enable = lib.mkEnableOption "Beeper Desktop theme customization";
      };

      config = lib.mkIf cfg.enable {
        home.packages = lib.optional (builtins.elem pkgs.stdenv.hostPlatform.system pkgs.beeper.meta.platforms) pkgs.beeper;

        home.file =
          lib.optionalAttrs pkgs.stdenv.isDarwin {
            # Legacy Beeper path.
            "Library/Application Support/Beeper/custom.css" = {
              text = beeperCSS;
              force = true;
            };
            # Current desktop app path used by newer builds.
            "Library/Application Support/Beeper Desktop/custom.css" = {
              text = beeperCSS;
              force = true;
            };
            # Beeper Texts/desktop path seen in upstream theme repos.
            "Library/Application Support/BeeperTexts/custom.css" = {
              text = beeperCSS;
              force = true;
            };
          }
          // lib.optionalAttrs pkgs.stdenv.isLinux {
            ".config/Beeper/custom.css".text = beeperCSS;
          };

        # ── Beeper Auto-Update Prevention (macOS "uchg" Hard Fix) ──────
        home.activation.disableBeeperUpdates = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            BEEPER_UPDATE_PATH="$HOME/Library/Application Support/Beeper/Update"
            BEEPER_SHIPIT_PATH="$HOME/Library/Caches/com.beeper.desktop.ShipIt"

            # 1. Block the 'Update' directory
            if ! /usr/bin/stat -f "%Sf" "$BEEPER_UPDATE_PATH" 2> /dev/null | grep -q uchg; then
              rm -rf "$BEEPER_UPDATE_PATH"
              mkdir -p "$BEEPER_UPDATE_PATH"
              /usr/bin/chflags uchg "$BEEPER_UPDATE_PATH"
            fi

            # 2. Block the Electron 'ShipIt' directory (where update staging happens)
            if ! /usr/bin/stat -f "%Sf" "$BEEPER_SHIPIT_PATH" 2> /dev/null | grep -q uchg; then
              rm -rf "$BEEPER_SHIPIT_PATH"
              mkdir -p "$BEEPER_SHIPIT_PATH"
              /usr/bin/chflags uchg "$BEEPER_SHIPIT_PATH"
            fi
          ''
        );
      };
    };
}
