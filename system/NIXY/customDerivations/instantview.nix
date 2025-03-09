{
  stdenvNoCC,
  fetchurl,
  _7zz,
}:

stdenvNoCC.mkDerivation (self: {
  pname = "instantview";
  version = "V3.22R0002";

  src = fetchurl {
    url = "https://www.siliconmotion.com/downloads/macOS_InstantView_${self.version}.dmg";
    hash = "sha256-PdgX9zCrVYtNbuOCYKVo9cegCG/VY7QXetivVsUltbg=";
  };

  nativeBuildInputs = [ _7zz ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"

    # Extract the DMG using 7zip
    7zz x "$src" -oextracted -y

    # Find the extracted app bundle
    appPath=$(find extracted -name 'macOS InstantView.app' -type d | head -n 1)

    if [ -z "$appPath" ]; then
      echo "Error: macOS InstantView.app not found in extracted DMG"
      exit 1
    fi

    mv "$appPath" "$out/Applications/"

    runHook postInstall
  '';
})
