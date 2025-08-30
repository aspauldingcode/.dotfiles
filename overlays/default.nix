# Custom overlays for package modifications and additions
{inputs}: final: prev: {
  # Custom package modifications can go here

  # Fix for air-formatter - make it available in stable pkgs by pulling from unstable
  # This ensures compatibility with nixvim and other tools that expect it in pkgs
  air-formatter =
    if prev ? unstable && prev.unstable ? air-formatter
    then prev.unstable.air-formatter
    else if final ? unstable && final.unstable ? air-formatter
    then final.unstable.air-formatter
    else throw "air-formatter not found in unstable packages";

  # Create a Darwin-compatible wayland that's essentially a no-op
  wayland = if final.stdenv.isDarwin 
    then final.runCommand "wayland-darwin-stub" {} ''
      mkdir -p $out/lib/pkgconfig $out/include $out/bin
      
      # Create minimal pkgconfig files
      cat > $out/lib/pkgconfig/wayland-client.pc << EOF
Name: wayland-client
Description: Wayland client library (Darwin stub)
Version: 1.24.0
Libs: 
Cflags: 
EOF
      
      cat > $out/lib/pkgconfig/wayland-server.pc << EOF
Name: wayland-server  
Description: Wayland server library (Darwin stub)
Version: 1.24.0
Libs:
Cflags:
EOF
      
      cat > $out/lib/pkgconfig/wayland-scanner.pc << EOF
Name: wayland-scanner
Description: Wayland scanner (Darwin stub)
Version: 1.24.0
Libs:
Cflags:
EOF
      
      # Create stub headers
      mkdir -p $out/include
      touch $out/include/wayland-client.h
      touch $out/include/wayland-server.h
      
      # Create stub wayland-scanner binary
      cat > $out/bin/wayland-scanner << 'EOF'
#!/bin/bash
echo "wayland-scanner stub for Darwin - doing nothing"
exit 0
EOF
      chmod +x $out/bin/wayland-scanner
      
      echo "Wayland stub for Darwin" > $out/README
    '' // {
      version = "1.24.0";
      src = null; # Stub doesn't need source
      meta = {
        description = "Wayland stub for Darwin";
        homepage = "https://wayland.freedesktop.org/";
        license = final.lib.licenses.mit;
        maintainers = [];
        platforms = final.lib.platforms.darwin;
      };
    }
    else prev.wayland;

  # Create a Darwin-compatible wayland-scanner that's essentially a no-op
  wayland-scanner = if final.stdenv.isDarwin
    then final.runCommand "wayland-scanner-darwin-stub" {} ''
      mkdir -p $out/bin
      
      # Create stub wayland-scanner binary
      cat > $out/bin/wayland-scanner << 'EOF'
#!/bin/bash
echo "wayland-scanner stub for Darwin - doing nothing"
exit 0
EOF
      chmod +x $out/bin/wayland-scanner
      
      echo "Wayland-scanner stub for Darwin" > $out/README
    '' // {
      version = "1.24.0";
      meta = {
        description = "Wayland scanner stub for Darwin";
        homepage = "https://wayland.freedesktop.org/";
        license = final.lib.licenses.mit;
        maintainers = [];
        platforms = final.lib.platforms.darwin;
        mainProgram = "wayland-scanner";
      };
    }
    else prev.wayland-scanner;

  # Fix gpgme tests failing on Darwin
  gpgme = prev.gpgme.overrideAttrs (oldAttrs: {
    doCheck = !final.stdenv.isDarwin;
  });

  # Fix libdrm to disable Valgrind on Darwin
  libdrm = prev.libdrm.overrideAttrs (oldAttrs: {
    buildInputs = final.lib.filter (dep: 
      !(final.lib.hasPrefix "valgrind" (final.lib.getName dep))
    ) (oldAttrs.buildInputs or []);
    
    mesonFlags = (oldAttrs.mesonFlags or []) ++ final.lib.optionals final.stdenv.isDarwin [
      "-Dvalgrind=disabled"
    ];
  });

  # Create a Darwin-compatible qtwayland that's essentially a no-op
  qtwayland = if final.stdenv.isDarwin 
    then final.runCommand "qtwayland-darwin-stub" {} ''
      mkdir -p $out
      echo "QtWayland stub for Darwin" > $out/README
    ''
    else prev.qtwayland;

  # Fix KDE packages to work on Darwin
  libsForQt5 = prev.libsForQt5 // {
    kguiaddons = prev.libsForQt5.kguiaddons.overrideAttrs (oldAttrs: {
      buildInputs = final.lib.filter (dep: 
        !(final.lib.hasInfix "wayland" (final.lib.getName dep))
      ) (oldAttrs.buildInputs or []);
      
      cmakeFlags = (oldAttrs.cmakeFlags or []) ++ final.lib.optionals final.stdenv.isDarwin [
        "-DCMAKE_DISABLE_FIND_PACKAGE_Wayland=ON"
        "-DCMAKE_DISABLE_FIND_PACKAGE_WaylandClient=ON"
      ];
    });

    kconfigwidgets = prev.libsForQt5.kconfigwidgets.overrideAttrs (oldAttrs: {
      buildInputs = final.lib.filter (dep: 
        !(final.lib.hasInfix "wayland" (final.lib.getName dep))
      ) (oldAttrs.buildInputs or []);
      
      cmakeFlags = (oldAttrs.cmakeFlags or []) ++ final.lib.optionals final.stdenv.isDarwin [
        "-DCMAKE_DISABLE_FIND_PACKAGE_Wayland=ON"
      ];
    });
  };

  # Mobile-specific packages
  mobile = {
    # Mobile development tools
    inherit
      (prev)
      android-tools
      fastboot
      heimdall
      ;
  };

  # Development tools with custom configurations
  dev = {
    inherit
      (prev)
      git
      neovim
      tmux
      ;
  };
}
