{pkgs, ...}: {
  programs.browserpass.enable = true;
  programs.firefox = {
    enable = true;
    profiles = {
      alex = {
        bookmarks = {};
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          enhancer-for-youtube # non-free
          sponsorblock
          ublock-origin
          bitwarden
          darkreader
          tabliss
          tampermonkey
          temporary-containers
          return-youtube-dislikes
          remove-youtube-s-suggestions
          refined-github
          re-enable-right-click
          private-relay
          onetab
        ];
        settings = {
          "browser.disableResetPrompt" = true;
          "browser.download.panel.shown" = true;
          "browser.download.useDownloadDir" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          "browser.startup.homepage" = "https://searx.aicampground.com";
          "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":18,"newElementCount":4}'';
          "dom.security.https_only_mode" = true;
          "identity.fxaccounts.enabled" = false;
          "privacy.trackingprotection.enabled" = true;
          "signon.rememberSignons" = false;
          "extensions.enabledAddons" = "enhancer-for-youtube@sponsorblock@ublock-origin@bitwarden@darkreader@tabliss@tampermonkey@temporary-containers@return-youtube-dislikes@remove-youtube-s-suggestions@refined-github@re-enable-right-click@private-relay@onetab";
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.warnOnCloseOtherTabs" = false;
        };
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