#!/usr/bin/env python3
"""Evaluate the current Lean + SMT symbolic-execution baseline.

The report is intentionally about the implemented model, not about an imagined
full ECL VM.  It reruns the profile-driven raw-step candidate queue, summarizes
which modeled path classes are covered, records source-level opcode surface that
is still outside the current semantics, and folds in retained retail validation
evidence when those artifacts are present beside the repository.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REFERENCE_ROOT = REPO_ROOT.parent / "reference"
DEFAULT_RETAIL_ROOT = REPO_ROOT.parent / "retail_validation"

MODELED_RAW_STEP_PATHS = [
    "yielded",
    "skipped-before-buffer",
    "skipped-non-progress",
    "skipped-in-bounds",
    "skipped-at-or-past-end",
    "advanced-before-buffer",
    "advanced-non-progress",
    "advanced-in-bounds",
    "advanced-at-or-past-end",
    "jumped-before-buffer",
    "jumped-non-progress",
    "jumped-in-bounds",
    "jumped-at-or-past-end",
    "vm-error",
]

MODELED_RAW_BODY_PATHS = [
    "decjump-taken-before-buffer",
    "decjump-taken-non-progress",
    "decjump-taken-in-bounds",
    "decjump-taken-at-or-past-end",
    "decjump-not-taken-before-buffer",
    "decjump-not-taken-non-progress",
    "decjump-not-taken-in-bounds",
    "decjump-not-taken-at-or-past-end",
    "int-divisor-zero",
]

SOURCE_COVERAGE = [
    {
        "area": "ECL loader/header shape",
        "status": "covered-by-model",
        "reason": "shared HeaderShape drives TH06/TH07/TH08 header counts, timeline slots, sub offsets, and first missing-byte faults",
    },
    {
        "area": "CallEclSub lookup policy",
        "status": "covered-by-model",
        "reason": "negative-sub-id policy is title-profiled; positive out-of-bounds lookup is covered across titles",
    },
    {
        "area": "timeline prefix cursor movement",
        "status": "covered-by-model",
        "reason": "timeline size width is profile-derived and checked for before-buffer, non-progress, in-bounds, and at/past-end transfers",
    },
    {
        "area": "raw ECL dispatch skeleton",
        "status": "covered-by-symbolic-execution",
        "reason": "time gate, difficulty skip, ordinary advance, fixed jump, VM error, and cursor classes are enumerated by SMT path constraints",
    },
    {
        "area": "JUMPDEC body semantics",
        "status": "covered-by-symbolic-execution",
        "reason": "shared profile records opcode, target-time slot, displacement slot, and counter slot; SMT enumerates taken/not-taken cursor classes",
    },
    {
        "area": "integer div/mod immediate divisor hazards",
        "status": "covered-by-symbolic-execution",
        "reason": "shared profile records source-backed integer div/mod opcodes and divisor operand slots; SMT finds zero-divisor body faults",
    },
    {
        "area": "raw ECL difficulty mask policy",
        "status": "covered-by-model",
        "reason": "TH06/TH07 active-bit intersection and TH08 contains(active|override) are separate profile policies",
    },
    {
        "area": "ANM entry header/nextOffset profile",
        "status": "partially-covered",
        "reason": "entry table shape and nextOffset chain headers are modeled, but ANM opcode execution and resource side effects are not",
    },
    {
        "area": "full raw ECL opcode bodies",
        "status": "partially-covered",
        "reason": "UNIMP, fixed JUMP, JUMPDEC, and integer div/mod divisor hazards are modeled; other opcode bodies still collapse to prefix-level ordinary advance",
    },
    {
        "area": "operandFlags / variable lvalue-rvalue resolution",
        "status": "not-yet-modeled",
        "reason": "TH07/TH08 operand masks branch into local/global/enemy/player/RNG state; those host-state cells are not yet in the symbolic state",
    },
    {
        "area": "conditional jumps, CALL/RET, callback stack",
        "status": "not-yet-modeled",
        "reason": "needs multi-step ECL context state, stack depth, time updates, comparison flags, and target subroutine bounds",
    },
    {
        "area": "remaining arithmetic body faults",
        "status": "not-yet-modeled",
        "reason": "immediate integer div/mod zero is modeled; resolver-driven divisors, float divide/fmod zero, overflow, and numeric non-finite behavior still require operand resolution plus C/C++-faithful arithmetic semantics",
    },
    {
        "area": "bullet/laser/enemy/ANM/sound host side effects",
        "status": "not-yet-modeled",
        "reason": "requires game-state object models and invariants beyond a single raw instruction cursor transfer",
    },
    {
        "area": "integrated multi-context scheduler",
        "status": "not-yet-modeled",
        "reason": "timeline spawning, enemy contexts, time progression, and inter-resource callbacks are outside the one-step raw dispatch baseline",
    },
]


class EvaluationError(RuntimeError):
    pass


def run_command(argv: list[str], *, input_text: str | None = None) -> tuple[subprocess.CompletedProcess[str], float]:
    started = time.perf_counter()
    proc = subprocess.run(
        argv,
        cwd=REPO_ROOT,
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    elapsed = time.perf_counter() - started
    return proc, elapsed


def run_json_command(argv: list[str]) -> tuple[Any, dict[str, Any]]:
    proc, elapsed = run_command(argv)
    if proc.returncode != 0:
        detail = proc.stderr.strip() or proc.stdout.strip()
        raise EvaluationError(f"{' '.join(argv)} failed with exit {proc.returncode}: {detail}")
    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise EvaluationError(f"{' '.join(argv)} did not return JSON: {exc}") from exc
    return payload, {
        "argv": argv,
        "returncode": proc.returncode,
        "elapsedSeconds": round(elapsed, 3),
    }


def run_check_script() -> dict[str, Any]:
    proc, elapsed = run_command(["./scripts/check.sh"])
    report = {
        "argv": ["./scripts/check.sh"],
        "returncode": proc.returncode,
        "elapsedSeconds": round(elapsed, 3),
        "stdoutLineCount": len(proc.stdout.splitlines()),
        "stderrLineCount": len(proc.stderr.splitlines()),
    }
    if proc.returncode != 0:
        report["stdoutTail"] = proc.stdout.splitlines()[-40:]
        report["stderrTail"] = proc.stderr.splitlines()[-40:]
        raise EvaluationError(json.dumps(report, indent=2, sort_keys=True))
    return report


def load_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.queue_json:
        path = Path(args.queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_candidate_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("candidate queue did not return an object")
    return payload, command


def load_body_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.body_queue_json:
        path = Path(args.body_queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_body_candidate_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("body candidate queue did not return an object")
    return payload, command


def action_from_path(path: str) -> str:
    if path == "yielded":
        return "yielded"
    if path == "vm-error":
        return "vm-error"
    return path.split("-", 1)[0]


def body_action_from_path(path: str) -> str:
    if path == "int-divisor-zero":
        return "int-divisor-zero"
    if path.startswith("decjump-taken-"):
        return "decjump-taken"
    if path.startswith("decjump-not-taken-"):
        return "decjump-not-taken"
    return path


def cursor_goal_from_path(path: str) -> str:
    if path in {"yielded", "vm-error"}:
        return "-"
    return path.split("-", 1)[1]


def body_cursor_goal_from_path(path: str) -> str:
    if path == "int-divisor-zero":
        return "-"
    if path.startswith("decjump-taken-"):
        return path.removeprefix("decjump-taken-")
    if path.startswith("decjump-not-taken-"):
        return path.removeprefix("decjump-not-taken-")
    return "-"


def summarize_queue(queue: dict[str, Any]) -> dict[str, Any]:
    candidates = queue.get("candidates", [])
    if not isinstance(candidates, list):
        raise EvaluationError("candidate queue has no candidate list")

    statuses = Counter(str(candidate.get("status")) for candidate in candidates)
    risks = Counter(str(candidate.get("risk", {}).get("class")) for candidate in candidates)
    priorities = Counter(str(candidate.get("risk", {}).get("priority")) for candidate in candidates)
    actions = Counter(action_from_path(str(candidate.get("path"))) for candidate in candidates)
    fixture_actions = Counter(str(candidate.get("fixture", {}).get("action")) for candidate in candidates)
    cursor_goals = Counter(cursor_goal_from_path(str(candidate.get("path"))) for candidate in candidates)
    cursor_classes = Counter(str(candidate.get("fixture", {}).get("cursorClass", "-")) for candidate in candidates)
    matches = Counter(str(candidate.get("fixture", {}).get("matchesPath")) for candidate in candidates)

    by_environment: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = (
            f"{candidate.get('title')}:{candidate.get('environment')}:"
            f"active={candidate.get('activeMask')}:override={candidate.get('overrideMask')}"
        )
        by_environment[key].append(candidate)

    expected_paths = set(MODELED_RAW_STEP_PATHS)
    env_reports = {}
    for env, env_candidates in sorted(by_environment.items()):
        paths = {str(candidate.get("path")) for candidate in env_candidates}
        env_reports[env] = {
            "pathCount": len(paths),
            "candidateCount": len(env_candidates),
            "satCount": sum(1 for candidate in env_candidates if candidate.get("status") == "sat"),
            "matchesPathCount": sum(
                1 for candidate in env_candidates
                if candidate.get("fixture", {}).get("matchesPath") == "true"
            ),
            "missingModeledPaths": sorted(expected_paths - paths),
            "extraPaths": sorted(paths - expected_paths),
        }

    top_candidates = [
        {
            "id": candidate.get("id"),
            "risk": candidate.get("risk", {}).get("class"),
            "priority": candidate.get("risk", {}).get("priority"),
            "hex": candidate.get("fixture", {}).get("hex"),
            "rawInstructionHex": candidate.get("fixture", {}).get("rawInstructionHex"),
            "action": candidate.get("fixture", {}).get("action"),
            "cursorClass": candidate.get("fixture", {}).get("cursorClass"),
        }
        for candidate in candidates[:10]
    ]

    return {
        "schema": queue.get("schema"),
        "environmentCount": queue.get("environmentCount"),
        "candidateCount": queue.get("candidateCount"),
        "uniquePathCount": len({str(candidate.get("path")) for candidate in candidates}),
        "modeledPathCount": len(MODELED_RAW_STEP_PATHS),
        "modeledPaths": MODELED_RAW_STEP_PATHS,
        "statuses": dict(statuses),
        "matchesPath": dict(matches),
        "riskCounts": dict(risks),
        "priorityCounts": dict(priorities),
        "pathActionCounts": dict(actions),
        "fixtureActionCounts": dict(fixture_actions),
        "cursorGoalCounts": dict(cursor_goals),
        "fixtureCursorClassCounts": dict(cursor_classes),
        "allModeledPathsCoveredPerEnvironment": all(
            not report["missingModeledPaths"] and not report["extraPaths"]
            for report in env_reports.values()
        ),
        "allSat": statuses == Counter({"sat": len(candidates)}),
        "allMaterializedAndReplayMatched": matches == Counter({"true": len(candidates)}),
        "byEnvironment": env_reports,
        "topCandidates": top_candidates,
    }


def summarize_body_queue(queue: dict[str, Any]) -> dict[str, Any]:
    candidates = queue.get("candidates", [])
    if not isinstance(candidates, list):
        raise EvaluationError("body candidate queue has no candidate list")

    statuses = Counter(str(candidate.get("status")) for candidate in candidates)
    risks = Counter(str(candidate.get("risk", {}).get("class")) for candidate in candidates)
    priorities = Counter(str(candidate.get("risk", {}).get("priority")) for candidate in candidates)
    actions = Counter(body_action_from_path(str(candidate.get("path"))) for candidate in candidates)
    fixture_actions = Counter(str(candidate.get("fixture", {}).get("action")) for candidate in candidates)
    cursor_goals = Counter(body_cursor_goal_from_path(str(candidate.get("path"))) for candidate in candidates)
    cursor_classes = Counter(str(candidate.get("fixture", {}).get("cursorClass", "-")) for candidate in candidates)
    fault_kinds = Counter(str(candidate.get("fixture", {}).get("faultKind", "-")) for candidate in candidates)
    matches = Counter(str(candidate.get("fixture", {}).get("matchesPath")) for candidate in candidates)

    by_environment: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = (
            f"{candidate.get('title')}:{candidate.get('environment')}:"
            f"active={candidate.get('activeMask')}:override={candidate.get('overrideMask')}"
        )
        by_environment[key].append(candidate)

    expected_paths = set(MODELED_RAW_BODY_PATHS)
    env_reports = {}
    for env, env_candidates in sorted(by_environment.items()):
        paths = {str(candidate.get("path")) for candidate in env_candidates}
        env_reports[env] = {
            "pathCount": len(paths),
            "candidateCount": len(env_candidates),
            "satCount": sum(1 for candidate in env_candidates if candidate.get("status") == "sat"),
            "matchesPathCount": sum(
                1 for candidate in env_candidates
                if candidate.get("fixture", {}).get("matchesPath") == "true"
            ),
            "missingModeledPaths": sorted(expected_paths - paths),
            "extraPaths": sorted(paths - expected_paths),
        }

    top_candidates = [
        {
            "id": candidate.get("id"),
            "risk": candidate.get("risk", {}).get("class"),
            "priority": candidate.get("risk", {}).get("priority"),
            "hex": candidate.get("fixture", {}).get("hex"),
            "action": candidate.get("fixture", {}).get("action"),
            "cursorClass": candidate.get("fixture", {}).get("cursorClass"),
            "faultKind": candidate.get("fixture", {}).get("faultKind"),
            "faultDetail": candidate.get("fixture", {}).get("faultDetail"),
        }
        for candidate in candidates[:10]
    ]

    return {
        "schema": queue.get("schema"),
        "environmentCount": queue.get("environmentCount"),
        "candidateCount": queue.get("candidateCount"),
        "uniquePathCount": len({str(candidate.get("path")) for candidate in candidates}),
        "modeledPathCount": len(MODELED_RAW_BODY_PATHS),
        "modeledPaths": MODELED_RAW_BODY_PATHS,
        "statuses": dict(statuses),
        "matchesPath": dict(matches),
        "riskCounts": dict(risks),
        "priorityCounts": dict(priorities),
        "pathActionCounts": dict(actions),
        "fixtureActionCounts": dict(fixture_actions),
        "cursorGoalCounts": dict(cursor_goals),
        "fixtureCursorClassCounts": dict(cursor_classes),
        "faultKindCounts": dict(fault_kinds),
        "allModeledPathsCoveredPerEnvironment": all(
            not report["missingModeledPaths"] and not report["extraPaths"]
            for report in env_reports.values()
        ),
        "allSat": statuses == Counter({"sat": len(candidates)}),
        "allMaterializedAndReplayMatched": matches == Counter({"true": len(candidates)}),
        "byEnvironment": env_reports,
        "topCandidates": top_candidates,
    }


def unique_preserving(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result = []
    for value in values:
        if value not in seen:
            seen.add(value)
            result.append(value)
    return result


def source_opcode_surface(reference_root: Path) -> dict[str, Any]:
    report: dict[str, Any] = {
        "referenceRoot": str(reference_root),
        "available": reference_root.exists(),
        "titles": {},
    }
    if not reference_root.exists():
        return report

    th06 = reference_root / "th06" / "src" / "EclManager.hpp"
    th07 = reference_root / "th07" / "src" / "th07" / "EclManager.hpp"
    th08_low = reference_root / "th08" / "src" / "EclRunLow.inl"
    th08_run = reference_root / "th08" / "src" / "EclRun.cpp"

    if th06.exists():
        text = th06.read_text(errors="ignore")
        names: list[str] = []
        if "enum EclRawInstrOpcode" in text:
            block = text.split("enum EclRawInstrOpcode", 1)[1].split("};", 1)[0]
            names = unique_preserving(re.findall(r"\b(ECL_OPCODE_[A-Z0-9_]+)\b", block))
        report["titles"]["th06"] = {
            "source": str(th06),
            "rawOpcodeSymbolCount": len(names),
            "modeledOpcodeSpecificSymbols": [
                "ECL_OPCODE_UNIMP",
                "ECL_OPCODE_JUMP",
                "ECL_OPCODE_JUMPDEC",
                "ECL_OPCODE_MATHINTDIV",
                "ECL_OPCODE_MATHINTMOD",
            ],
            "notYetOpcodeBodyModeledCountLowerBound": max(0, len(names) - 5),
            "firstSymbols": names[:8],
            "lastSymbols": names[-8:],
        }

    if th07.exists():
        text = th07.read_text(errors="ignore")
        start = text.find("ECL_UNIMP")
        end = text.find("ECL_FREEZE_ECL_DURING_BOMB")
        names: list[str] = []
        if start != -1 and end != -1:
            block = text[start:end + len("ECL_FREEZE_ECL_DURING_BOMB")]
            names = unique_preserving(re.findall(r"\b(ECL_[A-Z0-9_]+)\b", block))
        report["titles"]["th07"] = {
            "source": str(th07),
            "rawOpcodeSymbolCountApprox": len(names),
            "modeledOpcodeSpecificSymbols": [
                "ECL_UNIMP",
                "ECL_JUMP",
                "ECL_DEC_JUMP",
                "ECL_DIV",
                "ECL_MOD",
            ],
            "notYetOpcodeBodyModeledCountLowerBound": max(0, len(names) - 5),
            "firstSymbols": names[:8],
            "lastSymbols": names[-8:],
        }

    if th08_low.exists():
        low_text = th08_low.read_text(errors="ignore")
        case_labels = unique_preserving(re.findall(r"\bcase\s+([0-9]+)\s*:", low_text))
        report["titles"]["th08"] = {
            "source": str(th08_low),
            "runSource": str(th08_run) if th08_run.exists() else None,
            "lowOpcodeCaseLabelCount": len(case_labels),
            "modeledOpcodeSpecificCases": [
                "case 1",
                "case 4",
                "case 5",
                "case 13",
                "case 14",
                "case 23",
                "case 24",
            ],
            "notYetOpcodeBodyModeledCountLowerBound": max(0, len(case_labels) - 7),
            "firstCaseLabels": case_labels[:12],
            "lastCaseLabels": case_labels[-12:],
        }

    return report


def danmakufuzz_baseline(reference_root: Path) -> dict[str, Any]:
    manifest = reference_root / "DanmakuFuzz" / "findings" / "by-status" / "manifest.json"
    data = load_json_if_exists(manifest)
    if data is None:
        return {
            "available": False,
            "manifest": str(manifest),
        }

    entries = data.get("entries", [])
    if not isinstance(entries, list):
        entries = []
    statuses = Counter(str(entry.get("status")) for entry in entries)
    confirmed = [
        {
            "title": entry.get("title"),
            "scope": entry.get("scope"),
            "expectedOracle": entry.get("expected_oracle"),
            "notes": entry.get("notes"),
        }
        for entry in entries
        if entry.get("status") == "confirmed-retail"
    ]
    return {
        "available": True,
        "manifest": str(manifest),
        "updated": data.get("updated"),
        "entryCount": len(entries),
        "statusCounts": dict(statuses),
        "confirmedRetailCount": len(confirmed),
        "confirmedRetail": confirmed,
        "defaultPolicy": data.get("default_policy", []),
    }


def load_json_if_exists(path: Path) -> Any | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return None


def summarize_retail_report(name: str, path: Path) -> dict[str, Any]:
    data = load_json_if_exists(path)
    if data is None:
        return {"name": name, "path": str(path), "available": False}

    summary: dict[str, Any] = {"name": name, "path": str(path), "available": True}
    if data.get("schema") == "danmakufuzz-retail-confirmation-repeat-v1":
        attempts = data.get("attempts", [])
        summary.update(
            {
                "schema": data.get("schema"),
                "expectationPassed": data.get("expectation_passed"),
                "passedAttempts": data.get("passed_attempts"),
                "requiredAttempts": data.get("require"),
                "classifications": sorted({
                    str(attempt.get("classification"))
                    for attempt in attempts
                    if attempt.get("classification") is not None
                }),
                "retailSignatureKeys": sorted({
                    str(attempt.get("retail_signature_key"))
                    for attempt in attempts
                    if attempt.get("retail_signature_key") is not None
                }),
            }
        )
        return summary

    run = data.get("run", {})
    oracle = run.get("oracle", {})
    baseline = oracle.get("baseline_comparison", {})
    patched = data.get("patched_archives", [])
    summary.update(
        {
            "schema": data.get("schema", "single-retail-report"),
            "classification": oracle.get("classification") or run.get("termination_reason"),
            "retailSignatureKey": oracle.get("wine_log_normalized_primary_signature") or run.get("retail_signature_key"),
            "payloadSha256": data.get("payload_sha256"),
            "patchedArchiveSha256": patched[0].get("sha256") if patched else None,
            "baselineTerminationReason": baseline.get("baseline_termination_reason"),
            "mutantTerminationReason": baseline.get("mutant_termination_reason") or run.get("termination_reason"),
        }
    )
    return summary


def retail_confirmations(retail_root: Path) -> list[dict[str, Any]]:
    return [
        summarize_retail_report(
            "TH06 raw symex jumped-before-buffer",
            retail_root / "formal-th06-raw-symex-jumped-before-buffer-20260831T111946Z" / "report.json",
        ),
        summarize_retail_report(
            "TH06 timeline arg0=256 subTable counterexample",
            retail_root / "formal-th06-stage5-arg0-256-run3-long-probe" / "report.json",
        ),
    ]


def fuzz_comparison() -> dict[str, Any]:
    return {
        "formalCurrentlyBeatsFuzzFor": [
            "exhaustively enumerating the implemented raw-step path classes instead of waiting for random mutation to hit each class",
            "exhaustively enumerating the implemented JUMPDEC taken/not-taken cursor classes and immediate integer div/mod zero-divisor faults",
            "returning satisfiable/unsatisfiable path facts with concrete byte-realizable witnesses",
            "keeping TH06/TH07/TH08 differences in shared profiles, reducing per-title semantic drift",
            "explaining exact invariants such as cursor must progress and remain in-bounds",
        ],
        "fuzzCurrentlyBeatsFormalFor": [
            "full gameplay side effects through bullets, lasers, enemies, ANM, rendering, input, and callbacks",
            "unknown opcode-body behavior that has not yet been source-modeled",
            "large multi-resource interactions where a retail oracle is easier to observe than to prove",
            "empirical prioritization of which formally reachable witnesses are retail-visible bugs",
        ],
        "currentVerdict": (
            "The current Lean+SMT baseline is stronger than prior fuzzing on the modeled VM-core skeleton, "
            "because all 14 raw-step path classes and all 9 initial body-step path classes are solved and materialized for every default environment. "
            "It is not yet stronger than fuzzing for the full ECL/ANM VM, because most opcode bodies and host-state branches "
            "remain outside the semantics."
        ),
        "nextHighValueFormalWork": [
            "add operand resolver state and symbolic lvalue/rvalue branches",
            "add bounded multi-step raw ECL contexts for JUMPDEC, conditional jumps, CALL, and RET",
            "model integer division/modulo preconditions and prove divide-by-zero reachability or absence",
            "reuse the existing materializer queue to lower top-ranked TH07/TH08 witnesses once retail archive adapters exist",
        ],
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run and summarize the current Lean+SMT symbolic-execution effectiveness baseline."
    )
    parser.add_argument(
        "--queue-json",
        help="reuse an existing symex_candidate_queue.py JSON payload instead of rerunning the solver",
    )
    parser.add_argument(
        "--body-queue-json",
        help="reuse an existing symex_body_candidate_queue.py JSON payload instead of rerunning the body solver",
    )
    parser.add_argument(
        "--run-check",
        action="store_true",
        help="run ./scripts/check.sh before the candidate-queue evaluation",
    )
    parser.add_argument(
        "--reference-root",
        type=Path,
        default=DEFAULT_REFERENCE_ROOT,
        help="path containing th06/th07/th08 and DanmakuFuzz reference clones",
    )
    parser.add_argument(
        "--retail-root",
        type=Path,
        default=DEFAULT_RETAIL_ROOT,
        help="path containing retained retail validation artifacts",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    commands: dict[str, Any] = {}
    if args.run_check:
        commands["check"] = run_check_script()

    queue, command = load_queue(args)
    commands["candidateQueue"] = command
    queue_summary = summarize_queue(queue)
    body_queue, body_command = load_body_queue(args)
    commands["bodyCandidateQueue"] = body_command
    body_queue_summary = summarize_body_queue(body_queue)

    payload = {
        "schema": "touhou-formal-symex-effectiveness-v1",
        "date": "2026-08-31",
        "commands": commands,
        "rawStepSymbolicCoverage": queue_summary,
        "rawBodySymbolicCoverage": body_queue_summary,
        "sourceOpcodeSurface": source_opcode_surface(args.reference_root),
        "sourceCoverage": SOURCE_COVERAGE,
        "retailConfirmations": retail_confirmations(args.retail_root),
        "danmakuFuzzBaseline": danmakufuzz_baseline(args.reference_root),
        "fuzzComparison": fuzz_comparison(),
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except EvaluationError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
