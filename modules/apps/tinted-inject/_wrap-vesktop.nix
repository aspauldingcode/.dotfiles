{ pkgs, tintedInject }:
let
  ext = "${tintedInject}/extension";
  extra = "--enable-unsafe-extension-debugging";
  feat = "--disable-features=DisableLoadExtensionCommandLineSwitch";
  load = "--load-extension=${ext}";

  wrap =
    vesktop:
    vesktop.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
      postFixup = (old.postFixup or "") + ''
        appBin="$out/Applications/Vesktop.app/Contents/MacOS/vesktop"
        if [ -e "$appBin" ]; then
          mv "$appBin" "$appBin.real"
          makeWrapper "$appBin.real" "$appBin" \
            --add-flags ${pkgs.lib.escapeShellArg extra} \
            --add-flags ${pkgs.lib.escapeShellArg feat} \
            --add-flags ${pkgs.lib.escapeShellArg load}
        elif [ -x "$out/bin/vesktop" ]; then
          wrapProgram "$out/bin/vesktop" \
            --add-flags ${pkgs.lib.escapeShellArg extra} \
            --add-flags ${pkgs.lib.escapeShellArg feat} \
            --add-flags ${pkgs.lib.escapeShellArg load}
        fi
      '';
    });

  wrapped = wrap pkgs.vesktop;
in
# HM does `cfg.package.override { withSystemVencord = ... }`; keep that
# working so the wrap is not stripped.
wrapped
// {
  override = args: wrap (pkgs.vesktop.override args);
}
