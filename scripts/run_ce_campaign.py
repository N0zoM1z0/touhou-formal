#!/usr/bin/env python3
"""Run the current symbolic CE campaign and persist reviewable artifacts.

This script is an orchestration layer.  The solver paths, Lean replay checks,
and risk labels remain owned by the existing lane-specific queue scripts.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_ROOT = REPO_ROOT / "formal_results" / "ce_campaigns"

QUEUE_LANES = [
    {
        "name": "raw_step",
        "title": "Raw ECL dispatch step",
        "script": "scripts/symex_candidate_queue.py",
        "file": "raw_step_queue.json",
        "eval_arg": "--queue-json",
    },
    {
        "name": "raw_body",
        "title": "Raw opcode body slice",
        "script": "scripts/symex_body_candidate_queue.py",
        "file": "raw_body_queue.json",
        "eval_arg": "--body-queue-json",
    },
    {
        "name": "int_resolver",
        "title": "Integer operand resolver",
        "script": "scripts/symex_int_resolver_queue.py",
        "file": "int_resolver_queue.json",
        "eval_arg": "--resolver-queue-json",
    },
    {
        "name": "int_binary",
        "title": "Integer binary arithmetic",
        "script": "scripts/symex_int_binary_candidate_queue.py",
        "file": "int_binary_queue.json",
        "eval_arg": "--int-binary-queue-json",
    },
    {
        "name": "callret",
        "title": "CALL/RET stack and sub lookup",
        "script": "scripts/symex_callret_candidate_queue.py",
        "file": "callret_queue.json",
        "eval_arg": "--callret-queue-json",
    },
    {
        "name": "condcall",
        "title": "TH06 conditional CALL",
        "script": "scripts/symex_condcall_candidate_queue.py",
        "file": "condcall_queue.json",
        "eval_arg": "--condcall-queue-json",
    },
    {
        "name": "boss_int",
        "title": "Boss-indexed integer read",
        "script": "scripts/symex_boss_int_candidate_queue.py",
        "file": "boss_int_queue.json",
        "eval_arg": "--boss-int-queue-json",
    },
    {
        "name": "boss_float",
        "title": "Boss-indexed float read",
        "script": "scripts/symex_boss_float_candidate_queue.py",
        "file": "boss_float_queue.json",
        "eval_arg": "--boss-float-queue-json",
    },
]

PRIORITY_RANK = {
    "high": 0,
    "medium": 1,
    "low": 2,
    "control": 3,
}


class CampaignError(RuntimeError):
    pass


def run_json_command(argv: list[str], timeout: int | None) -> tuple[Any, dict[str, Any]]:
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            argv,
            cwd=REPO_ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        elapsed = time.perf_counter() - started
        raise CampaignError(
            f"{' '.join(argv)} timed out after {elapsed:.1f}s"
        ) from exc

    elapsed = time.perf_counter() - started
    command_report = {
        "argv": argv,
        "returncode": completed.returncode,
        "elapsedSeconds": round(elapsed, 3),
        "stderrTail": completed.stderr.splitlines()[-20:],
    }
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise CampaignError(f"{' '.join(argv)} failed: {detail}")
    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise CampaignError(f"{' '.join(argv)} did not emit JSON: {exc}") from exc
    return payload, command_report


def write_json(path: Path, payload: Any) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")


def fixture_oracle(candidate: dict[str, Any]) -> dict[str, Any]:
    fixture = candidate.get("fixture", {})
    return {
        "action": fixture.get("action"),
        "cursorClass": fixture.get("cursorClass"),
        "faultKind": fixture.get("faultKind"),
        "faultDetail": fixture.get("faultDetail"),
        "result": fixture.get("result"),
        "matchesPath": fixture.get("matchesPath"),
    }


def compact_candidate(lane: dict[str, str], candidate: dict[str, Any]) -> dict[str, Any]:
    fixture = candidate.get("fixture", {})
    witness = candidate.get("witness", {})
    risk = candidate.get("risk", {})
    return {
        "lane": lane["name"],
        "laneTitle": lane["title"],
        "id": candidate.get("id"),
        "title": candidate.get("title"),
        "environment": candidate.get("environment"),
        "activeMask": candidate.get("activeMask"),
        "overrideMask": candidate.get("overrideMask"),
        "path": candidate.get("path"),
        "status": candidate.get("status"),
        "risk": {
            "class": risk.get("class"),
            "priority": risk.get("priority"),
            "reason": risk.get("reason"),
        },
        "oracle": fixture_oracle(candidate),
        "fixture": {
            "hex": fixture.get("hex"),
            "rawInstructionHex": fixture.get("rawInstructionHex"),
            "eclFileHex": fixture.get("eclFileHex"),
            "size": fixture.get("size"),
            "opcode": fixture.get("opcode") or fixture.get("decodedOpcode"),
            "operandMask": fixture.get("operandMask") or fixture.get("decodedOperandMask"),
        },
        "witness": {
            key: witness.get(key)
            for key in (
                "opcode",
                "nextOffset",
                "instructionMask",
                "operandMask",
                "jumpDisplacement",
                "divisorValue",
                "lhsRaw",
                "rhsRaw",
                "lhsHost",
                "rhsHost",
                "bossIndexRaw",
                "bossIndexHost",
                "bossPresent",
                "callStackDepth",
                "subId",
                "subTableSize",
                "bufferSize",
                "difficultyPass",
            )
        },
        "nextAction": candidate.get("nextAction"),
    }


def lane_summary(lane: dict[str, str], payload: dict[str, Any], elapsed: float) -> dict[str, Any]:
    candidates = payload.get("candidates", [])
    if not isinstance(candidates, list):
        raise CampaignError(f"{lane['name']} queue has no candidate list")

    status_counts = Counter(str(candidate.get("status")) for candidate in candidates)
    match_counts = Counter(
        str(candidate.get("fixture", {}).get("matchesPath"))
        for candidate in candidates
    )
    risk_counts = Counter(
        str(candidate.get("risk", {}).get("class"))
        for candidate in candidates
    )
    priority_counts = Counter(
        str(candidate.get("risk", {}).get("priority"))
        for candidate in candidates
    )
    title_counts = Counter(str(candidate.get("title")) for candidate in candidates)
    high = [
        candidate for candidate in candidates
        if candidate.get("risk", {}).get("priority") == "high"
    ]
    medium = [
        candidate for candidate in candidates
        if candidate.get("risk", {}).get("priority") == "medium"
    ]

    return {
        "title": lane["title"],
        "queueSchema": payload.get("schema"),
        "elapsedSeconds": round(elapsed, 3),
        "candidateCount": len(candidates),
        "highCounterexampleCount": len(high),
        "mediumSurpriseCount": len(medium),
        "statusCounts": dict(status_counts),
        "matchesPathCounts": dict(match_counts),
        "riskCounts": dict(risk_counts),
        "priorityCounts": dict(priority_counts),
        "titleCounts": dict(title_counts),
        "allSat": status_counts == Counter({"sat": len(candidates)}),
        "allReplayMatched": match_counts == Counter({"true": len(candidates)}),
    }


def build_summary(
    output_dir: Path,
    generated_at: str,
    lane_payloads: dict[str, dict[str, Any]],
    lane_commands: dict[str, dict[str, Any]],
    effectiveness: dict[str, Any],
) -> dict[str, Any]:
    summaries: dict[str, Any] = {}
    counterexamples: list[dict[str, Any]] = []
    semantic_surprises: list[dict[str, Any]] = []
    controls: list[dict[str, Any]] = []

    for lane in QUEUE_LANES:
        payload = lane_payloads[lane["name"]]
        command = lane_commands[lane["name"]]
        summaries[lane["name"]] = lane_summary(lane, payload, command["elapsedSeconds"])
        for candidate in payload.get("candidates", []):
            compact = compact_candidate(lane, candidate)
            priority = candidate.get("risk", {}).get("priority")
            if priority == "high":
                counterexamples.append(compact)
            elif priority == "medium":
                semantic_surprises.append(compact)
            else:
                controls.append(compact)

    sort_key = lambda item: (
        PRIORITY_RANK.get(str(item["risk"].get("priority")), 9),
        str(item.get("lane")),
        str(item.get("title")),
        str(item.get("path")),
        str(item.get("environment")),
    )
    counterexamples.sort(key=sort_key)
    semantic_surprises.sort(key=sort_key)
    controls.sort(key=sort_key)

    risk_counts = Counter(
        str(candidate["risk"].get("class"))
        for candidate in counterexamples
    )
    lane_counts = Counter(str(candidate["lane"]) for candidate in counterexamples)
    title_counts = Counter(str(candidate.get("title")) for candidate in counterexamples)

    total_candidates = sum(
        summary["candidateCount"] for summary in summaries.values()
    )
    total_elapsed = sum(
        summary["elapsedSeconds"] for summary in summaries.values()
    )

    queue_files = {
        lane["name"]: str((output_dir / lane["file"]).relative_to(REPO_ROOT))
        for lane in QUEUE_LANES
    }
    queue_files["effectiveness"] = str((output_dir / "effectiveness.json").relative_to(REPO_ROOT))

    return {
        "schema": "touhou-formal-ce-campaign-summary-v1",
        "generatedAt": generated_at,
        "outputDirectory": str(output_dir.relative_to(REPO_ROOT)),
        "queueFiles": queue_files,
        "totals": {
            "candidateCount": total_candidates,
            "highCounterexampleCount": len(counterexamples),
            "mediumSurpriseCount": len(semantic_surprises),
            "controlCount": len(controls),
            "laneElapsedSeconds": round(total_elapsed, 3),
            "allQueuesSat": all(summary["allSat"] for summary in summaries.values()),
            "allQueuesReplayMatched": all(
                summary["allReplayMatched"] for summary in summaries.values()
            ),
        },
        "counterexamplesByRisk": dict(risk_counts),
        "counterexamplesByLane": dict(lane_counts),
        "counterexamplesByTitle": dict(title_counts),
        "laneSummaries": summaries,
        "expectationLedger": expectation_ledger(),
        "counterexamples": counterexamples,
        "semanticSurprises": semantic_surprises,
        "residualBlindSpots": residual_blind_spots(effectiveness),
    }


def expectation_ledger() -> list[dict[str, str]]:
    return [
        {
            "property": "raw instruction cursor stays in the decoded ECL buffer and progresses when dispatch advances or jumps",
            "precondition": "one byte-realizable raw instruction passes the title difficulty/time gate",
            "oracle": "Lean replays the materialized fixture and classifies cursorClass as before-buffer, at-or-past-end, or non-progress",
            "consequence": "a reachable VM step can move execution outside the decoded instruction stream or stall it",
        },
        {
            "property": "integer DIV/MOD do not execute with zero divisor or signed idiv overflow operands",
            "precondition": "one modeled integer arithmetic opcode passes resolver and difficulty gates",
            "oracle": "fixture faultKind is divide-by-zero or arithmetic-overflow after concrete Lean replay",
            "consequence": "the source-level opcode body reaches a CPU/host arithmetic fault boundary",
        },
        {
            "property": "boss-indexed reads only access in-bounds, non-null g_EnemyManager.bosses entries",
            "precondition": "TH07/TH08 boss read opcode executes with operandFlags selecting boss-backed resolution",
            "oracle": "fixture faultKind is out-of-bounds-read or null-dereference after concrete Lean replay",
            "consequence": "the VM can construct a boss table OOB read or null boss dereference without manual seed selection",
        },
        {
            "property": "CALL/RET and conditional CALL only touch valid call-stack and subTable entries",
            "precondition": "CALL/RET-family opcode executes under the title stack/sub lookup policy",
            "oracle": "lane risk class reports stack OOB write/read, child-context OOB read, or subTable OOB read with matchesPath=true",
            "consequence": "subroutine control flow can escape the modeled stack/table bounds",
        },
    ]


def residual_blind_spots(effectiveness: dict[str, Any]) -> list[str]:
    comparison = effectiveness.get("fuzzComparison", {})
    items = comparison.get("fuzzCurrentlyBeatsFormalFor", [])
    if isinstance(items, list) and items:
        return [str(item) for item in items]
    return [
        "persistent host game state beyond typed opcode-boundary effects",
        "bounded multi-step and multi-context ECL scheduling",
        "full ANM opcode execution and rendering/audio/runtime oracles",
    ]


def write_markdown_summary(path: Path, summary: dict[str, Any]) -> None:
    totals = summary["totals"]
    lines = [
        "# CE Campaign",
        "",
        f"Generated: `{summary['generatedAt']}`",
        "",
        "This campaign reruns every current SMT-backed symbolic execution lane,",
        "stores the full queue JSON for each lane, then builds a high-priority",
        "counterexample summary from the lane-owned risk labels.",
        "",
        "## Totals",
        "",
        f"- Candidates: {totals['candidateCount']}",
        f"- High-priority counterexamples: {totals['highCounterexampleCount']}",
        f"- Medium-priority semantic surprises: {totals['mediumSurpriseCount']}",
        f"- Controls: {totals['controlCount']}",
        f"- All queues SAT: {str(totals['allQueuesSat']).lower()}",
        f"- All concrete replays matched requested paths: {str(totals['allQueuesReplayMatched']).lower()}",
        f"- Queue elapsed seconds: {totals['laneElapsedSeconds']}",
        "",
        "## High-Priority Counterexamples By Lane",
        "",
        "| Lane | Candidates | High CE | Matched | Elapsed s |",
        "| --- | ---: | ---: | --- | ---: |",
    ]
    for lane_name, lane_summary_data in summary["laneSummaries"].items():
        matched = str(lane_summary_data["allReplayMatched"]).lower()
        lines.append(
            "| "
            f"{lane_name} | "
            f"{lane_summary_data['candidateCount']} | "
            f"{lane_summary_data['highCounterexampleCount']} | "
            f"{matched} | "
            f"{lane_summary_data['elapsedSeconds']} |"
        )

    lines.extend([
        "",
        "## Risk Classes",
        "",
    ])
    for risk, count in sorted(summary["counterexamplesByRisk"].items()):
        lines.append(f"- `{risk}`: {count}")

    lines.extend([
        "",
        "## Representative CE Witnesses",
        "",
        "| ID | Risk | Oracle | Fixture hex |",
        "| --- | --- | --- | --- |",
    ])
    for candidate in summary["counterexamples"][:20]:
        oracle = candidate["oracle"]
        oracle_text = (
            str(oracle.get("faultKind"))
            if oracle.get("faultKind") not in (None, "-", "None")
            else str(oracle.get("cursorClass") or oracle.get("action"))
        )
        hex_text = (
            candidate["fixture"].get("hex")
            or candidate["fixture"].get("rawInstructionHex")
            or "-"
        )
        lines.append(
            "| "
            f"`{candidate['id']}` | "
            f"`{candidate['risk']['class']}` | "
            f"`{oracle_text}` | "
            f"`{hex_text}` |"
        )

    lines.extend([
        "",
        "## Residual Blind Spots",
        "",
    ])
    for item in summary["residualBlindSpots"]:
        lines.append(f"- {item}")

    path.write_text("\n".join(lines) + "\n")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run every current SMT-backed CE queue and save campaign artifacts."
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=DEFAULT_OUTPUT_ROOT,
        help="directory where timestamped campaign folders are created",
    )
    parser.add_argument(
        "--name",
        help="campaign folder name; defaults to the UTC timestamp",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=600,
        help="per-queue timeout in seconds; use 0 to disable",
    )
    parser.add_argument(
        "--run-check",
        action="store_true",
        help="ask evaluate_symex_effectiveness.py to run ./scripts/check.sh after queues are saved",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H%M%SZ")
    output_dir = args.output_root / (args.name or generated_at)
    output_dir.mkdir(parents=True, exist_ok=False)
    timeout = None if args.timeout == 0 else args.timeout

    lane_payloads: dict[str, dict[str, Any]] = {}
    lane_commands: dict[str, dict[str, Any]] = {}
    for lane in QUEUE_LANES:
        payload, command = run_json_command(
            [sys.executable, lane["script"]],
            timeout,
        )
        if not isinstance(payload, dict):
            raise CampaignError(f"{lane['name']} did not return a JSON object")
        lane_payloads[lane["name"]] = payload
        lane_commands[lane["name"]] = command
        write_json(output_dir / lane["file"], payload)

    eval_argv = [sys.executable, "scripts/evaluate_symex_effectiveness.py"]
    for lane in QUEUE_LANES:
        eval_argv.extend([lane["eval_arg"], str(output_dir / lane["file"])])
    if args.run_check:
        eval_argv.append("--run-check")
    effectiveness, effectiveness_command = run_json_command(eval_argv, timeout)
    write_json(output_dir / "effectiveness.json", effectiveness)

    summary = build_summary(
        output_dir,
        generated_at,
        lane_payloads,
        lane_commands,
        effectiveness,
    )
    summary["commands"] = {
        "queues": lane_commands,
        "effectiveness": effectiveness_command,
    }
    write_json(output_dir / "summary.json", summary)
    write_markdown_summary(output_dir / "README.md", summary)

    print(json.dumps({
        "schema": "touhou-formal-ce-campaign-run-v1",
        "outputDirectory": str(output_dir.relative_to(REPO_ROOT)),
        "summary": {
            "candidateCount": summary["totals"]["candidateCount"],
            "highCounterexampleCount": summary["totals"]["highCounterexampleCount"],
            "mediumSurpriseCount": summary["totals"]["mediumSurpriseCount"],
            "allQueuesSat": summary["totals"]["allQueuesSat"],
            "allQueuesReplayMatched": summary["totals"]["allQueuesReplayMatched"],
            "counterexamplesByRisk": summary["counterexamplesByRisk"],
            "counterexamplesByLane": summary["counterexamplesByLane"],
        },
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except CampaignError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
