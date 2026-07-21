# Shared GTK CSS for gtkgreet (login) and gtklock (session lock).
#
# Identical surface language on both apps:
#   gtkgreet glass → box#body   (upstream greetd docs)
#   gtklock  glass → #window-box
# Wallpaper is desktop-current 1:1 on both (runtime placeholders or baked).
# Stylix base16 + fonts + optional profile avatar are shared chrome.
#
# Design: "dendritic glass" — full-bleed wallpaper, one floating frosted
# card, accent hairline, soft pill controls. GTK3 has no backdrop-filter,
# so the card fill is a pre-blurred wallpaper crop.
# Do NOT use text-transform — gtklock rejects the whole stylesheet.
# Do NOT use non-standard font-weight (e.g. 650) — GTK3 CSS only accepts
# keyword weights or the classic 100…900 hundreds.
#
# Concentric corners: r_panel = r_control + panelGap.
#
# Call as:
#   (import ./_gtk-auth-style.nix) {
#     inherit lib pkgs wallpaper;
#     colors = config.lib.stylix.colors;
#     revealIcon = "/nix/store/.../eye.png"; # optional
#     fontFamily = "Inter";                  # optional
#     runtimeWallpaper = true;               # gtklock: __DENDRITIC_AUTH_*__
#     avatar = "/nix/store/.../profile.jpg"; # optional circular photo
#   }
{
  lib,
  pkgs,
  colors,
  wallpaper ? null,
  revealIcon ? null,
  fontFamily ? "Inter",
  # When true, CSS uses placeholders substituted by gtklock-auth at lock time.
  runtimeWallpaper ? false,
  avatar ? null,
}:
let
  controlRadius = 14;
  panelGap = 22;
  panelRadius = controlRadius + panelGap; # 36
  chipGap = 8;
  chipRadius = lib.max 0 (controlRadius - chipGap);
  avatarSize = 88;

  px = n: "${toString n}px";
  hex = name: "#${colors.${name}}";
  rgba =
    name: alpha:
    "rgba(${colors."${name}-rgb-r"}, ${colors."${name}-rgb-g"}, ${colors."${name}-rgb-b"}, ${alpha})";

  wallpaperBlur =
    if runtimeWallpaper || wallpaper == null then
      null
    else
      pkgs.runCommand "gtk-auth-wallpaper-blur.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          magick ${lib.escapeShellArg (toString wallpaper)} \
            -auto-orient \
            -resize '1920x1080^' \
            -gravity center -extent 1920x1080 \
            -scale 5% \
            -gaussian-blur 0x1.4 \
            -resize 1920x1080! \
            -quality 92 \
            PNG32:"$out"
        '';

  wallpaperUrl =
    if runtimeWallpaper then
      "__DENDRITIC_AUTH_WALLPAPER__"
    else if wallpaper == null then
      null
    else
      "file://${toString wallpaper}";

  wallpaperBlurUrl =
    if runtimeWallpaper then
      "__DENDRITIC_AUTH_WALLPAPER_BLUR__"
    else if wallpaperBlur == null then
      null
    else
      "file://${toString wallpaperBlur}";

  # Circular crop via ImageMagick for GTK CSS border-radius friendliness.
  avatarRound =
    if avatar == null then
      null
    else
      pkgs.runCommand "dendritic-auth-avatar.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          magick ${lib.escapeShellArg (toString avatar)} \
            -auto-orient \
            -resize '${toString avatarSize}x${toString avatarSize}^' \
            -gravity center -extent ${toString avatarSize}x${toString avatarSize} \
            \( +clone -size ${toString avatarSize}x${toString avatarSize} xc:none \
               -fill white -draw 'circle ${toString (avatarSize / 2)},${toString (avatarSize / 2)} ${toString (avatarSize / 2)},1' \) \
            -alpha off -compose CopyOpacity -composite \
            PNG32:"$out"
        '';

  avatarRoundUrl = if avatarRound == null then null else "file://${toString avatarRound}";

  # Room: sharp wallpaper + deep vignette so the card reads as the hero.
  wallpaperLayer =
    if wallpaperUrl == null then
      "background-color: ${hex "base00"};"
    else
      ''
        background-image:
          radial-gradient(
            ellipse 90% 70% at 50% 42%,
            ${rgba "base00" "0.18"} 0%,
            ${rgba "base00" "0.62"} 70%,
            ${rgba "base00" "0.82"} 100%
          ),
          url("${wallpaperUrl}");
        background-size: cover, cover;
        background-position: center, center;
        background-repeat: no-repeat, no-repeat;
        background-color: ${hex "base00"};
      '';

  # Card: frosted blur crop + translucent Stylix wash + accent top edge.
  # Optional avatar layered at the top center of the glass card.
  panelBackground =
    if wallpaperBlurUrl == null && avatarRoundUrl == null then
      ''
        background-color: ${rgba "base01" "0.90"};
        background-image: none;
      ''
    else if avatarRoundUrl == null then
      ''
        background-color: ${rgba "base01" "0.28"};
        background-image:
          linear-gradient(
            165deg,
            ${rgba "base01" "0.55"} 0%,
            ${rgba "base00" "0.62"} 55%,
            ${rgba "base00" "0.72"} 100%
          ),
          url("${wallpaperBlurUrl}");
        background-size: cover, cover;
        background-position: center, center;
        background-repeat: no-repeat, no-repeat;
      ''
    else if wallpaperBlurUrl == null then
      ''
        background-color: ${rgba "base01" "0.90"};
        background-image: url("${avatarRoundUrl}");
        background-size: ${px avatarSize} ${px avatarSize};
        background-position: center ${px panelGap};
        background-repeat: no-repeat;
      ''
    else
      ''
        background-color: ${rgba "base01" "0.28"};
        background-image:
          url("${avatarRoundUrl}"),
          linear-gradient(
            165deg,
            ${rgba "base01" "0.55"} 0%,
            ${rgba "base00" "0.62"} 55%,
            ${rgba "base00" "0.72"} 100%
          ),
          url("${wallpaperBlurUrl}");
        background-size: ${px avatarSize} ${px avatarSize}, cover, cover;
        background-position: center ${px panelGap}, center, center;
        background-repeat: no-repeat, no-repeat, no-repeat;
      '';

  panelPaddingTop = if avatarRoundUrl == null then panelGap else panelGap + avatarSize + 16;

  controlReset = ''
    background-image: none;
    border-image: none;
    box-shadow: none;
    text-shadow: none;
    outline: none;
    outline-offset: 0;
  '';

  # Shared glass card — MUST target both app roots.
  glassPanel = ''
    ${panelBackground}
    border: 1px solid ${rgba "base05" "0.16"};
    border-top: 1px solid ${rgba "base0D" "0.55"};
    border-radius: ${px panelRadius};
    padding: ${px panelPaddingTop} ${px (panelGap + 6)} ${px panelGap} ${px (panelGap + 6)};
    min-width: 320px;
    box-shadow:
      0 1px 0 ${rgba "base07" "0.06"} inset,
      0 18px 48px ${rgba "base00" "0.55"},
      0 0 0 1px ${rgba "base00" "0.25"};
  '';
in
''
  /* ── Dendritic glass: gtkgreet + gtklock (identical tokens) ───────── */

  window {
    ${wallpaperLayer}
    color: ${hex "base05"};
    font-family: ${fontFamily}, "SF Pro Display", "Segoe UI", sans-serif;
    font-size: 14px;
  }

  window.focused {
    /* no-op hook for multi-monitor gtklock focus class */
  }

  window.hidden {
    opacity: 1;
  }

  /*
   * Glass card roots
   *   gtkgreet → box#body
   *   gtklock  → #window-box
   * Do NOT clear box#body — that was why greet looked broken.
   */
  box#body,
  #window-box {
    ${glassPanel}
  }

  /* gtklock nests body inside #window-box — keep inner revealer transparent */
  #window-box #body-revealer,
  #window-box #body-grid,
  #window-box box#body,
  revealer#body-revealer,
  grid#body-grid {
    background-color: transparent;
    background-image: none;
    border: none;
    border-radius: 0;
    padding: 0;
    margin: 0;
    box-shadow: none;
  }

  box#body decoration,
  #window-box decoration {
    border-radius: ${px panelRadius};
  }

  /* ── Clock / date (gtklock; harmless no-ops on gtkgreet) ──────────── */
  #clock-label,
  #clock {
    color: ${hex "base07"};
    font-size: 64px;
    font-weight: 200;
    letter-spacing: 2px;
    padding: 0;
    margin: 0;
  }

  #date-label {
    color: ${rgba "base05" "0.72"};
    font-size: 13px;
    font-weight: 500;
    letter-spacing: 1.2px;
    padding: 0;
    margin: 6px 0 0 0;
  }

  #info-box {
    background: transparent;
    border: none;
    padding: 0;
    margin: 0 0 22px 0;
  }

  #time-box {
    background: transparent;
    border: none;
    padding: 0;
    margin: 0;
  }

  /* ── Labels ───────────────────────────────────────────────────────── */
  label {
    color: ${rgba "base05" "0.90"};
    font-size: 13px;
    font-weight: 500;
    background: none;
    box-shadow: none;
  }

  /* Soften the literal "Password:" prompt — card already implies it. */
  #input-label {
    color: ${rgba "base05" "0.55"};
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.8px;
    padding: 0 14px 0 2px;
    min-width: 0;
  }

  #error-label,
  .error,
  #warning-label {
    color: ${hex "base08"};
    font-size: 12px;
    font-weight: 600;
    letter-spacing: 0.2px;
    padding: 4px 0 0 0;
    margin: 0;
  }

  /* ── Nested controls (concentric with panel) ──────────────────────── */
  entry,
  #input-field {
    ${controlReset}
    background-color: ${rgba "base00" "0.62"};
    color: ${hex "base05"};
    border: 1px solid ${rgba "base05" "0.14"};
    border-radius: ${px controlRadius};
    border-style: solid;
    padding: 12px 16px;
    min-height: 22px;
    caret-color: ${hex "base0D"};
  }

  /*
   * gtkgreet environment selector is a GtkComboBox:
   *   combobox > box.linked > button.combo > box > cellview + arrow
   * Chrome only on the outer node — styling box/button too double-nests.
   */
  #command-selector,
  combobox {
    ${controlReset}
    background-color: ${rgba "base00" "0.62"};
    color: ${hex "base05"};
    border: 1px solid ${rgba "base05" "0.14"};
    border-radius: ${px controlRadius};
    border-style: solid;
    padding: 0;
    min-height: 22px;
  }

  #command-selector > box,
  #command-selector button,
  #command-selector entry,
  #command-selector cellview,
  combobox > box,
  combobox button,
  combobox entry,
  combobox cellview {
    ${controlReset}
    background-color: transparent;
    background-image: none;
    color: inherit;
    border: none;
    border-radius: ${px controlRadius};
    border-style: none;
    padding: 12px 16px;
    margin: 0;
    min-height: 22px;
    box-shadow: none;
    text-shadow: none;
    -gtk-icon-shadow: none;
  }

  /* Arrow chip: keep padding on the button; don't re-pad the inner box. */
  #command-selector button > box,
  combobox button > box {
    padding: 0;
  }

  entry decoration,
  #input-field decoration,
  #command-selector decoration,
  combobox decoration {
    border-radius: ${px controlRadius};
    box-shadow: none;
    background-image: none;
  }

  entry undershoot.left,
  entry undershoot.right,
  entry overshoot.left,
  entry overshoot.right,
  #input-field undershoot.left,
  #input-field undershoot.right,
  #input-field overshoot.left,
  #input-field overshoot.right {
    background: none;
    background-image: none;
    border: none;
    box-shadow: none;
  }

  entry:focus,
  #input-field:focus,
  #command-selector:focus-within,
  combobox:focus-within {
    ${controlReset}
    background-color: ${rgba "base00" "0.82"};
    border-color: ${hex "base0D"};
    border-radius: ${px controlRadius};
  }

  #command-selector:focus-within > box,
  #command-selector:focus-within button,
  #command-selector:focus-within entry,
  combobox:focus-within > box,
  combobox:focus-within button,
  combobox:focus-within entry {
    background-color: transparent;
    background-image: none;
    border: none;
    box-shadow: none;
  }

  entry selection,
  #input-field selection {
    background-color: ${rgba "base0D" "0.42"};
    color: ${hex "base07"};
  }

  /* Password reveal eye */
  #input-field image.right,
  entry image.right {
    color: ${hex "base0D"};
    min-width: 22px;
    min-height: 22px;
    margin: 0 6px 0 2px;
    opacity: 0.95;
    ${
      if revealIcon == null then
        "-gtk-icon-style: symbolic;"
      else
        ''-gtk-icon-source: url("file://${toString revealIcon}");''
    }
  }

  #input-field image.right:hover,
  entry image.right:hover {
    opacity: 0.75;
  }

  /* Kill Adwaita gradient chrome — background-image must stay none.
   * Exclude .combo (GtkComboBox internals) — those are flattened above. */
  button:not(.combo),
  button.default:not(.combo),
  button.suggested-action:not(.combo),
  button.destructive-action:not(.combo),
  #unlock-button,
  box#body button:not(.combo),
  #window-box button:not(.combo) {
    ${controlReset}
    background-color: ${hex "base0D"};
    background-image: none;
    color: ${hex "base00"};
    border: 1px solid ${hex "base0D"};
    border-radius: ${px controlRadius};
    border-style: solid;
    padding: 11px 20px;
    font-weight: 600;
    letter-spacing: 0.4px;
    min-height: 20px;
    margin: 10px 0 0 0;
    box-shadow: none;
    text-shadow: none;
    -gtk-icon-shadow: none;
  }

  button:not(.combo) decoration,
  button.default:not(.combo) decoration,
  button.suggested-action:not(.combo) decoration,
  #unlock-button decoration,
  box#body button:not(.combo) decoration,
  #window-box button:not(.combo) decoration {
    border-radius: ${px controlRadius};
    box-shadow: none;
    background-image: none;
    border-image: none;
  }

  button:not(.combo) label,
  button.default:not(.combo) label,
  button.suggested-action:not(.combo) label,
  #unlock-button label,
  box#body button:not(.combo) label,
  #window-box button:not(.combo) label {
    color: inherit;
    background: none;
    background-image: none;
    border: none;
    box-shadow: none;
    text-shadow: none;
  }

  button:not(.combo):hover,
  button.default:not(.combo):hover,
  button.suggested-action:not(.combo):hover,
  #unlock-button:hover,
  box#body button:not(.combo):hover,
  #window-box button:not(.combo):hover {
    ${controlReset}
    background-color: ${hex "base0C"};
    background-image: none;
    border-color: ${hex "base0C"};
    border-radius: ${px controlRadius};
    color: ${hex "base00"};
    box-shadow: none;
  }

  button:not(.combo):active,
  button.default:not(.combo):active,
  button.suggested-action:not(.combo):active,
  #unlock-button:active,
  box#body button:not(.combo):active,
  #window-box button:not(.combo):active {
    ${controlReset}
    background-color: ${hex "base0D"};
    background-image: none;
    border-color: ${hex "base0D"};
    border-radius: ${px controlRadius};
    box-shadow: none;
  }

  button:not(.combo):disabled,
  button.default:not(.combo):disabled,
  button.suggested-action:not(.combo):disabled,
  #unlock-button:disabled,
  box#body button:not(.combo):disabled,
  #window-box button:not(.combo):disabled {
    ${controlReset}
    background-color: ${rgba "base02" "0.80"};
    background-image: none;
    border-color: ${rgba "base02" "0.80"};
    color: ${rgba "base05" "0.40"};
    border-radius: ${px controlRadius};
    box-shadow: none;
  }

  /* Message / error strip */
  #message-box,
  #message-scrolled-window,
  #window-box infobar,
  box#body infobar {
    background-color: ${rgba "base00" "0.40"};
    background-image: none;
    border-radius: ${px chipRadius};
    padding: ${px chipGap};
    margin: 8px 0 0 0;
    border: 1px solid ${rgba "base08" "0.28"};
    box-shadow: none;
  }

  #window-box infobar label,
  box#body infobar label {
    color: ${hex "base05"};
  }

  /* ── gtklock-userinfo-module (optional; AccountsService icon) ─────── */
  #user-box,
  #user-revealer {
    background: transparent;
    background-image: none;
    border: none;
    box-shadow: none;
    margin: 0 0 12px 0;
    padding: 0;
  }

  #user-image {
    border-radius: 999px;
    min-width: ${px avatarSize};
    min-height: ${px avatarSize};
    margin: 0 0 8px 0;
    box-shadow:
      0 0 0 2px ${rgba "base0D" "0.45"},
      0 8px 24px ${rgba "base00" "0.45"};
  }

  #user-name {
    color: ${rgba "base05" "0.85"};
    font-size: 14px;
    font-weight: 600;
    letter-spacing: 0.3px;
  }
''
