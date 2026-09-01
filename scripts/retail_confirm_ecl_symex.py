#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any

from ecl_wire_patch import EclWireFile
from retail_pbg import (
    RetailArchive,
    replace_archive_entry,
    sha256_bytes,
    th08_encrypt_blob,
    th08_try_decrypt_blob,
)
from retail_confirm_boss_int_read import (
    ARCHIVE_NAMES,
    DEFAULT_SOURCE_GAME_DIRS,
    DEFAULT_SCREEN_SIZE,
    DEFAULT_RETAIL_ROOT,
    prepare_retail_cfg,
    run_wine_probe,
    _find_archive_entry,
)
from symex_materialize_callret_step import (
    WITNESS_FIELDS as CALLRET_WITNESS_FIELDS,
    cli_value as callret_cli_value,
)
from symex_materialize_raw_step import parse_get_value


FORMAL_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ACTIVE_MASK = 2
DEFAULT_OVERRIDE_MASK = 0

FAMILY_CONFIGS = {
    "int-binary": {
        "artifact_label": "int-binary",
        "default_symex_path": "int-binary-divisor-zero-raw-immediate",
        "materializer": "symex_materialize_int_binary.py",
        "schema": "touhou-formal-retail-int-binary-candidate-v1",
        "formal_id_tag": "ECL-INT-BINARY",
        "lean_model": "TouhouFormal.ECL.rawIntBinaryStep",
        "mutation_family": "int-binary-symbolic-step",
        "state_assumption": (
            "Raw-immediate div/mod witnesses are primarily instruction-local; "
            "host state is only used for the selected retail placement and menu path."
        ),
    },
    "raw-body": {
        "artifact_label": "raw-body",
        "default_symex_path": "int-divisor-zero",
        "materializer": "symex_materialize_body_step.py",
        "schema": "touhou-formal-retail-raw-body-candidate-v1",
        "formal_id_tag": "ECL-RAW-BODY",
        "lean_model": "TouhouFormal.ECL.rawBodyStep",
        "mutation_family": "raw-body-symbolic-step",
        "state_assumption": (
            "The legacy body-slice witness is instruction-local for immediate "
            "integer div/mod zero; richer control paths may depend on VM state."
        ),
    },
    "callret": {
        "artifact_label": "callret",
        "default_symex_path": "ret-stack-read-before-stack",
        "materializer": "symex_materialize_callret_step.py",
        "schema": "touhou-formal-retail-callret-candidate-v1",
        "formal_id_tag": "ECL-CALLRET",
        "lean_model": "TouhouFormal.ECL.rawCallRetStep",
        "mutation_family": "callret-symbolic-step",
        "state_assumption": (
            "Only top-level RET underflow and negative/positive subTable lookup "
            "paths are plausible one-instruction retail probes. Stack-full and "
            "TH08 child-context paths need a composed state setup."
        ),
    },
}


def _utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def _family_config(family: str) -> dict[str, str]:
    config = FAMILY_CONFIGS.get(family)
    if config is None:
        raise ValueError(f"unsupported ECL symex family: {family}")
    return config


def _default_artifact_dir(title: str, family: str, symex_path: str) -> Path:
    safe = "".join(char if char.isalnum() or char in "-_" else "-" for char in symex_path)
    label = _family_config(family)["artifact_label"]
    return DEFAULT_RETAIL_ROOT / f"formal-{title}-{label}-{safe}-{_utc_stamp()}"


def _run_symex_materializer(
    title: str,
    family: str,
    path_name: str,
    active_mask: int,
    override_mask: int,
    callret_constraints: dict[str, Any],
) -> dict[str, Any]:
    if callret_constraints:
        if family != "callret":
            raise RuntimeError("forced SMT constraints are currently supported only for --family callret")
        return _run_constrained_callret_materializer(
            title,
            path_name,
            active_mask,
            override_mask,
            callret_constraints,
        )

    config = _family_config(family)
    command = [
        sys.executable,
        str(FORMAL_ROOT / "scripts" / config["materializer"]),
        title,
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
        raise RuntimeError("symex materializer must be called with one concrete path")
    if record.get("status") != "sat":
        raise RuntimeError(f"symex path is not satisfiable: {record.get('status')}")
    fixture = record.get("fixture")
    if not isinstance(fixture, dict) or fixture.get("matchesPath") != "true":
        raise RuntimeError(f"symex fixture did not replay into the requested path: {fixture!r}")
    if "hex" not in fixture:
        raise RuntimeError(f"symex fixture has no hex payload: {fixture!r}")
    return record


def _checked_stdout(argv: list[str], *, input_text: str | None = None) -> str:
    completed = subprocess.run(
        argv,
        cwd=FORMAL_ROOT,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(f"{' '.join(argv)} failed: {detail}")
    return completed.stdout


def _format_smt_value(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    return str(value)


def _with_extra_constraints(query: str, constraints: dict[str, Any]) -> str:
    marker = "(check-sat)"
    if marker not in query:
        raise RuntimeError("callret SMT query has no check-sat marker")
    assertion = "".join(
        f"(assert (= {name} {_format_smt_value(value)}))\n"
        for name, value in sorted(constraints.items())
    )
    return query.replace(marker, assertion + marker, 1)


def _materialize_callret(title: str, path_name: str, values: dict[str, Any]) -> dict[str, str]:
    missing = [field for field in CALLRET_WITNESS_FIELDS if field not in values]
    if missing:
        raise RuntimeError(f"Z3 callret witness missing fields: {', '.join(missing)}")
    text = _checked_stdout([
        "lake",
        "exe",
        "symex",
        "materialize-callret",
        title,
        path_name,
        *[callret_cli_value(values[field]) for field in CALLRET_WITNESS_FIELDS],
    ])
    result: dict[str, str] = {}
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        result[key] = value
    if result.get("matchesPath") != "true":
        raise RuntimeError(f"materialized CALL/RET witness did not replay into requested path: {result}")
    return result


def _run_constrained_callret_materializer(
    title: str,
    path_name: str,
    active_mask: int,
    override_mask: int,
    constraints: dict[str, Any],
) -> dict[str, Any]:
    query = _checked_stdout([
        "lake",
        "exe",
        "symex",
        "query-callret-values",
        title,
        path_name,
        str(active_mask),
        str(override_mask),
    ])
    constrained_query = _with_extra_constraints(query, constraints)
    z3 = subprocess.run(
        ["z3", "-in"],
        cwd=FORMAL_ROOT,
        input=constrained_query,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if z3.returncode != 0:
        detail = z3.stderr.strip() or z3.stdout.strip()
        raise RuntimeError(f"z3 failed: {detail}")
    z3_result = parse_get_value(z3.stdout)
    record: dict[str, Any] = {
        "title": title,
        "path": path_name,
        "activeMask": active_mask,
        "overrideMask": override_mask,
        "status": z3_result.status,
        "extraConstraints": constraints,
    }
    if z3_result.status != "sat":
        raise RuntimeError(f"constrained callret path is not satisfiable: {z3_result.status}")
    record["witness"] = z3_result.values
    record["fixture"] = _materialize_callret(title, path_name, z3_result.values)
    return record


def _copy_game_tree(source_game_dir: Path, destination_game_dir: Path) -> None:
    if destination_game_dir.exists():
        raise FileExistsError(f"destination game directory already exists: {destination_game_dir}")
    shutil.copytree(source_game_dir, destination_game_dir)


def build_case(args: argparse.Namespace, artifact_dir: Path) -> Path:
    source_game_dir = args.source_game_dir.resolve()
    source_archive_path = source_game_dir / ARCHIVE_NAMES[args.title]
    if not source_archive_path.is_file():
        raise FileNotFoundError(f"missing source archive: {source_archive_path}")

    symex_record = _run_symex_materializer(
        args.title,
        args.family,
        args.symex_path,
        args.active_mask,
        args.override_mask,
        args.callret_constraints,
    )
    fixture = symex_record["fixture"]
    fixture_hex = str(fixture["hex"])
    replacement = bytes.fromhex(fixture_hex)
    requested_replacement_size = (
        args.force_next_offset
        if args.force_next_offset is not None and args.force_next_offset > len(replacement)
        else len(replacement)
    )

    archive = RetailArchive.from_path(source_archive_path)
    entry_name = _find_archive_entry(archive, args.seed_name)
    source_payload = archive.extract(entry_name)
    plain_payload, crypt_key = (
        th08_try_decrypt_blob(source_payload) if args.title == "th08" else (source_payload, None)
    )
    ecl = EclWireFile(args.title, plain_payload)
    timeline_site = None
    if args.sub_index is None and args.instruction_index is None and args.site_selection == "reachable-timeline-spawn":
        selected = ecl.timeline_spawn_patch_site(
            requested_replacement_size,
            active_mask=args.active_mask,
        )
        site = selected.raw_site
        timeline_site = selected.timeline_site
    else:
        site = ecl.select_patch_site(
            requested_replacement_size,
            sub_index=args.sub_index,
            instruction_index=args.instruction_index,
        )
    if len(replacement) < site.size and args.force_next_offset == site.size:
        replacement = replacement + b"\0" * (site.size - len(replacement))
    if len(replacement) != site.size:
        raise RuntimeError(
            f"materialized fixture has {len(replacement)} bytes but selected site has {site.size}"
        )

    plain_mutant_payload = ecl.patch_raw_instruction(site, replacement)
    payload = (
        th08_encrypt_blob(plain_mutant_payload, crypt_key)
        if crypt_key is not None
        else plain_mutant_payload
    )
    config = _family_config(args.family)

    source_result_dir = artifact_dir / "source-result"
    override_data_dir = source_result_dir / "override" / "data"
    override_data_dir.mkdir(parents=True, exist_ok=True)
    payload_path = override_data_dir / entry_name
    payload_path.write_bytes(payload)

    result = {
        "schema": config["schema"],
        "formal_result_id": f"{args.title.upper()}-{config['formal_id_tag']}-{args.symex_path.upper()}",
        "lean_model": config["lean_model"],
        "symex_command": [
            f"scripts/{config['materializer']}",
            args.title,
            args.symex_path,
            str(args.active_mask),
            str(args.override_mask),
        ],
        "case_name": f"formal-{args.title}-{config['artifact_label']}-{args.symex_path}",
        "mutant_name": (
            f"{config['artifact_label']}-{args.symex_path}-"
            f"s{site.sub_index:02d}-i{site.instruction_index:04d}"
        ),
        "source_game_dir": str(source_game_dir),
        "source_archive": str(source_archive_path),
        "source_archive_sha256": sha256_bytes(source_archive_path.read_bytes()),
        "source_payload_sha256": sha256_bytes(source_payload),
        "source_plain_payload_sha256": sha256_bytes(plain_payload),
        "seed_name": entry_name,
        "override_dir": str((source_result_dir / "override").resolve()),
        "payload_sha256": sha256_bytes(payload),
        "symex": symex_record,
        "mutation_metadata": {
            "family": config["mutation_family"],
            "symex_family": args.family,
            "symex_path": args.symex_path,
            "active_mask": args.active_mask,
            "override_mask": args.override_mask,
            "state_assumption": config["state_assumption"],
            "site_selection": args.site_selection,
            "fixture_hex": fixture_hex,
            "fixture_size": len(bytes.fromhex(fixture_hex)),
            "patched_instruction_hex": replacement.hex(),
            "patched_instruction_size": len(replacement),
            "forced_next_offset": args.force_next_offset,
            "th08_crypt_key_index": crypt_key,
            "timeline_spawn_source": (
                {
                    "timeline_index": timeline_site.timeline_index,
                    "instruction_index": timeline_site.instruction_index,
                    "file_offset": timeline_site.file_offset,
                    "time": timeline_site.time,
                    "opcode": timeline_site.opcode,
                    "size": timeline_site.size,
                    "first_arg_sub_index": timeline_site.first_arg,
                    "difficulty_mask": timeline_site.difficulty_mask,
                }
                if timeline_site is not None
                else None
            ),
            "site_key": f"sub:{site.sub_index:04d}:instr:{site.instruction_index:04d}",
            "old_instruction": {
                "file_offset": site.file_offset,
                "time": site.time,
                "opcode": site.opcode,
                "size": site.size,
                "difficulty_mask": site.difficulty_mask,
                "operand_mask": site.operand_mask,
                "hex": plain_payload[site.file_offset:site.file_offset + site.size].hex(),
            },
            "new_instruction": {
                "file_offset": site.file_offset,
                "hex": replacement.hex(),
            },
        },
        "sites": [
            {
                "site_kind": "raw-sub-instruction",
                "sub_index": site.sub_index,
                "instruction_index": site.instruction_index,
                "file_offset": site.file_offset,
            }
        ],
        "limitations": [
            "This preserves the original ECL layout and patches one equal-sized raw instruction.",
            "Default site selection uses source-backed timeline spawn opcodes, not dynamic trace coverage.",
            "Retail execution is a black-box Wine probe for TH07/TH08.",
            config["state_assumption"],
        ],
    }
    result_path = source_result_dir / "result.json"
    result_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return result_path


def patch_game_archive(args: argparse.Namespace, result_path: Path, artifact_dir: Path) -> dict[str, object]:
    result = json.loads(result_path.read_text(encoding="utf-8"))
    game_dir = artifact_dir / "game"
    _copy_game_tree(args.source_game_dir.resolve(), game_dir)
    payload_path = Path(result["override_dir"]) / "data" / result["seed_name"]
    patch_report = replace_archive_entry(
        game_dir / ARCHIVE_NAMES[args.title],
        str(result["seed_name"]),
        payload_path.read_bytes(),
    )
    patch_report_path = artifact_dir / "patched-archive.json"
    patch_report_path.write_text(json.dumps(patch_report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return {
        "game_dir": str(game_dir.resolve()),
        "patched_archive": patch_report,
    }


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Lower a generic ECL symbolic witness into a TH07/TH08 retail DAT mutation."
    )
    parser.add_argument("title", choices=("th07", "th08"))
    parser.add_argument("--family", choices=tuple(FAMILY_CONFIGS), required=True)
    parser.add_argument("--source-game-dir", type=Path)
    parser.add_argument("--artifact-dir", type=Path)
    parser.add_argument("--symex-path")
    parser.add_argument("--active-mask", type=int, default=DEFAULT_ACTIVE_MASK)
    parser.add_argument("--override-mask", type=int, default=DEFAULT_OVERRIDE_MASK)
    parser.add_argument(
        "--force-next-offset",
        type=int,
        help="add nextOffset == N to the SMT query before materializing a CALL/RET witness",
    )
    parser.add_argument(
        "--force-sub-id",
        type=int,
        help="add subId == N to the SMT query before materializing a CALL/RET witness",
    )
    parser.add_argument(
        "--force-sub-count",
        type=int,
        help="add subCount == N to the SMT query before materializing a CALL/RET witness",
    )
    parser.add_argument(
        "--force-stack-depth",
        type=int,
        help="add stackDepth == N to the SMT query before materializing a CALL/RET witness",
    )
    parser.add_argument(
        "--force-child-context-slot",
        type=int,
        help="add childContextSlot == N to the SMT query before materializing a CALL/RET witness",
    )
    parser.add_argument(
        "--force-stack-disabled",
        action=argparse.BooleanOptionalAction,
        default=None,
        help="add stackDisabled == true/false to the SMT query before materializing a CALL/RET witness",
    )
    parser.add_argument("--seed-name", default="ecldata1.ecl")
    parser.add_argument("--sub-index", type=int)
    parser.add_argument("--instruction-index", type=int)
    parser.add_argument(
        "--site-selection",
        choices=("reachable-timeline-spawn", "sub-first", "any-first"),
        default="reachable-timeline-spawn",
    )
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--run-wine", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--startup-seconds", type=float, default=10.0)
    parser.add_argument("--window-settle-seconds", type=float, default=5.0)
    parser.add_argument("--post-input-wait-seconds", type=float, default=12.0)
    parser.add_argument("--key-hold-seconds", type=float, default=0.03)
    parser.add_argument("--key-settle-seconds", type=float, default=0.35)
    parser.add_argument("--xvfb-screen-size", default=DEFAULT_SCREEN_SIZE)
    parser.add_argument("--cfg-windowed", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument(
        "--cfg-color-mode",
        choices=("32bit", "16bit", "preserve"),
        default="32bit",
    )
    parser.add_argument("--cfg-safe-video-flags", action="store_true")
    parser.add_argument(
        "--keys",
        nargs="+",
        default=["z", "z", "Down", "Down", "Down", "z", "z", "z", "z", "z", "z"],
    )
    args = parser.parse_args(argv)
    config = _family_config(args.family)
    if args.symex_path is None:
        args.symex_path = str(config["default_symex_path"])
    if args.source_game_dir is None:
        args.source_game_dir = DEFAULT_SOURCE_GAME_DIRS[args.title]
    if args.artifact_dir is None:
        args.artifact_dir = _default_artifact_dir(args.title, args.family, args.symex_path)
    if args.active_mask < 0 or args.active_mask > 255:
        raise ValueError("--active-mask must fit in a byte")
    if args.override_mask < 0 or args.override_mask > 255:
        raise ValueError("--override-mask must fit in a byte")
    for name in ("force_next_offset", "force_sub_id", "force_sub_count", "force_stack_depth", "force_child_context_slot"):
        value = getattr(args, name)
        if value is not None and value < -32768:
            raise ValueError(f"--{name.replace('_', '-')} is too small")
    args.callret_constraints = {
        name: value
        for name, value in {
            "nextOffset": args.force_next_offset,
            "subId": args.force_sub_id,
            "subCount": args.force_sub_count,
            "stackDepth": args.force_stack_depth,
            "childContextSlot": args.force_child_context_slot,
            "stackDisabled": args.force_stack_disabled,
        }.items()
        if value is not None
    }
    if args.site_selection == "any-first" and args.sub_index is None:
        args.sub_index = -1
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    artifact_dir = args.artifact_dir.resolve()
    if (artifact_dir / "game").exists() or (artifact_dir / "source-result").exists():
        raise FileExistsError(f"artifact directory already contains a prepared case: {artifact_dir}")
    artifact_dir.mkdir(parents=True, exist_ok=True)
    result_path = build_case(args, artifact_dir)
    patch_report = patch_game_archive(args, result_path, artifact_dir)
    cfg_report = prepare_retail_cfg(args, Path(patch_report["game_dir"]))
    report: dict[str, object] = {
        "artifact_dir": str(artifact_dir),
        "source_result": str(result_path.resolve()),
        "patched": patch_report,
        "cfg": cfg_report,
        "prepare_only": args.prepare_only,
    }
    if not args.prepare_only and args.run_wine:
        report["wine_probe"] = run_wine_probe(args, Path(patch_report["game_dir"]), artifact_dir)
    (artifact_dir / "report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
