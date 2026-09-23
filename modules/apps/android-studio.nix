{
  flake.modules.homeManager.dendritic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dendritic.apps.android-studio;
      sdkRoot = "${config.home.homeDirectory}/Library/Android/sdk";
      sdkPathXml = pkgs.writeText "android.sdk.path.xml" ''
        <application>
          <component name="AndroidSdkPathStore">
            <option name="androidSdkAbsolutePath" value="${sdkRoot}" />
          </component>
        </application>
      '';
    in
    {
      options.dendritic.apps.android-studio.enable = lib.mkEnableOption "Android Studio SDK integration";

      config = lib.mkIf cfg.enable {
        # CLI tools and Gradle launched from an interactive shell use the same
        # SDK as Android Studio.  The GUI app receives its path below because
        # macOS does not inherit Home Manager's shell environment.
        home.sessionVariables = {
          ANDROID_HOME = sdkRoot;
          ANDROID_SDK_ROOT = sdkRoot;
        };

        # Android Studio persists this absolute path per product version.  Do
        # not point it into /nix/store: SDK packages managed by Studio are
        # mutable and old store paths disappear after garbage collection.
        home.activation.androidStudioSdk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          studio_base="$HOME/Library/Application Support/Google"
          if [ -x "${sdkRoot}/platform-tools/adb" ] && [ -d "$studio_base" ]; then
            for studio_dir in "$studio_base"/AndroidStudio*/; do
              [ -d "$studio_dir" ] || continue
              $DRY_RUN_CMD mkdir -p "$studio_dir/options"
              $DRY_RUN_CMD cp -f "${sdkPathXml}" "$studio_dir/options/android.sdk.path.xml"
            done
          fi
        '';
      };
    };
}
