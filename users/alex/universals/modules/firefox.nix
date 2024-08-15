{
  fetchurl,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkForce;
  inherit (config.colorscheme) colors;
in {
  programs.firefox = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin
      then null
      else pkgs.firefox;
    profiles = {
      alex = {
        userChrome = ''
          /* Use Nix-Colors theme */
          #navigator-toolbox {
            --toolbar-bgcolor: #${colors.base00};
          }

          :root {
            --toolbar-bgcolor: #${colors.base00};
            --toolbar-color: #${colors.base05};
            --toolbar-border-color: #${colors.base03};

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
              /* background: repeat linear-gradient(45deg,#${colors.base03},#${colors.base08},#${colors.base0C},#${colors.base0E},#${colors.base0B},#${colors.base09})!important; */
              background-color: #${colors.base07} !important;
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

        '';
        userContent = ''
          # Here too
        '';
        bookmarks = {};
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          enhancer-for-youtube # non-free
          sponsorblock
          ublock-origin
          istilldontcareaboutcookies
          bitwarden
          violentmonkey
          temporary-containers
          return-youtube-dislikes
          refined-github
          re-enable-right-click
          privacy-badger
          unpaywall
          languagetool
          ff2mpv
          link-cleaner
          hover-zoom-plus
          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "bonjourr";
            version = "19.2.4";
            addonId = "{4f391a9e-8717-4ba6-a5b1-488a34931fcb}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4266784/bonjourr_startpage-19.2.4.xpi"; # must be .xpi link
            sha256 = "sha256-UHf07ICiNMkZNCF/7xJ7YFfqy1SeeoXm/3b4+PZ1mWc=";
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
          "browser.newtabpage.activity-stream.newNewtabExperience.colors" = "#${colors.base0D},#${colors.base08},#${colors.base0B},#${colors.base09},#${colors.base0E},#${colors.base0A},#${colors.base0F}";
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.search.isUS" = true;
          "browser.search.region" = "US";
          "browser.search.widget.inNavBar" = true;
          "browser.sessionstore.resume_from_crash" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          # "browser.startup.homepage" = "https://searx.aicampground.com";
          "browser.tabs.inTitlebar" =
            if pkgs.stdenv.isDarwin
            then 1
            else 0; # Set 0 for Default OS titlebar, 1 for no titlebar
          "browser.tabs.loadInBackground" = true;
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.warnOnCloseOtherTabs" = false;
          "browser.warnOnQuit" = false;
          "browser.warnOnQuitShortcut" = false;
          "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":18,"newElementCount":4}'';
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
          "pdfjs.highlightEditorColors" = "yellow=#${colors.base0A},green=#${colors.base0B},blue=#${colors.base0D},pink=#${colors.base0E},red=#${colors.base08}";
          "pdfjs.pageColorsBackground" = "#${colors.base00}";
          "pdfjs.pageColorsForeground" = "#${colors.base05}";
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "privacy.webrtc.sharedTabWarning" = true;
          "reader.colors_menu.enabled" = false;
          "reader.custom_colors.background" = "#${colors.base00}";
          "reader.custom_colors.foreground" = "#${colors.base05}";
          "reader.custom_colors.selection-highlight" = "#${colors.base0A}";
          "reader.custom_colors.unvisited-links" = "#${colors.base0D}";
          "reader.custom_colors.visited-links" = "#${colors.base0E}";
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
          # "widget.gtk.theme-scrollbar-colors.scrollbar-color" = "#${colors.base00}";
          # "widget.gtk.theme-scrollbar-colors.scrollbar-color-hover" = "#${colors.base02}";
          # "widget.gtk.theme-scrollbar-colors.scrollbar-color-active" = "#${colors.base0D}";

          # Firefox Color settings
          "browser.display.use_system_colors" = false;
          "browser.display.background_color" = "#${colors.base00}";
          "browser.display.foreground_color" = "#${colors.base05}";
          "browser.display.focus_background_color" = "#${colors.base0D}";
          "browser.display.focus_text_color" = "#${colors.base05}";
          "browser.display.document_color_use" = 2; # Override the colors specified by the page with your selections above
          "browser.anchor_color" = "#${colors.base0D}";
          "browser.visited_color" = "#${colors.base0E}";
          "browser.active_color" = "#${colors.base0B}";
          "browser.hover_color" = "#${colors.base0A}";
          "browser.text_color" = "#${colors.base05}";
          "browser.text_background_color" = "#${colors.base00}";
          "browser.text_anchor_color" = "#${colors.base0D}";
          "browser.text_visited_color" = "#${colors.base0E}";
          "browser.text_active_color" = "#${colors.base0B}";
          "browser.text_hover_color" = "#${colors.base0A}";
          "browser.text_selection_color" = "#${colors.base0A}";
          "browser.text_highlight_color" = "#${colors.base0B}";
          "browser.text_link_color" = "#${colors.base0D}";
          "browser.text_visited_link_color" = "#${colors.base0E}";
          "browser.text_active_link_color" = "#${colors.base0B}";
          "browser.text_hover_link_color" = "#${colors.base0A}";
          "browser.textfield_color" = "#${colors.base05}";
          "browser.textfield_background_color" = "#${colors.base00}";
          "browser.textfield_border_color" = "#${colors.base03}";
          "browser.textfield_placeholder_color" = "#${colors.base04}";
          "browser.textfield_focus_color" = "#${colors.base06}";
          "browser.textfield_focus_background_color" = "#${colors.base01}";
          "browser.textfield_focus_border_color" = "#${colors.base0D}";
          "browser.textfield_disabled_color" = "#${colors.base02}";
          "browser.textfield_disabled_background_color" = "#${colors.base01}";
          "browser.textfield_disabled_border_color" = "#${colors.base03}";
          "browser.textfield_selection_color" = "#${colors.base0A}";
          "browser.textfield_highlight_color" = "#${colors.base0B}";
          "browser.textfield_link_color" = "#${colors.base0D}";
          "browser.textfield_visited_link_color" = "#${colors.base0E}";
          "browser.textfield_active_link_color" = "#${colors.base0B}";
          "browser.textfield_hover_link_color" = "#${colors.base0A}";
          "browser.button_text_color" = "#${colors.base05}";
          "browser.button_background_color" = "#${colors.base00}";
          "browser.button_border_color" = "#${colors.base03}";
          "browser.button_hover_text_color" = "#${colors.base06}";
          "browser.button_hover_background_color" = "#${colors.base01}";
          "browser.button_hover_border_color" = "#${colors.base0D}";
          "browser.button_active_text_color" = "#${colors.base05}";
          "browser.button_active_background_color" = "#${colors.base00}";
          "browser.button_active_border_color" = "#${colors.base03}";
          "browser.button_disabled_text_color" = "#${colors.base02}";
          "browser.button_disabled_background_color" = "#${colors.base01}";
          "browser.button_disabled_border_color" = "#${colors.base03}";
          "browser.menu_text_color" = "#${colors.base05}";
          "browser.menu_background_color" = "#${colors.base00}";
          "browser.menu_border_color" = "#${colors.base03}";
          "browser.menu_hover_text_color" = "#${colors.base06}";
          "browser.menu_hover_background_color" = "#${colors.base01}";
          "browser.menu_hover_border_color" = "#${colors.base0D}";
          "browser.menu_active_text_color" = "#${colors.base05}";
          "browser.menu_active_background_color" = "#${colors.base00}";
          "browser.menu_active_border_color" = "#${colors.base03}";
          "browser.menu_disabled_text_color" = "#${colors.base02}";
          "browser.menu_disabled_background_color" = "#${colors.base01}";
          "browser.menu_disabled_border_color" = "#${colors.base03}";
          # "browser.theme.toolbar-theme" = 0;
          # "browser.theme.content-theme" = 0;
          # "browser.theme.dark-private-windows" = true;
          # "browser.theme.dark-toolbar" = true;
          # "browser.theme.dark-content" = true;
          # "browser.theme.dark-sidebar" = true;
          # "browser.theme.dark-inactive-tabs" = true;
          # "browser.theme.dark-active-tab" = true;
          # "browser.theme.dark-tab-line" = true;
          # "browser.theme.dark-tab-background-text" = true;
          # "browser.theme.dark-tab-background-separator" = true;
          # "browser.theme.dark-tab-selected-text" = true;
          # "browser.theme.dark-tab-loading-fill" = true;
          # "browser.theme.dark-toolbar-field" = true;
          # "browser.theme.dark-toolbar-field-focus" = true;
          # "browser.theme.dark-toolbar-field-border-focus" = true;
          # "browser.theme.dark-toolbar-field-text" = true;
          # "browser.theme.dark-toolbar-field-text-focus" = true;
          # "browser.theme.dark-toolbar-field-border" = true;
          # "browser.theme.dark-toolbar-top-separator" = true;
          # "browser.theme.dark-toolbar-bottom-separator" = true;
          # "browser.theme.dark-toolbar-vertical-separator" = true;
          # "browser.theme.dark-bookmark-text" = true;
          # "browser.theme.dark-toolbar-color" = "#${colors.base00}";
          # "browser.theme.dark-toolbar-text-color" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-field-color" = "#${colors.base01}";
          # "browser.theme.dark-toolbar-field-text-color" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-field-focus-color" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-focus-text-color" = "#${colors.base06}";
          # "browser.theme.dark-toolbar-field-border-color" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-field-focus-border-color" = "#${colors.base0D}";
          # "browser.theme.dark-tab-background-color" = "#${colors.base01}";
          # "browser.theme.dark-tab-line-color" = "#${colors.base0D}";
          # "browser.theme.dark-tab-text-color" = "#${colors.base05}";
          # "browser.theme.dark-tab-selected-color" = "#${colors.base02}";
          # "browser.theme.dark-tab-loading-color" = "#${colors.base0D}";
          # "browser.theme.dark-sidebar-background-color" = "#${colors.base00}";
          # "browser.theme.dark-sidebar-text-color" = "#${colors.base05}";
          # "browser.theme.dark-inactive-tab-background-color" = "#${colors.base01}";
          # "browser.theme.dark-inactive-tab-text-color" = "#${colors.base04}";
          # "browser.theme.dark-highlight-color" = "#${colors.base0A}";
          # "browser.theme.dark-selected-tab-background-color" = "#${colors.base02}";
          # "browser.theme.dark-selected-tab-text-color" = "#${colors.base06}";
          # "browser.theme.dark-popup-background" = "#${colors.base01}";
          # "browser.theme.dark-popup-text" = "#${colors.base05}";
          # "browser.theme.dark-popup-border" = "#${colors.base03}";
          # "browser.theme.dark-popup-highlight" = "#${colors.base0A}";
          # "browser.theme.dark-popup-highlight-text" = "#${colors.base00}";
          # "browser.theme.dark-ntp-background" = "#${colors.base00}";
          # "browser.theme.dark-ntp-text" = "#${colors.base05}";
          # "browser.theme.dark-sidebar-highlight" = "#${colors.base0A}";
          # "browser.theme.dark-sidebar-highlight-text" = "#${colors.base00}";
          # "browser.theme.dark-sidebar-border" = "#${colors.base03}";
          # "browser.theme.dark-sidebar-separator" = "#${colors.base03}";
          # "browser.theme.dark-sidebar-selected-background" = "#${colors.base02}";
          # "browser.theme.dark-sidebar-selected-text" = "#${colors.base06}";
          # "browser.theme.dark-sidebar-hover-background" = "#${colors.base01}";
          # "browser.theme.dark-sidebar-hover-text" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-button-background" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-button-hover-background" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-button-active-background" = "#${colors.base04}";
          # "browser.theme.dark-toolbar-button-text" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-button-hover-text" = "#${colors.base06}";
          # "browser.theme.dark-toolbar-button-active-text" = "#${colors.base07}";
          # "browser.theme.dark-toolbar-button-icon" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-button-hover-icon" = "#${colors.base06}";
          # "browser.theme.dark-toolbar-button-active-icon" = "#${colors.base07}";
          # "browser.theme.dark-toolbar-button-border" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-button-hover-border" = "#${colors.base04}";
          # "browser.theme.dark-toolbar-button-active-border" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-field-focus-outline" = "#${colors.base0D}";
          # "browser.theme.dark-toolbar-field-focus-outline-width" = "2px";
          # "browser.theme.dark-toolbar-field-focus-outline-style" = "solid";
          # "browser.theme.dark-toolbar-field-focus-outline-offset" = "0px";
          # "browser.theme.dark-toolbar-field-border-radius" = "4px";
          # "browser.theme.dark-toolbar-field-focus-border-radius" = "4px";
          # "browser.theme.dark-toolbar-field-text-focus" = "#${colors.base07}";
          # "browser.theme.dark-toolbar-field-background-focus" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-border-focus" = "#${colors.base0D}";
          # "browser.theme.dark-toolbar-field-separator-focus" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-field-highlight-focus" = "#${colors.base0A}";
          # "browser.theme.dark-toolbar-field-highlight-text-focus" = "#${colors.base00}";
          # "browser.theme.dark-toolbar-field-shadow-focus" = "#${colors.base0B}";
          # "browser.theme.dark-toolbar-field-shadow-text-focus" = "#${colors.base01}";
          # "browser.theme.dark-toolbar-field-outline-focus" = "#${colors.base0C}";
          # "browser.theme.dark-toolbar-field-outline-text-focus" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-glow-focus" = "#${colors.base0D}";
          # "browser.theme.dark-toolbar-field-glow-text-focus" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-field-glow-background-focus" = "#${colors.base01}";
          # "browser.theme.dark-toolbar-field-glow-border-focus" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-glow-shadow-focus" = "#${colors.base04}";
          # "browser.theme.dark-toolbar-field-glow-highlight-focus" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-field-glow-outline-focus" = "#${colors.base06}";
          # "browser.theme.dark-toolbar-field-glow-outline-text-focus" = "#${colors.base07}";
          # "browser.theme.dark-toolbar-field-glow-separator-focus" = "#${colors.base08}";
          # "browser.theme.dark-toolbar-field-glow-accent-focus" = "#${colors.base09}";
          # "browser.theme.dark-toolbar-field-glow-accent-text-focus" = "#${colors.base0A}";
          # "browser.theme.dark-toolbar-field-glow-accent-background-focus" = "#${colors.base0B}";
          # "browser.theme.dark-toolbar-field-glow-accent-border-focus" = "#${colors.base0C}";
          # "browser.theme.dark-toolbar-field-glow-accent-shadow-focus" = "#${colors.base0D}";
          # "browser.theme.dark-toolbar-field-glow-accent-highlight-focus" = "#${colors.base0E}";
          # "browser.theme.dark-toolbar-field-glow-accent-outline-focus" = "#${colors.base0F}";
          # "browser.theme.dark-toolbar-field-glow-accent-outline-text-focus" = "#${colors.base00}";
          # "browser.theme.dark-toolbar-field-glow-accent-separator-focus" = "#${colors.base01}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-focus" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-text-focus" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-background-focus" = "#${colors.base04}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-border-focus" = "#${colors.base05}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-shadow-focus" = "#${colors.base06}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-highlight-focus" = "#${colors.base07}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-outline-focus" = "#${colors.base08}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-outline-text-focus" = "#${colors.base09}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-separator-focus" = "#${colors.base0A}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-focus" = "#${colors.base0B}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-text-focus" = "#${colors.base0C}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-background-focus" = "#${colors.base0D}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-border-focus" = "#${colors.base0E}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-shadow-focus" = "#${colors.base0F}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-highlight-focus" = "#${colors.base00}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-outline-focus" = "#${colors.base01}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-outline-text-focus" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-separator-focus" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-outline-focus" = "#${colors.base01}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-outline-text-focus" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-separator-focus" = "#${colors.base03}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-outline-focus" = "#${colors.base01}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-outline-text-focus" = "#${colors.base02}";
          # "browser.theme.dark-toolbar-field-glow-accent-glow-accent-separator-focus" = "#${colors.base03}";
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
						uiAccentCustom0 = "#${colors.base0D}";
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
						"adguard-social"
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
