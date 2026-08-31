#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
MATERIALIZER = REPO_ROOT / "scripts" / "symex_materialize_int_resolver.py"

DEFAULT_ENVS = [
    ("th06", 0, "slot0"),
    ("th07", 0, "slot0"),
    ("th08", 0, "slot0"),
]


class QueueError(RuntimeError):
    pass


def run_materializer(title: str, path: str, slot: int) -> Any:
    command = [
        sys.executable,
        str(MATERIALIZER),
        title,
        path,
        str(slot),
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
        raise QueueError(f"int resolver materializer failed for {title}/{path}: {detail}")
    return json.loads(completed.stdout)


def classify_path(path: str) -> dict[str, Any]:
    if path == "raw-immediate":
        return {
            "class": "mask-clear-raw-immediate",
            "priority": "medium",
            "priorityRank": 1,
            "reason": "operand mask bit is clear, so the raw operand value is used directly",
        }
    if path == "resolved-host":
        return {
            "class": "mask-set-known-selector",
            "priority": "high",
            "priorityRank": 0,
            "reason": "operand mask bit is set and selector is known, so the value comes from symbolic host state",
        }
    if path == "resolved-default-raw":
        return {
            "class": "mask-set-default-raw",
            "priority": "high",
            "priorityRank": 0,
            "reason": "operand mask bit is set but selector is unknown, so ZUN's resolver falls back to the raw operand",
        }
    return {
        "class": "resolver-control",
        "priority": "low",
        "priorityRank": 2,
        "reason": "resolver path control",
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
        "slot": record["slot"],
        "path": path,
        "status": record["status"],
        "risk": risk,
        "fixture": {
            "hex": fixture.get("hex"),
            "size": int(fixture["size"]) if isinstance(fixture.get("size"), str) and fixture["size"].isdigit() else fixture.get("size"),
            "decodedOperandMask": fixture.get("decodedOperandMask"),
            "rawValue": fixture.get("rawValue"),
            "resolvedKind": fixture.get("resolvedKind"),
            "resolvedValue": fixture.get("resolvedValue"),
            "selectorKnown": fixture.get("selectorKnown"),
            "flagEnabled": fixture.get("flagEnabled"),
            "hostValue": fixture.get("hostValue"),
            "matchesPath": fixture.get("matchesPath"),
        },
        "witness": {
            key: witness.get(key)
            for key in (
                "slot",
                "rawValue",
                "hostValue",
                "operandMask",
            )
        },
        "nextAction": next_action_for(record["title"], path),
    }


def next_action_for(title: str, path: str) -> str:
    if path == "resolved-default-raw":
        return "use as metamorphic/control seed: mask-set unknown selector should behave like raw immediate where opcode semantics only reads the resolved value"
    if path == "resolved-host":
        return "compose with conditional jumps and arithmetic hazards using symbolic host values"
    return "keep as mask-clear baseline for TH07/TH08 operandFlags-sensitive opcodes"


def parse_env(text: str) -> tuple[str, int, str]:
    parts = text.split(":")
    if len(parts) not in (2, 3):
        raise argparse.ArgumentTypeError("env must be title:slot[:name]")
    title, slot_text = parts[:2]
    if title not in {"th06", "th07", "th08"}:
        raise argparse.ArgumentTypeError("env title must be th06, th07, or th08")
    try:
        slot = int(slot_text, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("slot must be an integer") from exc
    if slot < 0:
        raise argparse.ArgumentTypeError("slot must be nonnegative")
    name = parts[2] if len(parts) == 3 else f"slot{slot}"
    return title, slot, name


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a profile-driven symbolic integer operand resolver queue."
    )
    parser.add_argument(
        "--env",
        action="append",
        type=parse_env,
        help="environment as title:slot[:name]; defaults cover TH06/TH07/TH08 slot 0",
    )
    parser.add_argument(
        "--path",
        default="all",
        help="path name from `lake exe symex list-int-resolver-paths`, or all",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    envs = args.env or DEFAULT_ENVS
    candidates: list[dict[str, Any]] = []
    for title, slot, env_name in envs:
        records = run_materializer(title, args.path, slot)
        if isinstance(records, dict):
            records = [records]
        if not isinstance(records, list):
            raise QueueError("int resolver materializer returned neither object nor list")
        for record in records:
            if not isinstance(record, dict):
                raise QueueError(f"bad int resolver materializer record: {record!r}")
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
        "schema": "touhou-formal-symex-int-resolver-queue-v1",
        "generator": "scripts/symex_int_resolver_queue.py",
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
