{ config, lib, pkgs, ... }:

# theme okular!
let 
  inherit (config.colorScheme) palette;
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
          [Core General]
          ExternalEditor=Custom
          ExternalEditorCommand=nvim +%l %c

          [Dlg Presentation]
          SlidesBackgroundColor=#${palette.base00}

          [Document]
          ChangeColors=true
          RenderMode=Recolor
          
          [Dlg Accessibility]
          RecolorBackground=#${palette.base00}
          RecolorForeground=#${palette.base07}

          [General]
          ttsEngine=macos
          ttsVoice=Zarvox

          [PageView]
          BackgroundColor=#${palette.base00}
          UseCustomBackgroundColor=true
          MouseMode=TextSelect

          [Reviews]
          DrawingTools=<tool name="Red"><engine color="#${palette.base08}"><annotation color="#${palette.base08}" type="Ink" width="2"/></engine></tool>,<tool name="Green"><engine color="#${palette.base0B}"><annotation color="#${palette.base0B}" type="Ink" width="2"/></engine></tool>,<tool name="Blue"><engine color="#${palette.base0D}"><annotation color="#${palette.base0D}" type="Ink" width="2"/></engine></tool>,<tool name="Yellow"><engine color="#${palette.base0A}"><annotation color="#${palette.base0A}" type="Ink" width="2"/></engine></tool>,<tool name="Black"><engine color="#${palette.base00}"><annotation color="#${palette.base00}" type="Ink" width="2"/></engine></tool>,<tool name="White"><engine color="#${palette.base07}"><annotation color="#${palette.base07}" type="Ink" width="2"/></engine></tool>
          QuickAnnotationTools=<tool default="true" id="1" name="Yellow Highlighter" type="highlight"><engine color="#${palette.base0C}" type="TextSelector"><annotation color="#${palette.base0C}" type="Highlight"/></engine><shortcut>1</shortcut></tool>,<tool default="true" id="2" name="Green Highlighter" type="highlight"><engine color="#${palette.base0B}" type="TextSelector"><annotation color="#${palette.base0B}" type="Highlight"/></engine><shortcut>2</shortcut></tool>,<tool id="3" type="underline"><engine color="#${palette.base08}" type="TextSelector"><annotation color="#${palette.base08}" type="Underline"/></engine><shortcut>3</shortcut></tool>,<tool default="true" id="4" name="Insert Text" type="typewriter"><engine block="true" type="PickPoint"><annotation color="#${palette.base07}" textColor="#${palette.base00}" type="Typewriter" width="0"/></engine><shortcut>4</shortcut></tool>,<tool id="5" type="note-inline"><engine block="true" color="#${palette.base0A}" hoverIcon="tool-note-inline" type="PickPoint"><annotation color="#${palette.base0A}" textColor="#ff${palette.base00}" type="FreeText"/></engine><shortcut>5</shortcut></tool>,<tool id="6" type="note-linked"><engine color="#${palette.base0A}" hoverIcon="tool-note" type="PickPoint"><annotation color="#${palette.base0A}" icon="Note" type="Text"/></engine><shortcut>6</shortcut></tool>
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
        [Core General]
        ExternalEditor=Custom
        ExternalEditorCommand=nvim +%l %c

        [Dlg Presentation]
        SlidesBackgroundColor=#${palette.base00}

        [Document]
        ChangeColors=true
        RenderMode=Recolor

        [Dlg Accessibility]
        RecolorBackground=#${palette.base00}
        RecolorForeground=#${palette.base07}

        [General]
        ttsVoice=samantha

        [PageView]
        BackgroundColor=#${palette.base00}
        UseCustomBackgroundColor=true
        MouseMode=TextSelect

        [Reviews]
        DrawingTools=<tool name="Red"><engine color="#${palette.base08}"><annotation color="#${palette.base08}" type="Ink" width="2"/></engine></tool>,<tool name="Green"><engine color="#${palette.base0B}"><annotation color="#${palette.base0B}" type="Ink" width="2"/></engine></tool>,<tool name="Blue"><engine color="#${palette.base0D}"><annotation color="#${palette.base0D}" type="Ink" width="2"/></engine></tool>,<tool name="Yellow"><engine color="#${palette.base0A}"><annotation color="#${palette.base0A}" type="Ink" width="2"/></engine></tool>,<tool name="Black"><engine color="#${palette.base00}"><annotation color="#${palette.base00}" type="Ink" width="2"/></engine></tool>,<tool name="White"><engine color="#${palette.base07}"><annotation color="#${palette.base07}" type="Ink" width="2"/></engine></tool>
        QuickAnnotationTools=<tool default="true" id="1" name="Yellow Highlighter" type="highlight"><engine color="#${palette.base0C}" type="TextSelector"><annotation color="#${palette.base0C}" type="Highlight"/></engine><shortcut>1</shortcut></tool>,<tool default="true" id="2" name="Green Highlighter" type="highlight"><engine color="#${palette.base0B}" type="TextSelector"><annotation color="#${palette.base0B}" type="Highlight"/></engine><shortcut>2</shortcut></tool>,<tool id="3" type="underline"><engine color="#${palette.base08}" type="TextSelector"><annotation color="#${palette.base08}" type="Underline"/></engine><shortcut>3</shortcut></tool>,<tool default="true" id="4" name="Insert Text" type="typewriter"><engine block="true" type="PickPoint"><annotation color="#${palette.base07}" textColor="#${palette.base00}" type="Typewriter" width="0"/></engine><shortcut>4</shortcut></tool>,<tool id="5" type="note-inline"><engine block="true" color="#${palette.base0A}" hoverIcon="tool-note-inline" type="PickPoint"><annotation color="#${palette.base0A}" textColor="#ff${palette.base00}" type="FreeText"/></engine><shortcut>5</shortcut></tool>,<tool id="6" type="note-linked"><engine color="#${palette.base0A}" hoverIcon="tool-note" type="PickPoint"><annotation color="#${palette.base0A}" icon="Note" type="Text"/></engine><shortcut>6</shortcut></tool>
      '';
    };
  };
}
