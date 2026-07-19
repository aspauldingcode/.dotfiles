# Local AI bench — sliceanddice (NixOS)

- Host: `sliceanddice`
- Started: `2026-07-17T04:25:48Z`
- Finished: `2026-07-17T05:34:40Z`
- API: `http://127.0.0.1:11434`

## Top picks (loadModels)

1. **`gemma3:1b`** — role `small-gemma`, tier `outperform`, score 0.9431, tps≈48.90, coding≈3.33
2. **`llama3.2:3b`** — role `small-chat`, tier `outperform`, score 0.8297, tps≈39.52, coding≈4.17
3. **`llama3.2:1b`** — role `ultra-light-chat`, tier `usable`, score 0.7256, tps≈27.03, coding≈3.33
4. **`qwen2.5-coder:3b`** — role `small-coder`, tier `usable`, score 0.6806, tps≈22.72, coding≈3.75

```nix
loadModels = ["gemma3:1b", "llama3.2:3b", "llama3.2:1b", "qwen2.5-coder:3b"];
```

## Full ranking

| Model                | Tier       |  Score | tok/s | Coding | Tools |
| -------------------- | ---------- | -----: | ----: | -----: | ----: |
| `gemma3:1b`          | outperform | 0.9431 | 48.90 |   3.33 |  5.00 |
| `llama3.2:3b`        | outperform | 0.8297 | 39.52 |   4.17 |  5.00 |
| `llama3.2:1b`        | usable     | 0.7256 | 27.03 |   3.33 |  5.00 |
| `qwen2.5-coder:3b`   | usable     | 0.6806 | 22.72 |   3.75 |  5.00 |
| `qwen2.5-coder:1.5b` | usable     | 0.6095 | 11.58 |   3.33 |  5.00 |
| `qwen2.5-coder:7b`   | usable     | 0.5203 | 10.48 |   3.75 |  5.00 |
| `gemma3:4b`          | usable     | 0.5124 | 11.88 |   3.33 |  5.00 |
| `gpt-oss:20b`        | too_slow   | 0.1314 |  9.99 |   1.25 |  0.00 |
| `qwen3:8b`           | unable     |    0.0 |  8.93 |   0.00 |  0.00 |

## Rejected / not selected

- `gpt-oss:20b` — `too_slow`
- `qwen3:8b` — `unable`

## Hardware snapshot (start)

```json
{
  "nvidia": {
    "vram_used_mib": 12.0,
    "vram_total_mib": 4096.0,
    "gpu_util_pct": 7.0,
    "power_w": 752.67
  },
  "mem": {
    "MemTotal": 16067348,
    "MemAvailable": 5089372,
    "SwapTotal": 4194300,
    "SwapFree": 2472168
  }
}
```
