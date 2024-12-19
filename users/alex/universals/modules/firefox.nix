{
  fetchurl,
  pkgs,
  lib,
  config,
  ...
}: 

let
  inherit (lib) mkForce;
  inherit (config.colorscheme) palette;
in {

  home.packages = if pkgs.stdenv.isDarwin then [ pkgs.defaultbrowser ] else [];

  home.activation = if pkgs.stdenv.isDarwin then {
    setDefaultBrowser = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.defaultbrowser}/bin/defaultbrowser firefox
    '';
  } else {};

  programs.firefox = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin
      then pkgs.firefox-bin
      else pkgs.firefox;
    profiles = {
      alex = {
        userChrome = ''
          /* Use Nix-Colors theme */
          #navigator-toolbox {
            --toolbar-bgcolor: #${palette.base00};
          }

          /* Customize toolbar icons color */
          .toolbarbutton-icon {
            fill: #${palette.base05} !important;
            fill-opacity: 1 !important;
          }

          /* Adjust icon color on hover and active states */
          .toolbarbutton-1:not([disabled]):hover .toolbarbutton-icon,
          .toolbarbutton-1:not([disabled])[open] .toolbarbutton-icon {
            fill: #${palette.base0D} !important;
          }

          /* Hide titlebar buttons and adjust spacing on macOS */
          @media (-moz-platform: macos) {
            .titlebar-buttonbox-container,
            #window-controls { 
              display: none !important; 
            }
            
            /* Shift tabs to the left by 38px */
            #TabsToolbar {
              padding-left: 0 !important;
              display: flex !important;
              margin-left: -38px !important;
              width: calc(100% + 38px) !important;
            }
          }

          /* Permanently hide bookmarks, site info button, three dots menu, and tracking protection shield in urlbar */
          #star-button-box,
          #identity-box,
          #pageActionButton {
            display: none !important;
          }

          /* Hide tracking protection icon when window width is less than 1000px */
          @media (max-width: 800px) {
            #tracking-protection-icon-container {
              display: none !important;
            }
          }

          /* Hide all addons/extensions buttons from toolbar after 600px */
          @media (max-width: 600px) {
            #nav-bar .unified-extensions-item {
              display: none !important;
            }
            /* Adjust padding to prevent empty space */
            #nav-bar-customization-target {
              padding-right: 0 !important;
            }
          }

          /* Hide the Sidebery icon when window width is 200px or less */
          @media (max-width: 200px) {
            #sidebar-button,
            #_3c078156-979c-498b-8990-85f7987dd929_-browser-action {
              display: none !important;
            }
          }

          /* Remove min-width and min-height constraints */
          #main-window {
            min-width: 0 !important;
            min-height: 0 !important;
          }

          /* Allow content to resize to any dimensions */
          #browser {
            min-width: 0 !important;
            min-height: 0 !important;
          }

          /* Ensure toolbars can shrink */
          #nav-bar,
          #PersonalToolbar,
          #TabsToolbar {
            min-width: 0 !important;
            min-height: 0 !important;
          }

          /* Allow searchbar to shrink to 0 */
          #urlbar-container {
            min-width: 0 !important;
            flex-shrink: 1 !important;
            flex-basis: 0 !important;
          }

          /* Hide pinned addons when window width is 700px or less */
          @media (max-width: 700px) {
            #unified-extensions-panel .unified-extensions-item[pinned] {
              display: none !important;
            }
          }

          /* Hide addons panel when window width is 300px or less */
          @media (max-width: 300px) {
            #unified-extensions-button {
              display: none !important;
            }
          }

          /* Hide forward/backward arrows when space is limited */
          @media (max-width: 400px) {
            #forward-button {
              display: none !important;
            }
          }
          @media (max-width: 150px) {
            #back-button {
              display: none !important;
            }
          }
            
          /* Hide hamburger menu and refresh button when extremely limited */
          @media (max-width: 200px) {
            #PanelUI-button,
            #reload-button {
              display: none !important;
            }
          }

          /* Allow addons toolbar to be hidden */
          #nav-bar-customization-target {
            min-height: 0 !important;
          }

          /* Allow window to shrink to 0 */
          :root {
            min-width: 0 !important;
            min-height: 0 !important;
          }

          :root {
            --toolbar-bgcolor: #${palette.base00};
            --toolbar-color: #${palette.base05};
            --toolbar-border-color: #${palette.base03};

            /* Adds a gradient outline to selected tab. This is going to need modifications if you use tabs that don't follow Proton styling. */

            .tab-background[selected]{
              outline: none !important;
              border: 2px solid transparent !important;
              box-shadow: none !important;
              background-clip: padding-box;
            }
            .tab-background[selected] > .tab-context-line{ margin: -5px 0 0 !important; }
            .tabbrowser-tab[selected] > .tab-stack::before{
              content: "";
              display: flex;
              min-height: inherit;
              border-radius: var(--tab-border-radius);
              grid-area: 1/1;
              margin-block: var(--tab-block-margin);
              /* Edit gradient colors here */
              /* background: repeat linear-gradient(45deg,#${palette.base03},#${palette.base08},#${palette.base0C},#${palette.base0E},#${palette.base0B},#${palette.base09})!important; */
              background-color: #${palette.base07} !important;
            }
          }

          #navigator-toolbox,
          #nav-bar,
          #PersonalToolbar,
          #toolbar-menubar,
          #titlebar,
          #sidebar-box,
          #sidebar-header,
          #sidebar {
            background-color: var(--toolbar-bgcolor) !important;
            color: var(--toolbar-color) !important;
            border-color: var(--toolbar-border-color) !important;
          }

          /* disable tab bars */
          #TabsToolbar {
            display: none !important;
          }

          /* Hide the "Extension (B...t Startpage)" element */
          #identity-box {
            display: none !important;
          }
          /* Change the background color of the search bar when active */
          #urlbar-background {
            background-color: #${palette.base01} !important;
          }
          
          /* Change the text color of the search bar when active */
          #urlbar-input {
            color: #${palette.base05} !important;
          }
          
          /* Add a subtle border to the search bar when active */
          #urlbar[focused="true"] > #urlbar-background {
            border: 1px solid #${palette.base0D} !important;
            box-shadow: 0 0 3px #${palette.base0D} !important;
          }

          /* Add this new rule for the menu panel */
          #appMenu-popup {
            --arrowpanel-background: #${palette.base00} !important;
            --arrowpanel-color: #${palette.base05} !important;
          }

          /* Change the background color of the customize toolbar page */
          #customization-container {
            background-color: #${palette.base00} !important;
          }

          /* Style for the customize toolbar button */
          #customization-done-button {
            background-color: #${palette.base02} !important;
            color: #${palette.base05} !important;
            border-color: #${palette.base03} !important;
          }

          #customization-done-button:hover {
            background-color: #${palette.base03} !important;
            border-color: #${palette.base0D} !important;
          }

          #customization-done-button:active {
            background-color: #${palette.base04} !important;
          }

          /* Hide toolbar context menu */
          #toolbar-context-menu {
            display: none !important;
          }

          /* Style the urlbar results popup */
          /* .urlbarView {
            background-color: #${palette.base00} !important;
            color: #${palette.base05} !important;
          } */

          /* Style individual result items */
          .urlbarView-row {
            color: #${palette.base05} !important;
          }

          /* Style the selected result */
          .urlbarView-row[selected] {
            background-color: #${palette.base02} !important;
            color: #${palette.base06} !important;
          }

          /* Style the search engine icon */
          .urlbarView-type-icon {
            fill: #${palette.base05} !important;
          }

          /* Style the "Search with" text */
          .urlbarView-action {
            color: #${palette.base04} !important;
          }

          /* Style the extensions popup background */
          #unified-extensions-view,
          .panel-arrowcontent {
            background-color: #${palette.base00} !important;
          }

          /* Style the individual extension items */
          .unified-extensions-item {
            background-color: #${palette.base00} !important;
            color: #${palette.base05} !important;
          }

          .unified-extensions-item:hover {
            background-color: #${palette.base01} !important;
          }

          /* Style the "Manage extensions" button at the bottom */
          #unified-extensions-manage-extensions {
            background-color: #${palette.base01} !important;
            color: #${palette.base05} !important;
          }

          #unified-extensions-manage-extensions:hover {
            background-color: #${palette.base02} !important;
          }

          /* Add this new rule for addon icons */
          .webextension-browser-action {
            filter: grayscale(100%) brightness(1.2) contrast(1.2) opacity(0.7) drop-shadow(0 0 0 #${palette.base05}) !important;
          }

          /* Style the sidebar title and context menu */
          #sidebar-header,
          #sidebar-switcher-target,
          #viewButton {
            background-color: #${palette.base00} !important;
            color: #${palette.base05} !important;
          }

          #sidebar-switcher-target:hover,
          #viewButton:hover {
            background-color: #${palette.base01} !important;
          }

          /* Style the sidebar context menu */
          #sidebarMenu-popup {
            --arrowpanel-background: #${palette.base00} !important;
            --arrowpanel-color: #${palette.base05} !important;
            --arrowpanel-border-color: #${palette.base03} !important;
          }

          #sidebarMenu-popup menuitem:hover {
            background-color: #${palette.base01} !important;
          }

          /* Style the sidebar itself */
          #sidebar-box,
          #sidebar {
            background-color: #${palette.base00} !important;
            color: #${palette.base05} !important;
          }

          /* Style for permission prompts */
          .popup-notification-panel {
            background-color: #${palette.base01} !important;
            color: #${palette.base05} !important;
            border: none !important;
            border-radius: 8px !important;
          }

          .popup-notification-body,
          .popup-notification-footer,
          .popup-notification-content,
          .popup-notification-header {
            background-color: transparent !important;
            color: #${palette.base05} !important;
          }

          /* Ensure buttons are visible */
          .popup-notification-primary-button,
          .popup-notification-secondary-button {
            display: inline-block !important;
          }
          
          /* Ensure only the notification background is set correctly */
          .popup-notification-panel *:not(.popup-notification-button):not(.popup-notification-primary-button):not(.popup-notification-secondary-button):not(.popup-notification-button *):not(.popup-notification-primary-button *):not(.popup-notification-secondary-button *):not(.text-link):not(.checkbox-check):not(.checkbox-label) {
            background-color: #${palette.base00} !important;
          }

          /* Style for both buttons */
          .popup-notification-button {
            background-color: #${palette.base02} !important;
            color: #${palette.base05} !important;
            border: none !important;
            border-radius: 4px !important;
            margin: 4px !important;
            padding: 6px 12px !important;
          }

          /* Style for the "Allow" (primary) button */
          .popup-notification-primary-button {
            background-color: #${palette.base0D} !important;
            color: #${palette.base00} !important;
          }

          .popup-notification-primary-button:hover {
            background-color: #${palette.base0C} !important;
          }

          /* Style for the "Block" (secondary) button */
          .popup-notification-secondary-button:hover {
            background-color: #${palette.base03} !important;
          }

          .checkbox-check {
            background-color: transparent !important;
            border: 1px solid #${palette.base04} !important;
          }

          .checkbox-label {
            color: #${palette.base04} !important;
          }

          /* Style for the "Learn more" link */
          .text-link {
            color: #${palette.base0D} !important;
          }

          .text-link:hover {
            color: #${palette.base0C} !important;
            text-decoration: none !important;
          }

          /* Additional styles to ensure full coverage */
          .panel-arrowcontent,
          .panel-arrowbox,
          .panel-arrow {
            background-color: #${palette.base00} !important;
          }

          /* Style for warning messages */
          .message-bar,
          .message-bar-content,
          .message-bar-button {
            background-color: #${palette.base00} !important;
            color: #${palette.base05} !important;
          }

          /* Ensure any overlays or additional panels are styled */
          .panel-viewstack,
          .panel-mainview,
          .panel-subview {
            background-color: #${palette.base00} !important;
            color: #${palette.base05} !important;
          }
        '';
        userContent = ''
          @-moz-document url("about:newtab") {
            body {
              background-image: url("${./../../extraConfig/wallpapers/sweden.png}") !important;
              background-size: cover !important;
              background-position: center !important;
            }
          }
        '';
        bookmarks = {};
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          enhancer-for-youtube # non-free
          sponsorblock
          ublock-origin
          istilldontcareaboutcookies
          bitwarden
          tampermonkey
          return-youtube-dislikes
          re-enable-right-click
          privacy-badger
          unpaywall
          languagetool
          ff2mpv
          link-cleaner
          hover-zoom-plus
          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "bonjourr";
            version = "20.1.2";
            addonId = "{4f391a9e-8717-4ba6-a5b1-488a34931fcb}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4362336/bonjourr_startpage-20.1.2.xpi"; # must be .xpi link
            sha256 = "sha256-wO6AbhBIKvq2Xjwn0jsyIjV9m7DouGu5g2macs0BtaY=";
            meta = {
              homepage = "https://bonjourr.fr/";
              description = "Minimalist and lightweight startpage; Improve your web browsing experience with Bonjourr, a beautiful, customizable and lightweight homepage inspired by iOS.";
              license = lib.licenses.gpl3;
              mozPermissions = [
                # "storage"
                # "unlimitedStorage"
                "bookmarks"
              ];
              platforms = lib.platforms.all;
            };
          })

          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "unhook";
            version = "1.6.7";
            addonId = "myallychou@gmail.com";
            url = "https://addons.mozilla.org/firefox/downloads/file/4210197/youtube_recommended_videos-1.6.7.xpi"; # must be .xpi link
            sha256 = "sha256-wqMjrRL3LYh6UbAZx0j6y9yHsvcSOBOfy+oOKxCgTQQ=";
            meta = {
              homepage = "https://unhook.app/";
              description = "Hide YouTube distractions including related videos, comments, suggestions, and trending content.";
              license = lib.licenses.unfree;
              mozPermissions = ["storage"];
              platforms = lib.platforms.all;
            };
          })

          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "sidebery";
            version = "5.2.0";
            addonId = "{3c078156-979c-498b-8990-85f7987dd929}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4230615/sidebery-5.2.0.xpi";
            sha256 = "sha256-mfW67Xe3jOEH2FihIz1esf62O1Pzkqt1n23n5P1QUpk=";
            meta = {
              homepage = "https://github.com/mbnuqw/sidebery";
              description = "Sidebery - Vertical tabs with tree-like bookmarks";
              license = lib.licenses.mpl20;
              mozPermissions = [
                "tabs"
                "storage"
                "menus"
                "bookmarks"
                "sessions"
                "contextualIdentities"
                "cookies"
              ];
              platforms = lib.platforms.all;
            };
          })

          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "hide-youtube-thumbnails";
            version = "2.5.0";
            addonId = "{17c4514d-71fa-4633-8c07-1fe0b354c885}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4176136/hide_youtube_thumbnails-2.5.0.xpi"; # must be .xpi link
            sha256 = "sha256-daaVXCy1Q4TOWRQm40qW7mbModMuLuAkSwn7466uhbY=";
            meta = {
              homepage = "https://github.com/domdomegg/hideytthumbnails-extension";
              description = "A simple browser extension which removes thumbnails from YouTube, for less clickbaity browsing.";
              license = lib.licenses.mit;
              mozPermissions = ["storage"];
              platforms = lib.platforms.all;
            };
          })
          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "YouTube Windowed FullScreen";
            version = "4.2";
            addonId = "{59c55aed-bdb3-4f2f-b81d-27011a689be6}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4321745/youtube_window_fullscreen-4.2.xpi"; # must be .xpi link
            sha256 = "sha256-GUGlkylH6FDBtbHNkYQG//YDuS72+s1PqRvwFIB42hU=";
            meta = {
              homepage = "https://github.com/domdomegg/hideytthumbnails-extension";
              description = "Watch videos on YouTube fullscreen within your browsers screen.";
              license = lib.licenses.mpl20;
              mozPermissions = ["storage"];
              platforms = lib.platforms.all;
            };
          })
        ];

        # ~/.mozilla/firefox/PROFILE_NAME/prefs.js | user.js
        settings = {
          "app.normandy.first_run" = false;
          "app.shield.optoutstudies.enabled" = false;
          "app.update.channel" = "default";
          "browser.aboutConfig.showWarning" = false;
          "browser.bookmarks.showMobileBookmarks" = true;
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.contentblocking.category" = "standard";
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "browser.disableResetPrompt" = true;
          "browser.display.suppress_canvas_background_image_on_forced_colors" = true;
          "browser.download.panel.shown" = true;
          "browser.download.useDownloadDir" = false;
          "browser.download.viewableInternally.typeWasRegistered.svg" = true;
          "browser.download.viewableInternally.typeWasRegistered.webp" = true;
          "browser.download.viewableInternally.typeWasRegistered.xml" = true;
          "browser.fullscreen.autohide" = false;
          "browser.link.open_newwindow" = 3; # Open links in new tabs
          "browser.newtabpage.activity-stream.newNewtabExperience.colors" = "#${palette.base0D},#${palette.base08},#${palette.base0B},#${palette.base09},#${palette.base0E},#${palette.base0A},#${palette.base0F}";
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.search.isUS" = true;
          "browser.search.region" = "US";
          "browser.search.widget.inNavBar" = true;
          "browser.sessionstore.resume_from_crash" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          "browser.startup.homepage" = "moz-extension://9d877b4e-2fe9-4689-b41a-566a02359dd1/index.html";
          "browser.tabs.inTitlebar" =
            if pkgs.stdenv.isDarwin
            then 1
            else 0; # Set 0 for Default OS titlebar, 1 for no titlebar
          "browser.tabs.loadInBackground" = true;
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.warnOnCloseOtherTabs" = false;
          "browser.tabs.tabmanager.enabled" = false;
          "browser.warnOnQuit" = false;
          "browser.warnOnQuitShortcut" = false;
          "browser.uiCustomization.state" = ''{"placements":{"nav-bar":["_3c078156-979c-498b-8990-85f7987dd929_-browser-action","back-button","forward-button","stop-reload-button","urlbar-container","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"TabsToolbar":["tabbrowser-tabs","new-tab-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","TabsToolbar"],"currentVersion":18}'';
          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.urlbar.quickactions.enabled" = false;
          "browser.urlbar.quickactions.showPrefs" = false;
          "browser.urlbar.shortcuts.quickactions" = false;
          "browser.urlbar.showSearchSuggestionsFirst" = false;
          "browser.urlbar.suggest.quickactions" = false;
          "doh-rollout.balrog-migration-done" = true;
          "doh-rollout.doneFirstRun" = true;
          "dom.forms.autocomplete.formautofill" = false;
          "dom.security.https_only_mode" = true;
          "distribution.searchplugins.defaultLocale" = "en-US";
          "editor.use_custom_colors" = false;
          "extensions.activeThemeID" = "default-theme@mozilla.org"; # Use system theme
          "extensions.autoDisableScopes" = 0;
          "extensions.update.enabled" = true; # is that bad?
          "extensions.webcompat.enable_picture_in_picture_overrides" = true;
          "extensions.webcompat.enable_shims" = true;
          "extensions.webcompat.perform_injections" = true;
          "extensions.webcompat.perform_ua_overrides" = true;
          "font.default.x-western" = "JetBrains Mono";
          "font.name.serif.x-western" = "JetBrains Mono";
          "font.name.sans-serif.x-western" = "JetBrains Mono";
          "font.name.monospace.x-western" = "JetBrains Mono";
          "font.size.variable.x-western" = 16;
          "font.size.fixed.x-western" = 13;
          "browser.display.use_document_fonts" = 0;
          "full-screen-api.warning.delay" = 0;
          "full-screen-api.warning.timeout" = 0;
          "general.autoScroll" = true;
          "general.useragent.locale" = "en-US";
          "identity.fxaccounts.enabled" = true;
          "layout.css.forced-colors.enabled" = true;
          "layout.css.inverted-colors.enabled" = false;
          "layout.css.osx-font-smoothing.enabled" = true;
          "network.proxy.socks_remote_dns" = true;
          "pdfjs.forcePageColors" = false;
          "pdfjs.highlightEditorColors" = "yellow=#${palette.base0A},green=#${palette.base0B},blue=#${palette.base0D},pink=#${palette.base0E},red=#${palette.base08}";
          "pdfjs.pageColorsBackground" = "#${palette.base00}";
          "pdfjs.pageColorsForeground" = "#${palette.base05}";
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.webrtc.sharedTabWarning" = true;
          "reader.colors_menu.enabled" = false;
          "reader.custom_colors.background" = "#${palette.base00}";
          "reader.custom_colors.foreground" = "#${palette.base05}";
          "reader.custom_colors.selection-highlight" = "#${palette.base0A}";
          "reader.custom_colors.unvisited-links" = "#${palette.base0D}";
          "reader.custom_colors.visited-links" = "#${palette.base0E}";
          "permissions.fullscreen.allowed" = true;
          "security.webauth.u2f" = true;
          "security.webauth.webauthn" = true;
          "security.webauth.webauthn_enable_softtoken" = true;
          "security.webauth.webauthn_enable_usbtoken" = true;
          "signon.rememberSignons" = true;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "ui.use_standins_for_native_colors" = false;
          "webgl.colorspaces.prototype" = false;
          # "widget.gtk.libadwaita-colors.enabled" = true;
          # "widget.gtk.theme-scrollbar-colors.enabled" = true;
          # "widget.gtk.theme-scrollbar-colors.scrollbar-color" = "#${palette.base00}";
          # "widget.gtk.theme-scrollbar-colors.scrollbar-color-hover" = "#${palette.base02}";
          # "widget.gtk.theme-scrollbar-colors.scrollbar-color-active" = "#${palette.base0D}";

          # Firefox Color settings
          "browser.display.use_system_colors" = false;
          "browser.display.background_color" = "#${palette.base00}";
          "browser.display.foreground_color" = "#${palette.base05}";
          "browser.display.focus_background_color" = "#${palette.base0D}";
          "browser.display.focus_text_color" = "#${palette.base05}";
          "browser.display.document_color_use" = 2; # Override the colors specified by the page with your selections above
          "browser.anchor_color" = "#${palette.base0D}";
          "browser.visited_color" = "#${palette.base0E}";
          "browser.active_color" = "#${palette.base0B}";
          "browser.hover_color" = "#${palette.base0A}";
          "browser.text_color" = "#${palette.base05}";
          "browser.text_background_color" = "#${palette.base00}";
          "browser.text_anchor_color" = "#${palette.base0D}";
          "browser.text_visited_color" = "#${palette.base0E}";
          "browser.text_active_color" = "#${palette.base0B}";
          "browser.text_hover_color" = "#${palette.base0A}";
          "browser.text_selection_color" = "#${palette.base0A}";
          "browser.text_highlight_color" = "#${palette.base0B}";
          "browser.text_link_color" = "#${palette.base0D}";
          "browser.text_visited_link_color" = "#${palette.base0E}";
          "browser.text_active_link_color" = "#${palette.base0B}";
          "browser.text_hover_link_color" = "#${palette.base0A}";
          "browser.textfield_color" = "#${palette.base05}";
          "browser.textfield_background_color" = "#${palette.base00}";
          "browser.textfield_border_color" = "#${palette.base03}";
          "browser.textfield_placeholder_color" = "#${palette.base04}";
          "browser.textfield_focus_color" = "#${palette.base06}";
          "browser.textfield_focus_background_color" = "#${palette.base01}";
          "browser.textfield_focus_border_color" = "#${palette.base0D}";
          "browser.textfield_disabled_color" = "#${palette.base02}";
          "browser.textfield_disabled_background_color" = "#${palette.base01}";
          "browser.textfield_disabled_border_color" = "#${palette.base03}";
          "browser.textfield_selection_color" = "#${palette.base0A}";
          "browser.textfield_highlight_color" = "#${palette.base0B}";
          "browser.textfield_link_color" = "#${palette.base0D}";
          "browser.textfield_visited_link_color" = "#${palette.base0E}";
          "browser.textfield_active_link_color" = "#${palette.base0B}";
          "browser.textfield_hover_link_color" = "#${palette.base0A}";
          "browser.button_text_color" = "#${palette.base05}";
          "browser.button_background_color" = "#${palette.base00}";
          "browser.button_border_color" = "#${palette.base03}";
          "browser.button_hover_text_color" = "#${palette.base06}";
          "browser.button_hover_background_color" = "#${palette.base01}";
          "browser.button_hover_border_color" = "#${palette.base0D}";
          "browser.button_active_text_color" = "#${palette.base05}";
          "browser.button_active_background_color" = "#${palette.base00}";
          "browser.button_active_border_color" = "#${palette.base03}";
          "browser.button_disabled_text_color" = "#${palette.base02}";
          "browser.button_disabled_background_color" = "#${palette.base01}";
          "browser.button_disabled_border_color" = "#${palette.base03}";
          "browser.menu_text_color" = "#${palette.base05}";
          "browser.menu_background_color" = "#${palette.base00}";
          "browser.menu_border_color" = "#${palette.base03}";
          "browser.menu_hover_text_color" = "#${palette.base06}";
          "browser.menu_hover_background_color" = "#${palette.base01}";
          "browser.menu_hover_border_color" = "#${palette.base0D}";
          "browser.menu_active_text_color" = "#${palette.base05}";
          "browser.menu_active_background_color" = "#${palette.base00}";
          "browser.menu_active_border_color" = "#${palette.base03}";
          "browser.menu_disabled_text_color" = "#${palette.base02}";
          "browser.menu_disabled_background_color" = "#${palette.base01}";
          "browser.menu_disabled_border_color" = "#${palette.base03}";
        };
      };
    };

    policies = {
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;
      DisableBuiltinPDFViewer = true;
      DisableFirefoxAccounts = false;
      DisableFirefoxScreenshots = true;
      DisableFirefoxStudies = true;
      DisableForgetButton = true;
      DisableFormHistory = true;
      DisableMasterPasswordCreation = true;
      DisablePasswordReveal = true;
      DisablePocket = true;
      DisableProfileImport = true;
      DisableProfileRefresh = true;
      DisableSetDesktopBackground = true;
      DisableTelemetry = true;
      DisplayMenuBar = "default-off";
      DontCheckDefaultBrowser = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        EmailTracking = true;
        Fingerprinting = true;
      };
      EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };
      "3rdparty".Extensions = {
        # https://github.com/libredirect/browser_extension/blob/b3457faf1bdcca0b17872e30b379a7ae55bc8fd0/src/config.json
				"7esoorv3@alefvanoon.anonaddy.me" = {
					# FIXME(Krey): This doesn't work
					services.youtube.options.enabled = true;
				};
        # https://github.com/gorhill/uBlock/blob/master/platform/common/managed_storage.json
        "uBlock0@raymondhill.net".adminSettings = {
					userSettings = rec {
						uiTheme = "auto";
						uiAccentCustom = true;
						uiAccentCustom0 = "#${palette.base0D}";
						cloudStorageEnabled = mkForce false; # Security liability?
						importedLists = [
							"https://filters.adtidy.org/extension/ublock/filters/3.txt"
							"https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
						];
						externalLists = lib.concatStringsSep "\n" importedLists;
					};
					selectedFilterLists = [
						"CZE-0"
						"adguard-generic"
						"adguard-annoyance"
						"adguard-spyware-url"
						"easylist"
						"easyprivacy"
						"https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
						"plowe-0"
						"ublock-abuse"
						"ublock-badware"
						"ublock-filters"
						"ublock-privacy"
						"ublock-quick-fixes"
						"ublock-unbreak"
						"urlhaus-1"
          ];
        };
        # FIXME: Bonjourr settings BROKEN AT THE MOMENT!
        "bonjourr-startpage@{4f391a9e-8717-4ba6-a5b1-488a34931fcb}" = {
          about = {
            browser = "firefox";
            version = "20.1.2";
          };
          showall = true;
          lang = "en";
          dark = "system";
          favicon = "";
          tabtitle = "";
          greeting = "Alex";
          pagegap = {
          };
          pagewidth = 1000;
          time = true;
          main = true;
          dateformat = "eu";
          background_blur = 15;
          background_bright = {
          };
          background_type = "unsplash";
          quicklinks = true;
          syncbookmarks = null;
          textShadow = {
          };
          announcements = "major";
          review = -1;
          css = "#credit, #credit-container, #author {\n  display: none;\n}";
          hide = {
            greetings = false;
            settingsicon = false;
          };
          linkstyle = "large";
          linktitles = true;
          linkbackgrounds = true;
          linknewtab = false;
          linksrow = 6;
          linksimkepk = {
            _id = "linksimkepk";
            order = 8;
            title = "Nix Pills";
            url = "https://nixos.org/guides/nix-pills/";
            parent = "linksldfolj";
          };
          linksfmmckl = {
            _id = "linksfmmckl";
            order = 1;
            title = "NURpkgs Search";
            url = "https://nur.nix-community.org/";
            parent = "linksldfolj";
          };
          linkshmppjl = {
            _id = "linkshmppjl";
            order = 7;
            title = "NixVim";
            url = "https://nix-community.github.io/nixvim/plugins/lsp/servers/java-language-server/index.html#pluginslspserversjava-language-serverinstalllanguageserver";
            parent = "linksldfolj";
            icon = "https://avatars.githubusercontent.com/u/33221035";
          };
          linksfloiam = {
            _id = "linksfloiam";
            order = 15;
            title = "Lucid Charts";
            url = "https://lucid.app/documents";
            parent = "default";
          };
          linksinckeo = {
            _id = "linksinckeo";
            order = 12;
            title = "Azure Portal";
            url = "https://portal.azure.com/";
            parent = "default";
          };
          linkscigplp = {
            _id = "linkscigplp";
            order = 1;
            title = "Canvas";
            url = "https://canvas.umt.edu/";
            parent = "default";
            icon = "https://api.bonjourr.fr/favicon/blob/https://canvas.umt.edu/";
          };
          linksadjdgc = {
            _id = "linksadjdgc";
            order = 10;
            title = "WeBWorK";
            url = "https://webwork.umt.edu/webwork2/273-Multivar-Calculus_McKinnie_2024F";
            parent = "default";
          };
          linksdibolf = {
            _id = "linksdibolf";
            order = 4;
            title = "Home-Manager Options";
            url = "https://mipmip.github.io/home-manager-option-search/";
            parent = "linksldfolj";
            icon = "https://static-00.iconduck.com/assets.00/nixos-icon-1024x889-h69qc7j9.png";
          };
          linksdljokb = {
            _id = "linksdljokb";
            order = 32;
            title = "iOS Dev GUIDE NVIM";
            url = "https://wojciechkulik.pl/ios/the-complete-guide-to-ios-macos-development-in-neovim";
            parent = "default";
            icon = "https://wojciechkulik.pl/wp-content/uploads/2015/10/1446182122_binary.gif";
          };
          linkseeqmfq = {
            _id = "linkseeqmfq";
            order = 14;
            title = "LinkedIn";
            url = "https://linkedin.com/";
            parent = "default";
            icon = "https://upload.wikimedia.org/wikipedia/commons/8/81/LinkedIn_icon.svg";
          };
          linkselinko = {
            _id = "linkselinko";
            order = 1;
            title = "Outlook";
            url = "https://outlook.office.com/mail/";
            parent = "default";
            icon = "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSCTKO5yo-6Ge3fSKkx-i9c5zM_etIVloy0phNKM8hfRjkosSP3";
          };
          linkseoccka = {
            _id = "linkseoccka";
            order = 0;
            title = ".dotfiles";
            url = "https://github.com/aspauldingcode/.dotfiles";
            parent = "default";
            icon = "https://github.githubassets.com/apple-touch-icon-144x144.png";
          };
          linksepehlp = {
            _id = "linksepehlp";
            order = 9;
            title = "Princeton";
            url = "https://algs4.cs.princeton.edu/home/";
            parent = "default";
            icon = "https://algs4.cs.princeton.edu/cover.png";
          };
          linksepjhpa = {
            _id = "linksepjhpa";
            order = 37;
            title = "gif converter";
            url = "https://ezgif.com/video-to-gif";
            parent = "default";
          };
          linksepqjak = {
            _id = "linksepqjak";
            order = 8;
            title = "My UM";
            url = "https://www.umt.edu/my/";
            parent = "default";
            icon = "data:image/jpeg;base64,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";
          };
          linksfhgakm = {
            _id = "linksfhgakm";
            order = 20;
            title = "LeetCode";
            url = "https://leetcode.com/problemset/all/";
            parent = "default";
            icon = "https://leetcode.com/favicon.ico";
          };
          linksfhiadr = {
            _id = "linksfhiadr";
            order = 24;
            title = "Bootargs";
            url = "https://gist.github.com/startergo/ba5dbf561bf11ec6164e01a8d5d24754";
            parent = "default";
            icon = "https://www.apple.com/favicon.ico";
          };
          linksfpmpfj = {
            _id = "linksfpmpfj";
            order = 19;
            title = "iCloud Drive";
            url = "https://www.icloud.com/iclouddrive/";
            parent = "default";
            icon = "data:image/jpeg;base64,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";
          };
          linksfrpbkj = {
            _id = "linksfrpbkj";
            order = 7;
            title = "Accommodate";
            url = "http://umontana-accommodate.symplicity.com/sso/students/login";
            parent = "default";
            icon = "https://www.symplicity.com/hubfs/favicon.ico";
          };
          linkshbqhfc = {
            _id = "linkshbqhfc";
            order = 34;
            title = "12factorapps";
            url = "https://12factor.net/";
            parent = "default";
            icon = "data:image/jpeg;base64,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";
          };
          linkshclcmq = {
            _id = "linkshclcmq";
            order = 1;
            title = "NixOS Options";
            url = "https://search.nixos.org/options";
            parent = "linksldfolj";
            icon = "https://static-00.iconduck.com/assets.00/nixos-icon-1024x889-h69qc7j9.png";
          };
          linkshgmmjp = {
            _id = "linkshgmmjp";
            order = 2;
            title = "Gmail";
            url = "https://mail.google.com/mail/u/0/#inbox";
            parent = "default";
            icon = "https://ssl.gstatic.com/ui/v1/icons/mail/rfr/gmail.ico";
          };
          linksiegero = {
            _id = "linksiegero";
            order = 31;
            title = "nvim xcodebuild";
            url = "https://github.com/wojciech-kulik/xcodebuild.nvim?tab=readme-ov-file#-commands";
            parent = "default";
            icon = "https://github.githubassets.com/assets/apple-touch-icon-144x144-b882e354c005.png";
          };
          linksiihmkl = {
            _id = "linksiihmkl";
            order = 22;
            title = "pastee";
            url = "https://paste.ee/";
            parent = "default";
            icon = "https://www.svgrepo.com/show/493651/clipboard-copy-memory-editor-copy-paste.svg";
          };
          linksimierl = {
            _id = "linksimierl";
            order = 28;
            title = "3blue1brown";
            url = "https://www.3blue1brown.com/lessons/derivatives-power-rule";
            parent = "default";
            icon = "https://www.3blue1brown.com/favicons/favicon.png";
          };
          linksjdfqgo = {
            _id = "linksjdfqgo";
            order = 25;
            title = "Implement DRM";
            url = "https://github.com/dvdhrm/docs/tree/master/drm-howto";
            parent = "default";
            icon = "https://github.com/favicon.ico";
          };
          linksjmobmp = {
            _id = "linksjmobmp";
            order = 0;
            title = "vim keybinds to know";
            url = "https://scaron.info/blog/vim-keyboard-shortcuts.html";
            parent = "linksrnqbhm";
            icon = "https://scaron.info/theme/images/favicon.ico";
          };
          linkskfqprf = {
            _id = "linkskfqprf";
            order = 3;
            title = "NixMobile Options";
            url = "https://mobile.nixos.org/options/index.html";
            parent = "linksldfolj";
            icon = "https://static-00.iconduck.com/assets.00/nixos-icon-1024x889-h69qc7j9.png";
          };
          linkskiclnh = {
            _id = "linkskiclnh";
            order = 29;
            title = "OP6T-ROMS PE";
            url = "https://get.pixelexperience.org/fajita";
            parent = "default";
            icon = "https://get.pixelexperience.org/favicon-96x96.png";
          };
          linkslaaede = {
            _id = "linkslaaede";
            order = 16;
            title = "Word";
            url = "https://www.microsoft365.com/launch/word?auth=2";
            parent = "default";
            icon = "https://seeklogo.com/images/M/microsoft-word-logo-E648C182A5-seeklogo.com.png";
          };
          linksldfolj = {
            _id = "linksldfolj";
            order = 26;
            title = "";
            parent = "default";
            folder = true;
          };
          linksljkpep = {
            _id = "linksljkpep";
            order = 1;
            title = "NixVim LSPs";
            url = "https://nix-community.github.io/nixvim/plugins/lsp/servers/java-language-server/index.html#pluginslspserversjava-language-serverinstalllanguageserver";
            parent = "linksrnqbhm";
            icon = "data:image/svg+xml;base64,PHN2ZyBoZWlnaHQ9IjI2MiIgdmlld0JveD0iMCAwIDI2MiAyNjIiIHdpZHRoPSIyNjIiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGcgZmlsbD0ibm9uZSIgZmlsbC1ydWxlPSJldmVub2RkIj48cmVjdCBmaWxsPSIjZDhkOGQ4IiBoZWlnaHQ9IjI2MiIgcng9IjUyIiB3aWR0aD0iMjYyIi8+PGcgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMzMuNzIyMzIxIDM2LjI0MDE4MSkiPjxwYXRoIGQ9Im0xMTguNjQ0NDExLjYyNTk3NDUyYzguMDU5NiAxLjg2MDcwNTM2IDE0LjI0MjM0MyA3LjU0NDcwMDIzIDE3LjA3NDc0NCAxNC42OTM5MTUyOCA3LjM3NjY5Mi0yLjE2OTcyMjcgMTUuNjYyNTctLjc5NzE1NjcgMjIuMDkxMDM0IDQuNDA4NTExMiA2LjEzOTU5OCA0Ljk3MTc0ODEgOS4yMTE0OTQgMTIuMzI3NjQyNiA4Ljk2MjQ2IDE5LjY1ODM2NzkgNy4xOTg1OCAxLjQwNTg3MzQgMTMuNjc0Njc2IDYuMDUzNjk4IDE3LjEzNzgwMiAxMy4xNTQxNTggMy42MjYwNCA3LjQzNDQ4NDkgMy4wOTk2NjEgMTUuODE2NDU2Ny0uNjczODYyIDIyLjUxNjgwMDkgNi4zMjg3NjYgNC4zNjc2OTA1IDEwLjQ3NjMxMSAxMS42NzA2MjU4IDEwLjQ3NjMxMSAxOS45NDIyNzIyIDAgOC4yNzE2NDYtNC4xNDc1NDUgMTUuNTc0NTgyLTEwLjQ3NjQzNCAxOS45NDI2MDMgMy43NzM2NDYgNi43MDAwMTMgNC4zMDAwMjUgMTUuMDgxOTg1LjY3Mzk4NSAyMi41MTY0Ny0zLjQ2MzEyNiA3LjEwMDQ2LTkuOTM5MjIyIDExLjc0ODI4NS0xNy4xMzc4NjMgMTMuMTU0ODE3LjI0OTA5NSA3LjMzMDA2Ni0yLjgyMjgwMSAxNC42ODU5NjEtOC45NjIzOTkgMTkuNjU3NzA5LTYuNDI4NDY0IDUuMjA1NjY4LTE0LjcxNDM0MiA2LjU3ODIzNC0yMi4wOTE5OTQgNC40MDgzNzgtMi44MzE0NDEgNy4xNDkzNDgtOS4wMTQxODQgMTIuODMzMzQzLTE3LjA3Mzc4NCAxNC42OTQwNDgtOC4wNTk1MjEgMS44NjA2ODctMTYuMTA4MTUzLS41Mzc2NTEtMjEuNzg3ODk3Ny01LjcyMTU3My01LjY3OTg3MTYgNS4xODM5MjItMTMuNzI4NTAzNyA3LjU4MjI2LTIxLjc4ODAyMzggNS43MjE1NzMtOC4wNTk2MDA0LTEuODYwNzA1LTE0LjI0MjM0MzUtNy41NDQ3LTE3LjA3NDc0NDItMTQuNjkzOTE1LTcuMzc2NjkxOCAyLjE2OTcyMy0xNS42NjI1Njk4Ljc5NzE1Ny0yMi4wOTEwMzQzLTQuNDA4NTExLTYuMTM5NTk3Ni00Ljk3MTc0OC05LjIxMTQ5NDItMTIuMzI3NjQzLTguOTYyNDYwNC0xOS42NTgzNjgtNy4xOTg1NzkyLTEuNDA1ODczLTEzLjY3NDY3NTUtNi4wNTM2OTgtMTcuMTM3ODAxMi0xMy4xNTQxNTgtMy42MjYwNDA1Ni03LjQzNDQ4NS0zLjA5OTY2MTE2LTE1LjgxNjQ1Ny42NzM4NjE0LTIyLjUxNjgwMS02LjMyODc2NTM0LTQuMzY3NjktMTAuNDc2MzEwOC0xMS42NzA2MjYtMTAuNDc2MzEwOC0xOS45NDIyNzIgMC04LjI3MTY0NjQgNC4xNDc1NDU0Ni0xNS41NzQ1ODE3IDEwLjQ3NjQzMzktMTkuOTQyNjAzNC0zLjc3MzY0NTY2LTYuNzAwMDEzLTQuMzAwMDI1MDYtMTUuMDgxOTg0OC0uNjczOTg0NS0yMi41MTY0Njk3IDMuNDYzMTI1Ny03LjEwMDQ2IDkuOTM5MjIyLTExLjc0ODI4NDYgMTcuMTM3ODYyNS0xMy4xNTQ4MTY3LS4yNDkwOTUxLTcuMzMwMDY2NiAyLjgyMjgwMTUtMTQuNjg1OTYxMSA4Ljk2MjM5OTEtMTkuNjU3NzA5MiA2LjQyODQ2NDUtNS4yMDU2Njc5IDE0LjcxNDM0MjUtNi41NzgyMzM5IDIyLjA5MTk5MzktNC40MDgzNzg0IDIuODMxNDQxMS03LjE0OTM0Nzg1IDkuMDE0MTg0Mi0xMi44MzMzNDI3MiAxNy4wNzM3ODQ2LTE0LjY5NDA0ODA4IDguMDU5NTIwMS0xLjg2MDY4Njg0IDE2LjEwODE1MjIuNTM3NjUxNDUgMjEuNzg3ODk3MyA1LjcyMTU3MzYxIDUuNjc5ODcxMi01LjE4MzkyMjE2IDEzLjcyODUwMzItNy41ODIyNjA0NSAyMS43ODgwMjQyLTUuNzIxNTczNjF6IiBmaWxsPSIjMzMzIi8+PHBhdGggZD0ibTcwLjE3NjE3ODYgNzMuMzM0OTAxNWgxMC43MjI4Njc3Yy43NjEzODctOS4wOTE2MzcyIDYuNjYyMTM2Ny0xNC42MjI5MTMgMTUuODYyMjMwMy0xNC42MjI5MTMgOC44ODI4NDk0IDAgMTQuOTczOTQ1NCA1LjQ2NzY5NzkgMTQuOTczOTQ1NCAxMy40Nzg1MTExIDAgNi42NzU2Nzc3LTIuNjY0ODU1IDEwLjY4MTA4NDMtOS45NjE0ODEgMTUuMjU4NjkxOS04LjU2NTYwNCA1LjI3Njk2NDItMTIuNDM1OTg4MiAxMC45MzUzOTU4LTEyLjMwOTA5MDMgMTkuMzkxMjU0NXY1Ljc4NTU4N2gxMS4wNDAxMTIzdi00LjEzMjU2MmMwLTYuNzM5MjU2IDIuMzQ3NjEtMTAuMjM2MDM5NSAxMC4wODgzNzktMTUuMDA0MzgwNyA4LjYyOTA1My01LjI3Njk2NDIgMTIuOTQzNTc5LTEyLjU4ODQyMDcgMTIuOTQzNTc5LTIxLjg3MDc5MTYgMC0xMy40Nzg1MTExLTEwLjk3NjY2My0yMy4wNzg3NzE0LTI2LjMzMTMwMTktMjMuMDc4NzcxNC0xNS44NjIyMzA0IDAtMjYuMjY3ODUzNSA5LjQ3MzEwNDUtMjcuMDI5MjQwNSAyNC43OTUzNzQyem0yNS4yNTI2NzA3IDY5LjA0NTU4MDVjNC44MjIxMTc3IDAgOC42OTI1MDI3LTQuMDA1NDA3IDguNjkyNTAyNy05LjAyODA1OSAwLTUuMDIyNjUzLTMuODcwMzg1LTkuMDI4MDYtOC42OTI1MDI3LTkuMDI4MDYtNC44MjIxMTggMC04LjY5MjUwMjIgNC4wMDU0MDctOC42OTI1MDIyIDkuMDI4MDYgMCA1LjAyMjY1MiAzLjg3MDM4NDIgOS4wMjgwNTkgOC42OTI1MDIyIDkuMDI4MDU5eiIgZmlsbD0iI2ZmZiIgZmlsbC1ydWxlPSJub256ZXJvIi8+PC9nPjwvZz48L3N2Zz4=";
          };
          linksmahblp = {
            _id = "linksmahblp";
            order = 11;
            title = "Coursera";
            url = "https://www.coursera.org/my-learning";
            parent = "default";
            icon = "https://d3njjcbhbojbot.cloudfront.net/web/images/favicons/apple-touch-icon-v2-144x144.png";
          };
          linksmahdfl = {
            _id = "linksmahdfl";
            order = 17;
            title = "Excel";
            url = "https://www.microsoft365.com/launch/excel?auth=2";
            parent = "default";
            icon = "https://w7.pngwing.com/pngs/469/723/png-transparent-microsoft-office-365-excel-logo-icon-thumbnail.png";
          };
          linksmgmico = {
            _id = "linksmgmico";
            order = 2;
            title = "NixDarwin Options";
            url = "https://daiderd.com/nix-darwin/manual/index.html";
            parent = "linksldfolj";
            icon = "https://static-00.iconduck.com/assets.00/nixos-icon-1024x889-h69qc7j9.png";
          };
          linksmjapbl = {
            _id = "linksmjapbl";
            order = 4;
            title = "Moodle";
            url = "https://moodle.umt.edu/my/courses.php";
            parent = "default";
            icon = "https://moodle.umt.edu/admin/tool/mobile/pix/icon_144.png";
          };
          linksnalgrp = {
            _id = "linksnalgrp";
            order = 23;
            title = "KeyCodes";
            url = "https://adventuregamestudio.github.io/ags-manual/Keycodes.html";
            parent = "default";
            icon = "https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Alacritty_logo.svg/2300px-Alacritty_logo.svg.png";
          };
          linksohmmeb = {
            _id = "linksohmmeb";
            order = 21;
            title = "chatgpt";
            url = "https://chat.openai.com/";
            parent = "default";
            icon = "https://chat.openai.com/apple-touch-icon.png";
          };
          linksopdjoa = {
            _id = "linksopdjoa";
            order = 33;
            title = "SUPIR Super Upscale";
            url = "https://supir.xpixel.group/";
            parent = "default";
            icon = "https://supir.xpixel.group//./SUPIR-assets/xpixel-favicon.ico";
          };
          linkspjgghe = {
            _id = "linkspjgghe";
            order = 36;
            title = "MicroInternships";
            url = "https://info.parkerdewey.com/umt";
            parent = "default";
          };
          linkspjiakn = {
            _id = "linkspjiakn";
            order = 35;
            title = "UWP link generator";
            url = "https://store.rg-adguard.net/";
            parent = "default";
          };
          linksqjfgfp = {
            _id = "linksqjfgfp";
            order = 3;
            title = "Calendar";
            url = "https://calendar.google.com/calendar/u/0/r/week?pli=1";
            parent = "default";
            icon = "https://www.gstatic.com/calendar/images/manifest/logo_2020q4_192.png";
          };
          linksrmgale = {
            _id = "linksrmgale";
            order = 13;
            title = "Handshake";
            url = "https://umt.joinhandshake.com/stu";
            parent = "default";
            icon = "https://handshake-production-cdn.joinhandshake.com/assets/favicon-869286686b91a2c056896c603396b30a3980165ad8a12bfe2df00eb36f116dd3.ico";
          };
          linksrnehla = {
            _id = "linksrnehla";
            order = 5;
            title = "Fetchers";
            url = "https://nixos.org/manual/nixpkgs/unstable/#chap-writing-nix-expressions";
            parent = "linksldfolj";
            icon = "https://nixos.org/favicon.png";
          };
          linksrnqbhm = {
            _id = "linksrnqbhm";
            order = 27;
            parent = "default";
            folder = true;
          };
          linksronfql = {
            _id = "linksronfql";
            order = 5;
            title = "Cyberbear";
            url = "https://www.umt.edu/cyberbear/";
            parent = "default";
            icon = "data:image/png;base64,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";
          };
          linksrpiqqh = {
            _id = "linksrpiqqh";
            order = 18;
            title = "jpg2pdf";
            url = "https://jpg2pdf.com/";
            parent = "default";
            icon = "https://jpg2pdf.com/images/jpg2pdf/favicon.svg";
          };
          linksahlbcc = {
            _id = "linksahlbcc";
            order = 6;
            title = "Exceledraw";
            url = "https://excalidraw.com/";
            parent = "default";
          };
          linksbjjcoq = {
            _id = "linksbjjcoq";
            order = 15;
            title = "PostMarketOS";
            url = "https://postmarketos.org/";
            parent = "default";
            icon = "https://postmarketos.org/static/img/favicon.ico";
          };
          linksbjlcpd = {
            _id = "linksbjlcpd";
            order = 12;
            title = "Desmos";
            url = "https://www.desmos.com/calculator";
            parent = "default";
            icon = "https://www.desmos.com/assets/pwa/icon-192x192.png";
          };
          linkschoiem = {
            _id = "linkschoiem";
            order = 0;
            title = "Nixpkgs Search";
            url = "https://search.nixos.org/packages";
            parent = "linksldfolj";
            icon = "https://static-00.iconduck.com/assets.00/nixos-icon-1024x889-h69qc7j9.png";
          };
          linkscojicg = {
            _id = "linkscojicg";
            order = 10;
            title = "javadoc";
            url = "https://algs4.cs.princeton.edu/code/javadoc/edu/princeton/cs/algs4/package-summary.html";
            parent = "default";
          };
          linksdapfmi = {
            _id = "linksdapfmi";
            order = 30;
            title = "car file reverse-engineering";
            url = "https://blog.timac.org/2018/1018-reverse-engineering-the-car-file-format/";
            parent = "default";
            icon = "https://blog.timac.org/favicon.ico";
          };
          linkgroups = {
            on = true;
            selected = "default";
            groups = [
              "default"
            ];
            synced = [

            ];
            pinned = [

            ];
          };
          clock = {
            face = "number";
            ampm = true;
            analog = true;
            seconds = true;
            size = 1;
            style = "round";
            timezone = "auto";
            worldclocks = false;
          };
          analogstyle = {
            background = "#fff2";
            border = "#ffff";
            face = "number";
            shape = "round";
            hands = "modern";
          };
          worldclocks = [

          ];
          unsplash = {
            every = "tabs";
            collection = "";
            lastCollec = "night";
            pausedImage = null;
            time = 1728174390111;
          };
          weather = {
            ccode = "US";
            city = "Missoula";
            fcHigh = 36;
            fcLast = 1699416000;
            forecast = "auto";
            geolocation = "off";
            lastCall = 1699399984;
            lastState = {
              description = "overcast clouds";
              feels_like = {
              };
              icon_id = 804;
              sunrise = 1699367196;
              sunset = 1699402271;
              temp = {
              };
              temp_max = {
              };
            };
            moreinfo = "none";
            provider = "";
            temperature = "actual";
            unit = "imperial";
          };
          notes = {
            on = true;
            text = "# To-Do:\n\n[x] DISABLE GATEKEEPER!\n[ ] Set up wg-quick with wireguard vpn to use NIXSTATION64 homework and transfer files to/from NIXY:\n[ ] Sketchybar Plugins: [github](https://github.com/FelixKratz/SketchyBar/discussions/12)\n[ ] learn direnv: https://direnv.net/\n[ ] Figure out this:\n[ ] https://www.instructables.com/How-to-use-LEGO-NXT-sensors-and-motors-with-a-non-/\n\n";
            align = "left";
            opacity = {
            };
            width = 40;
          };
          searchbar = {
            on = true;
            opacity = {
            };
            engine = "google";
            newtab = false;
            placeholder = "";
            request = "";
            suggestions = true;
          };
          quotes = {
            on = true;
            author = false;
            frequency = "day";
            last = 1728169765419;
            type = "classic";
            userlist = "";
          };
          font = {
            size = "12.1";
            family = "dejavu sans mono";
            system = true;
            weight = "400";
            weightlist = [

            ];
          };
          move = {
            layouts = {
              double = {
                grid = [
                  [
                    "main"
                    "time"
                  ]
                  [
                    "searchbar"
                    "searchbar"
                  ]
                  [
                    "quicklinks"
                    "notes"
                  ]
                  [
                    "quotes"
                    "quotes"
                  ]
                ];
                items = {
                  time = {
                    text = "";
                    box = "end baseline";
                  };
                  main = {
                    text = "";
                    box = "end end";
                  };
                  quicklinks = {
                    text = "left";
                    box = "baseline end";
                  };
                  notes = {
                    text = "";
                    box = "baseline baseline";
                  };
                  searchbar = {
                    text = "";
                    box = "";
                  };
                  quotes = {
                    text = "";
                    box = "baseline center";
                  };
                };
              };
              single = {
                grid = [
                  [
                    "time"
                  ]
                  [
                    "quicklinks"
                  ]
                  [
                    "main"
                  ]
                  [
                    "quotes"
                  ]
                ];
                items = {
                  quicklinks = {
                    text = "";
                    box = "center baseline";
                  };
                };
              };
              triple = {
                grid = [
                  [
                    "."
                    "time"
                    "."
                  ]
                  [
                    "."
                    "main"
                    "."
                  ]
                  [
                    "."
                    "quicklinks"
                    "."
                  ]
                ];
                items = {
                };
              };
            };
            selection = "double";
          };
        };
      };
      extensions = {
        pdf = {
          action = "useHelperApp";
          ask = true;
          handlers = [
            {
              name = "GNOME Document Viewer";
              path = "${pkgs.evince}/bin/evince";
            }
          ];
        };
      };
      FirefoxHome = {
        Highlights = true;
        Locked = true;
        Pocket = false;
        Search = true;
        Snippets = false;
        SponsoredPocket = false;
        SponsoredTopSites = false;
        TopSites = true;
      };
      FirefoxSuggest = {
        ImproveSuggest = false;
        Locked = true;
        SponsoredSuggestions = false;
        WebSuggestions = false;
      };
      Handlers = {
        mimeTypes."application/pdf".action = "saveToDisk";
      };
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      PDFjs = {
        Enabled = false;
        EnablePermissions = false;
      };
      PictureInPicture = {
        Enabled = true;
        Locked = true;
      };
      PromptForDownloadLocation = true;
      Proxy = {
        Locked = true;
        Mode = "system";
        SOCKSProxy = "127.0.0.1:9050";
        SOCKSVersion = 5;
        UseProxyForDNS = true;
      };
      SanitizeOnShutdown = {
        Cache = true;
        Cookies = false;
        Downloads = true;
        FormData = true;
        History = false;
        Locked = true;
        OfflineApps = true;
        Sessions = false;
        SiteSettings = false;
      };
      SearchEngines = {
        Add = [
          {
            Name = "SearXNG";
            URLTemplate = "http://searx3aolosaf3urwnhpynlhuokqsgz47si4pzz5hvb7uuzyjncl2tid.onion/search?q={searchTerms}";
            Method = "GET";
            IconURL = "http://searx3aolosaf3urwnhpynlhuokqsgz47si4pzz5hvb7uuzyjncl2tid.onion/favicon.ico";
            Description = "SearX instance ran by tiekoetter.com as onion-service";
          }
        ];
        Default = "SearXNG";
        PreventInstalls = true;
        Remove = [
          "Amazon.com"
          "Bing"
          "Google"
        ];
      };
      SearchSuggestEnabled = false;
      ShowHomeButton = true;
      StartDownloadsInTempDirectory = true;
      UseSystemPrintDialog = true;
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        Locked = true;
        MoreFromMozilla = false;
        SkipOnboarding = true;
        UrlbarInterventions = false;
        WhatsNew = false;
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    "text/html" = ["firefox.desktop"];
    "text/xml" = ["firefox.desktop"];
    "x-scheme-handler/http" = ["firefox.desktop"];
    "x-scheme-handler/https" = ["firefox.desktop"];
  };
}
