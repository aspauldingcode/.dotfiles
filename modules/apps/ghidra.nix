# Install GhidraVibe MCP on PATH (stdio, same host model as mcp-nixos / wwn-mcp).
# Cursor mcp.json uses lib.getExe' of this package — see `_ide-mcp.nix`.
#
# Full engine stays optional (`installEngine`): mba keeps nix-run wrappers for
# the GUI so home switch does not force the fat Ghidra tree unless wanted.
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
      vibeFlake = "${config.home.homeDirectory}/GhidraVibe";
      nixExe =
        if builtins.pathExists "/nix/var/nix/profiles/default/bin/nix" then
          "/nix/var/nix/profiles/default/bin/nix"
        else
          "${pkgs.nix}/bin/nix";
      nixRun = ''${nixExe} --extra-experimental-features "nix-command flakes"'';
    in
    {
      imports = [ inputs.ghidra-vibe.homeModules.default ];

      programs.ghidra-vibe = {
        enable = true;
        # MCP bins only in the profile; GUI still via nix run below.
        installEngine = false;
        mcp.enable = true;
      };

      # Prefer GhidraVibe GUI / helpers over stock pkgs.ghidra.
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
      };
    };
}
