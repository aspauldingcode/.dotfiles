osascript -e 'tell application "System Events"
	tell process "NotificationCenter"
		if not (window "Notification Center" exists) then return
		set alertGroups to groups of first UI element of first scroll area of first group of window "Notification Center"
		repeat with aGroup in alertGroups
			try
				perform (first action of aGroup whose name contains "Close" or name contains "Clear")
			on error errMsg
				log errMsg
			end try
		end repeat
		-- Show no message on success
		return ""
	end tell
end tell'
