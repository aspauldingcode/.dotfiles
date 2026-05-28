{
  # Safari ships with macOS (Cryptex path); we just need to pin it in the
  # dock. No HM half because Safari is system-managed.
  flake.modules.darwin.dendritic =
    { lib, ... }:
    {
      dendritic.dock.apps = lib.mkOrder 100 [
        "/System/Cryptexes/App/System/Applications/Safari.app"
      ];
    };
}
