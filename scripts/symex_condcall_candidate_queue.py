#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
MATERIALIZER = REPO_ROOT / "scripts" / "symex_materialize_condcall_step.py"

DEFAULT_ENVS = [
    ("th06", 1, 0, "formal-active-bit0"),
    ("th06", 8, 0, "retail-lunatic-bit3"),
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
        raise QueueError(f"conditional CALL materializer failed for {title}/{path}: {detail}")
    return json.loads(completed.stdout)


def classify_path(path: str) -> dict[str, Any]:
    if path.startswith("condcall-stack-write-"):
        return {
            "class": "call-stack-oob-write",
            "priority": "high",
            "priorityRank": 0,
            "reason": "TH06 conditional CALL reaches HANDLE_CALL and writes savedContextStack[stackDepth] before the increment guard",
        }
    if path == "condcall-lookup-fault":
        return {
            "class": "call-subtable-oob-read",
            "priority": "high",
            "priorityRank": 0,
            "reason": "TH06 conditional CALL guard can be true while eclSub is outside subTable",
        }
    if path.startswith("condcall-false-"):
        return {
            "class": "condcall-fallthrough-cursor",
            "priority": "medium",
            "priorityRank": 1,
            "reason": "TH06 conditional CALL guard false path falls through using offsetToNext, including non-progress and out-of-range cursors",
        }
    return {
        "class": "condcall-control",
        "priority": "low",
        "priorityRank": 2,
        "reason": "reachable TH06 conditional CALL control path in the current stack abstraction",
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
                "lhsRaw",
                "lhsHost",
                "rhsRaw",
                "bufferSize",
                "difficultyPass",
            )
        },
        "nextAction": next_action_for(path, risk["class"]),
    }


def next_action_for(path: str, risk_class: str) -> str:
    if risk_class in {"call-stack-oob-write", "call-subtable-oob-read"}:
        return "compose with bounded multi-step reachability from a normal TH06 stack depth before retail validation"
    if path.startswith("condcall-false-"):
        return "compose with loop/liveness search to distinguish intentional polling from malformed non-progress fallthrough"
    return "keep as guarded-CALL control coverage for scheduler composition"


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
        description="Build a profile-driven symbolic conditional CALL candidate queue."
    )
    parser.add_argument(
        "--env",
        action="append",
        type=parse_env,
        help="environment as title:activeMask:overrideMask[:name]; defaults cover TH06 formal bit0 and retail lunatic bit3",
    )
    parser.add_argument(
        "--path",
        default="all",
        help="path name from `lake exe symex list-condcall-paths`, or all",
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
            raise QueueError("conditional CALL materializer returned neither object nor list")
        for record in records:
            if not isinstance(record, dict):
                raise QueueError(f"bad conditional CALL materializer record: {record!r}")
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
        "schema": "touhou-formal-symex-condcall-candidate-queue-v1",
        "generator": "scripts/symex_condcall_candidate_queue.py",
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
