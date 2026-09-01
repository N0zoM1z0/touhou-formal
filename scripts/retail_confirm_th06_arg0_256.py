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


FORMAL_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_ROOT = FORMAL_ROOT.parent
DANMAKUFUZZ_ROOT = WORKSPACE_ROOT / "reference" / "DanmakuFuzz"
DANMAKUFUZZ_SRC = DANMAKUFUZZ_ROOT / "src"
DEFAULT_SOURCE_GAME_DIR = WORKSPACE_ROOT / "retail_extract" / "th06-20260831-unar" / "th06"
DEFAULT_RETAIL_ROOT = FORMAL_ROOT / "retail_validation"

ST_ARCHIVE_NAME = "紅魔郷ST.DAT"
SEED_NAME = "ecldata5.ecl"
PRACTICE_STAGE = 5
TIMELINE_INDEX = 1
ARG0_VALUE = 256
EXPECTED_PAYLOAD_SHA256 = "2ff0c53669575690e60298536be0f43d32affa7be1e6f9073f793c5488d02304"
EXPECTED_CLASSIFICATION = "retail-frame-stall"


def _import_danmakufuzz() -> None:
    if not DANMAKUFUZZ_SRC.is_dir():
        raise FileNotFoundError(f"missing DanmakuFuzz source tree: {DANMAKUFUZZ_SRC}")
    sys.path.insert(0, str(DANMAKUFUZZ_SRC))


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _default_artifact_dir() -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return DEFAULT_RETAIL_ROOT / f"formal-th06-stage5-arg0-256-{stamp}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build and optionally run the TH06 formal counterexample "
            "timeline[1].arg0 = 256 against an isolated retail Wine copy."
        )
    )
    parser.add_argument("--source-game-dir", type=Path, default=DEFAULT_SOURCE_GAME_DIR)
    parser.add_argument("--artifact-dir", type=Path, default=None)
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--repeat", type=int, default=1)
    parser.add_argument("--require", type=int)
    parser.add_argument("--timeout-seconds", type=float, default=28.0)
    parser.add_argument("--stage-entry-wait-seconds", type=float, default=4.0)
    parser.add_argument("--stage-entry-min-frame", type=int, default=60)
    parser.add_argument("--progress-probe-seconds", type=float, default=12.0)
    parser.add_argument("--progress-probe-frames", type=int, default=450)
    parser.add_argument("--startup-normalization", choices=("auto", "gdb", "off"), default="auto")
    parser.add_argument("--expect-classification", default=EXPECTED_CLASSIFICATION)
    return parser.parse_args()


def build_case(source_game_dir: Path, artifact_dir: Path) -> Path:
    _import_danmakufuzz()

    from danmakufuzz.corpus.pbg3 import Pbg3Archive
    from danmakufuzz.ecl_ir.model import TimelineInstruction
    from danmakufuzz.ecl_ir.parser import parse_ecl
    from danmakufuzz.ecl_ir.serializer import serialize_ecl_canonical

    source_game_dir = source_game_dir.resolve()
    archive_path = source_game_dir / ST_ARCHIVE_NAME
    if not archive_path.is_file():
        raise FileNotFoundError(f"missing TH06 stage archive: {archive_path}")

    source_archive = Pbg3Archive.from_bytes(archive_path.read_bytes())
    source_payload = source_archive.extract(SEED_NAME)
    source_payload_sha256 = _sha256_bytes(source_payload)

    ecl = parse_ecl(source_payload).clone()
    if not 0 <= TIMELINE_INDEX < len(ecl.timeline):
        raise RuntimeError(f"{SEED_NAME} has no timeline index {TIMELINE_INDEX}")
    old = ecl.timeline[TIMELINE_INDEX]
    ecl.timeline[TIMELINE_INDEX] = TimelineInstruction(
        time=old.time,
        arg0=ARG0_VALUE,
        opcode=old.opcode,
        size=old.size,
        args=old.args,
    )
    payload = serialize_ecl_canonical(ecl)
    payload_sha256 = _sha256_bytes(payload)
    if payload_sha256 != EXPECTED_PAYLOAD_SHA256:
        raise RuntimeError(
            "payload SHA-256 drifted; formal retail case is not the known "
            f"stage5 arg0=256 representative: expected {EXPECTED_PAYLOAD_SHA256}, got {payload_sha256}"
        )

    source_result_dir = artifact_dir / "source-result"
    payload_path = source_result_dir / "override" / "data" / SEED_NAME
    payload_path.parent.mkdir(parents=True, exist_ok=True)
    payload_path.write_bytes(payload)
    result = {
        "schema": "touhou-formal-retail-counterexample-v1",
        "formal_result_id": "TH06-ECL-SUBTABLE-ARG0-256",
        "lean_theorem": "TouhouFormal.TH06.rawOneSubArg0256_shared_counterexample",
        "smt_query": "lake exe smt th06-sub-oob | z3 -in",
        "case_name": "formal-stage5-arg0-256",
        "mutant_name": "timeline-arg0-256",
        "source_archive": str(archive_path),
        "source_payload_sha256": source_payload_sha256,
        "seed_name": SEED_NAME,
        "override_dir": str((source_result_dir / "override").resolve()),
        "payload_sha256": payload_sha256,
        "mutation_metadata": {
            "family": "timeline-arg0",
            "field_name": "arg0",
            "value": ARG0_VALUE,
            "site_key": f"timeline:{TIMELINE_INDEX:04d}",
            "model_fault": "EclManager.CallEclSub subTable out-of-bounds read",
        },
        "sites": [
            {
                "site_kind": "timeline",
                "instruction_index": TIMELINE_INDEX,
            }
        ],
    }
    result_path = source_result_dir / "result.json"
    result_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return result_path


def run_retail_confirmation(args: argparse.Namespace, result_path: Path, artifact_dir: Path) -> int:
    require = args.require if args.require is not None else args.repeat
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
        "3",
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
        "--compare-clean-baseline",
        "--expect-classification",
        args.expect_classification,
        "--repeat",
        str(args.repeat),
        "--require",
        str(require),
    ]
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
    if args.require is not None and (args.require < 1 or args.require > args.repeat):
        raise RuntimeError("--require must be between 1 and --repeat")
    artifact_dir = (args.artifact_dir or _default_artifact_dir()).resolve()
    if (artifact_dir / "game").exists() or (artifact_dir / "run-001").exists():
        raise FileExistsError(f"artifact directory already contains a retail run: {artifact_dir}")
    artifact_dir.mkdir(parents=True, exist_ok=True)

    result_path = build_case(args.source_game_dir, artifact_dir)
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
