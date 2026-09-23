# Shared MCP server definitions for Cursor, Antigravity, VS Code, and Zed.
#
# Cursor and Antigravity share one canonical MCP server map. Keep their
# generated configurations identical so IDE-specific drift cannot silently
# remove tools or change commands, paths, or environment variables.
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.dendritic.ide.mcp;
  cursorEnabled = config.dendritic.apps.cursor.enable or false;
  antigravityEnabled = config.dendritic.apps.antigravity.enable or false;
  vscodeEnabled = config.dendritic.apps.vscode.enable or false;
  zedEnabled = config.dendritic.apps.zed.enable or false;
  ideMcpEnabled = cursorEnabled || antigravityEnabled || vscodeEnabled || zedEnabled;

  toZedContextServer =
    server:
    if (server.type or null) == "http" then
      { url = server.url; }
    else
      {
        command = server.command;
        args = server.args or [ ];
      }
      // lib.optionalAttrs (server ? env) { env = server.env; };

  lldbMcpPkg = import ../pkgs/_lldb-mcp.nix { inherit pkgs; };
  lldbMcpExe = lib.getExe lldbMcpPkg;

  agentDevicePkg = import ../pkgs/_agent-device.nix { inherit pkgs; };
  agentDeviceExe = lib.getExe agentDevicePkg;

  home = config.home.homeDirectory;
  # Prefer the live Determinate/system nix over pkgs.nix: /etc/nix/nix.conf may
  # enable features (e.g. provenance) that an older store nix does not know,
  # which breaks `nix run …#wwn-mcp` with "unknown experimental feature".
  nixExe =
    if builtins.pathExists "/nix/var/nix/profiles/default/bin/nix" then
      "/nix/var/nix/profiles/default/bin/nix"
    else
      "${pkgs.nix}/bin/nix";
  uvxExe = lib.getExe' pkgs.uv "uvx";
  uvExe = lib.getExe' pkgs.uv "uv";
  npxExe = "${pkgs.nodejs}/bin/npx";
  wawonaRepoRoot = cfg.wawonaRepoRoot;

  # GhidraVibe local stdio MCP (same host model as mcp-nixos / wwn-mcp).
  # Prefer home-manager `programs.ghidra-vibe.mcpPackage`; fall back to nix
  # shell of `#ghidra-vibe-mcp` only if that module is off.
  ghidraVibeMcpPkg =
    if
      (config.programs.ghidra-vibe.enable or false) && (config.programs.ghidra-vibe.mcp.enable or false)
    then
      config.programs.ghidra-vibe.mcpPackage
    else
      null;

  agentDevicePath =
    lib.makeBinPath (
      [
        agentDevicePkg
        pkgs.nodejs_24
        pkgs.coreutils
        pkgs.git
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        pkgs.android-tools
      ]
    )
    + ":/usr/bin:/bin:/usr/sbin:/sbin";

  # IDE-spawned MCP processes do not inherit shell PATH; use store paths.
  mcpPath =
    lib.makeBinPath (
      [
        pkgs.nodejs
        pkgs.coreutils
        pkgs.git
      ]
      ++ lib.optionals (!pkgs.stdenv.isDarwin) [ pkgs.lldb ]
    )
    + ":/usr/bin:/bin:/usr/sbin:/sbin";

  # macOS-only Xcode MCP wrappers (xctrace / xcodebuild). Not built on Linux.
  xcodebuildMcpPkg =
    if pkgs.stdenv.isDarwin then
      pkgs.writeShellScriptBin "xcodebuild-mcp" ''
        export PATH="${mcpPath}"
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
        # Pin cold-start: Antigravity MCP init times out on slow first npx fetch.
        exec ${npxExe} -y xcodebuildmcp@2.6.2 mcp
      ''
    else
      null;

  instrumentsMcpPkg =
    if pkgs.stdenv.isDarwin then
      pkgs.writeShellScriptBin "instruments-mcp" ''
        export PATH="${mcpPath}"
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
        exec ${npxExe} -y instrumentsmcp@latest
      ''
    else
      null;

  xcodeMcpEnv = {
    PATH = mcpPath;
    DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
  };

  # Force features the flake needs; drop unknown ones from /etc/nix/nix.conf
  # (e.g. provenance on older client nix).
  nixRunPrefix = [
    "--option"
    "experimental-features"
    "nix-command flakes"
    "--option"
    "warn-dirty"
    "false"
  ];

  # Prefer the home-manager package (programs.wwn-mcp) — same shape as
  # `uvx mcp-nixos`. Fall back to `nix run` only if the module is off.
  wwnMcpPkg =
    if (config.programs.wwn-mcp.enable or false) then config.programs.wwn-mcp.package else null;

  wwnMcpServer =
    if wwnMcpPkg != null then
      {
        command = lib.getExe wwnMcpPkg;
        args = [ ];
        env = {
          WWN_MCP_DATA_DIR = "${home}/.local/share/wwn-mcp";
          WWN_MCP_CORPUS_TOML = "${cfg.wwnMcpFlake}/corpus.toml";
        };
      }
    else
      {
        command = nixExe;
        args = nixRunPrefix ++ [
          "run"
          "${cfg.wwnMcpFlake}#wwn-mcp"
        ];
        env = {
          WWN_MCP_DATA_DIR = "${home}/.local/share/wwn-mcp";
          WWN_MCP_CORPUS_TOML = "${cfg.wwnMcpFlake}/corpus.toml";
        };
      };

  nixosMcpServer = {
    command = uvxExe;
    args = [ "mcp-nixos" ];
  };

  lldbMcpServer = {
    command = lldbMcpExe;
    args = [ ];
    env = {
      PATH = mcpPath;
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
    };
  };

  agentDeviceMcpServer = {
    command = agentDeviceExe;
    args = [ "mcp" ];
    env = {
      PATH = agentDevicePath;
      AGENT_DEVICE_NO_UPDATE_NOTIFIER = "1";
      # vphone lab profile + guest-ip resolution
      WAWONA_ROOT = "${home}/Wawona/Wawona";
      SSH_ASKPASS_REQUIRE = "never";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
    };
  };

  # Local stdio GhidraVibe MCP (no public URL; vibe auto-starts mcp-ext).
  ghidraAnalysisEnsure =
    if (config.programs.ghidra-vibe.enable or false) then
      "${config.programs.ghidra-vibe.analysisPackage}/bin/ghidra-vibe-analysis-ensure"
    else
      null;

  ghidraMcpEnv = {
    GHIDRA_MCP_URL = "http://127.0.0.1:8089";
  }
  // lib.optionalAttrs (ghidraAnalysisEnsure != null) {
    GHIDRA_VIBE_ANALYSIS_ENSURE = ghidraAnalysisEnsure;
  };

  ghidraVibeMcpServer =
    if ghidraVibeMcpPkg != null then
      {
        command = "${ghidraVibeMcpPkg}/bin/ghidra-vibe-mcp";
        args = [ ];
        env = ghidraMcpEnv;
      }
    else
      {
        command = nixExe;
        args = nixRunPrefix ++ [
          "shell"
          "--no-write-lock-file"
          "${cfg.ghidra.flake}#ghidra-vibe-mcp"
          "-c"
          "ghidra-vibe-mcp"
        ];
        env = ghidraMcpEnv;
      };

  ghidraVibeRagMcpServer =
    if ghidraVibeMcpPkg != null then
      {
        command = "${ghidraVibeMcpPkg}/bin/ghidra-vibe-rag-mcp";
        args = [ ];
      }
    else
      {
        command = nixExe;
        args = nixRunPrefix ++ [
          "shell"
          "--no-write-lock-file"
          "${cfg.ghidra.flake}#ghidra-vibe-mcp"
          "-c"
          "ghidra-vibe-rag-mcp"
        ];
      };

  xcodebuildMcpServer = lib.optionalAttrs pkgs.stdenv.isDarwin {
    xcodebuild = {
      command = lib.getExe xcodebuildMcpPkg;
      args = [ ];
      env = xcodeMcpEnv;
    };
  };

  instrumentsMcpServer = lib.optionalAttrs (pkgs.stdenv.isDarwin && cfg.instruments.enable) {
    instruments = {
      command = lib.getExe instrumentsMcpPkg;
      args = [ ];
      env = xcodeMcpEnv;
    };
  };

  # Lean set that stays under Antigravity's ~100 tool ceiling.
  # nixos≈2 + xcodebuild≈24 + wwn (small) ≪ 100.
  leanMcpServers = {
    wwn-mcp = wwnMcpServer;
    nixos = nixosMcpServer;
  }
  // xcodebuildMcpServer;

  # Shared Cursor / Antigravity set.
  heavyMcpServers =
    leanMcpServers
    // instrumentsMcpServer
    // lib.optionalAttrs cfg.lldb.enable { lldb = lldbMcpServer; }
    // lib.optionalAttrs cfg.agentDevice.enable { agent-device = agentDeviceMcpServer; }
    // lib.optionalAttrs cfg.ghidra.enable {
      ghidra-vibe = ghidraVibeMcpServer;
      ghidra-vibe-rag = ghidraVibeRagMcpServer;
    };

  # No agent-device here: Cursor merges User (~/.cursor/mcp.json) + project
  # mcp.json. Listing it in both shows two "agent-device" rows (User + Wawona).
  # Global heavy set already installs it once via userMcpServers.
  wawonaMcpServers =
    leanMcpServers
    // instrumentsMcpServer
    // lib.optionalAttrs cfg.lldb.enable { lldb = lldbMcpServer; };

  userMcpServers = heavyMcpServers;

  zedContextServers = lib.mapAttrs (_: toZedContextServer) userMcpServers;
  zedWawonaContextServers = lib.mapAttrs (_: toZedContextServer) wawonaMcpServers;

  # Cursor and Antigravity must remain in lockstep. The canonical user map is
  # deliberately reused rather than copied, which makes future additions and
  # removals apply to both IDEs atomically.
  antigravityMcpServers = userMcpServers;

  mcpJson = servers: {
    force = true;
    text = builtins.toJSON { mcpServers = servers; };
  };

  # Cursor / VS Code: ~/.cursor/mcp.json and <repo>/.cursor/mcp.json
  ideMcpFiles = prefix: {
    "${prefix}/mcp.json" = mcpJson userMcpServers;
    "Wawona/${prefix}/mcp.json" = mcpJson wawonaMcpServers;
    "${lib.removePrefix "${home}/" wawonaRepoRoot}/${prefix}/mcp.json" = mcpJson wawonaMcpServers;
  };

  # Antigravity reads Gemini paths, not ~/.antigravity-ide/mcp.json.
  # Live IDE path observed: ~/.gemini/antigravity/mcp_config.json
  antigravityMcpFiles =
    let
      wawonaRel = lib.removePrefix "${home}/" wawonaRepoRoot;
    in
    {
      ".gemini/antigravity/mcp_config.json" = mcpJson antigravityMcpServers;
      ".gemini/config/mcp_config.json" = mcpJson antigravityMcpServers;
      "Wawona/.agents/mcp_config.json" = mcpJson leanMcpServers;
      "${wawonaRel}/.agents/mcp_config.json" = mcpJson leanMcpServers;
    };
in
{
  options.dendritic.ide.mcp = {
    wwnMcpFlake = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Wawona/wwn-mcp";
      description = "Local wwn-mcp flake path (must include #wwn-mcp).";
    };

    wawonaRepoRoot = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/Wawona/Wawona";
      description = "Wawona app repo root (Xcode workspace).";
    };

    ghidra = {
      enable = lib.mkEnableOption "Ghidra MCP server in user-global IDE mcp.json";
      flake = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/GhidraVibe";
        description = ''
          Local GhidraVibe flake checkout. Prefer `programs.ghidra-vibe`
          (`#ghidra-vibe-mcp` stdio bins). Fallback: `nix shell …#ghidra-vibe-mcp`.
        '';
      };
      # Kept for docs/compat; Cursor mcp.json no longer injects these URLs.
      serverUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8089";
        description = "Optional engine URL for manual headless (not required by mcp.json).";
      };
      extUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8092";
        description = "Optional fixed mcp-ext URL (ghidra-vibe-mcp auto-binds ephemeral).";
      };
    };

    lldb = {
      enable = lib.mkEnableOption "LLDB MCP server in user-global IDE mcp.json";
    };

    instruments = {
      enable = lib.mkEnableOption "Instruments MCP server (xctrace profiling, leaks, memory) in IDE mcp.json (macOS only)";
    };

    agentDevice = {
      enable = lib.mkEnableOption "agent-device MCP server for iOS/Android simulator QA in IDE mcp.json";

      cursorRule = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install .cursor/rules/agent-device.mdc when Cursor is enabled.";
      };
    };
  };

  config = lib.mkIf ideMcpEnabled {
    # Shared Cursor and Antigravity defaults.
    dendritic.ide.mcp.ghidra.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.lldb.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.instruments.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.agentDevice.enable = lib.mkDefault (
      pkgs.stdenv.isDarwin && (config.dendritic.mobile.enable or false)
    );

    home.packages =
      lib.optionals pkgs.stdenv.isDarwin [ xcodebuildMcpPkg ]
      ++ lib.optionals (pkgs.stdenv.isDarwin && cfg.instruments.enable) [ instrumentsMcpPkg ]
      ++ lib.optionals cfg.lldb.enable [ lldbMcpPkg ]
      ++ lib.optionals cfg.agentDevice.enable [
        agentDevicePkg
      ]
      ++ lib.optionals cursorEnabled [
        pkgs.nodejs
      ]
      ++
        lib.optionals
          ((cursorEnabled || antigravityEnabled) && cfg.ghidra.enable && ghidraVibeMcpPkg != null)
          [
            ghidraVibeMcpPkg
          ];

      programs.zed-editor.userSettings.context_servers = lib.mkIf zedEnabled zedContextServers;

    home.file =
      lib.optionalAttrs cursorEnabled (ideMcpFiles ".cursor")
      // lib.optionalAttrs antigravityEnabled antigravityMcpFiles
      // lib.optionalAttrs vscodeEnabled (ideMcpFiles ".vscode")
      // lib.optionalAttrs zedEnabled (
        let
          wawonaRel = lib.removePrefix "${home}/" wawonaRepoRoot;
          zedSettings = {
            force = true;
            text = builtins.toJSON { context_servers = zedWawonaContextServers; };
          };
        in
        {
          "Wawona/.zed/settings.json" = zedSettings;
          "${wawonaRel}/.zed/settings.json" = zedSettings;
        }
      )
      // lib.optionalAttrs (cursorEnabled && cfg.agentDevice.enable && cfg.agentDevice.cursorRule) {
        ".cursor/rules/agent-device.mdc" = {
          force = true;
          text = ''
            ---
            description: Use agent-device for app and device automation
            alwaysApply: true
            ---

            Use agent-device only for app/device automation tasks.
            Before planning device work, run `agent-device --version` and read `agent-device help workflow`.
            For exploratory QA, read `agent-device help dogfood`.
            For logs, network, audio, traces, or runtime failures, read `agent-device help debugging`.
            For React Native component trees, props/state/hooks, slow renders, or rerenders, read `agent-device help react-devtools`.
            For React Native JavaScript heap growth, heap snapshots, or retained-object leaks, read `agent-device help cdp`.
            For React Native apps, overlays, Metro/Fast Refresh blockers, and routing to React DevTools or debugging evidence, read `agent-device help react-native`.

            Use MCP tools or the CLI in the integrated terminal.
            Prefer `open -> snapshot -i -> act -> re-snapshot -> verify -> close`.
            Keep mutating commands against one session serial.
            Capture screenshots, logs, network, perf, traces, recordings, and `.ad` replay scripts only when they add evidence.
          '';
        };
      };
  };
}
