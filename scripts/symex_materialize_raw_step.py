#!/usr/bin/env python3
"""Solve raw ECL symbolic-step paths and materialize profile-driven fixtures.

The Python layer intentionally does not know TH06/TH07/TH08 wire offsets.  It
only calls the Lean symex executable, asks Z3 for a model, parses fixed witness
fields, and asks Lean to encode/decode/replay the witness against the shared
profile-backed semantics.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


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
    "bufferSize",
]


class SymexError(RuntimeError):
    pass


@dataclass(frozen=True)
class Z3Result:
    status: str
    values: dict[str, Any]
    stdout: str
    stderr: str


def run_command(argv: list[str], *, input_text: str | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        argv,
        cwd=REPO_ROOT,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def checked_stdout(argv: list[str], *, input_text: str | None = None) -> str:
    proc = run_command(argv, input_text=input_text)
    if proc.returncode != 0:
        detail = proc.stderr.strip() or proc.stdout.strip()
        raise SymexError(f"{' '.join(argv)} failed with exit {proc.returncode}: {detail}")
    return proc.stdout


def tokenize_sexpr(text: str) -> list[str]:
    tokens: list[str] = []
    token = []
    for char in text:
        if char in "()":
            if token:
                tokens.append("".join(token))
                token.clear()
            tokens.append(char)
        elif char.isspace():
            if token:
                tokens.append("".join(token))
                token.clear()
        else:
            token.append(char)
    if token:
        tokens.append("".join(token))
    return tokens


def parse_one(tokens: list[str], index: int = 0) -> tuple[Any, int]:
    if index >= len(tokens):
        raise SymexError("unexpected end of S-expression")
    token = tokens[index]
    if token == "(":
        values = []
        index += 1
        while index < len(tokens) and tokens[index] != ")":
            value, index = parse_one(tokens, index)
            values.append(value)
        if index >= len(tokens):
            raise SymexError("unterminated S-expression")
        return values, index + 1
    if token == ")":
        raise SymexError("unexpected closing parenthesis")
    return token, index + 1


def parse_many(text: str) -> list[Any]:
    tokens = tokenize_sexpr(text)
    values = []
    index = 0
    while index < len(tokens):
        value, index = parse_one(tokens, index)
        values.append(value)
    return values


def atom_to_value(expr: Any) -> Any:
    if isinstance(expr, str):
        if expr == "true":
            return True
        if expr == "false":
            return False
        if expr.startswith("#x"):
            return int(expr[2:], 16)
        if expr.startswith("#b"):
            return int(expr[2:], 2)
        try:
            return int(expr, 10)
        except ValueError:
            return expr
    if isinstance(expr, list) and len(expr) == 2 and expr[0] == "-":
        value = atom_to_value(expr[1])
        if not isinstance(value, int):
            raise SymexError(f"cannot parse negative value: {expr!r}")
        return -value
    return expr


def parse_get_value(stdout: str) -> Z3Result:
    lines = [line.strip() for line in stdout.splitlines() if line.strip()]
    if not lines:
        raise SymexError("Z3 produced no stdout")
    status = lines[0]
    if status != "sat":
        return Z3Result(status=status, values={}, stdout=stdout, stderr="")
    sexprs = parse_many("\n".join(lines[1:]))
    if len(sexprs) != 1 or not isinstance(sexprs[0], list):
        raise SymexError(f"expected one get-value response, got: {sexprs!r}")
    values: dict[str, Any] = {}
    for pair in sexprs[0]:
        if not isinstance(pair, list) or len(pair) != 2 or not isinstance(pair[0], str):
            raise SymexError(f"bad get-value pair: {pair!r}")
        values[pair[0]] = atom_to_value(pair[1])
    return Z3Result(status=status, values=values, stdout=stdout, stderr="")


def solve_path(title: str, path: str, active_mask: int, override_mask: int) -> Z3Result:
    query = checked_stdout(
        [
            "lake",
            "exe",
            "symex",
            "query-values",
            title,
            path,
            str(active_mask),
            str(override_mask),
        ]
    )
    z3 = run_command(["z3", "-in"], input_text=query)
    if z3.returncode != 0:
        raise SymexError(f"z3 failed with exit {z3.returncode}: {z3.stderr.strip()}")
    result = parse_get_value(z3.stdout)
    return Z3Result(status=result.status, values=result.values, stdout=z3.stdout, stderr=z3.stderr)


def materialize(title: str, path: str, values: dict[str, Any], *, ecl_file: bool = False) -> dict[str, str]:
    missing = [field for field in WITNESS_FIELDS if field not in values]
    if missing:
        raise SymexError(f"Z3 witness missing fields: {', '.join(missing)}")
    argv = [
        "lake",
        "exe",
        "symex",
        "materialize-file" if ecl_file else "materialize",
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
        raise SymexError(f"materialized witness did not replay into requested path: {result}")
    return result


def list_paths() -> list[str]:
    text = checked_stdout(["lake", "exe", "symex", "list-paths"])
    return [line.strip() for line in text.splitlines() if line.strip()]


def solve_and_materialize(
    title: str,
    path: str,
    active_mask: int,
    override_mask: int,
    *,
    ecl_file: bool = False,
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
        record["fixture"] = materialize(title, path, z3_result.values, ecl_file=ecl_file)
    return record


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Solve raw ECL step paths with Z3 and materialize Lean-checked fixtures."
    )
    parser.add_argument("title", choices=["th06", "th07", "th08"])
    parser.add_argument("path", help="path name from `lake exe symex list-paths`, or `all`")
    parser.add_argument("active_mask", nargs="?", type=int, default=1)
    parser.add_argument("override_mask", nargs="?", type=int, default=0)
    parser.add_argument(
        "--ecl-file",
        action="store_true",
        help="materialize a minimal one-sub ECL file instead of only the raw instruction bytes",
    )
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
            ecl_file=args.ecl_file,
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
