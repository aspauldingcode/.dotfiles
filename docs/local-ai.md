# Local AI (dual-mode)

Cloud OpenAI / Cursor stay the default. Local Ollama is additive and free.

## sliceanddice (NixOS) — Phase 1

Enable: `dendritic.local-ai.enable` (system + HM).

Service: `ollama` (`pkgs.ollama-cuda`) on `127.0.0.1:11434`.

### Bench winners (2026-07-16)

See [local-ai-bench-sliceanddice.md](./local-ai-bench-sliceanddice.md).

| Role               | Model              | Notes                             |
| ------------------ | ------------------ | --------------------------------- |
| Fastest            | `gemma3:1b`        | ~49 tok/s, outperform             |
| Best small general | `llama3.2:3b`      | ~40 tok/s, best coding among fast |
| Coder              | `qwen2.5-coder:3b` | ~23 tok/s                         |
| Quality coder      | `qwen2.5-coder:7b` | ~10 tok/s, usable hybrid          |

Rejected: `qwen3:8b` (unable — empty coding replies / slow TTFT), `gpt-oss:20b` (too slow / weak tools on 4GB+16GB).

### CLI

Rust helpers (`modules/apps/local-ai-cli`): `ai-local` + `chat`.

```bash
ai-local --help                      # usage
ai-local --list                      # numbered models
ai-local                             # status + tags (JSON)
ai-local aider --model openai/qwen2.5-coder:3b
chat --help                          # usage
chat --list                          # numbered models
chat 'prompt'                        # chat with default model
chat -m 1 'prompt'                   # pick by list index
chat -m gemma3:1b 'prompt'           # pick by tag
chat --model=qwen2.5-coder:7b -- fix this
curl -s http://127.0.0.1:11434/v1/models
```

Never set `OPENAI_API_BASE` globally (breaks chatgpt-cli / cloud defaults).

### Neovim

CodeCompanion defaults to **openai** (sops). Switch to local with adapter `ollama`.

### Cursor

Default: Cursor cloud. Optional: Settings → Models → Override OpenAI Base URL → `http://127.0.0.1:11434/v1` (Tab stays cloud).

### Zed Agent (llama.cpp)

Declarative Nix wires Zed’s native `llama.cpp` provider to a local `llama-server`
on `127.0.0.1:8080` (Ollama stays on `:11434` for CLI / Cursor).

**System** (nix-darwin / NixOS):

```nix
dendritic.local-ai.enable = true;
dendritic.local-ai.llamaCpp.enable = true;
# optional pin (downloads on first start):
# dendritic.local-ai.llamaCpp.hfRepo = "unsloth/Qwen2.5-Coder-3B-Instruct-GGUF:Q4_K_M";
# dendritic.local-ai.llamaCpp.alias = "qwen2.5-coder-3b";
```

**Home Manager** (Zed settings):

```nix
dendritic.apps.zed.enable = true;
dendritic.apps.zed.localAgent.enable = true;
dendritic.apps.zed.localAgent.provider = "llama.cpp";
dendritic.apps.zed.localAgent.apiUrl = "http://127.0.0.1:8080";
# optional once alias/hfRepo is set:
# dendritic.apps.zed.localAgent.model = "qwen2.5-coder-3b";
```

That seeds:

```json
{
  "language_models": {
    "llama.cpp": {
      "api_url": "http://127.0.0.1:8080",
      "auto_discover": true
    }
  }
}
```

Darwin agent: `com.aspauldingcode.llama-cpp` → `/tmp/llama-cpp.log`.
NixOS: `systemctl status dendritic-llama-cpp`. Prefer `provider = "ollama"` +
`apiUrl = "http://127.0.0.1:11434"` if you want Zed on Ollama instead.

On mba, `-hf` hit Hugging Face `401 Invalid username or password` (bad hub
creds / xet cache). Smoke path uses a local GGUF instead:

```nix
dendritic.local-ai.llamaCpp.modelFile =
  "/Users/8amps/.cache/llama.cpp/models/qwen2.5-0.5b-instruct-q4_k_m.gguf";
dendritic.local-ai.llamaCpp.alias = "qwen2.5-0.5b";
dendritic.local-ai.llamaCpp.ctxSize = 8192;
dendritic.apps.zed.localAgent.contextWindow = 8192;
```

**Context overflow (~67k tokens):** `context_window` alone does not help.
Zed injects **every enabled MCP server’s tool schemas** into Agent requests
(agent-device, xcodebuild, ghidra, wwn-mcp, …). With `localAgent.enable`, Nix
sets `agent.default_profile = "local"` with `enable_all_context_servers =
false`. Start a **new** thread and pick profile **Local (no MCP)**. Use the
built-in **Write** profile when you want full MCP on a cloud model.

Download once with curl (anonymous) if missing, then `nh darwin switch`.

### Aider / OpenCode

```bash
ai-local aider --model openai/qwen2.5-coder:3b
# or
OPENAI_API_BASE=http://127.0.0.1:11434/v1 OPENAI_API_KEY=ollama opencode
```

## mba (macOS) — same CLI as sliceanddice

Enable: `dendritic.local-ai.enable` on Darwin + HM (same options as NixOS).

Service: `ollama` (`pkgs.ollama`, Metal) via launchd on `127.0.0.1:11434`.

```bash
# Cross-host (no rebuild required)
nix run .#ai-local -- --list
nix run .#chat -- -m 1 'ping'
nix run .#local-ai-bench -- scripts/local-ai-bench/matrices/mba.yaml

# After darwin / NixOS switch — same binaries on mba + sliceanddice
ai-local --list
chat 'hello'
```

ANE / ANEMLL ranking remains a separate matrix (`matrices/mba-ane.yaml`). Metal Ollama is what the shared CLI talks to today.

### Bench

```bash
nix run .#local-ai-bench   # auto-picks matrices/{mba,sliceanddice}.yaml from hostname
python3 scripts/local-ai-bench/score.py --host mba
python3 scripts/local-ai-bench/report.py --host mba
```
