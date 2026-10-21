# Trae IDE (ByteDance VS Code fork) from the upstream Linux .deb.
#
# The .deb ships Electron plus closed-source .so files (libaha_net,
# libsscronet, …) and extensions download native helpers at runtime, so the
# tree is not patchelf'd. It runs inside a buildFHSEnv instead, the same
# model as nixpkgs `antigravity-ide-fhs` / `vscode-fhs`.
{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  buildFHSEnv,
  writeShellScript,
}:
let
  pname = "trae";
  version = "2.3.91093";

  sources = {
    x86_64-linux = {
      arch = "x64";
      hash = "sha256-FL4gkgMxITTLupq5ZWKXfsUgvHKvHNeVBHtaZLXKT+Y=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-cFPIevej/rphlFdRSMXQDQpCFvVyHta3BTFoZnsDYgM=";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  src' = sources.${system} or (throw "trae: unsupported system ${system}");

  unwrapped = stdenvNoCC.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://lf-cdn.trae.ai/obj/trae-ai-us/pkg/app/releases/stable/${version}/linux/TRAE-linux-${src'.arch}.deb";
      inherit (src') hash;
    };

    nativeBuildInputs = [ dpkg ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-owner --no-same-permissions
      runHook postUnpack
    '';

    # Vendor binaries + signed .asc sidecars: leave bytes untouched.
    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib" "$out/share"
      cp -r usr/share/trae "$out/lib/trae"
      cp -r usr/share/pixmaps usr/share/mime usr/share/appdata "$out/share/"
      if [ -d usr/share/bash-completion ]; then
        cp -r usr/share/bash-completion "$out/share/"
      fi
      mkdir -p "$out/share/applications"
      for f in usr/share/applications/*.desktop; do
        sed -e "s|/usr/share/trae/trae|trae|g" "$f" >"$out/share/applications/$(basename "$f")"
      done
      runHook postInstall
    '';

    meta = {
      description = "Trae AI IDE (unwrapped upstream tree)";
      homepage = "https://www.trae.ai";
      license = lib.licenses.unfree;
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      platforms = builtins.attrNames sources;
    };
  };
in
buildFHSEnv {
  inherit pname version;

  # Electron + Chromium runtime, plus what VS Code extensions commonly dlopen.
  targetPkgs =
    pkgs: with pkgs; [
      unwrapped
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      curl
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      git
      gnutls
      glib
      gtk3
      icu
      krb5
      libdrm
      libgbm
      libgcrypt
      libglvnd
      libnotify
      libpulseaudio
      libsecret
      # libmsalruntime.so (Microsoft account sign-in) links WebKitGTK.
      libsoup_3
      libuuid
      libxkbcommon
      libxkbfile
      mesa
      nspr
      nss
      openssl
      pango
      stdenv.cc.cc.lib
      systemd
      udev
      vulkan-loader
      wayland
      webkitgtk_4_1
      xdg-utils
      zlib
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxtst
      libxcb
      libxshmfence
    ];

  runScript = writeShellScript "trae-launch" ''
    exec ${unwrapped}/lib/trae/trae \
      ''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}} \
      "$@"
  '';

  extraInstallCommands = ''
    mkdir -p "$out/share"
    ln -s ${unwrapped}/share/pixmaps "$out/share/pixmaps"
    ln -s ${unwrapped}/share/mime "$out/share/mime"
    ln -s ${unwrapped}/share/applications "$out/share/applications"
  '';

  passthru = {
    inherit unwrapped;
  };

  meta = unwrapped.meta // {
    description = "Trae AI IDE (FHS-wrapped)";
    mainProgram = "trae";
  };
}
