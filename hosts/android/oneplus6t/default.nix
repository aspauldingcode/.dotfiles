# OnePlus 6T (LineageOS codename: fajita)
#
# Managed over authorized adb shell (uid 2000) via nix-android — no root, no
# replacing the OS, no Nix on the phone. Upstream's supported consumer targets
# are stock Pixel and GrapheneOS; LineageOS / OnePlus is best-effort
# (https://github.com/devindudeman/nix-android/blob/main/docs/SUPPORT.md).
#
# Workflow (controller = mba or sliceanddice):
#   adb devices
#   nix run .#android-rebuild -- update --flake .#oneplus6t-darwin \
#     --lock hosts/android/oneplus6t/apps.lock.json
#   nix run .#android-rebuild -- plan --flake .#oneplus6t-darwin --serial SERIAL
#   nix run .#android-rebuild -- switch --flake .#oneplus6t-darwin --serial SERIAL
#
# On x86_64 Linux use .#oneplus6t-linux instead. Populate more apps with
# `android-rebuild import --serial SERIAL` or by editing this file + `update`.
{
  device = {
    name = "oneplus6t";
    abi = "arm64-v8a";
    user = 0;
  };

  apps = {
    # Main f-droid.org repository — pins resolved into apps.lock.json.
    fdroid.packages = [
      "org.fdroid.fdroid"
      "com.termux"
    ];

    # Sideloaded / non-Play keepers (presence assertions).
    # Wawona: com.aspauldingcode.wawona
    attended = [
      "com.aspauldingcode.wawona"
    ];

    # release."org.thoughtcrime.securesms".updateJson =
    #   "https://updates.signal.org/android/latest.json";
    # play = [ "com.spotify.music" ];

    # Remove undeclared third-party owner apps. System packages are never
    # cleanup candidates (use android.packages.disabled for those).
    # ALWAYS review `plan` uninstall lines before `switch`.
    cleanup = "uninstall";
  };

  android = {
    darkMode = true;
    privateDns = "opportunistic";

    # defaultApps.browser = "org.mozilla.fennec_fdroid";

    permissions."com.termux" = {
      grant = [ "android.permission.POST_NOTIFICATIONS" ];
      flags."android.permission.POST_NOTIFICATIONS" = [ "user-set" ];
    };
    appOps."com.termux".RUN_IN_BACKGROUND = "allow";
    batteryOptimization.exempt = [ "com.termux" ];
  };
}
