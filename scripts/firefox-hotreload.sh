#!/usr/bin/env bash
# Firefox userChrome.css Hot-Reload Helper Script
#
# This script attempts to hot-reload Firefox's userChrome.css without restarting the browser
# by using AppleScript (macOS) or other methods to send the reload command to Firefox.

set -euo pipefail

# Path to the JavaScript reload script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JS_RELOAD_SCRIPT="$SCRIPT_DIR/firefox-reload-userchrome.js"

# Check if Firefox is running
if ! pgrep -x firefox >/dev/null; then
    echo "⚠️  Firefox is not running. userChrome.css changes will be applied when Firefox starts."
    exit 0
fi

echo "🔄 Attempting to hot-reload Firefox userChrome.css..."

# Function to reload userChrome.css on macOS using AppleScript
reload_macos() {
    # Create a temporary AppleScript that opens Browser Console and executes the reload script
    local temp_script=$(mktemp)

    # Read the JavaScript reload code
    local js_code
    js_code=$(cat "$JS_RELOAD_SCRIPT" | tr '\n' ' ' | sed 's/"/\\"/g')

    cat > "$temp_script" << EOF
tell application "Firefox"
    activate
    delay 0.5
end tell

-- Send keyboard shortcut to open Browser Console (Cmd+Shift+J)
tell application "System Events"
    key code 38 using {command down, shift down}
    delay 1

    -- Paste and execute the reload script
    keystroke "$js_code"
    delay 0.2
    key code 36 -- Enter key
    delay 0.5

    -- Close the Browser Console (Cmd+Shift+J again)
    key code 38 using {command down, shift down}
end tell
EOF

    osascript "$temp_script"
    rm "$temp_script"

    echo "✅ userChrome.css hot-reload command sent to Firefox"
}

# Function to reload userChrome.css on Linux
reload_linux() {
    echo "ℹ️  On Linux, automatic hot-reload is not yet implemented."
    echo "📋 To manually reload userChrome.css:"
    echo "   1. Open Firefox Browser Console with Ctrl+Shift+J"
    echo "   2. Paste the contents of: $JS_RELOAD_SCRIPT"
    echo "   3. Press Enter to execute"
    echo ""
    echo "🔗 Alternatively, you can copy this one-liner:"
    echo "   (function(){try{const ss=Components.classes['@mozilla.org/content/style-sheet-service;1'].getService(Components.interfaces.nsIStyleSheetService);const io=Components.classes['@mozilla.org/network/io-service;1'].getService(Components.interfaces.nsIIOService);const ds=Components.classes['@mozilla.org/file/directory_service;1'].getService(Components.interfaces.nsIProperties);const chromepath=ds.get('UChrm',Components.interfaces.nsIFile);chromepath.append('userChrome.css');const chromefile=io.newFileURI(chromepath);if(ss.sheetRegistered(chromefile,ss.USER_SHEET)){ss.unregisterSheet(chromefile,ss.USER_SHEET);}ss.loadAndRegisterSheet(chromefile,ss.USER_SHEET);console.log('✅ userChrome.css reloaded');return 'Success!';}catch(e){console.error('❌ Error:',e);return 'Failed: '+e.message;}})()"
}

# Detect platform and run appropriate reload function
if [[ "$(uname)" == "Darwin" ]]; then
    reload_macos
elif [[ "$(uname)" == "Linux" ]]; then
    reload_linux
else
    echo "❌ Unsupported platform: $(uname)"
    exit 1
fi
