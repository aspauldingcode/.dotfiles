# Shared MCP server definitions for Cursor, Antigravity, VS Code, and Zed.
#
# Antigravity enforces a hard ~100-tool ceiling across ALL MCP servers.
# Heavy servers (instruments≈29, lldb≈28, agent-device≈40, xcodebuild≈24,
# ghidra≈20) cannot all be enabled there at once. Cursor tolerates more;
# Antigravity therefore gets a lean default set unless
# `dendritic.ide.mcp.antigravity.includeHeavy = true`.
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

  # GhidraVibe MCP bridges live under #ghidra-vibe (share/ghidra-mcp/).
  # Old GhidraMCP_Vibe_RSE #server attr is gone; resolve at runtime from the
  # local checkout so tip WIP does not need a flake input lock.
  ghidraVibeRootExpr = ''root="$(dirname "$(dirname "$(command -v ghidra-vibe-rag-mcp)")")" '';

  ghidraVibeShell =
    name: innerText:
    let
      inner = pkgs.writeShellScript "${name}-inner" ''
        set -euo pipefail
        ${innerText}
      '';
    in
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      exec ${nixExe} ${lib.escapeShellArgs nixRunPrefix} shell \
        --no-write-lock-file "${cfg.ghidra.flake}#ghidra-vibe" -c ${inner} "$@"
    '';

  cursorGhidraMcpPkg = ghidraVibeShell "cursor-ghidra-mcp" ''
    ${ghidraVibeRootExpr}
    export GHIDRA_MCP_URL="${cfg.ghidra.serverUrl}"
    exec ${uvExe} run "$root/share/ghidra-mcp/bridge_mcp_ghidra.py" "$@"
  '';

  cursorGhidraVibeMcpPkg = ghidraVibeShell "cursor-ghidra-vibe-mcp" ''
    ${ghidraVibeRootExpr}
    export GHIDRA_MCP_URL="${cfg.ghidra.serverUrl}"
    export GHIDRA_VIBE_MCP_EXT_URL="${cfg.ghidra.extUrl}"
    exec ${uvExe} run "$root/share/ghidra-mcp/bridge_mcp_vibe.py" "$@"
  '';

  cursorGhidraVibeRagMcpPkg = ghidraVibeShell "cursor-ghidra-vibe-rag-mcp" ''
    export GHIDRA_MCP_URL="${cfg.ghidra.serverUrl}"
    exec ghidra-vibe-rag-mcp "$@"
  '';

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

  # @guildforge/mcp requires Node >= 24.
  guildforgePath =
    lib.makeBinPath [
      pkgs.nodejs_24
      pkgs.coreutils
    ]
    + ":/usr/bin:/bin";

  npx24Exe = "${pkgs.nodejs_24}/bin/npx";

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

  # Loads DISCORD_TOKEN + GUILD_ID from (in order):
  #   1. process env
  #   2. ~/.config/guildforge/env (pass-materialize)
  #   3. secretspec / pass (shared vault)
  guildforgeMcpPkg = pkgs.writeShellScriptBin "guildforge-mcp" ''
    export PATH="${guildforgePath}:${pkgs.pass}/bin:${pkgs.secretspec}/bin:${pkgs.coreutils}/bin:$PATH"
    envFile="${cfg.guildforge.envFile}"
    secretspecToml="${../../home/secretspec.toml}"
    if [ -r "$envFile" ]; then
      set -a
      # shellcheck disable=SC1090
      . "$envFile"
      set +a
    fi
    if [ -z "''${DISCORD_TOKEN:-}" ] && command -v secretspec >/dev/null 2>&1; then
      DISCORD_TOKEN="$(secretspec get -f "$secretspecToml" DISCORD_TOKEN 2>/dev/null || true)"
      export DISCORD_TOKEN
    fi
    if [ -z "''${GUILD_ID:-}" ] && command -v secretspec >/dev/null 2>&1; then
      GUILD_ID="$(secretspec get -f "$secretspecToml" GUILD_ID 2>/dev/null || true)"
      export GUILD_ID
    fi
    if [ -z "''${DISCORD_TOKEN:-}" ] && command -v pass >/dev/null 2>&1; then
      DISCORD_TOKEN="$(pass show secretspec/shared/default/DISCORD_TOKEN 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
      export DISCORD_TOKEN
    fi
    if [ -z "''${GUILD_ID:-}" ] && command -v pass >/dev/null 2>&1; then
      GUILD_ID="$(pass show secretspec/shared/default/GUILD_ID 2>/dev/null | head -n1 | tr -d '[:space:]' || true)"
      export GUILD_ID
    fi
    if [ -z "''${DISCORD_TOKEN:-}" ] || [ -z "''${GUILD_ID:-}" ]; then
      echo "guildforge-mcp: missing DISCORD_TOKEN/GUILD_ID — run: pass-guildforge-bootstrap" >&2
      exit 1
    fi
    exec ${npx24Exe} -y @guildforge/mcp "$@"
  '';

  guildforgeBootstrap = pkgs.writeShellApplication {
    name = "pass-guildforge-bootstrap";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.pass
      pkgs.gnupg
      pkgs.bash
    ];
    text = ''
      exec ${pkgs.bash}/bin/bash ${../../scripts/pass-guildforge-bootstrap.sh} "$@"
    '';
  };

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
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer";
    };
  };

  # uv + GhidraVibe bridges (see ~/GhidraVibe/docs/CURSOR.md). Engine must
  # already be up on GHIDRA_MCP_URL (gui or ghidra-vibe-mcp-headless).
  ghidraMcpServer = {
    command = lib.getExe cursorGhidraMcpPkg;
    args = [ ];
    env = {
      GHIDRA_MCP_URL = cfg.ghidra.serverUrl;
    };
  };

  ghidraVibeMcpServer = {
    command = lib.getExe cursorGhidraVibeMcpPkg;
    args = [ ];
    env = {
      GHIDRA_MCP_URL = cfg.ghidra.serverUrl;
      GHIDRA_VIBE_MCP_EXT_URL = cfg.ghidra.extUrl;
    };
  };

  # Rust JSpace RAG MCP (discover/search/index) — Cursor heavy set.
  ghidraVibeRagMcpServer = {
    command = lib.getExe cursorGhidraVibeRagMcpPkg;
    args = [ ];
    env = {
      GHIDRA_MCP_URL = cfg.ghidra.serverUrl;
    };
  };

  guildforgeMcpServer = {
    command = lib.getExe guildforgeMcpPkg;
    args = [ ];
    env = {
      PATH = guildforgePath;
    };
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
  # nixos≈2 + xcodebuild≈24 + wwn (small) + guildforge≈12 ≪ 100.
  leanMcpServers = {
    wwn-mcp = wwnMcpServer;
    nixos = nixosMcpServer;
  }
  // xcodebuildMcpServer
  // lib.optionalAttrs cfg.guildforge.enable { guildforge = guildforgeMcpServer; };

  # Stripe remote MCP (OAuth in Cursor). HTTP URL, no secret key in mcp.json.
  # https://docs.stripe.com/mcp.md — authenticate via Cursor MCP consent.
  stripeMcpServer = {
    type = "http";
    url = "https://mcp.stripe.com";
  };

  # Full set for Cursor / VS Code (higher tool budgets).
  heavyMcpServers =
    leanMcpServers
    // instrumentsMcpServer
    // {
      stripe = stripeMcpServer;
    }
    // lib.optionalAttrs cfg.lldb.enable { lldb = lldbMcpServer; }
    // lib.optionalAttrs cfg.agentDevice.enable { agent-device = agentDeviceMcpServer; }
    // lib.optionalAttrs cfg.ghidra.enable {
      ghidra = ghidraMcpServer;
      ghidra-vibe = ghidraVibeMcpServer;
      ghidra-vibe-rag = ghidraVibeRagMcpServer;
    }
    // lib.optionalAttrs cfg.guildforge.enable { guildforge = guildforgeMcpServer; };

  wawonaMcpServers =
    leanMcpServers
    // instrumentsMcpServer
    // lib.optionalAttrs cfg.lldb.enable { lldb = lldbMcpServer; }
    // lib.optionalAttrs cfg.agentDevice.enable { agent-device = agentDeviceMcpServer; };

  userMcpServers = heavyMcpServers;

  zedContextServers = lib.mapAttrs (_: toZedContextServer) userMcpServers;
  zedWawonaContextServers = lib.mapAttrs (_: toZedContextServer) wawonaMcpServers;

  antigravityMcpServers = if cfg.antigravity.includeHeavy then heavyMcpServers else leanMcpServers;

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

    antigravity = {
      includeHeavy = lib.mkEnableOption ''
        Include instruments/lldb/ghidra/agent-device/guildforge in Antigravity MCP.
        Off by default: Antigravity rejects configs that would exceed ~100 tools.
      '';
    };

    ghidra = {
      enable = lib.mkEnableOption "Ghidra MCP server in user-global IDE mcp.json";
      flake = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/GhidraVibe";
        description = ''
          Local GhidraVibe flake checkout. MCP bridges use
          `#ghidra-vibe` (share/ghidra-mcp + ghidra-vibe-rag-mcp).
          Replaces the retired GhidraMCP_Vibe_RSE path.
        '';
      };
      serverUrl = lib.mkOption {
        type = lib.types.str;
        # GhidraVibe engine default (no trailing slash)
        default = "http://127.0.0.1:8089";
      };
      extUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8092";
        description = "GhidraVibe MCP extension URL (dyld / Malimite / nav).";
      };
    };

    guildforge = {
      enable = lib.mkEnableOption ''
        GuildForge Discord MCP (@guildforge/mcp) in IDE mcp.json.
        Credentials: pass SecretSpec keys DISCORD_TOKEN + GUILD_ID
        (materialized to ~/.config/guildforge/env). Bootstrap with
        `pass-guildforge-bootstrap`.
      '';
      envFile = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/.config/guildforge/env";
        description = ''
          Env file written by pass-materialize from SecretSpec. Sourced by
          guildforge-mcp; also falls back to `secretspec get` / `pass show`.
        '';
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
    # Cursor defaults: heavy tooling on. Antigravity uses leanMcpServers unless
    # includeHeavy — do not enable guildforge until secrets exist.
    dendritic.ide.mcp.ghidra.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.lldb.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.instruments.enable = lib.mkDefault pkgs.stdenv.isDarwin;
    dendritic.ide.mcp.guildforge.enable = lib.mkDefault true;
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
      ++ lib.optionals cfg.guildforge.enable [
        guildforgeMcpPkg
        guildforgeBootstrap
        pkgs.nodejs_24
        pkgs.secretspec
      ]
      ++ lib.optionals cursorEnabled [
        pkgs.nodejs
      ]
      ++ lib.optionals (cursorEnabled && cfg.ghidra.enable) [
        cursorGhidraMcpPkg
        cursorGhidraVibeMcpPkg
        cursorGhidraVibeRagMcpPkg
        pkgs.uv
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
