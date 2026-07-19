{
  lib,
  python3Packages,
  writeShellApplication,
}:
let
  py = python3Packages.python.withPackages (ps: [ ps.hidapi ]);
  script = ./_dendritic-sword-kbd-bl.py;
in
writeShellApplication {
  name = "dendritic-sword-kbd-bl";
  runtimeInputs = [ py ];
  text = ''
    exec ${py}/bin/python3 ${script} "$@"
  '';
}
