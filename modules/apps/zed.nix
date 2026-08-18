{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.apps.zed;
      zedPkg = if pkgs.stdenv.isLinux then pkgs.zed-editor-fhs else pkgs.zed-editor;
      agent = cfg.localAgent;
      # Plain attrs for toJSON — avoid mkIf inside nested settings.
      localAgentSettings =
        let
          providerKey = agent.provider; # "llama.cpp" | "ollama"
          providerBlock = {
            api_url = agent.apiUrl;
            auto_discover = agent.autoDiscover;
          }
          // lib.optionalAttrs (agent.contextWindow != null) {
            context_window = agent.contextWindow;
          };
          # MCP tool schemas alone (agent-device, xcodebuild, ghidra, …) blow past
          # an 8k–32k local ctx (~67k tokens observed). Disable all context
          # servers for the local profile; cloud Write profile keeps MCP.
          localProfile = {
            name = "Local (no MCP)";
            enable_all_context_servers = false;
            context_servers = { };
            tools = {
              # Keep a tiny built-in set that fits small local models.
              read_file = true;
              edit_file = true;
              grep = true;
              diagnostics = true;
              list_directory = true;
              find_path = true;
              terminal = false;
              fetch = false;
              thinking = false;
            };
          }
          // lib.optionalAttrs (agent.model != null) {
            default_model = {
              provider = agent.provider;
              model = agent.model;
            };
          };
          agentBlock = {
            default_profile = "local";
            profiles = {
              local = localProfile;
            };
          }
          // lib.optionalAttrs (agent.model != null) {
            default_model = {
              provider = agent.provider;
              model = agent.model;
            };
          };
        in
        lib.optionalAttrs agent.enable ({
          language_models = {
            ${providerKey} = providerBlock;
          };
          agent = agentBlock;
        });
    in
    {
      imports = [ ./_ide-mcp.nix ];

      options.dendritic.apps.zed = {
        enable = lib.mkEnableOption "Zed IDE";

        localAgent = {
          enable = lib.mkEnableOption ''
            Declarative Zed Agent → local LLM provider (llama.cpp or Ollama).
            Pair with dendritic.local-ai.llamaCpp.enable (system) for :8080.
            Forces agent profile "local" with enable_all_context_servers=false
            so MCP tool schemas do not exceed small local context windows.
          '';

          provider = lib.mkOption {
            type = lib.types.enum [
              "llama.cpp"
              "ollama"
            ];
            default = "llama.cpp";
            description = "Zed language_models / agent.default_model.provider key.";
          };

          apiUrl = lib.mkOption {
            type = lib.types.str;
            default = "http://127.0.0.1:8080";
            description = ''
              Provider base URL. llama.cpp defaults to llama-server :8080;
              for Ollama use http://127.0.0.1:11434.
            '';
          };

          autoDiscover = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Zed language_models.<provider>.auto_discover.";
          };

          model = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Optional agent.default_model.model. Null = pick in the UI after
              auto-discovery (recommended until an alias/hfRepo is fixed).
            '';
          };

          contextWindow = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = null;
            example = 8192;
            description = ''
              language_models.<provider>.context_window. Does NOT strip MCP tool
              schemas — use the "local" agent profile (enable_all_context_servers
              = false) for that. Keep ≤ llama-server `-c`.
            '';
          };
        };
      };

      config = lib.mkIf cfg.enable {
        programs.zed-editor = {
          enable = true;
          package = zedPkg;
          # Allow the app to persist UI tweaks; Nix still seeds settings + MCP.
          mutableUserSettings = true;
          extensions = [
            "nix"
            "toml"
            "dockerfile"
          ];
          # Fonts/theme come from Stylix's zed target (`modules/zed/hm.nix`).
          userSettings = {
            format_on_save = "on";
            autosave = "on_focus_change";
          }
          // localAgentSettings;
        };

        # HM writes ~/.config/zed; macOS Zed reads Application Support.
        home.file = lib.optionalAttrs pkgs.stdenv.isDarwin {
          "Library/Application Support/Zed/settings.json" = {
            force = true;
            text = builtins.toJSON config.programs.zed-editor.userSettings;
          };
        };
      };
    };

  # Dock registration: Zed sits between Cursor (160) and Antigravity (170).
  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      user = config.system.primaryUser;
      zedEnabled = config.home-manager.users.${user}.dendritic.apps.zed.enable or false;
    in
    lib.mkIf zedEnabled {
      dendritic.dock.apps = lib.mkOrder 165 [
        "${pkgs.zed-editor}/Applications/Zed.app"
      ];
    };
}
