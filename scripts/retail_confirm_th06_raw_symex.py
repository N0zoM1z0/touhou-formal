#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from typing import Any


FORMAL_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_ROOT = FORMAL_ROOT.parent
DANMAKUFUZZ_ROOT = WORKSPACE_ROOT / "reference" / "DanmakuFuzz"
DANMAKUFUZZ_SRC = DANMAKUFUZZ_ROOT / "src"
DEFAULT_SOURCE_GAME_DIR = WORKSPACE_ROOT / "retail_extract" / "th06-20260831-unar" / "th06"
DEFAULT_RETAIL_ROOT = WORKSPACE_ROOT / "retail_validation"

ST_ARCHIVE_NAME = "紅魔郷ST.DAT"
SEED_NAME = "ecldata5.ecl"
PRACTICE_STAGE = 5
DEFAULT_SUB_INDEX = 0
DEFAULT_INSTRUCTION_INDEX = 0
DEFAULT_SYMEX_PATH = "jumped-before-buffer"


def _import_danmakufuzz() -> None:
    if not DANMAKUFUZZ_SRC.is_dir():
        raise FileNotFoundError(f"missing DanmakuFuzz source tree: {DANMAKUFUZZ_SRC}")
    sys.path.insert(0, str(DANMAKUFUZZ_SRC))


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _default_artifact_dir(path_name: str) -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    safe_path = "".join(char if char.isalnum() or char in "-_" else "-" for char in path_name)
    return DEFAULT_RETAIL_ROOT / f"formal-th06-raw-symex-{safe_path}-{stamp}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Lower a Lean/Z3 raw ECL symbolic-step witness into a TH06 retail "
            "ECL mutation and optionally run the isolated Wine confirmation."
        )
    )
    parser.add_argument("--source-game-dir", type=Path, default=DEFAULT_SOURCE_GAME_DIR)
    parser.add_argument("--artifact-dir", type=Path)
    parser.add_argument("--symex-path", default=DEFAULT_SYMEX_PATH)
    parser.add_argument(
        "--active-mask",
        type=int,
        help="formal active difficulty mask; defaults to 1 << --difficulty for TH06 retail",
    )
    parser.add_argument("--override-mask", type=int, default=0)
    parser.add_argument("--difficulty", type=int, choices=range(4), default=3)
    parser.add_argument("--seed-name", default=SEED_NAME)
    parser.add_argument("--sub-index", type=int, default=DEFAULT_SUB_INDEX)
    parser.add_argument("--instruction-index", type=int, default=DEFAULT_INSTRUCTION_INDEX)
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--compare-clean-baseline", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--repeat", type=int, default=1)
    parser.add_argument("--require", type=int)
    parser.add_argument("--timeout-seconds", type=float, default=28.0)
    parser.add_argument("--stage-entry-wait-seconds", type=float, default=4.0)
    parser.add_argument("--stage-entry-min-frame", type=int, default=60)
    parser.add_argument("--progress-probe-seconds", type=float, default=12.0)
    parser.add_argument("--progress-probe-frames", type=int, default=450)
    parser.add_argument("--startup-normalization", choices=("auto", "gdb", "off"), default="auto")
    parser.add_argument("--expect-classification")
    parser.add_argument("--expect-signature-key")
    return parser.parse_args()


def _effective_active_mask(args: argparse.Namespace) -> int:
    return args.active_mask if args.active_mask is not None else (1 << args.difficulty)


def _run_symex_materializer(path_name: str, active_mask: int, override_mask: int) -> dict[str, Any]:
    command = [
        sys.executable,
        str(FORMAL_ROOT / "scripts" / "symex_materialize_raw_step.py"),
        "th06",
        path_name,
        str(active_mask),
        str(override_mask),
    ]
    completed = subprocess.run(
        command,
        cwd=FORMAL_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(f"symex materializer failed: {detail}")
    record = json.loads(completed.stdout)
    if not isinstance(record, dict):
        raise RuntimeError("symex materializer did not return a JSON object")
    if record.get("status") != "sat":
        raise RuntimeError(f"symex path is not satisfiable: {record.get('status')}")
    fixture = record.get("fixture")
    if not isinstance(fixture, dict) or fixture.get("matchesPath") != "true":
        raise RuntimeError(f"symex fixture did not replay into the requested path: {fixture!r}")
    return record


def _raw_instruction_from_bytes(raw: bytes):
    _import_danmakufuzz()

    from danmakufuzz.ecl_ir.model import RawInstruction

    if len(raw) < 12:
        raise ValueError(f"raw instruction fixture is too small: {len(raw)}")
    return RawInstruction(
        time=int.from_bytes(raw[0:4], "little", signed=True),
        opcode=int.from_bytes(raw[4:6], "little", signed=True),
        offset_to_next=int.from_bytes(raw[6:8], "little", signed=True),
        unk8=raw[8],
        skip_for_difficulty=raw[9],
        unk_a=raw[10],
        unk_b=raw[11],
        args=raw[12:],
    )


def build_case(args: argparse.Namespace, artifact_dir: Path) -> Path:
    _import_danmakufuzz()

    from danmakufuzz.corpus.pbg3 import Pbg3Archive
    from danmakufuzz.ecl_ir.parser import parse_ecl
    from danmakufuzz.ecl_ir.serializer import serialize_ecl_canonical

    active_mask = _effective_active_mask(args)
    if not 0 <= active_mask <= 255 or not 0 <= args.override_mask <= 255:
        raise ValueError("active and override masks must fit in an unsigned byte")
    if args.sub_index < 0 or args.instruction_index < 0:
        raise ValueError("sub-index and instruction-index must be nonnegative")

    symex_record = _run_symex_materializer(
        args.symex_path,
        active_mask,
        args.override_mask,
    )
    fixture = symex_record["fixture"]
    fixture_hex = fixture["hex"]
    raw_instruction = _raw_instruction_from_bytes(bytes.fromhex(str(fixture_hex)))

    source_game_dir = args.source_game_dir.resolve()
    archive_path = source_game_dir / ST_ARCHIVE_NAME
    if not archive_path.is_file():
        raise FileNotFoundError(f"missing TH06 stage archive: {archive_path}")

    source_archive = Pbg3Archive.from_bytes(archive_path.read_bytes())
    source_payload = source_archive.extract(args.seed_name)
    source_payload_sha256 = _sha256_bytes(source_payload)
    ecl = parse_ecl(source_payload).clone()
    if args.sub_index >= len(ecl.subs):
        raise IndexError(f"{args.seed_name} has no sub {args.sub_index}")
    selected_sub = ecl.subs[args.sub_index]
    if args.instruction_index >= len(selected_sub.instructions):
        raise IndexError(
            f"{args.seed_name} sub {args.sub_index} has no instruction {args.instruction_index}"
        )
    old_instruction = selected_sub.instructions[args.instruction_index]
    selected_sub.instructions[args.instruction_index] = raw_instruction
    payload = serialize_ecl_canonical(ecl)
    payload_sha256 = _sha256_bytes(payload)

    source_result_dir = artifact_dir / "source-result"
    payload_path = source_result_dir / "override" / "data" / args.seed_name
    payload_path.parent.mkdir(parents=True, exist_ok=True)
    payload_path.write_bytes(payload)
    result = {
        "schema": "touhou-formal-retail-raw-symex-candidate-v1",
        "formal_result_id": "ECL-RAW-STEP-WITNESS-MATERIALIZATION",
        "lean_model": "TouhouFormal.ECL.rawStep",
        "symex_command": [
            "scripts/symex_materialize_raw_step.py",
            "th06",
            args.symex_path,
            str(active_mask),
            str(args.override_mask),
        ],
        "case_name": f"formal-th06-raw-symex-{args.symex_path}",
        "mutant_name": f"raw-symex-{args.symex_path}-s{args.sub_index:02d}-i{args.instruction_index:04d}",
        "source_archive": str(archive_path),
        "source_payload_sha256": source_payload_sha256,
        "seed_name": args.seed_name,
        "override_dir": str((source_result_dir / "override").resolve()),
        "payload_sha256": payload_sha256,
        "symex": symex_record,
        "mutation_metadata": {
            "family": "raw-ecl-symbolic-step",
            "symex_path": args.symex_path,
            "active_mask": active_mask,
            "override_mask": args.override_mask,
            "retail_difficulty": args.difficulty,
            "retail_active_mask_rule": "1 << g_GameManager.difficulty",
            "fixture_hex": fixture_hex,
            "fixture_size": int(fixture["size"]),
            "site_key": f"sub:{args.sub_index:04d}:instr:{args.instruction_index:04d}",
            "old_instruction": {
                "time": old_instruction.time,
                "opcode": old_instruction.opcode,
                "offset_to_next": old_instruction.offset_to_next,
                "skip_for_difficulty": old_instruction.skip_for_difficulty,
                "args_hex": old_instruction.args.hex(),
            },
            "new_instruction": {
                "time": raw_instruction.time,
                "opcode": raw_instruction.opcode,
                "offset_to_next": raw_instruction.offset_to_next,
                "skip_for_difficulty": raw_instruction.skip_for_difficulty,
                "args_hex": raw_instruction.args.hex(),
            },
        },
        "sites": [
            {
                "site_kind": "raw-sub-instruction",
                "sub_index": args.sub_index,
                "instruction_index": args.instruction_index,
            }
        ],
        "limitations": [
            "This lowers a symbolic raw-step witness into a reachable TH06 ECL site; it is not a retail finding until confirm_case records a stable oracle.",
            "The current DanmakuFuzz ECL serializer is TH06-shaped; TH07/TH08 retail lowering needs separate tooling.",
        ],
    }
    result_path = source_result_dir / "result.json"
    result_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return result_path


def run_retail_confirmation(args: argparse.Namespace, result_path: Path, artifact_dir: Path) -> int:
    command = [
        sys.executable,
        "-m",
        "danmakufuzz.retail.confirm_case",
        "--result",
        str(result_path),
        "--source-game-dir",
        str(args.source_game_dir.resolve()),
        "--artifact-dir",
        str(artifact_dir),
        "--practice-stage",
        str(PRACTICE_STAGE),
        "--difficulty",
        str(args.difficulty),
        "--timeout-seconds",
        str(args.timeout_seconds),
        "--stage-entry-wait-seconds",
        str(args.stage_entry_wait_seconds),
        "--stage-entry-min-frame",
        str(args.stage_entry_min_frame),
        "--progress-probe-seconds",
        str(args.progress_probe_seconds),
        "--progress-probe-frames",
        str(args.progress_probe_frames),
        "--startup-normalization",
        args.startup_normalization,
        "--repeat",
        str(args.repeat),
    ]
    if args.compare_clean_baseline:
        command.append("--compare-clean-baseline")
    if args.expect_classification:
        command.extend(["--expect-classification", args.expect_classification])
    if args.expect_signature_key:
        command.extend(["--expect-signature-key", args.expect_signature_key])
    if args.require is not None:
        command.extend(["--require", str(args.require)])
    env = os.environ.copy()
    existing_pythonpath = env.get("PYTHONPATH")
    env["PYTHONPATH"] = (
        str(DANMAKUFUZZ_SRC)
        if not existing_pythonpath
        else str(DANMAKUFUZZ_SRC) + os.pathsep + existing_pythonpath
    )
    completed = subprocess.run(command, cwd=DANMAKUFUZZ_ROOT, env=env, check=False)
    return completed.returncode


def main() -> int:
    args = parse_args()
    if args.repeat < 1:
        raise RuntimeError("--repeat must be at least 1")
    active_mask = _effective_active_mask(args)
    if not 0 <= active_mask <= 255 or not 0 <= args.override_mask <= 255:
        raise RuntimeError("active and override masks must fit in an unsigned byte")
    if args.require is not None and (args.require < 1 or args.require > args.repeat):
        raise RuntimeError("--require must be between 1 and --repeat")
    if args.require is not None and not (args.expect_classification or args.expect_signature_key):
        raise RuntimeError("--require needs --expect-classification or --expect-signature-key")
    artifact_dir = (args.artifact_dir or _default_artifact_dir(args.symex_path)).resolve()
    if (artifact_dir / "game").exists() or (artifact_dir / "run-001").exists():
        raise FileExistsError(f"artifact directory already contains a retail run: {artifact_dir}")
    artifact_dir.mkdir(parents=True, exist_ok=True)
    result_path = build_case(args, artifact_dir)
    print(json.dumps({
        "artifact_dir": str(artifact_dir),
        "source_result": str(result_path),
        "prepare_only": args.prepare_only,
    }, indent=2))
    if args.prepare_only:
        return 0
    return run_retail_confirmation(args, result_path, artifact_dir)


if __name__ == "__main__":
    raise SystemExit(main())
