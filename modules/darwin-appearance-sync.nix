# Legacy Darwin appearance sync (bash) — removed.
#
# Runtime light/dark state machine lives in `modules/apps/appearance.nix`
# (`dendritic-appearance supervise` / `reconcile`). This stub exists so the
# old module path does not leave dangling expectations; activation bootouts
# any leftover system daemon from previous generations.
{
  flake.modules.darwin.dendritic =
    { lib, ... }:
    {
      config = {
        system.activationScripts.postActivation.text = lib.mkAfter ''
          /bin/launchctl bootout system/dendritic-appearance-sync >/dev/null 2>&1 || true
          rm -f /Library/LaunchDaemons/dendritic-appearance-sync.plist >/dev/null 2>&1 || true
        '';
      };
    };
}
