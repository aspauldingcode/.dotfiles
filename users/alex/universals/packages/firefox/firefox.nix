{
  fetchurl,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkForce;
in
{
  programs.browserpass.enable = true;
  programs.firefox = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then null else pkgs.firefox;
    profiles = {
      alex = {
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
          (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
            pname = "bonjourr";
            version = "19.2.4";
            addonId = "{4f391a9e-8717-4ba6-a5b1-488a34931fcb}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4266784/bonjourr_startpage-19.2.4.xpi";
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
            url = "https://addons.mozilla.org/en-US/firefox/addon/youtube-recommended-videos/";
            sha256 = "sha256-MWVpCxKYWR95UGqf6PqDmguKBmZp0FL92Z1wjxx221I=";
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
            url = "https://addons.mozilla.org/en-US/firefox/addon/hide-youtube-thumbnails/?utm_source=addons.mozilla.org&utm_medium=referral&utm_content=search.Check";
            sha256 = "sha256-LMjjuoQ3ZZMkPMTeTNKMN+54LmF8Q03ptL256t9/KMI=";
            meta = {
              homepage = "https://github.com/domdomegg/hideytthumbnails-extension";
              description = "A simple browser extension which removes thumbnails from YouTube, for less clickbaity browsing.";
              license = lib.licenses.mit;
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
          "browser.download.panel.shown" = true;
          "browser.download.useDownloadDir" = false;
          "browser.download.viewableInternally.typeWasRegistered.svg" = true;
          "browser.download.viewableInternally.typeWasRegistered.webp" = true;
          "browser.download.viewableInternally.typeWasRegistered.xml" = true;
          "browser.link.open_newwindow" = 3; # Open links in new tabs
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.search.isUS" = true;
          "browser.search.region" = "US";
          "browser.search.widget.inNavBar" = true;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          # "browser.startup.homepage" = "https://searx.aicampground.com";
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
          "network.proxy.socks_remote_dns" = true;
          "print.print_footerleft" = "";
          "print.print_footerright" = "";
          "print.print_headerleft" = "";
          "print.print_headerright" = "";
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "security.webauth.u2f" = true;
          "security.webauth.webauthn" = true;
          "security.webauth.webauthn_enable_softtoken" = true;
          "security.webauth.webauthn_enable_usbtoken" = true;
          "signon.rememberSignons" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.display.use_system_colors" = true;
          "browser.display.suppress_canvas_background_image_on_forced_colors" = true;
          "browser.newtabpage.activity-stream.newNewtabExperience.colors" = "#0090ED,#FF4F5F,#2AC3A2,#FF7139,#A172FF,#FFA437,#FF2A8A";
          "editor.use_custom_colors" = false;
          "layout.css.forced-colors.enabled" = true;
          "layout.css.inverted-colors.enabled" = false;
          "pdfjs.forcePageColors" = false;
          "pdfjs.highlightEditorColors" = "yellow=#FFFF98,green=#53FFBC,blue=#80EBFF,pink=#FFCBE6,red=#FF4F5F";
          "pdfjs.pageColorsBackground" = "Canvas";
          "pdfjs.pageColorsForeground" = "CanvasText";
          "reader.colors_menu.enabled" = false;
          "reader.custom_colors.background" = "";
          "reader.custom_colors.foreground" = "";
          "reader.custom_colors.selection-highlight" = "";
          "reader.custom_colors.unvisited-links" = "";
          "reader.custom_colors.visited-links" = "";
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
