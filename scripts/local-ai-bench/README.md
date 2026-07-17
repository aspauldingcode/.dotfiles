# local-ai-bench

Data-driven local LLM bench for the dendritic fleet.

## Phase 1 — sliceanddice (NixOS)

```bash
# On sliceanddice (or via ssh), with Ollama listening on :11434:
python3 scripts/local-ai-bench/bench.py \
  --matrix scripts/local-ai-bench/matrices/sliceanddice.yaml \
  --out scripts/local-ai-bench/results/sliceanddice/raw.json

python3 scripts/local-ai-bench/score.py
python3 scripts/local-ai-bench/report.py
```

## Phase 2 — mba (macOS ANE)

`matrices/mba-ane.yaml` is a **gated stub**. Do not run until interactive OK.
Metal / Ollama / MLX / llama.cpp are disqualified for macOS local ranking.
