{ stdenvNoCC, fetchurl }:

# Create a derivation package for macOS InstantView application
stdenvNoCC.mkDerivation (self:{ 
  name = "instantview";
  version = "V3.21R0001";

  src = fetchurl {
    name = "instantview";
    url = "https://www.siliconmotion.com/downloads/macOS_InstantView_${self.version}.dmg";
    hash = "sha256-Fs0PB7/1EceI11qFCiFxIXZChVHtOdfjojZYRwj8Bpc=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = 
  let hdiutil = "/usr/bin/hdiutil"; in ''
  dir=$(mktemp -d)
  ${hdiutil} attach "$src" -mountpoint "$dir"
  detach() {
    while ! ${hdiutil} detach -force "$dir"; do
    echo "failed to detach image at $dir"
    sleep 1
    done
  }
  trap detach EXIT

  mkdir -p $out/Applications
  cp -r "$dir"/'macOS InstantView.app' $out/Applications/
  '';
})
