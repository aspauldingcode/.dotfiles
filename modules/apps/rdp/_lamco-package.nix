{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  openssl,
  pipewire,
  libva,
  libdrm,
  zlib,
  glib,
  dbus,
  systemd,
  pam,
  libxkbcommon,
  openh264,
  wayland,
  gcc-unwrapped,
}:

stdenv.mkDerivation rec {
  pname = "lamco-rdp-server";
  version = "1.4.4";

  src = fetchurl {
    url = "https://github.com/lamco-admin/lamco-rdp-server/releases/download/v${version}/lamco-rdp-server_${version}-1_amd64.deb";
    hash = "sha256-vFSVmsgj1EQE0JxXABj1xFv42iq505+uKD2gAFhBYgs=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    openssl
    pipewire
    libva
    libdrm
    zlib
    glib
    dbus
    systemd
    pam
    libxkbcommon
    openh264
    wayland
    gcc-unwrapped.lib
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    install -Dm755 usr/bin/lamco-rdp-server $out/bin/.lamco-rdp-server-unwrapped
    install -Dm755 usr/bin/lamco-rdp-server-gui $out/bin/.lamco-rdp-server-gui-unwrapped
    cp -a usr/share/* $out/share/
    makeWrapper $out/bin/.lamco-rdp-server-unwrapped $out/bin/lamco-rdp-server \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          openh264
          wayland
        ]
      }" \
      --set-default OPENH264_LIBRARY_PATH "${openh264}/lib/libopenh264.so"
    makeWrapper $out/bin/.lamco-rdp-server-gui-unwrapped $out/bin/lamco-rdp-server-gui \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          openh264
          wayland
        ]
      }" \
      --set-default OPENH264_LIBRARY_PATH "${openh264}/lib/libopenh264.so"
    runHook postInstall
  '';

  # Binary is x86_64-linux only (upstream ships amd64 deb).
  meta = {
    description = "Wayland-native RDP server (shares the existing session via XDG portals)";
    homepage = "https://github.com/lamco-admin/lamco-rdp-server";
    license = lib.licenses.asl20; # also proprietary commercial terms for multi-server
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "lamco-rdp-server";
  };
}
