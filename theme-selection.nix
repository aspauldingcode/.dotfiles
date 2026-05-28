let
  # Single editable line:
  schemeBase = "gruvbox";
in
{
  # Derived values consumed by modules (keep modules theme-agnostic).
  name = schemeBase;
  schemes = {
    light = "${schemeBase}-light-hard";
    dark = "${schemeBase}-dark-hard";
  };
}
