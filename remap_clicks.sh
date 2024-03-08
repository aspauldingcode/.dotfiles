
#!/bin/bash

while true; do
    # Capture mouse button press events
    EVENT=$(cliclick -cp)

    # Check for Alt+Mouse button press (Event ID may vary, adjust if needed)
    if [[ $EVENT == *"altDown mouseDown"* ]]; then
        # Release Alt key (if still pressed)
        cliclick -kp:return

        # Simulate Cmd key press and hold
        cliclick -kp:command -w:100

        # Simulate mouse button press
        cliclick -kp:mouseLeft

        # Release Cmd key
        cliclick -kp:return
    fi
done

