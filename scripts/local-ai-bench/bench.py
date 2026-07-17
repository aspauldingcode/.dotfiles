#!/usr/bin/env python3
"""Local LLM benchmark orchestrator (Phase 1: Ollama OpenAI-compatible API)."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent
DEFAULT_BASE = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434")


def load_yaml_simple(path: Path) -> dict[str, Any]:
    """Minimal YAML subset loader for our matrix files (no PyYAML required)."""
    try:
        import yaml  # type: ignore

        with path.open() as f:
            return yaml.safe_load(f)
    except ImportError:
        pass

    # Fallback: hand-parse the flat structure we ship.
    data: dict[str, Any] = {"models": [], "prompt_tokens": [128, 512], "max_new_tokens": 128}
    models: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    in_models = False
    with path.open() as f:
        for raw in f:
            line = raw.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            if line.startswith("host:"):
                data["host"] = line.split(":", 1)[1].strip()
            elif line.startswith("models:"):
                in_models = True
            elif in_models and line.strip().startswith("- id:"):
                if current:
                    models.append(current)
                current = {"id": line.split(":", 1)[1].strip()}
            elif in_models and current and line.strip().startswith("role:"):
                current["role"] = line.split(":", 1)[1].strip()
            elif in_models and current and line.strip().startswith("expect:"):
                current["expect"] = line.split(":", 1)[1].strip()
            elif line.startswith("max_new_tokens:"):
                data["max_new_tokens"] = int(line.split(":", 1)[1].strip())
            elif line.startswith("prompt_tokens:"):
                inner = line.split(":", 1)[1].strip().strip("[]")
                data["prompt_tokens"] = [int(x.strip()) for x in inner.split(",") if x.strip()]
            elif line.startswith("warmup_runs:"):
                data["warmup_runs"] = int(line.split(":", 1)[1].strip())
            elif line.startswith("measured_runs:"):
                data["measured_runs"] = int(line.split(":", 1)[1].strip())
    if current:
        models.append(current)
    data["models"] = models
    return data


def http_json(method: str, url: str, body: dict | None = None, timeout: float = 600.0) -> Any:
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={"Content-Type": "application/json", "Authorization": "Bearer ollama"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode())


def nvidia_snapshot() -> dict[str, Any]:
    try:
        out = subprocess.check_output(
            [
                "nvidia-smi",
                "--query-gpu=memory.used,memory.total,utilization.gpu,power.draw",
                "--format=csv,noheader,nounits",
            ],
            text=True,
            timeout=10,
        ).strip()
        parts = [p.strip() for p in out.split(",")]
        return {
            "vram_used_mib": float(parts[0]) if parts else None,
            "vram_total_mib": float(parts[1]) if len(parts) > 1 else None,
            "gpu_util_pct": float(parts[2]) if len(parts) > 2 else None,
            "power_w": float(parts[3]) if len(parts) > 3 else None,
        }
    except Exception as e:  # noqa: BLE001
        return {"error": str(e)}


def meminfo() -> dict[str, int]:
    vals: dict[str, int] = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if ":" not in line:
                    continue
                k, v = line.split(":", 1)
                if k in ("MemTotal", "MemAvailable", "SwapTotal", "SwapFree"):
                    vals[k] = int(v.strip().split()[0])
    except OSError:
        pass
    return vals


def pad_prompt(n_tokens: int) -> str:
    # Roughly 1 token ≈ 4 chars for English; pad with numbered lines.
    unit = "word{:04d} "
    buf = []
    i = 0
    while len("".join(buf)) // 4 < n_tokens:
        buf.append(unit.format(i % 10000))
        i += 1
    return (
        "Summarize the following filler in one short sentence, then say DONE.\n\n"
        + "".join(buf)[: n_tokens * 4]
    )


def chat_completion(
    base: str,
    model: str,
    messages: list[dict[str, str]],
    max_tokens: int,
    timeout: float = 600.0,
) -> dict[str, Any]:
    t0 = time.perf_counter()
    try:
        resp = http_json(
            "POST",
            f"{base.rstrip('/')}/v1/chat/completions",
            {
                "model": model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": 0.2,
                "stream": False,
            },
            timeout=timeout,
        )
        dt = time.perf_counter() - t0
        choice = (resp.get("choices") or [{}])[0]
        content = ((choice.get("message") or {}).get("content")) or ""
        usage = resp.get("usage") or {}
        completion_tokens = int(usage.get("completion_tokens") or 0)
        prompt_tokens = int(usage.get("prompt_tokens") or 0)
        # Non-streaming: approximate TTFT as full latency; decode from completion/time.
        tps = (completion_tokens / dt) if dt > 0 and completion_tokens else 0.0
        return {
            "ok": True,
            "latency_s": dt,
            "ttft_s": dt,  # no stream; wall for first+all tokens
            "decode_tps": tps,
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "content": content,
            "error": None,
        }
    except Exception as e:  # noqa: BLE001
        return {
            "ok": False,
            "latency_s": time.perf_counter() - t0,
            "ttft_s": None,
            "decode_tps": 0.0,
            "prompt_tokens": 0,
            "completion_tokens": 0,
            "content": "",
            "error": str(e),
        }


def pull_model(base: str, model: str) -> dict[str, Any]:
    t0 = time.perf_counter()
    try:
        # Native Ollama pull API
        req = urllib.request.Request(
            f"{base.rstrip('/')}/api/pull",
            data=json.dumps({"name": model, "stream": False}).encode(),
            method="POST",
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=3600) as resp:
            body = resp.read().decode()
        return {"ok": True, "seconds": time.perf_counter() - t0, "raw": body[-500:]}
    except Exception as e:  # noqa: BLE001
        return {"ok": False, "seconds": time.perf_counter() - t0, "error": str(e)}


def score_coding(content: str, scenario: dict[str, Any]) -> float:
    if not content.strip():
        return 0.0
    if scenario.get("expect_json_tool"):
        try:
            # Find first JSON object in reply
            start = content.find("{")
            end = content.rfind("}")
            if start < 0 or end <= start:
                return 0.0
            obj = json.loads(content[start : end + 1])
            if isinstance(obj, dict) and "tool" in obj:
                return 5.0 if obj["tool"] in ("list_files", "read_file", "run_shell") else 2.0
            return 1.0
        except json.JSONDecodeError:
            return 0.5 if "list_files" in content else 0.0
    subs = scenario.get("expect_substrings") or []
    if not subs:
        return 3.0 if len(content) > 20 else 1.0
    hits = sum(1 for s in subs if s.lower() in content.lower())
    return min(5.0, (hits / max(len(subs), 1)) * 5.0)


def ensure_server(base: str) -> None:
    try:
        http_json("GET", f"{base.rstrip('/')}/api/tags", timeout=10)
    except Exception as e:  # noqa: BLE001
        print(f"ERROR: Ollama not reachable at {base}: {e}", file=sys.stderr)
        sys.exit(2)


def run_model(
    base: str,
    model: dict[str, Any],
    matrix: dict[str, Any],
    scenarios: dict[str, Any],
) -> dict[str, Any]:
    mid = model["id"]
    print(f"\n=== {mid} ===", flush=True)
    result: dict[str, Any] = {
        "model": mid,
        "role": model.get("role"),
        "expect": model.get("expect"),
        "pull": None,
        "throughput": [],
        "coding": {},
        "nvidia_after": None,
        "mem_after": None,
        "tier": None,
        "errors": [],
    }

    pull = pull_model(base, mid)
    result["pull"] = pull
    if not pull.get("ok"):
        result["errors"].append(f"pull failed: {pull.get('error')}")
        result["tier"] = "unable"
        return result

    cold = chat_completion(
        base,
        mid,
        [{"role": "user", "content": "Say hi in three words."}],
        max_tokens=16,
        timeout=300,
    )
    result["cold_load"] = cold
    if not cold.get("ok"):
        result["errors"].append(f"cold load failed: {cold.get('error')}")
        result["tier"] = "unable"
        return result

    warmup = int(matrix.get("warmup_runs") or 1)
    measured = int(matrix.get("measured_runs") or 3)
    max_new = int(matrix.get("max_new_tokens") or 128)

    for n_prompt in matrix.get("prompt_tokens") or [128, 512]:
        prompt = pad_prompt(int(n_prompt))
        for _ in range(warmup):
            chat_completion(
                base,
                mid,
                [{"role": "user", "content": prompt}],
                max_tokens=max_new,
                timeout=600,
            )
        runs = []
        for _ in range(measured):
            r = chat_completion(
                base,
                mid,
                [{"role": "user", "content": prompt}],
                max_tokens=max_new,
                timeout=600,
            )
            runs.append(r)
        ok_runs = [r for r in runs if r.get("ok")]
        if not ok_runs:
            result["throughput"].append(
                {"prompt_tokens_target": n_prompt, "ok": False, "runs": runs}
            )
            result["errors"].append(f"throughput failed @ {n_prompt}")
            continue
        avg_tps = sum(r["decode_tps"] for r in ok_runs) / len(ok_runs)
        avg_lat = sum(r["latency_s"] for r in ok_runs) / len(ok_runs)
        result["throughput"].append(
            {
                "prompt_tokens_target": n_prompt,
                "ok": True,
                "avg_decode_tps": avg_tps,
                "avg_latency_s": avg_lat,
                "runs": runs,
            }
        )

    coding_scores = {}
    for name, sc in scenarios.items():
        r = chat_completion(
            base,
            mid,
            [
                {"role": "system", "content": sc["system"]},
                {"role": "user", "content": sc["user"]},
            ],
            max_tokens=256,
            timeout=600,
        )
        score = score_coding(r.get("content") or "", sc) if r.get("ok") else 0.0
        coding_scores[name] = {
            "ok": r.get("ok"),
            "score": score,
            "latency_s": r.get("latency_s"),
            "content_preview": (r.get("content") or "")[:400],
            "error": r.get("error"),
        }
    result["coding"] = coding_scores
    result["nvidia_after"] = nvidia_snapshot()
    result["mem_after"] = meminfo()

    # Tier classification from plan bands
    tps_vals = [
        t["avg_decode_tps"]
        for t in result["throughput"]
        if t.get("ok") and t.get("avg_decode_tps") is not None
    ]
    best_tps = max(tps_vals) if tps_vals else 0.0
    ttft_512 = None
    for t in result["throughput"]:
        if t.get("prompt_tokens_target") == 512 and t.get("ok"):
            ttft_512 = t.get("avg_latency_s")
    coding_avg = (
        sum(v["score"] for v in coding_scores.values()) / max(len(coding_scores), 1)
        if coding_scores
        else 0.0
    )
    tool_score = coding_scores.get("agent_tools", {}).get("score", 0.0)

    if best_tps < 2.0 or coding_avg <= 0.0 or result["errors"]:
        # soft: if pull/cold worked but very slow
        if best_tps < 2.0 or coding_avg <= 0.0:
            tier = "unable"
        else:
            tier = "unable"
    elif best_tps < 8.0 or (ttft_512 is not None and ttft_512 > 15.0):
        tier = "too_slow"
    elif coding_avg >= 2.0 and tool_score >= 2.5:
        tier = "usable"
    else:
        tier = "too_slow" if coding_avg < 2.0 else "usable"

    result["summary"] = {
        "best_decode_tps": best_tps,
        "ttft_proxy_512_s": ttft_512,
        "coding_avg": coding_avg,
        "tool_score": tool_score,
    }
    result["tier"] = tier
    print(
        f"  tier={tier} tps={best_tps:.2f} coding={coding_avg:.2f} tool={tool_score:.2f}",
        flush=True,
    )
    return result


def main() -> int:
    ap = argparse.ArgumentParser(description="Local AI bench (Ollama)")
    ap.add_argument(
        "--matrix",
        type=Path,
        default=ROOT / "matrices" / "sliceanddice.yaml",
    )
    ap.add_argument(
        "--scenarios",
        type=Path,
        default=ROOT / "scenarios" / "coding.json",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=ROOT / "results" / "sliceanddice" / "raw.json",
    )
    ap.add_argument("--base", default=DEFAULT_BASE)
    ap.add_argument(
        "--models",
        nargs="*",
        help="Optional subset of model ids from the matrix",
    )
    args = ap.parse_args()

    matrix = load_yaml_simple(args.matrix)
    with args.scenarios.open() as f:
        scenarios = json.load(f)

    ensure_server(args.base)
    models = matrix.get("models") or []
    if args.models:
        want = set(args.models)
        models = [m for m in models if m["id"] in want]

    args.out.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "host": matrix.get("host", "unknown"),
        "base": args.base,
        "started_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "nvidia_before": nvidia_snapshot(),
        "mem_before": meminfo(),
        "results": [],
    }

    for model in models:
        try:
            payload["results"].append(run_model(args.base, model, matrix, scenarios))
        except KeyboardInterrupt:
            print("Interrupted", file=sys.stderr)
            break
        except Exception as e:  # noqa: BLE001
            payload["results"].append(
                {
                    "model": model.get("id"),
                    "tier": "unable",
                    "errors": [str(e)],
                }
            )

    payload["finished_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    args.out.write_text(json.dumps(payload, indent=2))
    print(f"\nWrote {args.out}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
