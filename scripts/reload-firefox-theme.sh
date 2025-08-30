#!/usr/bin/env bash
# Standalone Firefox userChrome.css Hot-Reload Script
# This script can be run independently to reload Firefox themes without restarting

set -euo pipefail

echo "🔄 Firefox userChrome.css Hot-Reload Tool"
echo "=========================================="

# Check if Firefox is running (using flexible process detection)
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS: Look for Firefox.app in process names
    if ! pgrep -f "Firefox.app" >/dev/null; then
        echo "❌ Firefox is not running."
        echo "   Please start Firefox first, then run this script."
        exit 1
    fi
else
    # Linux: Look for firefox in process names
    if ! pgrep -f firefox >/dev/null; then
        echo "❌ Firefox is not running."
        echo "   Please start Firefox first, then run this script."
        exit 1
    fi
fi

echo "✅ Firefox is running"

# Platform-specific reload
if [[ "$(uname)" == "Darwin" ]]; then
    echo "🍎 macOS: Attempting automatic hot-reload..."

    # JavaScript command for reloading userChrome.css
    js_reload_cmd='(function(){try{const ss=Components.classes["@mozilla.org/content/style-sheet-service;1"].getService(Components.interfaces.nsIStyleSheetService);const io=Components.classes["@mozilla.org/network/io-service;1"].getService(Components.interfaces.nsIIOService);const ds=Components.classes["@mozilla.org/file/directory_service;1"].getService(Components.interfaces.nsIProperties);const chromepath=ds.get("UChrm",Components.interfaces.nsIFile);chromepath.append("userChrome.css");const chromefile=io.newFileURI(chromepath);if(ss.sheetRegistered(chromefile,ss.USER_SHEET)){ss.unregisterSheet(chromefile,ss.USER_SHEET);}ss.loadAndRegisterSheet(chromefile,ss.USER_SHEET);console.log("✅ userChrome.css reloaded");return "Success!";}catch(e){console.error("❌ Error:",e);return "Failed: "+e.message;}})()'

    # Use AppleScript to automate the Browser Console
    if osascript -e "
        tell application \"Firefox\" to activate
        delay 0.3
        tell application \"System Events\"
          key code 38 using {command down, shift down}  -- Cmd+Shift+J
          delay 0.8
          keystroke \"$js_reload_cmd\"
          delay 0.2
          key code 36  -- Enter
          delay 0.5
          key code 38 using {command down, shift down}  -- Close console
        end tell
      " 2>/dev/null; then
        echo "✅ userChrome.css hot-reload completed successfully!"
    else
        echo "⚠️  Automatic reload failed. Manual steps:"
        echo "   1. Press Cmd+Shift+J to open Browser Console"
        echo "   2. Paste this command and press Enter:"
        echo "   $js_reload_cmd"
    fi

elif [[ "$(uname)" == "Linux" ]]; then
    echo "🐧 Linux: Manual hot-reload required"
    echo ""
    echo "📋 Steps to hot-reload userChrome.css:"
    echo "   1. In Firefox, press Ctrl+Shift+J to open Browser Console"
    echo "   2. Paste this command and press Enter:"
    echo ""
    echo "   (function(){try{const ss=Components.classes['@mozilla.org/content/style-sheet-service;1'].getService(Components.interfaces.nsIStyleSheetService);const io=Components.classes['@mozilla.org/network/io-service;1'].getService(Components.interfaces.nsIIOService);const ds=Components.classes['@mozilla.org/file/directory_service;1'].getService(Components.interfaces.nsIProperties);const chromepath=ds.get('UChrm',Components.interfaces.nsIFile);chromepath.append('userChrome.css');const chromefile=io.newFileURI(chromepath);if(ss.sheetRegistered(chromefile,ss.USER_SHEET)){ss.unregisterSheet(chromefile,ss.USER_SHEET);}ss.loadAndRegisterSheet(chromefile,ss.USER_SHEET);console.log('✅ userChrome.css reloaded');return 'Success!';}catch(e){console.error('❌ Error:',e);return 'Failed: '+e.message;}})()"
    echo ""
    echo "💡 Tip: You can bookmark this command for quick access!"

else
    echo "❌ Unsupported platform: $(uname)"
    exit 1
fi

echo ""
echo "📝 Note: This requires 'devtools.chrome.enabled = true' in about:config"
echo "🎨 Your Firefox theme should now reflect any userChrome.css changes!"
