on run
    repeat
        -- Get the mouse button state (1 for left, 2 for right)
        set mouseState to do shell script "cliclick cp:."
        set mouseButton to last word of mouseState

        -- Check for Alt+Mouse button press
        if mouseButton is "2" then
            -- Simulate Cmd+Mouse button press
            do shell script "cliclick kd:cmd c:."
            do shell script "cliclick ku:cmd"
        end if
    end repeat
end run

