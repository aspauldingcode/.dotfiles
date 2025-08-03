{pkgs}:
pkgs.stdenv.mkDerivation rec {
  name = "ammonia";
  version = "1.0";

  # Download the pre-compiled .pkg from the GitHub releases page
  src = pkgs.fetchurl {
    # Adjust the URL and version as needed.
    url = "https://github.com/corebedtime/ammonia/releases/download/${version}/ammonia.pkg";
    sha256 = "sha256-COrqtF1MVoqxs1heF1b/j0ysCglqyhcwnVZuA4TC8pQ=";
  };

  nativeBuildInputs = with pkgs; [
    unar
    gzip
    xar
  ];

  unpackPhase = ''
    mkdir -p $out
    cp ${src} $out/ammonia.pkg
    cd $out

    # Extract the pkg contents using pkgutil
    xar -xf ammonia.pkg

    # Extract the Payload
    cd Payload && gzip -d < Payload | cpio -i

    # Move everything up one level and cleanup
    cd ..
    mv Payload/* .
    rm -rf Payload Scripts Distribution ammonia.pkg *.plist
  '';

  dontBuild = true;
  dontInstall = true;

  meta = {
    description = "A derivation that extracts the Ammonia pre-compiled package using unar.";
    homepage = "https://github.com/corebedtime/ammonia/releases";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.darwin;
  };
}
