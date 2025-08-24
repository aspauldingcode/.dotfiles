{pkgs}:
pkgs.stdenv.mkDerivation {
  name = "ColorPicker";
  version = "1.0.0";

  src = pkgs.writeTextDir "color_picker.m" ''
    #import <Cocoa/Cocoa.h>
    #import <Foundation/Foundation.h>

    @interface ColorPickerApp : NSObject <NSApplicationDelegate>
    @property (nonatomic) BOOL hasOutput;
    @end

    @implementation ColorPickerApp

    - (void)applicationDidFinishLaunching:(NSNotification *)notification {
        self.hasOutput = NO;

        NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
        [colorPanel setShowsAlpha:NO];
        [colorPanel setMode:NSColorPanelModeRGB];
        [colorPanel setContinuous:NO];

        // Set a default gray color to avoid color space issues
        NSColor *defaultColor = [NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        [colorPanel setColor:defaultColor];

        // Show the panel
        [colorPanel makeKeyAndOrderFront:nil];

        // Set up notification for when the panel closes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(colorPanelWillClose:)
                                                     name:NSWindowWillCloseNotification
                                                   object:colorPanel];

        // Activate the app
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];
    }

    - (void)colorPanelWillClose:(NSNotification *)notification {
        // Prevent multiple outputs from multiple close notifications
        if (self.hasOutput) {
            return;
        }
        self.hasOutput = YES;

        NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
        NSColor *color = [colorPanel color];

        // Convert to RGB color space to avoid issues
        NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
        if (!rgbColor) {
            rgbColor = color;
        }

        CGFloat red, green, blue, alpha;
        [rgbColor getRed:&red green:&green blue:&blue alpha:&alpha];

        int redInt = (int)round(red * 255);
        int greenInt = (int)round(green * 255);
        int blueInt = (int)round(blue * 255);

        // Clamp values
        redInt = MAX(0, MIN(255, redInt));
        greenInt = MAX(0, MIN(255, greenInt));
        blueInt = MAX(0, MIN(255, blueInt));

        printf("%02X%02X%02X\n", redInt, greenInt, blueInt);
        [NSApp terminate:nil];
    }

    - (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
        return YES;
    }

    @end

    int main(int argc, char *argv[]) {
        @autoreleasepool {
            NSApplication *app = [NSApplication sharedApplication];
            ColorPickerApp *delegate = [[ColorPickerApp alloc] init];
            [app setDelegate:delegate];
            [app run];
        }
        return 0;
    }
  '';

  buildInputs = with pkgs; [
    darwin.apple_sdk.frameworks.Cocoa
    darwin.apple_sdk.frameworks.Foundation
  ];

  buildPhase = ''
    # Compile the Objective-C application
    clang -o ColorPicker color_picker.m \
      -framework Cocoa \
      -framework Foundation
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ColorPicker $out/bin/
  '';

  meta = {
    description = "A native Objective-C color picker for macOS";
    platforms = pkgs.lib.platforms.darwin;
  };
}
