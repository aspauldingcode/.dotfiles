{
  lib,
  stdenvNoCC,
  esbuild,
}:
stdenvNoCC.mkDerivation {
  pname = "dendritic-tinted-inject";
  version = "1.0.0";
  src = ./src;
  nativeBuildInputs = [ esbuild ];
  dontUnpack = true;
  buildPhase = ''
    runHook preBuild
    cp -r $src ./src
    chmod -R u+w src
    esbuild src/entry.ts \
      --bundle \
      --format=iife \
      --target=es2020 \
      --outfile=inject.js
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/extension
    cp inject.js $out/dendritic-tint.js
    cp inject.js $out/extension/inject.js
    cat > $out/extension/manifest.json <<'EOF'
    {
      "manifest_version": 3,
      "name": "Dendritic Tint",
      "version": "1.0.0",
      "description": "TintedBrowse LUT rewriter for Vesktop (Discord).",
      "content_scripts": [
        {
          "matches": [
            "https://discord.com/*",
            "https://*.discord.com/*",
            "https://discordapp.com/*",
            "https://*.discordapp.com/*"
          ],
          "js": ["inject.js"],
          "run_at": "document_start",
          "all_frames": true
        }
      ]
    }
    EOF
    runHook postInstall
  '';
  meta = {
    description = "TintedBrowse-identical LUT inject script for Vesktop and Spotify";
    license = lib.licenses.mit;
  };
}
