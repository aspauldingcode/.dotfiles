{ config, lib, pkgs, ... }:

# theme okular!
let 
  inherit (config.colorScheme) colors;
in
{
  home.file =
    if pkgs.stdenv.isDarwin
    then 
    {
      "Library/Preferences/okularrc" = 
      {
        text = ''
          1440x900 screen: Height=655
          1440x900 screen: Width=881
          1440x900 screen: XPosition=101
          1440x900 screen: YPosition=78
          MenuBar=Disabled
          State=AAAA/wAAAAD9AAAAAQAAAAAAAAFBAAACd/wCAAAAAfsAAAAcAG8AawB1AGwAYQByAF8AcwBpAGQAZQBiAGEAcgEAAAAYAAACdwAAAPQA///+AAACLwAAAncAAAAEAAAABAAAAAgAAAAI/AAAAAEAAAACAAAAAgAAABYAbQBhAGkAbgBUAG8AbwBsAEIAYQByAQAAAAD/////AAAAAAAAAAAAAAAiAGEAbgBuAG8AdABhAHQAaQBvAG4AVABvAG8AbABCAGEAcgEAAACt/////wAAAAAAAAAA

          [Desktop Entry]
          FullScreen=false

          [General]
          LockSidebar=true
          ShowSidebar=false

          [MainWindow]
          1440x900 screen: Height=509
          1440x900 screen: Width=650
          1440x900 screen: XPosition=667
          1440x900 screen: YPosition=61
          MenuBar=Disabled
          ToolBarsMovable=Disabled
        '';
      };
      "Library/Preferences/okularpartrc" = 
        {
        text = ''
          [Document]
          ChangeColors=true
          RenderMode=Recolor
          
          [Dlg Accessibility]
          RecolorBackground=#${colors.base00}
          RecolorForeground=#${colors.base07}

          ttsEngine=macos
          ttsVoice=Zarvox

          [PageView]
          MouseMode=TextSelect

          [Reviews]
          QuickAnnotationTools=<tool default="true" id="1" name="Yellow Highlighter" type="highlight">
            <engine color="#${colors.base0C}" type="TextSelector">
              <annotation color="#${colors.base0C}" type="Highlight"/>
            </engine>
            <shortcut>1</shortcut>
          </tool>,
          <tool default="true" id="2" name="Green Highlighter" type="highlight">
            <engine color="#${colors.base0B}" type="TextSelector">
              <annotation color="#${colors.base0B}" type="Highlight"/>
            </engine>
            <shortcut>2</shortcut>
          </tool>,
          <tool id="3" type="underline">
            <engine color="#${colors.base08}" type="TextSelector">
              <annotation color="#${colors.base08}" type="Underline"/>
            </engine>
            <shortcut>3</shortcut>
          </tool>,
          <tool default="true" id="4" name="Insert Text" type="typewriter">
            <engine block="true" type="PickPoint">
              <annotation color="#${colors.base07}" textColor="#${colors.base00}" type="Typewriter" width="0"/>
            </engine>
            <shortcut>4</shortcut>
          </tool>,
          <tool id="5" type="note-inline">
            <engine block="true" color="#${colors.base0A}" hoverIcon="tool-note-inline" type="PickPoint">
              <annotation color="#${colors.base0A}" textColor="#ff${colors.base00}" type="FreeText"/>
            </engine>
            <shortcut>5</shortcut>
          </tool>,
          <tool id="6" type="note-linked">
            <engine color="#${colors.base0A}" hoverIcon="tool-note" type="PickPoint">
              <annotation color="#${colors.base0A}" icon="Note" type="Text"/>
            </engine>
            <shortcut>6</shortcut>
            </tool>
          '';
        };
    }
    else {
      ".config/okular/okularrc" = {
      text = ''
        [MainWindow]
        1440x876 screen: XPosition=317
        1440x876 screen: YPosition=140
        RestorePositionForNextInstance=false
        State=AAAA/wAAAAD9AAAAAQAAAAAAAADIAAACD/wCAAAAAfsAAAAcAG8AawB1AGwAYQByAF8AcwBpAGQAZQBiAGEAcgEAAAA5AAACDwAAAOkA///+AAAC8gAAAg8AAAAEAAAABAAAAAgAAAAI/AAAAAMAAAABAAAAAQAAACwAcQB1AGkAYwBrAEEAbgBuAG8AdABhAHQAaQBvAG4AVABvAG8AbABCAGEAcgIAAAAA/////wAAAAAAAAAAAAAAAgAAAAEAAAAWAG0AYQBpAG4AVABvAG8AbABCAGEAcgEAAAAA/////wAAAAAAAAAAAAAAAgAAAAEAAAAiAGEAbgBuAG8AdABhAHQAaQBvAG4AVABvAG8AbABCAGEAcgAAAAAA/////wAAAAAAAAAA
        ToolBarsMovable=Disabled
        default=default
      '';
    };
    ".config/okular/okularpartrc" = {
      text = ''
        [Document]
        ChangeColors=true
        RenderMode=Recolor

        [Dlg Accessibility]
        RecolorBackground=#${colors.base00}
        RecolorForeground=#${colors.base07}

        [General]
        ttsVoice=samantha

        [PageView]
        MouseMode=TextSelect

        [Reviews]
        QuickAnnotationTools=
          <tool id="1" name="Yellow Highlighter" default="true" type="highlight">
            <engine type="TextSelector" color="#${colors.base0C}">
              <annotation type="Highlight" color="#${colors.base0C}"/>
            </engine>
            <shortcut>1</shortcut>
          </tool>,
          <tool id="2" name="Green Highlighter" default="true" type="highlight">
            <engine type="TextSelector" color="#${colors.base0B}">
              <annotation type="Highlight" color="#${colors.base0B}"/>
            </engine>
            <shortcut>2</shortcut>
          </tool>,
          <tool id="3" type="underline">
            <engine type="TextSelector" color="#${colors.base08}">
              <annotation type="Underline" color="#${colors.base08}"/>
            </engine>
            <shortcut>3</shortcut>
          </tool>,
          <tool id="4" name="Insert Text" default="true" type="typewriter">
            <engine block="true" type="PickPoint">
              <annotation width="0" textColor="#${colors.base00}" type="Typewriter" color="#${colors.base07}"/>
            </engine>
            <shortcut>4</shortcut>
          </tool>,
          <tool id="5" type="note-inline">
            <engine hoverIcon="tool-note-inline" block="true" type="PickPoint" color="#${colors.base0A}">
              <annotation textColor="#ff${colors.base00}" type="FreeText" color="#${colors.base0A}"/>
            </engine>
            <shortcut>5</shortcut>
          </tool>,
          <tool id="6" type="note-linked">
            <engine hoverIcon="tool-note" type="PickPoint" color="#${colors.base0A}">
              <annotation icon="Note" type="Text" color="#${colors.base0A}"/>
            </engine>
            <shortcut>6</shortcut>
          </tool>
      '';
    };
  };
}
