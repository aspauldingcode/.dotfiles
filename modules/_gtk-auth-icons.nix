# Clearer password show/hide icons for gtklock.
#
# Upstream hardcodes `view-reveal-symbolic` / `view-conceal-symbolic` in C, so
# we ship a tiny icon theme that overrides those two names with bolder glyphs,
# then launch gtklock with that theme selected.
{
  pkgs,
}:
let
  # Bold eye / eye-off. `currentColor` lets GTK symbolic recoloring + CSS tint.
  viewReveal = pkgs.writeText "view-reveal-symbolic.svg" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
      <path fill="currentColor" d="M8 3C4.5 3 1.6 5.1.5 8c1.1 2.9 4 5 7.5 5s6.4-2.1 7.5-5c-1.1-2.9-4-5-7.5-5zm0 1.5c2.3 0 4.2 1.9 4.2 4.2S10.3 12.9 8 12.9 3.8 11 3.8 8.7 5.7 4.5 8 4.5zm0 2.2a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>
    </svg>
  '';

  viewConceal = pkgs.writeText "view-conceal-symbolic.svg" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
      <path fill="currentColor" d="M1.1 1.1 0 2.2l2.2 2.2C1.3 5.4.7 6.6.5 8c1.1 2.9 4 5 7.5 5 1.3 0 2.5-.3 3.6-.8L13.8 15l1.1-1.1L1.1 1.1zM8 4.5c.5 0 1 .1 1.5.3L8.2 6.1c-.1 0-.2-.1-.2-.1a2 2 0 0 0-2 2c0 .1 0 .2.1.3L4.8 9.6C4.2 9.1 3.8 8.4 3.8 7.7 3.8 5.4 5.7 4.5 8 4.5zm6.7.8-1.5 1.5c.4.5.7 1.1.8 1.7-1.1 2.4-3.5 4-6 4-.5 0-1-.1-1.4-.2l-1.3 1.3c.9.4 1.8.6 2.7.6 3.5 0 6.4-2.1 7.5-5-.4-1.1-1.1-2.1-2-2.9z"/>
    </svg>
  '';
in
pkgs.runCommand "gtklock-auth-icons" { preferLocalBuild = true; } ''
    mkdir -p "$out/share/icons/gtklock-auth/symbolic/actions"
    cp ${viewReveal} "$out/share/icons/gtklock-auth/symbolic/actions/view-reveal-symbolic.svg"
    cp ${viewConceal} "$out/share/icons/gtklock-auth/symbolic/actions/view-conceal-symbolic.svg"
    cat > "$out/share/icons/gtklock-auth/index.theme" <<'EOF'
  [Icon Theme]
  Name=gtklock-auth
  Comment=Bold password reveal icons for gtklock
  Inherits=Adwaita,hicolor
  Directories=symbolic/actions

  [symbolic/actions]
  Context=Actions
  Size=16
  Type=Scalable
  MinSize=8
  MaxSize=256
  EOF
''
