#!/usr/bin/env python3
"""Solve integer operand resolver paths and replay them in Lean.

The resolver layer is intentionally host-symbolic: Lean materializes the raw
instruction bytes and operand mask, while ``hostValue`` stands for the concrete
value that a known selector would read from Enemy/GameManager/context state.
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
    "slot",
    "rawValue",
    "hostValue",
    "operandMask",
]

POSSIBLE_PATHS = {
    "th06": ["resolved-host", "resolved-default-raw"],
    "th07": ["raw-immediate", "resolved-host", "resolved-default-raw"],
    "th08": ["raw-immediate", "resolved-host", "resolved-default-raw"],
}


def solve_path(title: str, path: str, slot: int) -> Any:
    query = checked_stdout(
        [
            "lake",
            "exe",
            "symex",
            "query-int-resolver-values",
            title,
            path,
            str(slot),
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
        "materialize-int-resolver",
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
        raise SymexError(f"materialized resolver witness did not replay into requested path: {result}")
    return result


def list_paths(title: str, requested: str) -> list[str]:
    if requested == "all":
        return POSSIBLE_PATHS[title]
    return [requested]


def solve_and_materialize(title: str, path: str, slot: int) -> dict[str, Any]:
    z3_result = solve_path(title, path, slot)
    record: dict[str, Any] = {
        "title": title,
        "path": path,
        "slot": slot,
        "status": z3_result.status,
    }
    if z3_result.status == "sat":
        record["witness"] = z3_result.values
        record["fixture"] = materialize(title, path, z3_result.values)
    return record


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Solve integer operand resolver paths with Z3 and replay in Lean."
    )
    parser.add_argument("title", choices=["th06", "th07", "th08"])
    parser.add_argument("path", help="path name from `lake exe symex list-int-resolver-paths`, or `all`")
    parser.add_argument("slot", nargs="?", type=int, default=0)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    if args.slot < 0:
        raise SymexError("slot must be nonnegative")
    paths = list_paths(args.title, args.path)
    records = [solve_and_materialize(args.title, path, args.slot) for path in paths]
    payload: Any = records if args.path == "all" else records[0]
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except SymexError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
