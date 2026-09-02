#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
MATERIALIZER = REPO_ROOT / "scripts" / "symex_materialize_extension_step.py"

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
        raise QueueError(f"extension materializer failed for {title}/{path}: {detail}")
    return json.loads(completed.stdout)


def classify_path(path: str) -> dict[str, Any]:
    if path in {
        "extension-call-index-before-array",
        "extension-call-index-at-or-past-array",
        "extension-install-index-before-array",
        "extension-install-index-at-or-past-array",
    }:
        return {
            "class": "extension-callback-table-oob-read",
            "priority": "high",
            "priorityRank": 0,
            "reason": "extension dispatch indexes the fixed callback table without a pre-read bounds check",
        }
    if path == "extension-install-negative-clear":
        return {
            "class": "extension-negative-index-clears-callback",
            "priority": "medium",
            "priorityRank": 1,
            "reason": "negative install index clears the per-frame callback instead of touching the table",
        }
    return {
        "class": "extension-control",
        "priority": "low",
        "priorityRank": 2,
        "reason": "reachable extension-dispatch control path in the current single-instruction abstraction",
    }


def parse_size(value: Any) -> Any:
    if isinstance(value, str) and value.isdigit():
        return int(value)
    return value


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
            "size": parse_size(fixture.get("size")),
            "action": fixture.get("action"),
            "targetCursor": fixture.get("targetCursor"),
            "cursorClass": fixture.get("cursorClass"),
            "guardIndex": fixture.get("guardIndex"),
            "tableIndex": fixture.get("tableIndex"),
            "calledNow": fixture.get("calledNow"),
            "callbackInstalled": fixture.get("callbackInstalled"),
            "perFrameInstructionStored": fixture.get("perFrameInstructionStored"),
            "callbackCleared": fixture.get("callbackCleared"),
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
                "indexRaw0",
                "indexHost0",
                "indexRaw1",
                "indexHost1",
                "bufferSize",
                "difficultyPass",
            )
        },
        "nextAction": next_action_for(record["title"], path, risk["class"]),
    }


def next_action_for(title: str, path: str, risk_class: str) -> str:
    if risk_class == "extension-callback-table-oob-read":
        if path.startswith("extension-install-"):
            return (
                "compose with host-variable state or lower as an install opcode mutation; "
                "TH07/TH08 second-read witnesses need the selected host selector value"
            )
        return "lower to a minimal ECL opcode mutation and validate callback-table OOB in retail Wine"
    if risk_class == "extension-negative-index-clears-callback":
        return "keep as a semantic-surprise control for callback lifecycle and per-frame dispatch composition"
    return "keep as an extension-dispatch control for multi-step scheduler composition"


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
        description="Build a profile-driven symbolic raw ECL extension-dispatch candidate queue."
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
        help="path name from `lake exe symex list-extension-paths`, or all",
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
            raise QueueError("extension materializer returned neither object nor list")
        for record in records:
            if not isinstance(record, dict):
                raise QueueError(f"bad extension materializer record: {record!r}")
            if record.get("status") != "sat":
                continue
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
        "schema": "touhou-formal-symex-extension-candidate-queue-v1",
        "generator": "scripts/symex_extension_candidate_queue.py",
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
