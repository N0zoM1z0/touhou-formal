#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
MATERIALIZER = REPO_ROOT / "scripts" / "symex_materialize_callret_step.py"

DEFAULT_ENVS = [
    ("th06", 1, 0, "formal-active-bit0"),
    ("th06", 8, 0, "retail-lunatic-bit3"),
    ("th07", 1, 0, "formal-active-bit0"),
    ("th08", 1, 0, "formal-active-bit0"),
    ("th08", 1, 2, "override-mask-delta"),
]


class QueueError(RuntimeError):
    pass


def run_materializer(title: str, path: str, active_mask: int, override_mask: int) -> Any:
    command = [
        sys.executable,
        str(MATERIALIZER),
        title,
        path,
        str(active_mask),
        str(override_mask),
    ]
    completed = subprocess.run(
        command,
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise QueueError(f"CALL/RET materializer failed for {title}/{path}: {detail}")
    return json.loads(completed.stdout)


def classify_path(path: str) -> dict[str, Any]:
    if path.startswith("call-stack-write-"):
        return {
            "class": "call-stack-oob-write",
            "priority": "high",
            "priorityRank": 0,
            "reason": "CALL writes the saved context at stackDepth before checking the increment guard",
        }
    if path == "call-lookup-fault":
        return {
            "class": "call-subtable-oob-read",
            "priority": "high",
            "priorityRank": 0,
            "reason": "CALL reaches CallEclSub with a subId outside the title's checked range",
        }
    if path.startswith("ret-stack-read-"):
        return {
            "class": "ret-stack-oob-read",
            "priority": "high",
            "priorityRank": 0,
            "reason": "RET decrements stack depth before reading the saved context stack",
        }
    if path.startswith("ret-child-index-"):
        return {
            "class": "ret-child-context-oob-read",
            "priority": "high",
            "priorityRank": 0,
            "reason": "TH08 RET underflow indexes childEclBlocks[childContextSlot - 1]",
        }
    if path == "ret-exit-child":
        return {
            "class": "ret-child-context-exit",
            "priority": "medium",
            "priorityRank": 1,
            "reason": "TH08 RET underflow can be a child-context exit instead of a saved-stack restore",
        }
    if path == "call-no-op":
        return {
            "class": "call-negative-no-op",
            "priority": "medium",
            "priorityRank": 1,
            "reason": "TH08 negative subId returns from CallEclSub after CALL has already handled return context state",
        }
    return {
        "class": "callret-control",
        "priority": "low",
        "priorityRank": 2,
        "reason": "reachable CALL/RET control path in the current stack abstraction",
    }


def compact_record(record: dict[str, Any], env_name: str) -> dict[str, Any]:
    path = str(record["path"])
    risk = classify_path(path)
    fixture = record.get("fixture", {})
    witness = record.get("witness", {})
    return {
        "id": f"{record['title']}:{env_name}:{path}",
        "title": record["title"],
        "environment": env_name,
        "activeMask": record["activeMask"],
        "overrideMask": record["overrideMask"],
        "path": path,
        "status": record["status"],
        "risk": risk,
        "fixture": {
            "hex": fixture.get("hex"),
            "size": int(fixture["size"]) if isinstance(fixture.get("size"), str) and fixture["size"].isdigit() else fixture.get("size"),
            "action": fixture.get("action"),
            "stackDepthAfter": fixture.get("stackDepthAfter"),
            "returnCursor": fixture.get("returnCursor"),
            "returnCursorClass": fixture.get("returnCursorClass"),
            "targetSubOffset": fixture.get("targetSubOffset"),
            "childContextIndex": fixture.get("childContextIndex"),
            "faultKind": fixture.get("faultKind"),
            "faultDetail": fixture.get("faultDetail"),
            "matchesPath": fixture.get("matchesPath"),
        },
        "witness": {
            key: witness.get(key)
            for key in (
                "currentTime",
                "instrTime",
                "opcode",
                "nextOffset",
                "instructionMask",
                "operandMask",
                "activeMask",
                "overrideMask",
                "subId",
                "stackDepth",
                "stackDisabled",
                "subCount",
                "childContextSlot",
                "bufferSize",
                "difficultyPass",
            )
        },
        "nextAction": next_action_for(record["title"], path, risk["class"]),
    }


def next_action_for(title: str, path: str, risk_class: str) -> str:
    if path == "ret-child-index-before-array":
        return "prioritize TH08 main-context RET depth-zero retail validation; childContextSlot=0 is the expected main-context value"
    if risk_class in {"call-stack-oob-write", "ret-stack-oob-read", "ret-child-context-oob-read"}:
        return "compose with bounded multi-step reachability from a normal stack depth before retail validation"
    if risk_class == "call-subtable-oob-read":
        return "reuse existing CallEclSub retail lowering once CALL opcode mutation sites are selected"
    return "keep as CALL/RET control path for multi-step scheduler composition"


def parse_env(text: str) -> tuple[str, int, int, str]:
    parts = text.split(":")
    if len(parts) not in (3, 4):
        raise argparse.ArgumentTypeError("env must be title:activeMask:overrideMask[:name]")
    title, active, override = parts[:3]
    if title not in {"th06", "th07", "th08"}:
        raise argparse.ArgumentTypeError("env title must be th06, th07, or th08")
    try:
        active_mask = int(active, 0)
        override_mask = int(override, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("env masks must be integers") from exc
    if not 0 <= active_mask <= 255 or not 0 <= override_mask <= 255:
        raise argparse.ArgumentTypeError("env masks must fit in an unsigned byte")
    name = parts[3] if len(parts) == 4 else f"active{active_mask}-override{override_mask}"
    return title, active_mask, override_mask, name


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a profile-driven symbolic CALL/RET candidate queue."
    )
    parser.add_argument(
        "--env",
        action="append",
        type=parse_env,
        help="environment as title:activeMask:overrideMask[:name]; defaults cover TH06/TH07/TH08 plus TH08 override delta",
    )
    parser.add_argument(
        "--path",
        default="all",
        help="path name from `lake exe symex list-callret-paths`, or all",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    envs = args.env or DEFAULT_ENVS
    candidates: list[dict[str, Any]] = []
    for title, active_mask, override_mask, env_name in envs:
        records = run_materializer(title, args.path, active_mask, override_mask)
        if isinstance(records, dict):
            records = [records]
        if not isinstance(records, list):
            raise QueueError("CALL/RET materializer returned neither object nor list")
        for record in records:
            if not isinstance(record, dict):
                raise QueueError(f"bad CALL/RET materializer record: {record!r}")
            candidates.append(compact_record(record, env_name))
    candidates.sort(
        key=lambda item: (
            item["risk"]["priorityRank"],
            item["title"],
            item["environment"],
            item["path"],
        )
    )
    payload = {
        "schema": "touhou-formal-symex-callret-candidate-queue-v1",
        "generator": "scripts/symex_callret_candidate_queue.py",
        "pathRequest": args.path,
        "environmentCount": len(envs),
        "candidateCount": len(candidates),
        "candidates": candidates,
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except QueueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
