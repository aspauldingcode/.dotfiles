// Firefox userChrome.css Hot-Reload Script
// This script can be executed in Firefox's Browser Console (Ctrl+Shift+J / Cmd+Shift+J)
// to reload userChrome.css without restarting the browser
//
// Prerequisites:
// - devtools.chrome.enabled must be set to true in about:config
// - toolkit.legacyUserProfileCustomizations.stylesheets must be set to true in about:config
//
// Usage:
// 1. Open Browser Console with Ctrl+Shift+J (Windows/Linux) or Cmd+Shift+J (macOS)
// 2. Paste this script and press Enter
// 3. userChrome.css will be reloaded immediately

(function reloadUserChrome() {
  try {
    // Get the style sheet service
    const ss = Components.classes["@mozilla.org/content/style-sheet-service;1"].getService(
      Components.interfaces.nsIStyleSheetService
    );

    // Get the IO service
    const io = Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);

    // Get directory service to locate the chrome folder
    const ds = Components.classes["@mozilla.org/file/directory_service;1"].getService(
      Components.interfaces.nsIProperties
    );

    // Get the chrome directory path
    const chromepath = ds.get("UChrm", Components.interfaces.nsIFile);
    chromepath.append("userChrome.css");

    // Create file URI
    const chromefile = io.newFileURI(chromepath);

    // Check if the stylesheet is already registered and unregister it
    if (ss.sheetRegistered(chromefile, ss.USER_SHEET)) {
      ss.unregisterSheet(chromefile, ss.USER_SHEET);
      console.log("🔄 Unregistered existing userChrome.css");
    }

    // Register the stylesheet again (this reloads it)
    ss.loadAndRegisterSheet(chromefile, ss.USER_SHEET);
    console.log("✅ Successfully reloaded userChrome.css");

    return "userChrome.css hot-reload completed successfully!";
  } catch (error) {
    console.error("❌ Error reloading userChrome.css:", error);
    return "Failed to reload userChrome.css: " + error.message;
  }
})();
