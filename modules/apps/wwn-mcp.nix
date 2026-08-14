# Install wwn-mcp on PATH (stdio MCP, same host model as mcp-nixos).
# Cursor mcp.json uses `lib.getExe` of this package — see `_ide-mcp.nix`.
{ inputs, ... }:
{
  flake.modules.homeManager.dendritic =
    {
      config,
      lib,
      ...
    }:
    let
      localCorpus = "${config.home.homeDirectory}/Wawona/wwn-mcp/corpus.toml";
    in
    {
      imports = [ inputs.wwn-mcp.homeModules.wwn-mcp ];

      programs.wwn-mcp = {
        enable = true;
        # Live checkout so `../wwn-*` sibling paths in corpus.toml resolve.
        corpusManifest = localCorpus;
      };

      # Darwin has no systemd user timers; seed knowledge index after switch
      # without blocking on a full sibling fetch.
      home.activation.wwnMcpEnsureIndex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
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
      '';
    };
}
