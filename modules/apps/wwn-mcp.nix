# Install wwn-mcp on PATH (stdio MCP, same host model as mcp-nixos).
# Cursor mcp.json uses `lib.getExe` of this package — see `_ide-mcp.nix`.
#
# Disable on aarch64-linux: nixpkgs `fastembed` is meta.badPlatforms there
# (mba-asahi / microvm). Import the HM module unconditionally — `pkgs` in
# `imports` is infinite recursion.
{ inputs, ... }:
{
  flake.modules.homeManager.dendritic =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      wwnMcpOk = !(pkgs.stdenv.hostPlatform.isAarch64 && pkgs.stdenv.hostPlatform.isLinux);
      localCorpus = "${config.home.homeDirectory}/Wawona/wwn-mcp/corpus.toml";
    in
    {
      imports = [ inputs.wwn-mcp.homeModules.wwn-mcp ];

      programs.wwn-mcp = {
        enable = wwnMcpOk;
        # Live checkout so `../wwn-*` sibling paths in corpus.toml resolve.
        corpusManifest = localCorpus;
      };

      # Darwin has no systemd user timers; seed knowledge index after switch
      # without blocking on a full sibling fetch.
      home.activation.wwnMcpEnsureIndex = lib.mkIf wwnMcpOk (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          data="${config.programs.wwn-mcp.dataDir}"
          db="$data/index.sqlite"
          exe="${config.programs.wwn-mcp.package}/bin/wwn-mcp"
          mkdir -p "$data"
          export WWN_MCP_DATA_DIR="$data"
          export WWN_MCP_CORPUS_TOML="${localCorpus}"
          export FASTEMBED_CACHE_PATH="$data/models"
          if [ ! -f "$db" ]; then
            echo "wwn-mcp: seeding knowledge index…"
            "$exe" index --knowledge || true
          fi
        ''
      );
    };
}
