# ── Darwin System Maintenance Module ──────────────────────────
#
# This module integrates system-level maintenance tasks directly into
# the `nix-darwin` activation process. This ensures that every time
# you run `nh darwin switch`, the system state is verified and
# synchronized without needing a separate 'install' script.
#
{
  flake.modules.darwin.maintenance = { pkgs, lib, config, ... }: {
    
    # ── Activation Scripts ──────────────────────────────────────
    # These run during `darwin-rebuild switch` (activated by `nh`).
    system.activationScripts.postActivation.text = ''
      export PATH="/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
      
      maintenance_tasks() {
        echo "──────────────────────────────────────────────────────────"
        echo "  System Maintenance & Synchronization"
        echo "──────────────────────────────────────────────────────────"

        # 1. Clean up deprecated settings from Determinate Nix config
        if [ -f /etc/nix/nix.conf ]; then
           if grep -qE "^eval-cores|^lazy-trees" /etc/nix/nix.conf > /dev/null 2>&1; then
              echo "  🧹 Cleaning up deprecated settings in /etc/nix/nix.conf..."
              sed -i "" "s/^eval-cores/# eval-cores/" /etc/nix/nix.conf
              sed -i "" "s/^lazy-trees/# lazy-trees/" /etc/nix/nix.conf
           fi
        fi

        # 2. Determinate Nix Maintenance
        if command -v determinate-nixd > /dev/null; then
           echo "  ❄️  Verifying Determinate Nix status..."
           STATUS_OUT=$(determinate-nixd status 2>&1 || true)
           
           if echo "$STATUS_OUT" | grep -qi "determinate-nixd upgrade"; then
              echo "  ⤓ Determinate Nix update available. Upgrading..."
              determinate-nixd upgrade
           fi

           if echo "$STATUS_OUT" | grep -qiE "invalid-token|Anonymous|expired|logged out|unauthorized"; then
              echo "  ⚠️  Action Required: FlakeHub authentication is missing or expired."
              echo "     Please run 'determinate-nixd login' manually."
           fi
           
           if determinate-nixd version | grep -q "native-linux-builder"; then
              echo "  🚀 Native Linux Builder: Access confirmed!"
           fi
        fi

        # 3. Mac App Store Sync
        if [ -x ${config.dendritic.mas.syncScript}/bin/mas-sync ]; then
           echo "  🍎 Synchronizing Mac App Store..."
           sudo -u ${config.system.primaryUser} ${pkgs.bash}/bin/bash -c "source /etc/profile; ${config.dendritic.mas.syncScript}/bin/mas-sync"
        fi

        echo "──────────────────────────────────────────────────────────"
      }

      # Force output to stderr so it's more likely to be visible in 'nh'
      maintenance_tasks >&2
    '';
  };
}
