# Shared GTK CSS for gtkgreet (login) and gtklock (session lock).
# Call as: (import ./_gtk-auth-style.nix) { colors = …; wallpaper = …; }
{
  colors,
  wallpaper ? null,
}:
let
  wallpaperCss =
    if wallpaper == null then
      "background-color: ${colors.base00};"
    else
      ''
        background-image: url("file://${toString wallpaper}");
        background-size: cover;
        background-position: center;
        background-color: ${colors.base00};
      '';
in
''
  window {
    ${wallpaperCss}
    color: ${colors.base05};
    font-family: sans-serif;
  }

  /* gtkgreet */
  box,
  box#body {
    background-color: ${colors.base01};
    border-radius: 14px;
    padding: 18px;
    border: 1px solid ${colors.base0D};
  }

  /* gtklock */
  #clock-label,
  #date-label,
  #input-label {
    color: ${colors.base05};
  }

  entry {
    background-color: ${colors.base00};
    color: ${colors.base05};
    border: 1px solid ${colors.base02};
    border-radius: 10px;
    padding: 10px 14px;
    caret-color: ${colors.base0D};
  }

  entry:focus {
    border-color: ${colors.base0D};
  }

  button {
    background-color: ${colors.base0D};
    color: ${colors.base00};
    border: none;
    border-radius: 10px;
    padding: 8px 16px;
  }

  button:hover {
    background-color: ${colors.base0C};
  }

  label {
    color: ${colors.base05};
  }

  #error-label,
  .error {
    color: ${colors.base08};
  }
''
