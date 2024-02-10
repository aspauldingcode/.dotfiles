{ config, ... }:

# macOS Pheonix Window Manager Config
{

 # Note: to use phoenix typescript, learn of phoenix typings: https://github.com/mafredri/phoenix-typings/
 home.file.phoenix = {
    executable = true;
    target = ".config/phoenix/phoenix.js"; # javascript first.
    text = let inherit (config.colorScheme) colors; in /* javascript */ ''
    Phoenix.notify("Phoenix config loading")
    Phoenix.set({
  	daemon: false,
   	openAtLogin: true
    })
        Key.on('z', ['control', 'shift'], () => {
  	    const screen = Screen.main().flippedVisibleFrame();
  	    const window = Window.focused();

     	    if (window) {
                window.setTopLeft({
                    x: screen.x + (screen.width / 2) - (window.frame().width / 2),
                    y: screen.y + (screen.height / 2) - (window.frame().height / 2)
                });
            }
        });
    Phoenix.notify("All ok.")
    '';
 };
}
