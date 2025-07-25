{
  fetchurl,
  pkgs,
  lib,
  config,
  user,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (config.colorscheme) palette;
in
{
  home.packages = if pkgs.stdenv.isDarwin then [ pkgs.defaultbrowser ] else [ ];

  home.activation =
    if pkgs.stdenv.isDarwin then
      {
        setDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.defaultbrowser}/bin/defaultbrowser firefox
        '';
      }
    else
      { };

  programs.firefox = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.firefox-bin else pkgs.firefox;
    profiles = {
      ${user} = {
        userChrome =
          # CSS
          ''
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
              background-image: url("${./../../../extraConfig/wallpapers/sweden.png}") !important;
              background-size: cover !important;
              background-position: center !important;
            }
          }
        '';
        bookmarks = { };
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          # youtube fixup
          enhancer-for-youtube
          sponsorblock
          return-youtube-dislikes
          youtube-recommended-videos # unhook
          ublock-origin

          istilldontcareaboutcookies
          unpaywall
          bitwarden
          tampermonkey
          re-enable-right-click
          privacy-badger
          languagetool
          ff2mpv
          clearurls
          hover-zoom-plus
          sidebery
          xbrowsersync # sync bookmarks and everything between all browsers. YAY
          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "YouTube Windowed FullScreen";
            version = "4.11";
            addonId = "{59c55aed-bdb3-4f2f-b81d-27011a689be6}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4458289/youtube_window_fullscreen-4.11.xpi"; # must be .xpi link
            sha256 = "sha256-aKVi4jI9REFQX52BbU0L33MWnJD/7u2HKqk9wp+7ICI=";
            meta = {
              homepage = "https://github.com/domdomegg/hideytthumbnails-extension";
              description = "Watch videos on YouTube fullscreen within your browsers screen.";
              license = lib.licenses.mpl20;
              mozPermissions = [ "storage" ];
              platforms = lib.platforms.all;
            };
          })
        ];

        # ~/.mozilla/firefox/PROFILE_NAME/prefs.js | user.js
        settings = {
          "app.normandy.first_run" = false;
          "app.shield.optoutstudies.enabled" = false;
          "app.update.channel" = "default";
          "app.update.enabled" = false;
          "app.update.auto" = false;
          "app.update.silent" = false;
          "app.update.staging.enabled" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.bookmarks.showMobileBookmarks" = false;
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
          "browser.newtabpage.activity-stream.newNewtabExperience.colors" =
            "#${palette.base0D},#${palette.base08},#${palette.base0B},#${palette.base09},#${palette.base0E},#${palette.base0A},#${palette.base0F}";
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.search.isUS" = true;
          "browser.search.region" = "US";
          "browser.search.widget.inNavBar" = true;
          "browser.sessionstore.resume_from_crash" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          "browser.startup.homepage" = "moz-extension://9d877b4e-2fe9-4689-b41a-566a02359dd1/index.html";
          "browser.tabs.inTitlebar" = if pkgs.stdenv.isDarwin then 1 else 0; # Set 0 for Default OS titlebar, 1 for no titlebar
          "browser.tabs.loadInBackground" = true;
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.warnOnCloseOtherTabs" = false;
          "browser.tabs.tabmanager.enabled" = false;
          "browser.warnOnQuit" = false;
          "browser.warnOnQuitShortcut" = false;
          "browser.uiCustomization.state" =
            ''{"placements":{"nav-bar":["_3c078156-979c-498b-8990-85f7987dd929_-browser-action","back-button","forward-button","stop-reload-button","urlbar-container","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"TabsToolbar":["tabbrowser-tabs","new-tab-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","TabsToolbar"],"currentVersion":18}'';
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
          "font.default.x-western" = "JetBrainsMono Nerd Font Mono";
          "font.name.serif.x-western" = "JetBrainsMono Nerd Font Mono";
          "font.name.sans-serif.x-western" = "JetBrainsMono Nerd Font Mono";
          "font.name.monospace.x-western" = "JetBrainsMono Nerd Font Mono";
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
          "pdfjs.highlightEditorColors" =
            "yellow=#${palette.base0A},green=#${palette.base0B},blue=#${palette.base0D},pink=#${palette.base0E},red=#${palette.base08}";
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
      DisableCrashReporter = true;
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
            Name = "Google";
            URLTemplate = "https://www.google.com/search?q={searchTerms}";
            Method = "GET";
            IconURL = "https://www.google.com/favicon.ico";
            Description = "Google Search";
          }
        ];
        Default = "Google";
        PreventInstalls = true;
        Remove = [
          "Amazon.com"
          "Bing"
          "SearXNG"
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
    "text/html" = [ "firefox.desktop" ];
    "text/xml" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };
}
