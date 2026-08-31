#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
MATERIALIZER = REPO_ROOT / "scripts" / "symex_materialize_int_binary.py"

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
        raise QueueError(f"integer-binary materializer failed for {title}/{path}: {detail}")
    return json.loads(completed.stdout)


def classify_path(path: str, fixture: dict[str, Any]) -> dict[str, Any]:
    if "divide-overflow" in path:
        return {
            "class": "arithmetic-overflow",
            "priority": "high",
            "priorityRank": 0,
            "reason": "signed i32 division/modulo can reach the x86 idiv overflow case INT_MIN / -1",
        }
    if "divisor-zero" in path:
        if path.endswith("resolved-host"):
            reason = "zero divisor is supplied by resolved host state rather than the raw ECL operand bytes"
        else:
            reason = "source integer div/mod body reaches a zero divisor with no guard"
        return {
            "class": "arithmetic-fault",
            "priority": "high",
            "priorityRank": 0,
            "reason": reason,
        }
    if path == "int-binary-non-int-output":
        return {
            "class": "silent-no-op",
            "priority": "medium",
            "priorityRank": 2,
            "reason": "TH06-style typed output classification can skip the arithmetic body before reading RHS",
        }
    if fixture.get("outputKind") == "raw-operand-cell":
        return {
            "class": "raw-operand-self-write",
            "priority": "medium",
            "priorityRank": 2,
            "reason": "masked-off lvalue writes back into the instruction's raw operand cell",
        }
    if fixture.get("outputKind") == "resolved-default-raw-cell":
        return {
            "class": "default-raw-self-write",
            "priority": "medium",
            "priorityRank": 2,
            "reason": "unknown lvalue selector defaults to the instruction's raw operand cell",
        }
    return {
        "class": "host-lvalue-write",
        "priority": "low",
        "priorityRank": 3,
        "reason": "ordinary resolved host-lvalue arithmetic write",
    }


def compact_record(record: dict[str, Any], env_name: str) -> dict[str, Any]:
    path = str(record["path"])
    fixture = record.get("fixture", {})
    witness = record.get("witness", {})
    risk = classify_path(path, fixture)
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
            "opcode": fixture.get("decodedOpcode"),
            "operandMask": fixture.get("decodedOperandMask"),
            "op": fixture.get("op"),
            "outputKind": fixture.get("outputKind"),
            "lhsKind": fixture.get("lhsKind"),
            "rhsKind": fixture.get("rhsKind"),
            "lhsValue": fixture.get("lhsValue"),
            "rhsValue": fixture.get("rhsValue"),
            "action": fixture.get("action"),
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
                "outputRaw",
                "outputHostBefore",
                "lhsRaw",
                "rhsRaw",
                "lhsHost",
                "rhsHost",
                "bufferSize",
                "difficultyPass",
            )
        },
        "nextAction": next_action_for(risk["class"], record["title"], path),
    }


def next_action_for(risk_class: str, title: str, path: str) -> str:
    if risk_class in {"arithmetic-fault", "arithmetic-overflow"}:
        if title == "th06":
            return "splice into TH06 stage ECL and run retail Wine confirmation"
        return "retain as formal candidate until the title-specific retail ECL packer is wired"
    if risk_class in {"raw-operand-self-write", "default-raw-self-write"}:
        return "compose with multi-step execution to see whether operand self-write feeds a later VM transition"
    if path == "int-binary-non-int-output":
        return "use as a semantic-drift guard for TH06 typed-output behavior"
    return "keep as an ordinary arithmetic control witness"


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
        description="Build a profile-driven symbolic raw ECL integer-binary candidate queue."
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
        help="path name from `lake exe symex list-int-binary-paths`, or all",
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
            raise QueueError("integer-binary materializer returned neither object nor list")
        for record in records:
            if not isinstance(record, dict):
                raise QueueError(f"bad integer-binary materializer record: {record!r}")
            if record.get("status") == "sat":
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
        "schema": "touhou-formal-symex-int-binary-candidate-queue-v1",
        "generator": "scripts/symex_int_binary_candidate_queue.py",
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
