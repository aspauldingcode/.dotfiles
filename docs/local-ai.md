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

Rust helpers (`modules/apps/local-ai-cli`): `ai-local` + `ai-chat-local`.

```bash
ai-local --help                      # usage
ai-local --list                      # numbered models
ai-local                             # status + tags (JSON)
ai-local aider --model openai/qwen2.5-coder:3b
ai-chat-local --help                 # usage
ai-chat-local --list                 # numbered models
ai-chat-local 'prompt'               # chat with default model
ai-chat-local -m 1 'prompt'          # pick by list index
ai-chat-local -m gemma3:1b 'prompt'  # pick by tag
ai-chat-local --model=qwen2.5-coder:7b -- fix this
curl -s http://127.0.0.1:11434/v1/models
```

Never set `OPENAI_API_BASE` globally (breaks chatgpt-cli / cloud defaults).

### Neovim

CodeCompanion defaults to **openai** (sops). Switch to local with adapter `ollama`.

### Cursor

Default: Cursor cloud. Optional: Settings → Models → Override OpenAI Base URL → `http://127.0.0.1:11434/v1` (Tab stays cloud).

### Aider / OpenCode

```bash
ai-local aider --model openai/qwen2.5-coder:3b
# or
OPENAI_API_BASE=http://127.0.0.1:11434/v1 OPENAI_API_KEY=ollama opencode
```

## macOS (mba) — Phase 2 gated

ANE / ANEMLL only. Do not run Metal/Ollama/MLX as the macOS local primary until Phase 2 is approved interactively.
