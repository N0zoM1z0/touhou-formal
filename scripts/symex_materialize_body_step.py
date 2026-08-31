#!/usr/bin/env python3
"""Solve raw ECL body paths and materialize Lean-checked fixtures.

This is the opcode-body companion to ``symex_materialize_raw_step.py``.  The
Python layer still does not know TH06/TH07/TH08 wire offsets; it only asks Lean
for SMT, lets Z3 solve, and sends the witness back to Lean for profile-driven
byte encoding and replay.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from symex_materialize_raw_step import (
    SymexError,
    checked_stdout,
    parse_get_value,
    run_command,
)


REPO_ROOT = Path(__file__).resolve().parents[1]
WITNESS_FIELDS = [
    "currentTime",
    "instrTime",
    "opcode",
    "nextOffset",
    "instructionMask",
    "operandMask",
    "activeMask",
    "overrideMask",
    "jumpTargetTime",
    "jumpDisplacement",
    "counterBefore",
    "divisorValue",
    "bufferSize",
]


def solve_path(title: str, path: str, active_mask: int, override_mask: int) -> Any:
    query = checked_stdout(
        [
            "lake",
            "exe",
            "symex",
            "query-body-values",
            title,
            path,
            str(active_mask),
            str(override_mask),
        ]
    )
    z3 = run_command(["z3", "-in"], input_text=query)
    if z3.returncode != 0:
        raise SymexError(f"z3 failed with exit {z3.returncode}: {z3.stderr.strip()}")
    return parse_get_value(z3.stdout)


def materialize(title: str, path: str, values: dict[str, Any]) -> dict[str, str]:
    missing = [field for field in WITNESS_FIELDS if field not in values]
    if missing:
        raise SymexError(f"Z3 witness missing fields: {', '.join(missing)}")
    argv = [
        "lake",
        "exe",
        "symex",
        "materialize-body",
        title,
        path,
        *[str(values[field]) for field in WITNESS_FIELDS],
    ]
    text = checked_stdout(argv)
    result: dict[str, str] = {}
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        result[key] = value
    if result.get("matchesPath") != "true":
        raise SymexError(f"materialized body witness did not replay into requested path: {result}")
    return result


def list_paths() -> list[str]:
    text = checked_stdout(["lake", "exe", "symex", "list-body-paths"])
    return [line.strip() for line in text.splitlines() if line.strip()]


def solve_and_materialize(
    title: str,
    path: str,
    active_mask: int,
    override_mask: int,
) -> dict[str, Any]:
    z3_result = solve_path(title, path, active_mask, override_mask)
    record: dict[str, Any] = {
        "title": title,
        "path": path,
        "activeMask": active_mask,
        "overrideMask": override_mask,
        "status": z3_result.status,
    }
    if z3_result.status == "sat":
        record["witness"] = z3_result.values
        record["fixture"] = materialize(title, path, z3_result.values)
    return record


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Solve raw ECL body paths with Z3 and materialize Lean-checked fixtures."
    )
    parser.add_argument("title", choices=["th06", "th07", "th08"])
    parser.add_argument("path", help="path name from `lake exe symex list-body-paths`, or `all`")
    parser.add_argument("active_mask", nargs="?", type=int, default=1)
    parser.add_argument("override_mask", nargs="?", type=int, default=0)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if not 0 <= args.active_mask <= 255 or not 0 <= args.override_mask <= 255:
        raise SymexError("active_mask and override_mask must fit in an unsigned byte")
    paths = list_paths() if args.path == "all" else [args.path]
    records = [
        solve_and_materialize(
            args.title,
            path,
            args.active_mask,
            args.override_mask,
        )
        for path in paths
    ]
    payload: Any = records if args.path == "all" else records[0]
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except SymexError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
