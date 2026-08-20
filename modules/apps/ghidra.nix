{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # Local GhidraVibe checkout (replaces retired GhidraMCP_Vibe_RSE).
      vibeFlake = "${config.home.homeDirectory}/GhidraVibe";
      nixExe =
        if builtins.pathExists "/nix/var/nix/profiles/default/bin/nix" then
          "/nix/var/nix/profiles/default/bin/nix"
        else
          "${pkgs.nix}/bin/nix";
      nixRun = ''${nixExe} --extra-experimental-features "nix-command flakes"'';
    in
    {
      # Prefer GhidraVibe (headless + native UI + Rust JSpace) over stock pkgs.ghidra.
      home.packages = [
        (pkgs.writeShellScriptBin "ghidra-vibe" ''
          exec ${nixRun} run --no-write-lock-file "${vibeFlake}#default" -- "$@"
        '')
        (pkgs.writeShellScriptBin "ghidra-vibe-jspace" ''
          exec ${nixRun} shell --no-write-lock-file "${vibeFlake}#ghidra-vibe-tools" -c ghidra-vibe-jspace "$@"
        '')
        (pkgs.writeShellScriptBin "ghidra-vibe-dyld" ''
          exec ${nixRun} shell --no-write-lock-file "${vibeFlake}#ghidra-vibe" -c ghidra-vibe-dyld "$@"
        '')
        (pkgs.writeShellScriptBin "ghidra-vibe-mcp-headless" ''
          exec ${nixRun} shell --no-write-lock-file "${vibeFlake}#mcp-headless" -c ghidra-vibe-mcp-headless "$@"
        '')
      ];

      home.sessionVariables = {
        GHIDRA_VIBE_SWING = "0";
        # Auto heap via detect-maxmem; override only when needed.
        # GHIDRA_VIBE_MAXMEM = "8G";
        GHIDRA_MCP_URL = "http://127.0.0.1:8089";
        GHIDRA_VIBE_GUI_URL = "http://127.0.0.1:8091";
        GHIDRA_VIBE_MCP_EXT_URL = "http://127.0.0.1:8092";
      };
    };
}
