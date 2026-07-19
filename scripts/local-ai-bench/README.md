# local-ai-bench

Data-driven local LLM bench for the dendritic fleet.
Same entrypoint on mba (macOS) and sliceanddice (NixOS).

## Quick (either host)

```bash
# Ollama on :11434, then:
nix run .#local-ai-bench
# or explicit matrix:
nix run .#local-ai-bench -- scripts/local-ai-bench/matrices/mba.yaml
nix run .#local-ai-bench -- scripts/local-ai-bench/matrices/sliceanddice.yaml

python3 scripts/local-ai-bench/score.py --host mba
python3 scripts/local-ai-bench/report.py --host mba
```

## CLI parity

Rust helpers are identical on both hosts (`modules/apps/local-ai-cli`):

```bash
nix run .#ai-local -- --list
nix run .#chat -- 'hello'
# after switch: ai-local / chat on PATH
```

## ANE stub

`matrices/mba-ane.yaml` is reserved for ANEMLL/Core ML ranking (separate from Metal Ollama).
