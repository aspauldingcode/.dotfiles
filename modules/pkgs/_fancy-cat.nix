{ pkgs }:

let
  libvaxis = pkgs.fetchzip {
    url = "https://github.com/rockorager/libvaxis/archive/f6be46dbda3633dcfe20beb0d62e7f18f5ab7121.tar.gz";
    sha256 = "182cinyqqm66prpd4gxdiyc86q0m5lprik8zha8xgy8cmwsw259i";
  };

  zigimg = pkgs.fetchzip {
    url = "https://github.com/ivanstepanovftw/zigimg/archive/d7b7ab0ba0899643831ef042bd73289510b39906.tar.gz";
    sha256 = "10373hxywls72gc3aqhfl5hirspmrs9611pfxmqg9ylph6b16ixy";
  };

  zg = pkgs.fetchzip {
    url = "https://codeberg.org/chaten/zg/archive/749197a3f9d25e211615960c02380a3d659b20f9.tar.gz";
    sha256 = "1jk0y1p2c1alh2s659vd8l2146vpm5fsfx5f8k87csshvxy8qcf3";
  };

  fzwatch = pkgs.fetchzip {
    url = "https://github.com/freref/fzwatch/archive/cb462430687059e09c638cccf1cadfebeaef018a.tar.gz";
    sha256 = "05x7varahnjzc34kscz1zznq6pl8hjsv158l7dfagdrvaahcvn5h";
  };

  fastb64z = pkgs.fetchzip {
    url = "https://github.com/freref/fastb64z/archive/3defc5d33162670c28e42af073cf9bc003017da6.tar.gz";
    sha256 = "0hs6jv7jazhfjdql1ahnkqmr3zixxvr1sdd250zkcmznlah299j1";
  };
in
pkgs.stdenv.mkDerivation rec {
  pname = "fancy-cat";
  version = "0.5.0";

  src = pkgs.fetchFromGitHub {
    owner = "freref";
    repo = "fancy-cat";
    rev = "v0.5.0";
    fetchSubmodules = true;
    hash = "sha256-bHMrVrS8DuTmVJrFjTzWanhCjf7wC2QBW0Lyi0Wh5Bc=";
  };

  nativeBuildInputs = [
    pkgs.zig_0_15.hook
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.mupdf
    pkgs.harfbuzz
    pkgs.freetype
    pkgs.jbig2dec
    pkgs.libjpeg
    pkgs.openjpeg
    pkgs.gumbo
    pkgs.mujs
    pkgs.libz
  ]
  ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    pkgs.apple-sdk
    pkgs.libiconv
  ];

  postPatch = ''
    mkdir -p deps/vaxis deps/fzwatch deps/fastb64z
    cp -r ${libvaxis}/* deps/vaxis/
    cp -r ${fzwatch}/* deps/fzwatch/
    cp -r ${fastb64z}/* deps/fastb64z/

    chmod -R +w deps

    # Patch vaxis dependencies
    mkdir -p deps/vaxis/deps/zigimg deps/vaxis/deps/zg
    cp -r ${zigimg}/* deps/vaxis/deps/zigimg/
    cp -r ${zg}/* deps/vaxis/deps/zg/

    cat <<EOF > deps/vaxis/build.zig.zon
    .{
        .name = .vaxis,
        .version = "0.5.1",
        .minimum_zig_version = "0.15.1",
        .dependencies = .{
            .zigimg = .{
                .path = "deps/zigimg",
            },
            .zg = .{
                .path = "deps/zg",
            },
        },
        .paths = .{
            "LICENSE",
            "build.zig",
            "build.zig.zon",
            "src",
        },
    }
    EOF

    # Force use of system mupdf by removing the vendor Makefile
    rm -rf deps/mupdf

    # Patch build.zig to use system paths and pkg-config
    sed -i 's|/opt/homebrew/include|${pkgs.mupdf.dev}/include|g' build.zig
    sed -i 's|/opt/homebrew/lib|${pkgs.mupdf.out}/lib|g' build.zig
    sed -i 's|/usr/local/include|${pkgs.mupdf.dev}/include|g' build.zig
    sed -i 's|/usr/local/lib|${pkgs.mupdf.out}/lib|g' build.zig

    # Patch zg build.zig to use global optimization level for codegen tools (was hardcoded to .Debug)
    sed -i 's/.optimize = .Debug/.optimize = optimize/g' deps/vaxis/deps/zg/build.zig

    cat <<EOF > build.zig.zon
    .{
        .name = .fancy_cat,
        .version = "0.5.0",
        .fingerprint = 0x866b011980aee471,
        .minimum_zig_version = "0.15.0",
        .dependencies = .{
            .vaxis = .{
                .path = "deps/vaxis",
            },
            .fzwatch = .{
                .path = "deps/fzwatch",
            },
            .fastb64z = .{
                .path = "deps/fastb64z",
            },
        },
        .paths = .{
            "build.zig",
            "build.zig.zon",
            "src",
        },
    }
    EOF
  '';

  zigBuildFlags = [ "-Doptimize=ReleaseSmall" ];

  meta = with pkgs.lib; {
    description = "PDF viewer for terminals using the Kitty image protocol";
    homepage = "https://github.com/freref/fancy-cat";
    license = licenses.agpl3Only;
    platforms = platforms.unix;
    mainProgram = "fancy-cat";
  };
}
