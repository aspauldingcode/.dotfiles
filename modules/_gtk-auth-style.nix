# Shared GTK CSS for gtkgreet (login) and gtklock (session lock).
#
# Concentric corner radius (same model as waybar islands):
#   r_outer = r_inner + gap
# Arc centers share one origin so inset thickness stays constant through the
# curve. GTK3 has no CSS custom properties, so radii are computed in Nix.
# Refs: bettercorners.io, Cloud Four nested radii, Apple ConcentricRectangle.
#
# Wallpaper blur: GTK3 has no `backdrop-filter`, so we pre-blur the Stylix
# wallpaper with ImageMagick (downsample → blur → upsample = frosted look)
# and paint that into the glass panel. Window keeps the sharp image + scrim.
#
# GTK3 gotchas this file works around:
#   - Theme `background-image` / `border-image` paint over `background-color`
#     and ignore radius → square “ghost” corners. Always clear both.
#   - Outer `box-shadow` is not clipped to `border-radius` → halo at corners.
#     No elevation/focus rings via shadow on controls; use border color only.
#   - Separate `decoration` nodes stay square unless given the same radius
#     (same bug as Waybar tooltips).
#
# Call as:
#   (import ./_gtk-auth-style.nix) {
#     inherit lib pkgs wallpaper;
#     colors = config.lib.stylix.colors;
#     revealIcon = "/nix/store/.../view-reveal-symbolic.svg"; # optional
#   }
{
  lib,
  pkgs,
  colors,
  wallpaper ? null,
  revealIcon ? null,
}:
let
  # ── Concentric radius tokens ────────────────────────────────────────
  # Inner controls define the base curve; the glass panel grows outward
  # by its (uniform) padding so corners stay concentric.
  controlRadius = 10;
  panelGap = 16;
  panelRadius = controlRadius + panelGap; # 26

  # Secondary nest: message / error chips inside the panel.
  chipGap = 6;
  chipRadius = lib.max 0 (controlRadius - chipGap);

  px = n: "${toString n}px";

  hex = name: "#${colors.${name}}";
  # `alpha` is a string (e.g. "0.55") so CSS stays clean — Nix floats print noisy.
  rgba =
    name: alpha:
    "rgba(${colors."${name}-rgb-r"}, ${colors."${name}-rgb-g"}, ${colors."${name}-rgb-b"}, ${alpha})";

  # Frosted backdrop stand-in for the glass card. Heavy downsample + light
  # blur + upsample approximates a stack blur without a huge build cost.
  wallpaperBlur =
    if wallpaper == null then
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
            -scale 6% \
            -gaussian-blur 0x1.2 \
            -resize 1920x1080! \
            -quality 92 \
            PNG32:"$out"
        '';

  wallpaperLayer =
    if wallpaper == null then
      "background-color: ${hex "base00"};"
    else
      ''
        background-image:
          linear-gradient(
            ${rgba "base00" "0.42"},
            ${rgba "base00" "0.58"}
          ),
          url("file://${toString wallpaper}");
        background-size: cover, cover;
        background-position: center, center;
        background-repeat: no-repeat, no-repeat;
        background-color: ${hex "base00"};
      '';

  # Blurred wallpaper under a light frosted tint. Tint stays low so the
  # blur reads through; border-radius clips the image to the card.
  panelBackground =
    if wallpaperBlur == null then
      ''
        background-color: ${rgba "base01" "0.88"};
        background-image: none;
      ''
    else
      ''
        background-color: ${rgba "base01" "0.35"};
        background-image:
          linear-gradient(
            ${rgba "base01" "0.48"},
            ${rgba "base00" "0.55"}
          ),
          url("file://${toString wallpaperBlur}");
        background-size: cover, cover;
        background-position: center, center;
        background-repeat: no-repeat, no-repeat;
      '';

  # Shared reset for anything that themes paint with images/shadows.
  controlReset = ''
    background-image: none;
    border-image: none;
    box-shadow: none;
    text-shadow: none;
    outline: none;
    outline-offset: 0;
  '';
in
''
  /* ── Session auth surfaces (gtkgreet + gtklock) ───────────────────── */

  window {
    ${wallpaperLayer}
    color: ${hex "base05"};
    font-family: Inter, sans-serif;
    font-size: 14px;
  }

  /* Glass panel — sharp room + pre-blurred wallpaper fill (no backdrop-filter). */
  box#window,
  #window-box {
    ${panelBackground}
    border: 1px solid ${rgba "base05" "0.14"};
    border-radius: ${px panelRadius};
    padding: ${px panelGap};
    /* Soft drop only — large surface, less visible corner bleed than
       control-sized shadows. Keep spread modest. */
    box-shadow: 0 12px 32px ${rgba "base00" "0.40"};
  }

  /* gtkgreet: #body sits inside box#window — never double-glass. */
  box#body,
  box#window box#body {
    background-color: transparent;
    background-image: none;
    border: none;
    border-radius: 0;
    padding: 0;
    margin: 0;
    box-shadow: none;
  }

  /* Match decoration nodes to the panel (GTK paints these square by default). */
  box#window decoration,
  #window-box decoration {
    border-radius: ${px panelRadius};
  }

  /* ── Clock / date ─────────────────────────────────────────────────── */
  #clock,
  #clock-label {
    color: ${hex "base06"};
    font-size: 52px;
    font-weight: 300;
    letter-spacing: 1px;
    padding: 0;
    margin: 0;
  }

  #date-label {
    color: ${rgba "base05" "0.70"};
    font-size: 14px;
    font-weight: 500;
    letter-spacing: 0.4px;
    padding: 0;
    margin: 2px 0 0 0;
  }

  /* Space between time block and password row (sibling margin, not pad —
     keeps panel↔control concentric math intact). */
  #info-box {
    background: transparent;
    border: none;
    padding: 0;
    margin: 0 0 18px 0;
  }

  #time-box {
    background: transparent;
    border: none;
    padding: 0;
    margin: 0;
  }

  /* ── Labels ───────────────────────────────────────────────────────── */
  label {
    color: ${rgba "base05" "0.88"};
    font-size: 13px;
    font-weight: 500;
    background: none;
    box-shadow: none;
  }

  #input-label {
    color: ${rgba "base05" "0.70"};
    font-size: 12px;
    font-weight: 500;
    padding: 0 12px 0 0;
    min-width: 0;
  }

  #error-label,
  .error,
  #warning-label {
    color: ${hex "base08"};
    font-size: 12px;
    font-weight: 600;
    padding: 0;
    margin: 0;
  }

  /* ── Nested controls (concentric with panel) ────────────────────────
     r_control = r_panel − panelGap. No outer shadows — GTK won't clip them. */
  entry,
  #input-field,
  #command-selector,
  combobox,
  combobox > box,
  combobox button,
  combobox entry {
    ${controlReset}
    background-color: ${rgba "base00" "0.72"};
    color: ${hex "base05"};
    border: 1px solid ${rgba "base05" "0.18"};
    border-radius: ${px controlRadius};
    border-style: solid;
    padding: 10px 14px;
    min-height: 18px;
    caret-color: ${hex "base0D"};
  }

  entry decoration,
  #input-field decoration,
  combobox decoration,
  combobox button decoration {
    border-radius: ${px controlRadius};
    box-shadow: none;
    background-image: none;
  }

  /* Undershoot/overshoot edges are a common source of square corner ghosts. */
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
  #command-selector:focus,
  combobox:focus-within {
    ${controlReset}
    background-color: ${rgba "base00" "0.88"};
    border-color: ${hex "base0D"};
    border-radius: ${px controlRadius};
  }

  entry selection,
  #input-field selection {
    background-color: ${rgba "base0D" "0.45"};
    color: ${hex "base07"};
  }

  /* Password show/hide. Force a raster eye via -gtk-icon-source — GTK3
     symbolic theme lookup often paints a blank/"missing glyph" box here. */
  #input-field image.right,
  entry image.right {
    color: ${hex "base0D"};
    min-width: 24px;
    min-height: 24px;
    margin: 0 8px 0 4px;
    opacity: 1;
    ${
      if revealIcon == null then
        "-gtk-icon-style: symbolic;"
      else
        ''-gtk-icon-source: url("file://${toString revealIcon}");''
    }
  }

  #input-field image.right:hover,
  entry image.right:hover {
    opacity: 0.85;
  }

  button,
  #unlock-button,
  button.suggested-action {
    ${controlReset}
    background-color: ${hex "base0D"};
    color: ${hex "base00"};
    border: 1px solid ${hex "base0D"};
    border-radius: ${px controlRadius};
    border-style: solid;
    padding: 8px 18px;
    font-weight: 600;
    letter-spacing: 0.2px;
    min-height: 18px;
    margin: 4px 0 0 0;
  }

  button decoration,
  #unlock-button decoration,
  button.suggested-action decoration {
    border-radius: ${px controlRadius};
    box-shadow: none;
    background-image: none;
    border-image: none;
  }

  button label,
  #unlock-button label,
  button.suggested-action label {
    color: inherit;
    background: none;
    background-image: none;
    border: none;
    box-shadow: none;
    text-shadow: none;
  }

  button:hover,
  #unlock-button:hover,
  button.suggested-action:hover {
    ${controlReset}
    background-color: ${hex "base0C"};
    border-color: ${hex "base0C"};
    border-radius: ${px controlRadius};
    color: ${hex "base00"};
  }

  button:active,
  #unlock-button:active,
  button.suggested-action:active {
    ${controlReset}
    background-color: ${hex "base0D"};
    border-color: ${hex "base0D"};
    border-radius: ${px controlRadius};
  }

  button:disabled,
  #unlock-button:disabled {
    ${controlReset}
    background-color: ${rgba "base02" "0.85"};
    border-color: ${rgba "base02" "0.85"};
    color: ${rgba "base05" "0.45"};
    border-radius: ${px controlRadius};
  }

  /* Message / error strip — secondary concentric nest */
  #message-box,
  #message-scrolled-window {
    background-color: ${rgba "base00" "0.35"};
    background-image: none;
    border-radius: ${px chipRadius};
    padding: ${px chipGap};
    margin: 6px 0 0 0;
    border: 1px solid ${rgba "base08" "0.22"};
    box-shadow: none;
  }
''
