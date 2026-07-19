#!/usr/bin/env python3
"""Write markdown report from raw + ranked JSON."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--host",
        type=str,
        default="sliceanddice",
        help="Host results folder under results/ (mba, sliceanddice, …)",
    )
    ap.add_argument("--raw", type=Path, default=None)
    ap.add_argument("--ranked", type=Path, default=None)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()
    host_dir = ROOT / "results" / args.host
    if args.raw is None:
        args.raw = host_dir / "raw.json"
    if args.ranked is None:
        args.ranked = host_dir / "ranked.json"
    if args.out is None:
        args.out = ROOT.parents[1] / "docs" / f"local-ai-bench-{args.host}.md"

    raw = json.loads(args.raw.read_text())
    ranked = json.loads(args.ranked.read_text())
    title_host = ranked.get("host") or args.host

    lines = [
        f"# Local AI bench — {title_host}",
        "",
        f"- Host: `{title_host}`",
        f"- Started: `{raw.get('started_at')}`",
        f"- Finished: `{raw.get('finished_at')}`",
        f"- API: `{raw.get('base')}`",
        "",
        "## Top picks (loadModels)",
        "",
    ]
    for i, t in enumerate(ranked.get("top") or [], 1):
        s = t.get("summary") or {}
        lines.append(
            f"{i}. **`{t.get('model')}`** — role `{t.get('role')}`, tier `{t.get('tier')}`, "
            f"score {t.get('score')}, "
            f"tps≈{s.get('best_decode_tps', 0):.2f}, coding≈{s.get('coding_avg', 0):.2f}"
        )
    lines += [
        "",
        "```nix",
        f"loadModels = {json.dumps(ranked.get('loadModels') or [])};",
        "```",
        "",
        "## Full ranking",
        "",
        "| Model | Tier | Score | tok/s | Coding | Tools |",
        "|-------|------|------:|------:|-------:|------:|",
    ]
    for r in ranked.get("ranked") or []:
        s = r.get("summary") or {}
        lines.append(
            f"| `{r.get('model')}` | {r.get('tier')} | {r.get('score')} | "
            f"{s.get('best_decode_tps', 0):.2f} | {s.get('coding_avg', 0):.2f} | "
            f"{s.get('tool_score', 0):.2f} |"
        )

    rejects = ranked.get("reject") or []
    if rejects:
        lines += ["", "## Rejected / not selected", ""]
        for r in rejects:
            lines.append(f"- `{r.get('model')}` — `{r.get('tier')}` {r.get('errors') or ''}")

    lines += [
        "",
        "## Hardware snapshot (start)",
        "",
        "```json",
        json.dumps({"nvidia": raw.get("nvidia_before"), "mem": raw.get("mem_before")}, indent=2),
        "```",
        "",
    ]
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines) + "\n")
    print(f"Wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
