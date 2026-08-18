# Dual-mode local AI: free Ollama alongside existing cloud OpenAI.
# Same Rust CLI (ai-local / chat) on NixOS + Darwin.
# NixOS: CUDA ollama. Darwin: Metal ollama via launchd (ANE ranking is separate).
# Optional llama.cpp OpenAI-compatible HTTP server (:8080) for Zed Agent.
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.local-ai;
      llamaCfg = cfg.llamaCpp;
      llamaServerArgs = [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--host"
        llamaCfg.host
        "--port"
        (toString llamaCfg.port)
      ]
      ++ lib.optionals llamaCfg.jinja [ "--jinja" ]
      ++ [
        "-ngl"
        (toString llamaCfg.nGpuLayers)
      ]
      ++ lib.optionals (llamaCfg.ctxSize != null) [
        "-c"
        (toString llamaCfg.ctxSize)
      ]
      ++ lib.optionals (llamaCfg.hfRepo != null) [
        "-hf"
        llamaCfg.hfRepo
      ]
      ++ lib.optionals (llamaCfg.modelFile != null) [
        "-m"
        llamaCfg.modelFile
      ]
      ++ lib.optionals (llamaCfg.alias != null) [
        "-a"
        llamaCfg.alias
      ]
      ++ llamaCfg.extraArgs;
    in
    {
      options.dendritic.local-ai = {
        enable = lib.mkEnableOption "Local LLM serving (Ollama) + CLI agent packages";

        loadModels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Ollama model tags to pull on service start (from bench winners).";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Ollama bind address (localhost-only by default).";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 11434;
        };

        llamaCpp = {
          enable = lib.mkEnableOption "llama.cpp HTTP server (OpenAI-compatible) for Zed Agent";

          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "llama-server bind address.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
            description = "llama-server port (Zed language_models.\"llama.cpp\".api_url).";
          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "alex";
            description = "System user that owns ~/.cache/llama.cpp (HF downloads).";
          };

          hfRepo = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "unsloth/Qwen2.5-Coder-3B-Instruct-GGUF:Q4_K_M";
            description = ''
              Optional Hugging Face GGUF repo passed as `-hf`. Null starts router /
              cache-only mode (load models on demand from the llama.cpp cache).
            '';
          };

          modelFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional local GGUF path (`-m`). Mutually exclusive with hfRepo in practice.";
          };

          alias = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional model alias (`-a`) — use this as Zed agent.default_model.model.";
          };

          ctxSize = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = null;
            example = 8192;
            description = "llama-server context size (`-c`). Keep ≤ model train ctx; pair with Zed context_window.";
          };

          nGpuLayers = lib.mkOption {
            type = lib.types.int;
            default = -1;
            description = "GPU offload layers (`-ngl`). -1 = all (CUDA/Metal).";
          };

          jinja = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable `--jinja` (tool-calling templates for agent use).";
          };

          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Extra argv appended to llama-server.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        services.ollama = {
          enable = true;
          package = pkgs.ollama-cuda;
          host = cfg.host;
          port = cfg.port;
          loadModels = cfg.loadModels;
          environmentVariables = {
            OLLAMA_MAX_LOADED_MODELS = "1";
            OLLAMA_KEEP_ALIVE = "5m";
            # PRIME offload laptops: prefer NVIDIA when visible.
            CUDA_VISIBLE_DEVICES = "0";
          };
        };

        environment.systemPackages = with pkgs; [
          llama-cpp
          aider-chat
          opencode
          oterm
        ];

        # Hybrid PRIME: ensure the CUDA runner sees the NVIDIA device.
        systemd.services.ollama.environment = {
          __NV_PRIME_RENDER_OFFLOAD = "1";
          __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          __VK_LAYER_NV_optimus = "NVIDIA_only";
        };

        # ollama holds CUDA/UVM open across sleep → NV_ERR_NO_MEMORY on suspend.
        # Stop before sleep, start after resume (idempotent if already stopped).
        environment.etc."systemd/system-sleep/dendritic-ollama" = {
          mode = "0755";
          text = ''
            #!${pkgs.runtimeShell}
            case "$1" in
              pre)
                ${pkgs.systemd}/bin/systemctl stop ollama.service 2>/dev/null || true
                ${pkgs.systemd}/bin/systemctl stop dendritic-llama-cpp.service 2>/dev/null || true
                ;;
              post)
                ${pkgs.systemd}/bin/systemctl start ollama.service 2>/dev/null || true
                ${pkgs.systemd}/bin/systemctl start dendritic-llama-cpp.service 2>/dev/null || true
                ;;
            esac
          '';
        };

        systemd.services.dendritic-llama-cpp = lib.mkIf llamaCfg.enable {
          description = "llama.cpp OpenAI-compatible server (Zed Agent)";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            Type = "simple";
            User = llamaCfg.user;
            ExecStart = lib.escapeShellArgs llamaServerArgs;
            Restart = "on-failure";
            RestartSec = 3;
            # HF / GGUF cache under the user's home.
            Environment = [
              "HOME=/home/${llamaCfg.user}"
            ];
          };
        };
      };
    };

  flake.modules.darwin.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.local-ai;
      llamaCfg = cfg.llamaCpp;
      ollamaHost = "${cfg.host}:${toString cfg.port}";
      primary = config.system.primaryUser;
      primaryHome = config.users.users.${primary}.home;
      llamaServerArgs = [
        "${pkgs.llama-cpp}/bin/llama-server"
        "--host"
        llamaCfg.host
        "--port"
        (toString llamaCfg.port)
      ]
      ++ lib.optionals llamaCfg.jinja [ "--jinja" ]
      ++ [
        "-ngl"
        (toString llamaCfg.nGpuLayers)
      ]
      ++ lib.optionals (llamaCfg.ctxSize != null) [
        "-c"
        (toString llamaCfg.ctxSize)
      ]
      ++ lib.optionals (llamaCfg.hfRepo != null) [
        "-hf"
        llamaCfg.hfRepo
      ]
      ++ lib.optionals (llamaCfg.modelFile != null) [
        "-m"
        llamaCfg.modelFile
      ]
      ++ lib.optionals (llamaCfg.alias != null) [
        "-a"
        llamaCfg.alias
      ]
      ++ llamaCfg.extraArgs;
      # writeShellScriptBin → ProgramArguments basename is `ollama-pull-models`
      # (bare writeShellScript shows as HASH-ollama-pull-models in Login Items).
      pullModels = pkgs.writeShellScriptBin "ollama-pull-models" ''
        set -euo pipefail
        export OLLAMA_HOST=${lib.escapeShellArg ollamaHost}
        export PATH=${
          lib.makeBinPath [
            pkgs.ollama
            pkgs.coreutils
          ]
        }:$PATH
        for i in $(seq 1 60); do
          if ollama list >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done
        ${lib.concatMapStringsSep "\n" (m: ''
          ollama pull ${lib.escapeShellArg m} || true
        '') cfg.loadModels}
      '';
    in
    {
      options.dendritic.local-ai = {
        enable = lib.mkEnableOption "Local LLM serving (Ollama) + CLI agent packages";

        loadModels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Ollama model tags to pull after ollama starts.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 11434;
        };

        llamaCpp = {
          enable = lib.mkEnableOption "llama.cpp HTTP server (OpenAI-compatible) for Zed Agent";

          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
          };

          hfRepo = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "unsloth/Qwen2.5-Coder-3B-Instruct-GGUF:Q4_K_M";
            description = ''
              Optional Hugging Face GGUF repo (`-hf`). Null = router / cache-only
              (no download on activate).
            '';
          };

          modelFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          alias = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          ctxSize = lib.mkOption {
            type = lib.types.nullOr lib.types.ints.positive;
            default = null;
            example = 8192;
            description = "llama-server context size (`-c`). Pair with Zed localAgent.contextWindow.";
          };

          nGpuLayers = lib.mkOption {
            type = lib.types.int;
            default = -1;
            description = "Metal GPU layers (`-ngl`). -1 = all.";
          };

          jinja = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };

          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages =
          with pkgs;
          [
            ollama
            llama-cpp
          ]
          ++ lib.optionals (pkgs ? aider-chat) [ aider-chat ]
          ++ lib.optionals (pkgs ? opencode) [ opencode ]
          ++ lib.optionals (pkgs ? oterm) [ oterm ];

        launchd.user.agents.ollama = {
          serviceConfig = {
            Label = "com.aspauldingcode.ollama";
            ProgramArguments = [
              "${pkgs.ollama}/bin/ollama"
              "serve"
            ];
            EnvironmentVariables = {
              OLLAMA_HOST = ollamaHost;
              OLLAMA_MAX_LOADED_MODELS = "1";
              OLLAMA_KEEP_ALIVE = "5m";
            };
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/tmp/ollama.log";
            StandardErrorPath = "/tmp/ollama.err.log";
          };
        };

        launchd.user.agents.ollama-model-loader = lib.mkIf (cfg.loadModels != [ ]) {
          serviceConfig = {
            Label = "com.aspauldingcode.ollama-model-loader";
            ProgramArguments = [ (lib.getExe pullModels) ];
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "/tmp/ollama-model-loader.log";
            StandardErrorPath = "/tmp/ollama-model-loader.err.log";
          };
        };

        launchd.user.agents.llama-cpp = lib.mkIf llamaCfg.enable {
          serviceConfig = {
            Label = "com.aspauldingcode.llama-cpp";
            ProgramArguments = llamaServerArgs;
            EnvironmentVariables = {
              HOME = primaryHome;
            };
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "/tmp/llama-cpp.log";
            StandardErrorPath = "/tmp/llama-cpp.err.log";
          };
        };
      };
    };

  flake.modules.homeManager.dendritic =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dendritic.local-ai;
      # Prefer system ollama service; helpers never override global OPENAI_API_BASE.
      ollamaBase = "http://127.0.0.1:11434";
      localAiCli = pkgs.callPackage ./local-ai-cli/_package.nix {
        defaultBaseUrl = cfg.ollamaBaseUrl;
        defaultModel = cfg.defaultLocalModel;
      };
    in
    {
      options.dendritic.local-ai = {
        enable = lib.mkEnableOption "Local AI CLI helpers + optional OpenCode local provider";

        defaultProvider = lib.mkOption {
          type = lib.types.enum [
            "openai"
            "local"
          ];
          default = "openai";
          description = "Default AI provider for helpers (cloud OpenAI stays default).";
        };

        ollamaBaseUrl = lib.mkOption {
          type = lib.types.str;
          default = ollamaBase;
        };

        defaultLocalModel = lib.mkOption {
          type = lib.types.str;
          default = "qwen2.5-coder:3b";
          description = "Default Ollama model id for ai-local helpers.";
        };
      };

      config = lib.mkIf cfg.enable {
        # Rust CLI (ai-local / chat). Same package on NixOS + Darwin.
        home.packages = [
          localAiCli
        ]
        ++ lib.optionals (pkgs ? opencode) [ pkgs.opencode ]
        ++ lib.optionals (pkgs ? oterm) [ pkgs.oterm ];

        # After compinit (order 200); before fzf-tab (550).
        programs.zsh.initContent = lib.mkOrder 300 ''
          # Local AI helpers — model / command tab completion
          _ai_ollama_models() {
            local -a models nums
            local i=1
            models=(''${(f)"$(${localAiCli}/bin/chat --list-raw 2>/dev/null)"})
            # Model tags contain ':' — use compadd, not _describe (colon = desc sep).
            (( ''${#models} )) || models=(${cfg.defaultLocalModel})
            for _ in "''${models[@]}"; do
              nums+=("$i")
              i=$((i + 1))
            done
            compadd -a models
            compadd -a nums
          }

          _dendritic_chat() {
            _arguments -s -S \
              '(-h --help)'{-h,--help}'[show help]' \
              '(-i --interactive)'{-i,--interactive}'[open interactive TUI]' \
              '(-l --list)'{-l,--list}'[list installed models (numbered)]' \
              '(-m --model)'{-m,--model}'[model tag or list index]:model:_ai_ollama_models' \
              '*:prompt:_message'
          }
          compdef _dendritic_chat chat
          # Back-compat name
          compdef _dendritic_chat ai-chat-local

          # ai-local is a precommand: complete flags, then the wrapped command.
          _ai-local() {
            local -a preferred
            preferred=(aider opencode oterm curl)
            _arguments -s -S \
              '(-h --help)'{-h,--help}'[show help]' \
              '(-l --list)'{-l,--list}'[list installed models (numbered)]' \
              '*::command: _alternative "preferred:local agent:compadd -a preferred" "commands:command:_command_names -e"'
          }
          compdef _ai-local ai-local
        '';
      };
    };
}
