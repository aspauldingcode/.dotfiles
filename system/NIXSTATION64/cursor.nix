{
  lib,
  fetchurl,
  mkDerivation,
  appimageTools,
  makeWrapper,
}:

let
  pname = "cursor";
  version = "latest"; # Specify the correct version if available
  name = "${pname}-${version}";
  src = fetchurl {
    url = "https://downloader.cursor.sh/linux/appImage/x64";
    hash = "sha256-INSERT_HASH_HERE"; # Replace with the actual hash
  };
  appimage = appimageTools.wrapType2 { inherit version pname src; };
  appimageContents = appimageTools.extractType2 { inherit version pname src; };
in
mkDerivation {
  pname = pname;
  version = version;
  src = appimage;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    mv bin/${pname}-${version} bin/${pname}
    mkdir -p $out/bin
    cp -r bin/${pname} $out/bin
    mkdir -p $out/share/${pname}
    cp -a ${appimageContents}/locales $out/share/${pname}
    cp -a ${appimageContents}/resources $out/share/${pname}
    cp -a ${appimageContents}/usr/share/icons $out/share/icons
    install -Dm 644 ${appimageContents}/${pname}.desktop -t $out/share/applications/
    substituteInPlace $out/share/applications/${pname}.desktop --replace "AppRun" "${pname}"
    wrapProgram $out/bin/${pname} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}} --no-update"
    runHook postInstall
  '';
  meta = with lib; {
    description = "Cursor is a powerful tool for code editing and collaboration.";
    longDescription = ''
      Cursor is a state-of-the-art code editor designed to streamline coding
      and collaboration. It offers advanced features and a modern interface
      to enhance productivity for developers.
    '';
    homepage = "https://cursor.com";
    license = licenses.unfree;
    maintainers = with maintainers; [ yourName ]; # Replace with your actual username
    platforms = [ "x86_64-linux" ];
  };
}
