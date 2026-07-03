{ pkgs }:

let
  src = pkgs.fetchFromGitHub {
    owner = "stass";
    repo = "lldb-mcp";
    rev = "a610f2d0d3835739c41762352442ba2a13958b38";
    hash = "sha256-EM9Qcdblh4qbjqvy1NzGbafjhBa1CdyqZK5Tl3Fz798=";
  };

  python = pkgs.python3.withPackages (ps: [ ps.mcp ]);
in
pkgs.writeShellScriptBin "lldb-mcp" ''
  exec ${python}/bin/python3 ${src}/lldb_mcp.py "$@"
''
