{
  lib,
  stdenvNoCC,
  nixos-bgrt-plymouth,
  colors,
}:
let
  hex = name: colors.${name};
  plymouthIni = ''
    [Plymouth Theme]
    Name=dendritic
    Description=two-step NixOS snowflake on a Stylix backdrop
    ModuleName=two-step

    [two-step]
    ImageDir=@IMAGES@
    DialogHorizontalAlignment=.5
    DialogVerticalAlignment=.8
    HorizontalAlignment=.5
    VerticalAlignment=.5
    Transition=none
    TransitionDuration=0.0
    BackgroundStartColor=0x${hex "base00"}
    BackgroundEndColor=0x${hex "base00"}
    ProgressBarBackgroundColor=0x${hex "base02"}
    ProgressBarForegroundColor=0x${hex "base0D"}
    MessageBelowAnimation=true

    [boot-up]
    UseEndAnimation=false
    UseFirmwareBackground=false

    [shutdown]
    UseEndAnimation=false
    UseFirmwareBackground=false

    [reboot]
    UseEndAnimation=false
    UseFirmwareBackground=false
  '';
in
stdenvNoCC.mkDerivation {
  pname = "dendritic-plymouth-theme";
  version = "1.0.0";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  inherit plymouthIni;
  passAsFile = [ "plymouthIni" ];

  installPhase = ''
    runHook preInstall

    themeDir="$out/share/plymouth/themes/dendritic"
    mkdir -p "$themeDir"
    cp -a ${nixos-bgrt-plymouth}/share/plymouth/themes/nixos-bgrt/images "$themeDir/images"
    substitute "$plymouthIniPath" "$themeDir/dendritic.plymouth" \
      --replace-fail '@IMAGES@' "$themeDir/images"

    runHook postInstall
  '';

  meta = {
    description = "Plymouth two-step theme: NixOS logo + Stylix base00/base0D";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
