# Local AI bench — mba

- Host: `mba`
- Started: `2026-07-19T21:26:47Z`
- Finished: `2026-07-19T21:33:22Z`
- API: `http://127.0.0.1:11434`

## Top picks (loadModels)

1. **`qwen2.5-coder:3b`** — role `small-coder`, tier `outperform`, score 0.7638, tps≈8.83, coding≈3.75
2. **`llama3.2:3b`** — role `small-chat`, tier `outperform`, score 0.7394, tps≈8.04, coding≈3.75
3. **`gemma3:1b`** — role `small-gemma`, tier `usable`, score 0.7069, tps≈16.47, coding≈2.92
4. **`llama3.2:1b`** — role `ultra-light-chat`, tier `usable`, score 0.6324, tps≈8.17, coding≈3.33

```nix
loadModels = ["qwen2.5-coder:3b", "llama3.2:3b", "gemma3:1b", "llama3.2:1b"];
```

## Full ranking

| Model | Tier | Score | tok/s | Coding | Tools |
|-------|------|------:|------:|-------:|------:|
| `qwen2.5-coder:3b` | outperform | 0.7638 | 8.83 | 3.75 | 5.00 |
| `llama3.2:3b` | outperform | 0.7394 | 8.04 | 3.75 | 5.00 |
| `gemma3:1b` | usable | 0.7069 | 16.47 | 2.92 | 5.00 |
| `qwen2.5-coder:1.5b` | too_slow | 0.65 | 3.56 | 3.75 | 5.00 |
| `llama3.2:1b` | usable | 0.6324 | 8.17 | 3.33 | 5.00 |
| `gemma3:4b` | too_slow | 0.5328 | 6.30 | 3.33 | 5.00 |
| `qwen2.5-coder:7b` | too_slow | 0.4692 | 4.27 | 3.75 | 5.00 |

## Rejected / not selected

- `qwen2.5-coder:1.5b` — `too_slow` 
- `gemma3:4b` — `too_slow` 
- `qwen2.5-coder:7b` — `too_slow` 

## Hardware snapshot (start)

```json
{
  "nvidia": {
    "error": "[Errno 2] No such file or directory: 'nvidia-smi'"
  },
  "mem": {}
}
```

