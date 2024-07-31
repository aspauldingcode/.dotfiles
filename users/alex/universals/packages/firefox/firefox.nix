{
  fetchurl,
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (lib) mkForce;
  inherit (config.colorscheme) colors;
in
{
  programs.browserpass.enable = true;
  programs.firefox = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.firefox;
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
        bookmarks = { };
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          enhancer-for-youtube # non-free
          sponsorblock
          ublock-origin
          istilldontcareaboutcookies
          bitwarden
          tampermonkey
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
              mozPermissions = [ "storage" ];
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
              mozPermissions = [ "storage" ];
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
          "browser.bookmarks.showMobileBookmarks" = true;
          "browser.contentblocking.category" = "standard";
          "browser.ctrlTab.recentlyUsedOrder" = false;
          "browser.disableResetPrompt" = true;
          "browser.display.suppress_canvas_background_image_on_forced_colors" = true;
          "browser.display.use_system_colors" = true;
          "browser.download.panel.shown" = true;
          "browser.download.useDownloadDir" = false;
          "browser.download.viewableInternally.typeWasRegistered.svg" = true;
          "browser.download.viewableInternally.typeWasRegistered.webp" = true;
          "browser.download.viewableInternally.typeWasRegistered.xml" = true;
          "browser.link.open_newwindow" = 3; # Open links in new tabs
          "browser.newtabpage.activity-stream.newNewtabExperience.colors" = "#0090ED,#FF4F5F,#2AC3A2,#FF7139,#A172FF,#FFA437,#FF2A8A";
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.search.isUS" = true;
          "browser.search.region" = "US";
          "browser.search.widget.inNavBar" = true;
          "browser.sessionstore.resume_from_crash" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          # "browser.startup.homepage" = "https://searx.aicampground.com";
          "browser.tabs.inTitlebar" = if pkgs.stdenv.isDarwin then 1 else 0; # Set 0 for Default OS titlebar, 1 for no titlebar
          "browser.tabs.loadInBackground" = true;
          "browser.tabs.warnOnClose" = false;
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
          "general.autoScroll" = true;
          "general.useragent.locale" = "en-US";
          "identity.fxaccounts.enabled" = false;
          "layout.css.forced-colors.enabled" = true;
          "layout.css.inverted-colors.enabled" = false;
          "network.proxy.socks_remote_dns" = true;
          "pdfjs.forcePageColors" = false;
          "pdfjs.highlightEditorColors" = "yellow=#FFFF98,green=#53FFBC,blue=#80EBFF,pink=#FFCBE6,red=#FF4F5F";
          "pdfjs.pageColorsBackground" = "Canvas";
          "pdfjs.pageColorsForeground" = "CanvasText";
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "reader.colors_menu.enabled" = false;
          "reader.custom_colors.background" = "";
          "reader.custom_colors.foreground" = "";
          "reader.custom_colors.selection-highlight" = "";
          "reader.custom_colors.unvisited-links" = "";
          "reader.custom_colors.visited-links" = "";
          "security.webauth.u2f" = true;
          "security.webauth.webauthn" = true;
          "security.webauth.webauthn_enable_softtoken" = true;
          "security.webauth.webauthn_enable_usbtoken" = true;
          "signon.rememberSignons" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "ui.use_standins_for_native_colors" = false;
          "webgl.colorspaces.prototype" = false;
          "widget.gtk.libadwaita-colors.enabled" = true;
          "widget.gtk.theme-scrollbar-colors.enabled" = true;
        };
      };
    };

    policies = {
      AppAutoUpdate = false;
      BackgroundAppUpdate = false;
      DisableBuiltinPDFViewer = true;
      DisableFirefoxAccounts = true;
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
        "uBlock0@raymondhill.net".adminSettings = {
          userSettings = rec {
            uiTheme = "dark";
            uiAccentCustom = true;
            uiAccentCustom0 = "#8300ff";
            cloudStorageEnabled = mkForce false;
            importedLists = [
              "https://filters.adtidy.org/extension/ublock/filters/3.txt"
              "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            ];
            externalLists = lib.concatStringsSep "\n" importedLists;
          };
          selectedFilterLists = [
            "CZE-0"
            "adguard-annoyance"
            "adguard-generic"
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
    "text/html" = [ "firefox.desktop" ];
    "text/xml" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
  };
}
