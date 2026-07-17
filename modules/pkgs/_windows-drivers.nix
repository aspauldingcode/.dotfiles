# Build a Windows INF tree for MSI Sword 15 A11UD (and similar Tiger Lake + RTX 30).
#
# Pinned fetchurl packs are expanded here. Extra vendor zips can be dropped into
# /var/cache/dendritic-windows/drivers-extra and are rsync'd at stage time.
{
  lib,
  stdenvNoCC,
  fetchurl,
  p7zip,
  unzip,
  packs ? [ ],
}:
let
  packDrvs = map (
    pack:
    stdenvNoCC.mkDerivation {
      name = "dendritic-windrv-${pack.name}";
      src = fetchurl {
        url = pack.url;
        sha256 = pack.sha256;
      };
      nativeBuildInputs = [
        p7zip
        unzip
      ];
      dontUnpack = true;
      installPhase = ''
        runHook preInstall
        dest="$out/${pack.name}"
        mkdir -p "$dest"

        unpack_one() {
          local archive=$1
          local outdir=$2
          mkdir -p "$outdir"
          case "$archive" in
            *.zip)
              unzip -q "$archive" -d "$outdir" || 7z x -y -bd -o"$outdir" "$archive"
              ;;
            *)
              7z x -y -bd -o"$outdir" "$archive" || true
              if [ -z "$(find "$outdir" -iname '*.inf' -print -quit)" ]; then
                mkdir -p "$outdir/_streams"
                7z x -t# -y -bd -o"$outdir/_streams" "$archive" || true
                if [ -f "$outdir/_streams/2.7z" ]; then
                  7z x -y -bd -o"$outdir" "$outdir/_streams/2.7z" || true
                fi
                rm -rf "$outdir/_streams"
              fi
              ;;
          esac
        }

        unpack_one "$src" "$dest"

        # Nested vendor payloads (e.g. MSI zip → NSIS Setup.exe → driver/*.inf).
        if [ -z "$(find "$dest" -iname '*.inf' -print -quit)" ]; then
          mkdir -p "$dest/_nested"
          find "$dest" -type f \( -iname '*.exe' -o -iname '*.zip' \) ! -path '*/_nested/*' | while read -r inner; do
            [ -n "$inner" ] || continue
            base="$(basename "$inner")"
            case "$base" in
              *etup*.exe|*Setup*.exe|*setup*.exe)
                cp -f "$inner" "$dest/$base" || true
                ;;
            esac
            unpack_one "$inner" "$dest/_nested"
          done

          if [ -n "$(find "$dest/_nested" -iname '*.inf' -print -quit)" ]; then
            if [ -d "$dest/_nested/driver/Win10/amd64" ]; then
              mkdir -p "$dest/driver/Win10/amd64"
              cp -a "$dest/_nested/driver/Win10/amd64/." "$dest/driver/Win10/amd64/"
            else
              cp -a "$dest/_nested/." "$dest/"
            fi
          fi
          rm -rf "$dest/_nested"
        fi

        # Keep top-level Setup.exe for silent (/S) install on first Windows boot.
        find "$dest" -maxdepth 2 -type f -iname '*setup*.exe' | while read -r setup; do
          cp -f "$setup" "$dest/$(basename "$setup")" || true
        done

        if [ -z "$(find "$dest" -iname '*.inf' -print -quit)" ]; then
          echo "dendritic-windows-drivers: no INF in ${pack.name}" >&2
          find "$dest" -maxdepth 3 -type f | head -50 >&2 || true
          exit 1
        fi

        rm -rf \
          "$dest/PhysX" \
          "$dest/FrameViewSDK" \
          "$dest/NvApp" \
          "$dest/ShadowPlay" \
          "$dest/PPC" \
          "$dest/NVI2" \
          2>/dev/null || true

        if [ -n "$(find "$dest" -maxdepth 1 -iname '*setup*.exe' -print -quit)" ]; then
          printf '%s\n' '/S' >"$dest/silent-args.txt"
        fi

        runHook postInstall
      '';
      preferredLocalBuild = true;
      allowSubstitutes = true;
    }
  ) packs;
in
stdenvNoCC.mkDerivation {
  name = "dendritic-windows-drivers";
  dontUnpack = true;
  installPhase = ''
        mkdir -p "$out"
        ${lib.concatMapStringsSep "\n" (d: ''
          cp -a --no-preserve=mode ${d}/. "$out/"
        '') packDrvs}
        chmod -R u+w "$out"
        cat >"$out/README.txt" <<EOF
    Dendritic Windows driver tree. Install with:
      pnputil /add-driver C:\\dendritic-drivers\\*.inf /subdirs /install
    SteelSeries / MSI Setup.exe packages may also run silently (/S) from apply-drivers.cmd.
    EOF
  '';
  passthru = {
    inherit packs;
  };
}
