# restore windows after reboot to the location and size, layout type floating/bsp they were before rebooting.

# First, Query yabai windows before shutdown to statefile in /tmp/yabai_windows_state:
yabai -m query --windows > /tmp/yabai_windows_state

# Then, at login, open alacritty and read from the file:
cat /tmp/yabai_windows_state | jq -r '.[] | select(.app != null) | "\(.app) \(.frame.x) \(.frame.y) \(.frame.w) \(.frame.h) \(.space) \(if .floating then "float" else "bsp" end) \(.["is-hidden"])"' | while read app x y w h space type is_hidden; do
    # Open the application if it's not already running
    if [ "$is_hidden" = "true" ]; then
        open -g -a "$app"
    else
        open -a "$app"
    fi
    
    # Wait for the application window to appear
    sleep 1
    
    # Move to the correct space
    yabai -m window --space $space
    
    # Set the window type (floating or bsp)
    if [ "$type" = "float" ]; then
        yabai -m window --float
        # Move and resize the floating window
        yabai -m window --move abs:$x:$y
        yabai -m window --resize abs:$w:$h
    else
        yabai -m window --toggle float --toggle float  # Ensure the window is tiled
    fi
done