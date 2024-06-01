case "$SENDER" in
  "mouse.entered")
    sketchybar --set $NAME popup.drawing=on
    ;;
  "mouse.exited" | "mouse.exited.global")
    sketchybar --set $NAME popup.drawing=off
    ;;
  "mouse.clicked")
    # Handle click event if needed
    ;;
  "routine")
    # Update routine if needed
    ;;
esac
