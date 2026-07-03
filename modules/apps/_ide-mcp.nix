# Shared MCP server definitions for Cursor, Antigravity, and VS Code.
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
  ideMcpEnabled = cursorEnabled || antigravityEnabled || vscodeEnabled;

  lldbMcpPkg = import ../pkgs/_lldb-mcp.nix { inherit pkgs; };
  lldbMcpExe = lib.getExe lldbMcpPkg;

  agentDevicePkg = import ../pkgs/_agent-device.nix { inherit pkgs; };
  agentDeviceExe = lib.getExe agentDevicePkg;

  home = config.home.homeDirectory;
  nixExe = "${pkgs.nix}/bin/nix";
  uvxExe = lib.getExe' pkgs.uv "uvx";
  npxExe = "${pkgs.nodejs}/bin/npx";
  wawonaRepoRoot = cfg.wawonaRepoRoot;

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

  xcodebuildMcpPkg = pkgs.writeShellScriptBin "xcodebuild-mcp" ''
    export PATH="${mcpPath}"
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    exec ${npxExe} -y xcodebuildmcp@latest mcp
  '';
  xcodebuildMcpExe = lib.getExe xcodebuildMcpPkg;

  wwnMcpServer = {
    command = nixExe;
    args = [
      "run"
      "${cfg.wwnMcpFlake}#wwn-mcp"
      "--"
      "serve"
      "--transport"
      "stdio"
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

  xcodebuildMcpServer = {
    command = xcodebuildMcpExe;
    args = [ ];
    env = {
      PATH = mcpPath;
      DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
    };
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
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
    };
  };

  ghidraMcpServer = {
    command = nixExe;
    args = [
      "--option"
      "warn-dirty"
      "false"
      "run"
      "--no-write-lock-file"
      "${cfg.ghidra.flake}#server"
      "--"
      "--ghidra-server"
      cfg.ghidra.serverUrl
    ];
  };

  wawonaMcpServers = {
    wwn-mcp = wwnMcpServer;
    nixos = nixosMcpServer;
    xcodebuild = xcodebuildMcpServer;
  }
  // lib.optionalAttrs cfg.lldb.enable {
    lldb = lldbMcpServer;
  }
  // lib.optionalAttrs cfg.agentDevice.enable {
    agent-device = agentDeviceMcpServer;
  };

  userMcpServers =
    wawonaMcpServers
    // lib.optionalAttrs cfg.ghidra.enable {
      ghidra = ghidraMcpServer;
    };

  mcpJson = servers: {
    force = true;
    text = builtins.toJSON { mcpServers = servers; };
  };

  ideMcpFiles = prefix: {
    "${prefix}/mcp.json" = mcpJson userMcpServers;
    "Wawona/${prefix}/mcp.json" = mcpJson wawonaMcpServers;
    "${lib.removePrefix "${home}/" wawonaRepoRoot}/${prefix}/mcp.json" = mcpJson wawonaMcpServers;
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
        default = "${config.home.homeDirectory}/GhidraMCP_Vibe_RSE";
      };
      serverUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8080/";
      };
    };

    lldb = {
      enable = lib.mkEnableOption "LLDB MCP server in user-global IDE mcp.json";
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
    dendritic.ide.mcp.ghidra.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.lldb.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.agentDevice.enable = lib.mkDefault (
      pkgs.stdenv.isDarwin && (config.dendritic.mobile.enable or false)
    );

    home.packages =
      lib.optionals pkgs.stdenv.isDarwin [ xcodebuildMcpPkg ]
      ++ lib.optionals cfg.lldb.enable [ lldbMcpPkg ]
      ++ lib.optionals cfg.agentDevice.enable [
        agentDevicePkg
      ]
      ++ lib.optionals cursorEnabled [
        pkgs.nodejs
      ];

    home.file =
      lib.optionalAttrs cursorEnabled (ideMcpFiles ".cursor")
      // lib.optionalAttrs antigravityEnabled (ideMcpFiles ".antigravity")
      // lib.optionalAttrs vscodeEnabled (ideMcpFiles ".vscode")
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
