# Dual-mode local AI: free Ollama alongside existing cloud OpenAI.
# Same Rust CLI (ai-local / chat) on NixOS + Darwin.
# NixOS: CUDA ollama. Darwin: Metal ollama via launchd (ANE ranking is separate).
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
      ollamaHost = "${cfg.host}:${toString cfg.port}";
      pullModels = pkgs.writeShellScript "ollama-pull-models" ''
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
            Label = "com.aspaulding.ollama";
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
            Label = "com.aspaulding.ollama-model-loader";
            ProgramArguments = [ "${pullModels}" ];
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "/tmp/ollama-model-loader.log";
            StandardErrorPath = "/tmp/ollama-model-loader.err.log";
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
