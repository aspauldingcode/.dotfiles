{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  inherit (lib) optional optionals optionalString;

  # Fetch the Okular source code
  okularSrc = pkgs.fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "graphics";
    repo = "okular";
    rev = "v23.08.2"; # Use a valid tag
    sha256 = "sha256-DODFFjBjdzpmkyY8bXWnVsQXU/gsJCBOFerKRJLmRTg=";
  };

  # Embedded kdegraphics-mobipocket derivation
  kdegraphics-mobipocket = pkgs.stdenv.mkDerivation rec {
    pname = "kdegraphics-mobipocket";
    version = "23.08.2";

    src = pkgs.fetchFromGitLab {
      domain = "invent.kde.org";
      owner = "graphics";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-Dvz6YOqwSimE9qHAHjy6rK6vWxmm2+K+x+XBI4CNdlY=";
    };

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      gettext
      libsForQt5.wrapQtAppsHook
      extra-cmake-modules
    ];

    buildInputs = with pkgs; [
      libsForQt5.qtbase
      libsForQt5.qtdeclarative
      libsForQt5.qttools
      libsForQt5.qtsvg
      libsForQt5.qtspeech
      libsForQt5.kcoreaddons
      libsForQt5.ki18n
      libsForQt5.kconfig
      libsForQt5.kconfigwidgets
      libsForQt5.kservice
      zlib
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DBUILD_TESTING=OFF"
      "-DCMAKE_INSTALL_LIBDIR=$out/lib"
    ];

    meta = with lib; {
      description = "Library for mobipocket support in KDE applications";
      homepage = "https://invent.kde.org/graphics/kdegraphics-mobipocket";
      license = licenses.gpl2Plus;
      platforms = platforms.linux ++ platforms.darwin;
    };
  };

  # Add libkexiv2 derivation
  libkexiv2 = pkgs.stdenv.mkDerivation rec {
    pname = "libkexiv2";
    version = "23.08.5";

    src = pkgs.fetchurl {
      url = "mirror://kde/stable/release-service/${version}/src/${pname}-${version}.tar.xz";
      sha256 = "sha256-MUEwMHmQZfrxfsvkbmpM5MEXWPXB1ZDrKWxS9Pwam/I=";
    };

    nativeBuildInputs = with pkgs; [
      cmake
      extra-cmake-modules
      libsForQt5.wrapQtAppsHook
    ];

    buildInputs = with pkgs; [
      libsForQt5.qtbase
      libsForQt5.kconfig
      libsForQt5.ki18n
      exiv2
    ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DBUILD_TESTING=OFF"
    ];

    meta = with lib; {
      description = "A library to manipulate picture metadata";
      homepage = "https://invent.kde.org/graphics/libkexiv2";
      license = licenses.gpl2Plus;
      platforms = platforms.unix;
    };
  };

  # Define the Okular derivation
  okular = pkgs.stdenv.mkDerivation rec {
    pname = "okular";
    version = "23.08.2"; # Match the version used in rev

    src = okularSrc;

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      pkg-config
      gettext
      libsForQt5.qttools
      libsForQt5.wrapQtAppsHook
      extra-cmake-modules
    ];

    buildInputs =
      with pkgs;
      [
        libsForQt5.qtbase
        libsForQt5.qtdeclarative
        libsForQt5.qtsvg
        libsForQt5.qtspeech
        libsForQt5.phonon
        poppler
        poppler_utils
        libsForQt5.poppler
        libsForQt5.karchive
        libsForQt5.kbookmarks
        libsForQt5.kconfig
        libsForQt5.kconfigwidgets
        libsForQt5.kcoreaddons
        libsForQt5.kcrash
        libsForQt5.kiconthemes
        libsForQt5.kio
        libsForQt5.kparts
        libsForQt5.kservice
        libsForQt5.ktextwidgets
        libsForQt5.kxmlgui
        libsForQt5.threadweaver
        libsForQt5.kpty
        libsForQt5.khtml
        libkexiv2
        discount
        freetype
        zlib
        libjpeg
        libpng
        kdegraphics-mobipocket
        ebook_tools
        djvulibre
        libzip
        chmlib
        libspectre
      ]
      ++ optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.Cocoa
      ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DBUILD_TESTING=OFF"
      "-DOKULAR_UI=desktop"
      "-DWITH_MOBIPOCKET=ON"
      "-DWITH_CHM=ON"
      "-DWITH_PDF=ON"
      "-DFORCE_NOT_REQUIRED_DEPENDENCIES=CHM;LibSpectre;Poppler;KF5::KAccountsIntegration;KF5::Purpose"
      "-DCMAKE_DISABLE_FIND_PACKAGE_KF5KAccountsIntegration=ON"
      "-DCMAKE_DISABLE_FIND_PACKAGE_KF5Purpose=ON"
      "-DCMAKE_DISABLE_FIND_PACKAGE_KF5KExiv2=ON"
      "-DCMAKE_VERBOSE_MAKEFILE=ON"
      "-DCMAKE_INSTALL_PREFIX=$out"
    ] ++ optional pkgs.stdenv.isDarwin "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.14";

    preConfigure = optionalString pkgs.stdenv.isDarwin ''
      export MACOSX_DEPLOYMENT_TARGET=10.14
    '';

    NIX_CFLAGS_COMPILE = optionalString pkgs.stdenv.isDarwin "-fno-strict-aliasing";

    postInstall = ''
      echo "Checking Okular installation..."
      echo "Listing contents of $out:"
      ls -R $out
      echo "Searching for okular binary:"
      find $out -name okular -type f
      echo "Checking Okular binary..."
      OKULAR_BIN=$(find $out -name okular -type f)
      if [ -n "$OKULAR_BIN" ]; then
        echo "Okular binary found at: $OKULAR_BIN"
        if [ -x "$OKULAR_BIN" ]; then
          echo "Okular binary is executable."
          wrapQtApp "$OKULAR_BIN"
        else
          echo "Okular binary is not executable."
          chmod +x "$OKULAR_BIN"
          echo "Made Okular binary executable."
          wrapQtApp "$OKULAR_BIN"
        fi
      else
        echo "Okular binary not found."
      fi
    '';

    meta = with lib; {
      description = "Okular: Universal document viewer";
      homepage = "https://okular.kde.org/";
      license = licenses.gpl2Plus;
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
in
{
  environment.systemPackages = [ okular ];
}
