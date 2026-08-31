#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
MATERIALIZER = REPO_ROOT / "scripts" / "symex_materialize_body_step.py"

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
        raise QueueError(f"body materializer failed for {title}/{path}: {detail}")
    return json.loads(completed.stdout)


def classify_path(path: str) -> dict[str, Any]:
    if path == "int-divisor-zero":
        return {
            "class": "arithmetic-fault",
            "priority": "high",
            "priorityRank": 0,
            "reason": "source integer div/mod body reaches a zero divisor on the immediate/raw operand branch",
        }
    if "before-buffer" in path:
        return {
            "class": "cursor-underflow",
            "priority": "high",
            "priorityRank": 1,
            "reason": "the body-level transition sends the next instruction cursor negative",
        }
    if "at-or-past-end" in path:
        return {
            "class": "cursor-out-of-range",
            "priority": "high",
            "priorityRank": 1,
            "reason": "the body-level transition sends the cursor at or beyond the raw ECL buffer",
        }
    if "non-progress" in path:
        return {
            "class": "liveness",
            "priority": "high",
            "priorityRank": 2,
            "reason": "the body-level transition leaves the raw instruction cursor unchanged",
        }
    return {
        "class": "reachable-control-path",
        "priority": "low",
        "priorityRank": 3,
        "reason": "the body path is reachable but remains in-bounds in the current one-step model",
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
            "cursorClass": fixture.get("cursorClass"),
            "targetCursor": fixture.get("targetCursor"),
            "targetTime": fixture.get("targetTime"),
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
                "jumpTargetTime",
                "jumpDisplacement",
                "counterBefore",
                "divisorValue",
                "lhsRaw",
                "rhsRaw",
                "lhsHost",
                "rhsHost",
                "compareRegister",
                "bufferSize",
                "difficultyPass",
            )
        },
        "nextAction": next_action_for(risk["class"], record["title"], path),
    }


def next_action_for(risk_class: str, title: str, path: str) -> str:
    if title == "th06" and path == "int-divisor-zero":
        return "splice into TH06 stage ECL and run retail confirmation for integer div/mod zero"
    if path.startswith("int-condjump-"):
        return "compose with multi-step context bounds; then splice into a reachable conditional jump site for retail confirmation"
    if risk_class == "arithmetic-fault":
        return "retain as body-level formal finding; needs title retail adapter before Wine confirmation"
    if risk_class in {"cursor-underflow", "cursor-out-of-range", "liveness"}:
        return "splice fixture into a reachable ECL site and run retail confirmation"
    return "keep as path-coverage control unless later multi-step constraints make it interesting"


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
        description="Build a profile-driven symbolic raw ECL body candidate queue."
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
        help="path name from `lake exe symex list-body-paths`, or all",
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
            raise QueueError("body materializer returned neither object nor list")
        for record in records:
            if not isinstance(record, dict):
                raise QueueError(f"bad body materializer record: {record!r}")
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
        "schema": "touhou-formal-symex-body-candidate-queue-v1",
        "generator": "scripts/symex_body_candidate_queue.py",
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
