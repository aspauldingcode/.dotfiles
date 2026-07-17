#!/usr/bin/env python3
"""Rank sliceanddice bench results → top 3–4 + loadModels snippet."""

from __future__ import annotations

import argparse
import json
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def norm(vals: list[float], v: float, higher_better: bool = True) -> float:
    finite = [x for x in vals if x is not None]
    if not finite:
        return 0.0
    lo, hi = min(finite), max(finite)
    if hi <= lo:
        return 1.0
    x = (v - lo) / (hi - lo)
    return x if higher_better else 1.0 - x


def composite(row: dict, pool: list[dict]) -> float:
    s = row.get("summary") or {}
    tps_pool = [(r.get("summary") or {}).get("best_decode_tps") or 0.0 for r in pool]
    ttft_pool = [
        (r.get("summary") or {}).get("ttft_proxy_512_s") or 999.0 for r in pool
    ]
    coding_pool = [(r.get("summary") or {}).get("coding_avg") or 0.0 for r in pool]
    tool_pool = [(r.get("summary") or {}).get("tool_score") or 0.0 for r in pool]

    tps = s.get("best_decode_tps") or 0.0
    ttft = s.get("ttft_proxy_512_s") or 999.0
    coding = s.get("coding_avg") or 0.0
    tool = s.get("tool_score") or 0.0

    # efficiency proxy: prefer higher tps / lower VRAM if present
    vram = None
    nv = row.get("nvidia_after") or {}
    if isinstance(nv.get("vram_used_mib"), (int, float)):
        vram = float(nv["vram_used_mib"])
    vram_pool = []
    for r in pool:
        n = r.get("nvidia_after") or {}
        if isinstance(n.get("vram_used_mib"), (int, float)):
            vram_pool.append(float(n["vram_used_mib"]))
    eff = 1.0
    if vram is not None and vram_pool:
        # lower VRAM better when tps similar — invert
        eff = norm(vram_pool, vram, higher_better=False)

    return (
        0.35 * norm(tps_pool, tps, True)
        + 0.20 * norm(ttft_pool, ttft, False)
        + 0.25 * norm(coding_pool, coding, True)
        + 0.10 * norm(tool_pool, tool, True)
        + 0.10 * eff
    )


def promote_outperform(ranked: list[dict]) -> None:
    usable = [r for r in ranked if r["tier"] in ("usable", "outperform", "too_slow")]
    if not usable:
        return
    scores = [r["score"] for r in usable]
    if len(scores) < 2:
        usable[0]["tier"] = "outperform"
        return
    q3 = statistics.quantiles(scores, n=4)[2] if len(scores) >= 4 else max(scores) * 0.75
    for r in usable:
        if r["score"] >= q3 and r["tier"] == "usable":
            r["tier"] = "outperform"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--raw",
        type=Path,
        default=ROOT / "results" / "sliceanddice" / "raw.json",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=ROOT / "results" / "sliceanddice" / "ranked.json",
    )
    ap.add_argument("--top", type=int, default=4)
    args = ap.parse_args()

    raw = json.loads(args.raw.read_text())
    results = raw.get("results") or []
    scored = []
    for r in results:
        item = dict(r)
        item["score"] = composite(r, results) if r.get("tier") != "unable" else 0.0
        scored.append(item)

    scored.sort(key=lambda r: r["score"], reverse=True)
    promote_outperform(scored)

    # Top picks: prefer usable/outperform; fill with best too_slow if needed
    winners = [r for r in scored if r.get("tier") in ("outperform", "usable")]
    if len(winners) < 3:
        for r in scored:
            if r not in winners and r.get("tier") != "unable":
                winners.append(r)
            if len(winners) >= args.top:
                break
    winners = winners[: args.top]

    # Role diversification: keep unique roles when possible
    picked: list[dict] = []
    seen_roles: set[str] = set()
    for r in winners:
        role = r.get("role") or r.get("model")
        if role in seen_roles and len(picked) >= 2:
            continue
        seen_roles.add(role)
        picked.append(r)
    for r in winners:
        if r not in picked and len(picked) < args.top:
            picked.append(r)

    load_models = [r["model"] for r in picked if r.get("model")]

    out = {
        "host": raw.get("host"),
        "source": str(args.raw),
        "ranked": [
            {
                "model": r.get("model"),
                "role": r.get("role"),
                "tier": r.get("tier"),
                "score": round(r.get("score") or 0.0, 4),
                "summary": r.get("summary"),
            }
            for r in scored
        ],
        "top": [
            {
                "model": r.get("model"),
                "role": r.get("role"),
                "tier": r.get("tier"),
                "score": round(r.get("score") or 0.0, 4),
                "summary": r.get("summary"),
            }
            for r in picked
        ],
        "loadModels": load_models,
        "reject": [
            {
                "model": r.get("model"),
                "tier": r.get("tier"),
                "errors": r.get("errors"),
            }
            for r in scored
            if r.get("tier") in ("unable", "too_slow") and r not in picked
        ],
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(out, indent=2))
    print(json.dumps(out["top"], indent=2))
    print("loadModels =", load_models)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
