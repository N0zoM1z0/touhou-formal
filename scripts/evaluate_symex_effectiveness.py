#!/usr/bin/env python3
"""Evaluate the current Lean + SMT symbolic-execution baseline.

The report is intentionally about the implemented model, not about an imagined
full ECL VM.  It reruns the established symbolic candidate queues, summarizes
which modeled path classes are covered, derives the modeled opcode set from the
Lean title profiles, records source-level opcode surface that is still outside
the current semantics, and folds in retained retail validation evidence when
those artifacts are present beside the repository.
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
DEFAULT_RETAIL_ROOT = REPO_ROOT / "retail_validation"

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
    "int-condjump-taken-before-buffer",
    "int-condjump-taken-non-progress",
    "int-condjump-taken-in-bounds",
    "int-condjump-taken-at-or-past-end",
    "int-condjump-not-taken-before-buffer",
    "int-condjump-not-taken-non-progress",
    "int-condjump-not-taken-in-bounds",
    "int-condjump-not-taken-at-or-past-end",
    "int-divisor-zero",
]

MODELED_INT_RESOLVER_PATHS_BY_TITLE = {
    "th06": [
        "resolved-host",
        "resolved-default-raw",
    ],
    "th07": [
        "raw-immediate",
        "resolved-host",
        "resolved-default-raw",
    ],
    "th08": [
        "raw-immediate",
        "resolved-host",
        "resolved-default-raw",
    ],
}

MODELED_INT_RESOLVER_PATHS = sorted({
    path
    for paths in MODELED_INT_RESOLVER_PATHS_BY_TITLE.values()
    for path in paths
})

MODELED_INT_BINARY_PATHS_BY_TITLE = {
    "th06": [
        "int-binary-output-resolved-host",
        "int-binary-non-int-output",
        "int-binary-divisor-zero-resolved-host",
        "int-binary-divisor-zero-resolved-default-raw",
        "int-binary-divide-overflow-resolved-host",
        "int-binary-divide-overflow-resolved-default-raw",
    ],
    "th07": [
        "int-binary-output-raw-cell",
        "int-binary-output-resolved-host",
        "int-binary-output-default-raw-cell",
        "int-binary-divisor-zero-raw-immediate",
        "int-binary-divisor-zero-resolved-host",
        "int-binary-divisor-zero-resolved-default-raw",
        "int-binary-divide-overflow-raw-immediate",
        "int-binary-divide-overflow-resolved-host",
        "int-binary-divide-overflow-resolved-default-raw",
    ],
    "th08": [
        "int-binary-output-raw-cell",
        "int-binary-output-resolved-host",
        "int-binary-output-default-raw-cell",
        "int-binary-divisor-zero-raw-immediate",
        "int-binary-divisor-zero-resolved-host",
        "int-binary-divisor-zero-resolved-default-raw",
        "int-binary-divide-overflow-raw-immediate",
        "int-binary-divide-overflow-resolved-host",
        "int-binary-divide-overflow-resolved-default-raw",
    ],
}

MODELED_INT_BINARY_PATHS = sorted({
    path
    for paths in MODELED_INT_BINARY_PATHS_BY_TITLE.values()
    for path in paths
})

MODELED_CALLRET_PATHS_BY_TITLE = {
    "th06": [
        "call-stack-write-before-stack",
        "call-stack-write-at-or-past-stack",
        "call-lookup-fault",
        "call-entered",
        "ret-stack-read-before-stack",
        "ret-stack-read-at-or-past-stack",
        "ret-restored",
    ],
    "th07": [
        "call-stack-write-before-stack",
        "call-stack-write-at-or-past-stack",
        "call-lookup-fault",
        "call-entered",
        "ret-stack-read-before-stack",
        "ret-stack-read-at-or-past-stack",
        "ret-restored",
    ],
    "th08": [
        "call-stack-write-before-stack",
        "call-stack-write-at-or-past-stack",
        "call-lookup-fault",
        "call-entered",
        "call-no-op",
        "ret-stack-read-at-or-past-stack",
        "ret-restored",
        "ret-exit-child",
        "ret-child-index-before-array",
        "ret-child-index-at-or-past-array",
    ],
}

MODELED_CALLRET_PATHS = sorted({
    path
    for paths in MODELED_CALLRET_PATHS_BY_TITLE.values()
    for path in paths
})

MODELED_CONDCALL_PATHS_BY_TITLE = {
    "th06": [
        "condcall-false-before-buffer",
        "condcall-false-non-progress",
        "condcall-false-in-bounds",
        "condcall-false-at-or-past-end",
        "condcall-stack-write-before-stack",
        "condcall-stack-write-at-or-past-stack",
        "condcall-lookup-fault",
        "condcall-entered",
    ],
    "th07": [],
    "th08": [],
}

MODELED_CONDCALL_PATHS = sorted({
    path
    for paths in MODELED_CONDCALL_PATHS_BY_TITLE.values()
    for path in paths
})

MODELED_BOSS_INT_PATHS_BY_TITLE = {
    "th06": [],
    "th07": [
        "boss-int-value-raw-no-boss-read",
        "boss-int-index-before-array",
        "boss-int-index-at-or-past-array",
        "boss-int-null-deref",
        "boss-int-value-resolved-host",
        "boss-int-value-resolved-default-raw",
    ],
    "th08": [
        "boss-int-value-raw-no-boss-read",
        "boss-int-index-before-array",
        "boss-int-index-at-or-past-array",
        "boss-int-null-deref",
        "boss-int-value-resolved-host",
        "boss-int-value-resolved-default-raw",
    ],
}

MODELED_BOSS_INT_PATHS = sorted({
    path
    for paths in MODELED_BOSS_INT_PATHS_BY_TITLE.values()
    for path in paths
})

MODELED_BOSS_FLOAT_PATHS_BY_TITLE = {
    "th06": [],
    "th07": [
        "boss-float-value-raw-no-boss-read",
        "boss-float-index-before-array",
        "boss-float-index-at-or-past-array",
        "boss-float-null-deref",
        "boss-float-value-resolved-host",
        "boss-float-value-resolved-default-raw",
    ],
    "th08": [
        "boss-float-value-raw-no-boss-read",
        "boss-float-index-before-array",
        "boss-float-index-at-or-past-array",
        "boss-float-null-guarded-skip",
        "boss-float-value-resolved-host",
        "boss-float-value-resolved-default-raw",
    ],
}

MODELED_BOSS_FLOAT_PATHS = sorted({
    path
    for paths in MODELED_BOSS_FLOAT_PATHS_BY_TITLE.values()
    for path in paths
})

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
        "reason": "legacy body-slice check still records source-backed integer div/mod opcodes and immediate divisor operand slots; the fuller integer-binary slice supersedes this for resolver-driven arithmetic",
    },
    {
        "area": "integer operandFlags / rvalue resolver",
        "status": "covered-by-symbolic-execution",
        "reason": "shared resolver profile distinguishes TH06 always-resolve from TH07/TH08 bit-set operand masks, known selector ranges, exclusions, and default-to-raw fallthrough",
    },
    {
        "area": "integer lvalue writes and binary arithmetic",
        "status": "covered-by-symbolic-execution",
        "reason": "shared RawIntBinaryOpShape models ADD/SUB/MUL/DIV/MOD, title-specific assign versus in-place operand layouts, output lvalue resolution, RHS resolution, zero divisors, and signed i32 idiv overflow",
    },
    {
        "area": "scalar assignment and integer unary updates",
        "status": "covered-by-model",
        "reason": "shared title profiles model integer/float SET and INC/DEC, including TH06's GetVar-pointer/SetVar behavior and TH07/TH08 operandFlags-controlled lvalues",
    },
    {
        "area": "float arithmetic and scalar float functions",
        "status": "covered-by-model",
        "reason": "shared profiles model float ADD/SUB/MUL/DIV/MOD plus title-specific SIN/COS/ATAN2 or VectorAngle and angle normalization operand layouts; host float result bits remain explicit inputs",
    },
    {
        "area": "random scalar generation",
        "status": "covered-by-model",
        "reason": "shared profiles model TH06 range generators, TH07 range/add/sign generators, and TH08 sign generators with explicit RNG words and the TH06 SetVar re-resolution quirk",
    },
    {
        "area": "boss-indexed integer reads",
        "status": "covered-by-symbolic-execution",
        "reason": "shared RawBossIntReadShape models TH07 ECL_GET_BOSS_INT and TH08 low opcode 86, including value operand flag bypass, boss index resolution, bosses[8] bounds, null boss pointers, and host/default value resolution",
    },
    {
        "area": "boss-indexed float reads",
        "status": "covered-by-symbolic-execution",
        "reason": "shared RawBossFloatReadShape models TH07 ECL_GET_BOSS_FLOAT and TH08 low opcode 87 with the same bosses[8] boundary, float selector bit-pattern ranges, and the TH07 unguarded versus TH08 guarded null-policy delta",
    },
    {
        "area": "integer conditional jumps",
        "status": "covered-by-symbolic-execution",
        "reason": "TH06 compare-register jumps and TH07/TH08 operand-resolved compare jumps are modeled as shared RawIntConditionJumpShape profiles",
    },
    {
        "area": "float comparisons and conditional jumps",
        "status": "covered-by-model",
        "reason": "TH06 CMPFLOAT compare-register production and TH07/TH08 float conditional jumps share an explicit IEEE ordered/unordered relation, including NaN's unequal-only branch behavior",
    },
    {
        "area": "CALL/RET core stack semantics",
        "status": "covered-by-symbolic-execution",
        "reason": "plain CALL/RET opcodes are modeled with title-profiled stack sizes, increment guards, subTable lookup policy, and TH08's child-context RET underflow path",
    },
    {
        "area": "TH06 conditional CALL guard and shared CALL body",
        "status": "covered-by-symbolic-execution",
        "reason": "TH06 CALLLSS/CALLLEQ/CALLEQU/CALLGRE/CALLGEQ/CALLNEQ resolve cmpLhs, compare raw cmpRhs, and reuse the same modeled CALL stack/subTable body when taken",
    },
    {
        "area": "raw ECL difficulty mask policy",
        "status": "covered-by-model",
        "reason": "TH06/TH07 active-bit intersection and TH08 contains(active|override) are separate profile policies",
    },
    {
        "area": "immediate movement state writes",
        "status": "covered-by-model",
        "reason": "shared movement effects cover position, axis/polar velocity, angular velocity, speed, acceleration, player-relative angle, and movement bounds while preserving title-specific resolution, normalization, clamp, mode, and timer updates",
    },
    {
        "area": "timed movement state writes",
        "status": "covered-by-model",
        "reason": "one consecutive-family model covers TH06 opcode-selected easing and TH07/TH08 operand-driven direction/position interpolation, including repeated resolver reads, nonpositive-duration branches, mirror-X, origin/delta source differences, and timer writes",
    },
    {
        "area": "enemy hitbox and flag state writes",
        "status": "covered-by-model",
        "reason": "shared enemy-state effects cover primary/secondary hitboxes, source-width flag truncation, TH08 replace/disable/enable masks, alignment-effect collision mirroring, presentation-guarded death-mode writes, life/gauge updates, and exact timer-history resets",
    },
    {
        "area": "shooting control state writes",
        "status": "covered-by-model",
        "reason": "shared shooting effects cover ranked immediate/random intervals, timer initialization, suppress/defer gates, previous-pattern spawn requests, and resolved offsets with title-specific zero guards and Z writes",
    },
    {
        "area": "ECL time and wait controls",
        "status": "covered-by-model",
        "reason": "shared time-control effects cover ordinary no-op advance, TH06 GetVar-backed TIMESET, TH07 waitTimer/scriptWaitTime/add-time controls, TH08 secondaryTime/add-time controls, and the wait-gate pre-tail time decrement that produces a net frame stall",
    },
    {
        "area": "enemy lifecycle host effects",
        "status": "covered-by-model",
        "reason": "shared enemy-lifecycle effects cover TH06/TH07/TH08 absolute/relative spawn and non-boss remove-all opcodes, preserving parent-life gates, operand resolution, host truncation, context-copy policy, pool size, and remove-all loop deltas",
    },
    {
        "area": "item/drop host effects",
        "status": "covered-by-model",
        "reason": "shared item/drop effects cover looped power-or-point drops, point-only drops, single item spawns, and TH08 item-drop state writes while preserving raw/resolved counts, item ids, spread constants, power-threshold policy, and default item-state use",
    },
    {
        "area": "boss/spellcard lifecycle host effects",
        "status": "covered-by-model",
        "reason": "shared boss/spellcard lifecycle effects cover unchecked boss-slot/gauge boundaries, legacy TH06/TH07 spellcard start/end, TH08 StartSpell/EndSpell host calls, life markers, timeout/survival flags, run interrupts, and TH08 spellcard effect/bonus controls while preserving title deltas such as u8 bossSlot truncation and primary-slot-only GUI presence",
    },
    {
        "area": "bullet control host effects",
        "status": "covered-by-model",
        "reason": "shared bullet-control effects cover all-bullet clears, item/no-item/radius/transition clear variants, sound flag and override writes, repeated primary sound reads, title-specific targets, and signed-i16 rank-count truncation",
    },
    {
        "area": "laser spawn descriptors",
        "status": "covered-by-model",
        "reason": "shared laser-spawn effects cover fixed/aimed descriptor writes, shifted TH07/TH08 operandFlags, title-specific descriptor targets and position sources, spawn requests, and unchecked selected-slot pointer writes after the spawn call",
    },
    {
        "area": "ANM entry header/nextOffset profile",
        "status": "partially-covered",
        "reason": "entry table shape and nextOffset chain headers are modeled, but ANM opcode execution and resource side effects are not",
    },
    {
        "area": "full raw ECL opcode bodies",
        "status": "partially-covered",
        "reason": "the Lean title profiles now provide the authoritative modeled-opcode set used by this report; unprofiled opcode bodies still collapse to prefix-level ordinary advance",
    },
    {
        "area": "interrupts, callbacks, pending-sub dispatch",
        "status": "partially-covered",
        "reason": "callback configuration and explicit interrupt entry are modeled with partial-write/fault ordering; automatic callback triggers, high-opcode pending-sub dispatch, and their bounded multi-context lifecycles remain",
    },
    {
        "area": "remaining arithmetic body faults",
        "status": "not-yet-modeled",
        "reason": "integer div/mod zero and signed idiv overflow are modeled; exact signed add/sub/mul overflow behavior, float divide/fmod edge cases, and numeric non-finite behavior still require C/C++/x87/SSE-faithful arithmetic semantics",
    },
    {
        "area": "bullet/laser/enemy/ANM/sound host side effects",
        "status": "partially-covered",
        "reason": "immediate/timed enemy movement, hitbox/flag/death-mode/life/timer writes, enemy lifecycle spawn/remove requests, item/drop requests, boss/spellcard lifecycle requests, shooting controls, and primary bullet-pattern construction now have typed host-effect boundaries; full laser runtime, full EnemyManager/ItemManager state, full GUI/Spellcard/Catk runtime, ANM execution, and sound effects still require additional game-state models and invariants",
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


def load_int_resolver_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.resolver_queue_json:
        path = Path(args.resolver_queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_int_resolver_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("int resolver candidate queue did not return an object")
    return payload, command


def load_int_binary_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.int_binary_queue_json:
        path = Path(args.int_binary_queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_int_binary_candidate_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("integer-binary candidate queue did not return an object")
    return payload, command


def load_callret_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.callret_queue_json:
        path = Path(args.callret_queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_callret_candidate_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("CALL/RET candidate queue did not return an object")
    return payload, command


def load_condcall_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.condcall_queue_json:
        path = Path(args.condcall_queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_condcall_candidate_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("conditional CALL candidate queue did not return an object")
    return payload, command


def load_boss_int_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.boss_int_queue_json:
        path = Path(args.boss_int_queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_boss_int_candidate_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("boss integer-read candidate queue did not return an object")
    return payload, command


def load_boss_float_queue(args: argparse.Namespace) -> tuple[dict[str, Any], dict[str, Any]]:
    if args.boss_float_queue_json:
        path = Path(args.boss_float_queue_json)
        return json.loads(path.read_text()), {
            "argv": ["read-existing-json", str(path)],
            "returncode": 0,
            "elapsedSeconds": 0.0,
        }
    payload, command = run_json_command([sys.executable, "scripts/symex_boss_float_candidate_queue.py"])
    if not isinstance(payload, dict):
        raise EvaluationError("boss float-read candidate queue did not return an object")
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
    if path.startswith("int-condjump-taken-"):
        return "int-condjump-taken"
    if path.startswith("int-condjump-not-taken-"):
        return "int-condjump-not-taken"
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
    if path.startswith("int-condjump-taken-"):
        return path.removeprefix("int-condjump-taken-")
    if path.startswith("int-condjump-not-taken-"):
        return path.removeprefix("int-condjump-not-taken-")
    if path.startswith("decjump-taken-"):
        return path.removeprefix("decjump-taken-")
    if path.startswith("decjump-not-taken-"):
        return path.removeprefix("decjump-not-taken-")
    return "-"


def callret_action_from_path(path: str) -> str:
    if path.startswith("call-stack-write-"):
        return "call-stack-write"
    if path.startswith("ret-stack-read-"):
        return "ret-stack-read"
    if path.startswith("ret-child-index-"):
        return "ret-child-index"
    return path


def int_binary_action_from_path(path: str) -> str:
    if path.startswith("int-binary-output-"):
        return "int-binary-output"
    if path.startswith("int-binary-divisor-zero-"):
        return "int-binary-divisor-zero"
    if path.startswith("int-binary-divide-overflow-"):
        return "int-binary-divide-overflow"
    return path


def condcall_action_from_path(path: str) -> str:
    if path.startswith("condcall-false-"):
        return "condcall-false"
    if path.startswith("condcall-stack-write-"):
        return "condcall-stack-write"
    return path


def boss_int_action_from_path(path: str) -> str:
    if path.startswith("boss-int-index-"):
        return "boss-int-index"
    if path.startswith("boss-int-value-"):
        return "boss-int-value"
    return path


def boss_float_action_from_path(path: str) -> str:
    if path.startswith("boss-float-index-"):
        return "boss-float-index"
    if path.startswith("boss-float-value-"):
        return "boss-float-value"
    return path


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


def summarize_int_resolver_queue(queue: dict[str, Any]) -> dict[str, Any]:
    candidates = queue.get("candidates", [])
    if not isinstance(candidates, list):
        raise EvaluationError("int resolver candidate queue has no candidate list")

    statuses = Counter(str(candidate.get("status")) for candidate in candidates)
    risks = Counter(str(candidate.get("risk", {}).get("class")) for candidate in candidates)
    priorities = Counter(str(candidate.get("risk", {}).get("priority")) for candidate in candidates)
    paths = Counter(str(candidate.get("path")) for candidate in candidates)
    resolved_kinds = Counter(str(candidate.get("fixture", {}).get("resolvedKind", "-")) for candidate in candidates)
    selector_known = Counter(str(candidate.get("fixture", {}).get("selectorKnown", "-")) for candidate in candidates)
    flag_enabled = Counter(str(candidate.get("fixture", {}).get("flagEnabled", "-")) for candidate in candidates)
    matches = Counter(str(candidate.get("fixture", {}).get("matchesPath")) for candidate in candidates)

    by_environment: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = f"{candidate.get('title')}:{candidate.get('environment')}"
        by_environment[key].append(candidate)

    env_reports = {}
    for env, env_candidates in sorted(by_environment.items()):
        title = str(env_candidates[0].get("title"))
        expected_paths = set(MODELED_INT_RESOLVER_PATHS_BY_TITLE.get(title, MODELED_INT_RESOLVER_PATHS))
        observed_paths = {str(candidate.get("path")) for candidate in env_candidates}
        env_reports[env] = {
            "title": title,
            "pathCount": len(observed_paths),
            "candidateCount": len(env_candidates),
            "satCount": sum(1 for candidate in env_candidates if candidate.get("status") == "sat"),
            "matchesPathCount": sum(
                1 for candidate in env_candidates
                if candidate.get("fixture", {}).get("matchesPath") == "true"
            ),
            "modeledPathsForTitle": sorted(expected_paths),
            "missingModeledPaths": sorted(expected_paths - observed_paths),
            "extraPaths": sorted(observed_paths - expected_paths),
        }

    top_candidates = [
        {
            "id": candidate.get("id"),
            "risk": candidate.get("risk", {}).get("class"),
            "priority": candidate.get("risk", {}).get("priority"),
            "hex": candidate.get("fixture", {}).get("hex"),
            "resolvedKind": candidate.get("fixture", {}).get("resolvedKind"),
            "rawValue": candidate.get("fixture", {}).get("rawValue"),
            "selectorKnown": candidate.get("fixture", {}).get("selectorKnown"),
            "flagEnabled": candidate.get("fixture", {}).get("flagEnabled"),
        }
        for candidate in candidates[:10]
    ]

    return {
        "schema": queue.get("schema"),
        "environmentCount": queue.get("environmentCount"),
        "candidateCount": queue.get("candidateCount"),
        "uniquePathCount": len({str(candidate.get("path")) for candidate in candidates}),
        "modeledPathFamilies": MODELED_INT_RESOLVER_PATHS,
        "modeledPathsByTitle": MODELED_INT_RESOLVER_PATHS_BY_TITLE,
        "statuses": dict(statuses),
        "matchesPath": dict(matches),
        "riskCounts": dict(risks),
        "priorityCounts": dict(priorities),
        "pathCounts": dict(paths),
        "resolvedKindCounts": dict(resolved_kinds),
        "selectorKnownCounts": dict(selector_known),
        "flagEnabledCounts": dict(flag_enabled),
        "allModeledPathsCoveredPerEnvironment": all(
            not report["missingModeledPaths"] and not report["extraPaths"]
            for report in env_reports.values()
        ),
        "allSat": statuses == Counter({"sat": len(candidates)}),
        "allMaterializedAndReplayMatched": matches == Counter({"true": len(candidates)}),
        "byEnvironment": env_reports,
        "topCandidates": top_candidates,
    }


def summarize_int_binary_queue(queue: dict[str, Any]) -> dict[str, Any]:
    candidates = queue.get("candidates", [])
    if not isinstance(candidates, list):
        raise EvaluationError("integer-binary candidate queue has no candidate list")

    statuses = Counter(str(candidate.get("status")) for candidate in candidates)
    risks = Counter(str(candidate.get("risk", {}).get("class")) for candidate in candidates)
    priorities = Counter(str(candidate.get("risk", {}).get("priority")) for candidate in candidates)
    actions = Counter(int_binary_action_from_path(str(candidate.get("path"))) for candidate in candidates)
    fixture_actions = Counter(str(candidate.get("fixture", {}).get("action")) for candidate in candidates)
    fault_kinds = Counter(str(candidate.get("fixture", {}).get("faultKind", "-")) for candidate in candidates)
    output_kinds = Counter(str(candidate.get("fixture", {}).get("outputKind", "-")) for candidate in candidates)
    lhs_kinds = Counter(str(candidate.get("fixture", {}).get("lhsKind", "-")) for candidate in candidates)
    rhs_kinds = Counter(str(candidate.get("fixture", {}).get("rhsKind", "-")) for candidate in candidates)
    op_kinds = Counter(str(candidate.get("fixture", {}).get("op", "-")) for candidate in candidates)
    matches = Counter(str(candidate.get("fixture", {}).get("matchesPath")) for candidate in candidates)

    by_title = Counter(str(candidate.get("title")) for candidate in candidates)
    by_environment: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = (
            f"{candidate.get('title')}:{candidate.get('environment')}:"
            f"active={candidate.get('activeMask')}:override={candidate.get('overrideMask')}"
        )
        by_environment[key].append(candidate)

    env_reports = {}
    for env, env_candidates in sorted(by_environment.items()):
        title = str(env_candidates[0].get("title"))
        expected_paths = set(MODELED_INT_BINARY_PATHS_BY_TITLE.get(title, MODELED_INT_BINARY_PATHS))
        observed_paths = {str(candidate.get("path")) for candidate in env_candidates}
        env_reports[env] = {
            "title": title,
            "pathCount": len(observed_paths),
            "candidateCount": len(env_candidates),
            "satCount": sum(1 for candidate in env_candidates if candidate.get("status") == "sat"),
            "matchesPathCount": sum(
                1 for candidate in env_candidates
                if candidate.get("fixture", {}).get("matchesPath") == "true"
            ),
            "modeledPathsForTitle": sorted(expected_paths),
            "missingModeledPaths": sorted(expected_paths - observed_paths),
            "extraPaths": sorted(observed_paths - expected_paths),
        }

    top_candidates = [
        {
            "id": candidate.get("id"),
            "risk": candidate.get("risk", {}).get("class"),
            "priority": candidate.get("risk", {}).get("priority"),
            "hex": candidate.get("fixture", {}).get("hex"),
            "op": candidate.get("fixture", {}).get("op"),
            "outputKind": candidate.get("fixture", {}).get("outputKind"),
            "lhsKind": candidate.get("fixture", {}).get("lhsKind"),
            "rhsKind": candidate.get("fixture", {}).get("rhsKind"),
            "lhsValue": candidate.get("fixture", {}).get("lhsValue"),
            "rhsValue": candidate.get("fixture", {}).get("rhsValue"),
            "action": candidate.get("fixture", {}).get("action"),
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
        "modeledPathFamilies": MODELED_INT_BINARY_PATHS,
        "modeledPathsByTitle": MODELED_INT_BINARY_PATHS_BY_TITLE,
        "statuses": dict(statuses),
        "matchesPath": dict(matches),
        "riskCounts": dict(risks),
        "priorityCounts": dict(priorities),
        "pathActionCounts": dict(actions),
        "fixtureActionCounts": dict(fixture_actions),
        "faultKindCounts": dict(fault_kinds),
        "outputKindCounts": dict(output_kinds),
        "lhsKindCounts": dict(lhs_kinds),
        "rhsKindCounts": dict(rhs_kinds),
        "opCounts": dict(op_kinds),
        "candidateCountsByTitle": dict(by_title),
        "allModeledPathsCoveredPerEnvironment": all(
            not report["missingModeledPaths"] and not report["extraPaths"]
            for report in env_reports.values()
        ),
        "allSat": statuses == Counter({"sat": len(candidates)}),
        "allMaterializedAndReplayMatched": matches == Counter({"true": len(candidates)}),
        "byEnvironment": env_reports,
        "topCandidates": top_candidates,
    }


def summarize_callret_queue(queue: dict[str, Any]) -> dict[str, Any]:
    candidates = queue.get("candidates", [])
    if not isinstance(candidates, list):
        raise EvaluationError("CALL/RET candidate queue has no candidate list")

    statuses = Counter(str(candidate.get("status")) for candidate in candidates)
    risks = Counter(str(candidate.get("risk", {}).get("class")) for candidate in candidates)
    priorities = Counter(str(candidate.get("risk", {}).get("priority")) for candidate in candidates)
    actions = Counter(callret_action_from_path(str(candidate.get("path"))) for candidate in candidates)
    fixture_actions = Counter(str(candidate.get("fixture", {}).get("action")) for candidate in candidates)
    fault_kinds = Counter(str(candidate.get("fixture", {}).get("faultKind", "-")) for candidate in candidates)
    matches = Counter(str(candidate.get("fixture", {}).get("matchesPath")) for candidate in candidates)

    by_environment: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = (
            f"{candidate.get('title')}:{candidate.get('environment')}:"
            f"active={candidate.get('activeMask')}:override={candidate.get('overrideMask')}"
        )
        by_environment[key].append(candidate)

    env_reports = {}
    for env, env_candidates in sorted(by_environment.items()):
        title = str(env_candidates[0].get("title"))
        expected_paths = set(MODELED_CALLRET_PATHS_BY_TITLE.get(title, MODELED_CALLRET_PATHS))
        observed_paths = {str(candidate.get("path")) for candidate in env_candidates}
        env_reports[env] = {
            "title": title,
            "pathCount": len(observed_paths),
            "candidateCount": len(env_candidates),
            "satCount": sum(1 for candidate in env_candidates if candidate.get("status") == "sat"),
            "matchesPathCount": sum(
                1 for candidate in env_candidates
                if candidate.get("fixture", {}).get("matchesPath") == "true"
            ),
            "modeledPathsForTitle": sorted(expected_paths),
            "missingModeledPaths": sorted(expected_paths - observed_paths),
            "extraPaths": sorted(observed_paths - expected_paths),
        }

    top_candidates = [
        {
            "id": candidate.get("id"),
            "risk": candidate.get("risk", {}).get("class"),
            "priority": candidate.get("risk", {}).get("priority"),
            "hex": candidate.get("fixture", {}).get("hex"),
            "action": candidate.get("fixture", {}).get("action"),
            "faultKind": candidate.get("fixture", {}).get("faultKind"),
            "stackDepth": candidate.get("witness", {}).get("stackDepth"),
            "stackDisabled": candidate.get("witness", {}).get("stackDisabled"),
            "subId": candidate.get("witness", {}).get("subId"),
            "childContextSlot": candidate.get("witness", {}).get("childContextSlot"),
        }
        for candidate in candidates[:10]
    ]

    return {
        "schema": queue.get("schema"),
        "environmentCount": queue.get("environmentCount"),
        "candidateCount": queue.get("candidateCount"),
        "uniquePathCount": len({str(candidate.get("path")) for candidate in candidates}),
        "modeledPathFamilies": MODELED_CALLRET_PATHS,
        "modeledPathsByTitle": MODELED_CALLRET_PATHS_BY_TITLE,
        "statuses": dict(statuses),
        "matchesPath": dict(matches),
        "riskCounts": dict(risks),
        "priorityCounts": dict(priorities),
        "pathActionCounts": dict(actions),
        "fixtureActionCounts": dict(fixture_actions),
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


def summarize_condcall_queue(queue: dict[str, Any]) -> dict[str, Any]:
    candidates = queue.get("candidates", [])
    if not isinstance(candidates, list):
        raise EvaluationError("conditional CALL candidate queue has no candidate list")

    statuses = Counter(str(candidate.get("status")) for candidate in candidates)
    risks = Counter(str(candidate.get("risk", {}).get("class")) for candidate in candidates)
    priorities = Counter(str(candidate.get("risk", {}).get("priority")) for candidate in candidates)
    actions = Counter(condcall_action_from_path(str(candidate.get("path"))) for candidate in candidates)
    fixture_actions = Counter(str(candidate.get("fixture", {}).get("action")) for candidate in candidates)
    fault_kinds = Counter(str(candidate.get("fixture", {}).get("faultKind", "-")) for candidate in candidates)
    matches = Counter(str(candidate.get("fixture", {}).get("matchesPath")) for candidate in candidates)

    by_environment: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = (
            f"{candidate.get('title')}:{candidate.get('environment')}:"
            f"active={candidate.get('activeMask')}:override={candidate.get('overrideMask')}"
        )
        by_environment[key].append(candidate)

    env_reports = {}
    for env, env_candidates in sorted(by_environment.items()):
        title = str(env_candidates[0].get("title"))
        expected_paths = set(MODELED_CONDCALL_PATHS_BY_TITLE.get(title, MODELED_CONDCALL_PATHS))
        observed_paths = {str(candidate.get("path")) for candidate in env_candidates}
        env_reports[env] = {
            "title": title,
            "pathCount": len(observed_paths),
            "candidateCount": len(env_candidates),
            "satCount": sum(1 for candidate in env_candidates if candidate.get("status") == "sat"),
            "matchesPathCount": sum(
                1 for candidate in env_candidates
                if candidate.get("fixture", {}).get("matchesPath") == "true"
            ),
            "modeledPathsForTitle": sorted(expected_paths),
            "missingModeledPaths": sorted(expected_paths - observed_paths),
            "extraPaths": sorted(observed_paths - expected_paths),
        }

    top_candidates = [
        {
            "id": candidate.get("id"),
            "risk": candidate.get("risk", {}).get("class"),
            "priority": candidate.get("risk", {}).get("priority"),
            "hex": candidate.get("fixture", {}).get("hex"),
            "action": candidate.get("fixture", {}).get("action"),
            "faultKind": candidate.get("fixture", {}).get("faultKind"),
            "stackDepth": candidate.get("witness", {}).get("stackDepth"),
            "stackDisabled": candidate.get("witness", {}).get("stackDisabled"),
            "subId": candidate.get("witness", {}).get("subId"),
            "lhsRaw": candidate.get("witness", {}).get("lhsRaw"),
            "lhsHost": candidate.get("witness", {}).get("lhsHost"),
            "rhsRaw": candidate.get("witness", {}).get("rhsRaw"),
        }
        for candidate in candidates[:10]
    ]

    return {
        "schema": queue.get("schema"),
        "environmentCount": queue.get("environmentCount"),
        "candidateCount": queue.get("candidateCount"),
        "uniquePathCount": len({str(candidate.get("path")) for candidate in candidates}),
        "modeledPathFamilies": MODELED_CONDCALL_PATHS,
        "modeledPathsByTitle": MODELED_CONDCALL_PATHS_BY_TITLE,
        "statuses": dict(statuses),
        "matchesPath": dict(matches),
        "riskCounts": dict(risks),
        "priorityCounts": dict(priorities),
        "pathActionCounts": dict(actions),
        "fixtureActionCounts": dict(fixture_actions),
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


def summarize_boss_read_queue(
    queue: dict[str, Any],
    *,
    label: str,
    modeled_paths_by_title: dict[str, list[str]],
    modeled_paths: list[str],
    action_from_path_fn,
) -> dict[str, Any]:
    candidates = queue.get("candidates", [])
    if not isinstance(candidates, list):
        raise EvaluationError(f"{label} candidate queue has no candidate list")

    statuses = Counter(str(candidate.get("status")) for candidate in candidates)
    risks = Counter(str(candidate.get("risk", {}).get("class")) for candidate in candidates)
    priorities = Counter(str(candidate.get("risk", {}).get("priority")) for candidate in candidates)
    actions = Counter(action_from_path_fn(str(candidate.get("path"))) for candidate in candidates)
    fixture_actions = Counter(str(candidate.get("fixture", {}).get("action")) for candidate in candidates)
    fault_kinds = Counter(str(candidate.get("fixture", {}).get("faultKind", "-")) for candidate in candidates)
    output_kinds = Counter(str(candidate.get("fixture", {}).get("outputKind", "-")) for candidate in candidates)
    boss_index_kinds = Counter(str(candidate.get("fixture", {}).get("bossIndexKind", "-")) for candidate in candidates)
    value_kinds = Counter(str(candidate.get("fixture", {}).get("valueKind", "-")) for candidate in candidates)
    matches = Counter(str(candidate.get("fixture", {}).get("matchesPath")) for candidate in candidates)

    by_title = Counter(str(candidate.get("title")) for candidate in candidates)
    by_environment: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for candidate in candidates:
        key = (
            f"{candidate.get('title')}:{candidate.get('environment')}:"
            f"active={candidate.get('activeMask')}:override={candidate.get('overrideMask')}"
        )
        by_environment[key].append(candidate)

    env_reports = {}
    for env, env_candidates in sorted(by_environment.items()):
        title = str(env_candidates[0].get("title"))
        expected_paths = set(modeled_paths_by_title.get(title, modeled_paths))
        observed_paths = {str(candidate.get("path")) for candidate in env_candidates}
        env_reports[env] = {
            "title": title,
            "pathCount": len(observed_paths),
            "candidateCount": len(env_candidates),
            "satCount": sum(1 for candidate in env_candidates if candidate.get("status") == "sat"),
            "matchesPathCount": sum(
                1 for candidate in env_candidates
                if candidate.get("fixture", {}).get("matchesPath") == "true"
            ),
            "modeledPathsForTitle": sorted(expected_paths),
            "missingModeledPaths": sorted(expected_paths - observed_paths),
            "extraPaths": sorted(observed_paths - expected_paths),
        }

    top_candidates = [
        {
            "id": candidate.get("id"),
            "risk": candidate.get("risk", {}).get("class"),
            "priority": candidate.get("risk", {}).get("priority"),
            "hex": candidate.get("fixture", {}).get("hex"),
            "opcode": candidate.get("fixture", {}).get("opcode"),
            "operandMask": candidate.get("fixture", {}).get("operandMask"),
            "action": candidate.get("fixture", {}).get("action"),
            "faultKind": candidate.get("fixture", {}).get("faultKind"),
            "bossIndexRaw": candidate.get("witness", {}).get("bossIndexRaw"),
            "bossIndexHost": candidate.get("witness", {}).get("bossIndexHost"),
            "valueRaw": candidate.get("witness", {}).get("valueRaw"),
            "bossPresent": candidate.get("witness", {}).get("bossPresent"),
        }
        for candidate in candidates[:10]
    ]

    return {
        "schema": queue.get("schema"),
        "environmentCount": queue.get("environmentCount"),
        "candidateCount": queue.get("candidateCount"),
        "uniquePathCount": len({str(candidate.get("path")) for candidate in candidates}),
        "modeledPathFamilies": modeled_paths,
        "modeledPathsByTitle": modeled_paths_by_title,
        "statuses": dict(statuses),
        "matchesPath": dict(matches),
        "riskCounts": dict(risks),
        "priorityCounts": dict(priorities),
        "pathActionCounts": dict(actions),
        "fixtureActionCounts": dict(fixture_actions),
        "faultKindCounts": dict(fault_kinds),
        "outputKindCounts": dict(output_kinds),
        "bossIndexKindCounts": dict(boss_index_kinds),
        "valueKindCounts": dict(value_kinds),
        "candidateCountsByTitle": dict(by_title),
        "allModeledPathsCoveredPerEnvironment": all(
            not report["missingModeledPaths"] and not report["extraPaths"]
            for report in env_reports.values()
        ),
        "allSat": statuses == Counter({"sat": len(candidates)}),
        "allMaterializedAndReplayMatched": matches == Counter({"true": len(candidates)}),
        "byEnvironment": env_reports,
        "topCandidates": top_candidates,
    }


def summarize_boss_int_queue(queue: dict[str, Any]) -> dict[str, Any]:
    return summarize_boss_read_queue(
        queue,
        label="boss integer-read",
        modeled_paths_by_title=MODELED_BOSS_INT_PATHS_BY_TITLE,
        modeled_paths=MODELED_BOSS_INT_PATHS,
        action_from_path_fn=boss_int_action_from_path,
    )


def summarize_boss_float_queue(queue: dict[str, Any]) -> dict[str, Any]:
    return summarize_boss_read_queue(
        queue,
        label="boss float-read",
        modeled_paths_by_title=MODELED_BOSS_FLOAT_PATHS_BY_TITLE,
        modeled_paths=MODELED_BOSS_FLOAT_PATHS,
        action_from_path_fn=boss_float_action_from_path,
    )


def unique_preserving(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result = []
    for value in values:
        if value not in seen:
            seen.add(value)
            result.append(value)
    return result


def strip_c_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//.*", "", text)


def enum_block(text: str, enum_name: str) -> str | None:
    match = re.search(
        rf"\benum\s+{re.escape(enum_name)}\s*\{{(?P<body>.*?)\}}\s*;",
        text,
        flags=re.DOTALL,
    )
    if match is None:
        return None
    return strip_c_comments(match.group("body"))


def parse_sequential_enum(block: str, symbol_prefix: str) -> list[tuple[str, int]]:
    entries: list[tuple[str, int]] = []
    next_value = 0
    for raw_entry in block.split(","):
        entry = raw_entry.strip()
        match = re.match(
            rf"(?P<name>{re.escape(symbol_prefix)}[A-Z0-9_]+)"
            r"(?:\s*=\s*(?P<value>-?(?:0[xX][0-9a-fA-F]+|[0-9]+)))?\s*$",
            entry,
        )
        if match is None:
            continue
        value_text = match.group("value")
        value = int(value_text, 0) if value_text is not None else next_value
        entries.append((match.group("name"), value))
        next_value = value + 1
    return entries


def parse_explicit_enum(block: str, symbol_prefix: str) -> list[tuple[str, int]]:
    entries: list[tuple[str, int]] = []
    for raw_entry in block.split(","):
        entry = raw_entry.strip()
        match = re.match(
            rf"(?P<name>{re.escape(symbol_prefix)}[A-Z0-9_]+)\s*=\s*"
            r"(?P<value>-?(?:0[xX][0-9a-fA-F]+|[0-9]+))\s*$",
            entry,
        )
        if match is not None:
            entries.append((match.group("name"), int(match.group("value"), 0)))
    return entries


def modeled_profile_opcodes(title: str) -> dict[str, Any]:
    wire_path = REPO_ROOT / "TouhouFormal" / title.upper() / "Wire.lean"
    if not wire_path.exists():
        return {
            "available": False,
            "source": str(wire_path),
            "values": [],
            "constantsByValue": {},
        }

    text = wire_path.read_text(errors="ignore")
    constants = {
        name: int(value)
        for name, value in re.findall(
            r"^def\s+(eclOpcode[A-Za-z0-9_]+)\s*:\s*Int\s*:=\s*(-?[0-9]+)\s*$",
            text,
            flags=re.MULTILINE,
        )
    }
    referenced_names = set(
        re.findall(
            r"\b(?:opcode|callOpcode|retOpcode|firstOpcode|lastOpcode)\s*:=\s*"
            r"(eclOpcode[A-Za-z0-9_]+)\b",
            text,
        )
    )
    referenced_names.update(
        re.findall(
            r"\b[A-Za-z0-9_]*Op\s+(eclOpcode[A-Za-z0-9_]+)\b",
            text,
        )
    )
    family_ranges = re.findall(
        r"\bfirstOpcode\s*:=\s*(eclOpcode[A-Za-z0-9_]+)\s+"
        r"lastOpcode\s*:=\s*(eclOpcode[A-Za-z0-9_]+)\b",
        text,
    )
    unresolved_names = sorted(referenced_names - constants.keys())
    values_to_constants: dict[int, list[str]] = defaultdict(list)
    for name in sorted(referenced_names & constants.keys()):
        values_to_constants[constants[name]].append(name)

    for first_name, last_name in family_ranges:
        if first_name not in constants or last_name not in constants:
            continue
        first_value = constants[first_name]
        last_value = constants[last_name]
        if last_value < first_value:
            continue
        family_name = f"{first_name}..{last_name}"
        for value in range(first_value, last_value + 1):
            values_to_constants[value].append(family_name)

    for value in re.findall(
        r"\bunimplementedOpcode\s*:=\s*some\s+(-?[0-9]+)\b",
        text,
    ):
        values_to_constants[int(value)].append("unimplementedOpcode")

    values = sorted(values_to_constants)
    return {
        "available": True,
        "source": str(wire_path),
        "values": values,
        "constantsByValue": {
            str(value): sorted(set(values_to_constants[value]))
            for value in values
        },
        "unresolvedConstants": unresolved_names,
    }


def named_opcode_coverage(
    source_entries: list[tuple[str, int]],
    profile: dict[str, Any],
) -> dict[str, Any]:
    modeled_values = set(profile["values"])
    modeled_entries = [
        (name, value) for name, value in source_entries if value in modeled_values
    ]
    missing_entries = [
        (name, value) for name, value in source_entries if value not in modeled_values
    ]
    source_values = {value for _, value in source_entries}
    return {
        "profileSource": profile["source"],
        "profileOpcodeValues": profile["values"],
        "profileOpcodeConstantsByValue": profile["constantsByValue"],
        "unresolvedProfileConstants": profile["unresolvedConstants"],
        "profileOpcodesAbsentFromSource": sorted(modeled_values - source_values),
        "modeledOpcodeSpecificSymbols": [name for name, _ in modeled_entries],
        "modeledOpcodeSpecificValues": [value for _, value in modeled_entries],
        "modeledOpcodeSpecificCount": len(modeled_entries),
        "notYetOpcodeBodyModeledSymbols": [name for name, _ in missing_entries],
        "notYetOpcodeBodyModeledValues": [value for _, value in missing_entries],
        "notYetOpcodeBodyModeledCountLowerBound": len(missing_entries),
    }


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
    th08_high = reference_root / "th08" / "src" / "EclRunHigh.inl"
    th08_run = reference_root / "th08" / "src" / "EclRun.cpp"

    if th06.exists():
        text = th06.read_text(errors="ignore")
        block = enum_block(text, "EclRawInstrOpcode")
        entries = parse_sequential_enum(block, "ECL_OPCODE_") if block else []
        profile = modeled_profile_opcodes("th06")
        report["titles"]["th06"] = {
            "source": str(th06),
            "rawOpcodeSymbolCount": len(entries),
            **named_opcode_coverage(entries, profile),
            "firstSymbols": [name for name, _ in entries[:8]],
            "lastSymbols": [name for name, _ in entries[-8:]],
        }

    if th07.exists():
        text = th07.read_text(errors="ignore")
        block = enum_block(text, "EclOpcode")
        entries = parse_explicit_enum(block, "ECL_") if block else []
        profile = modeled_profile_opcodes("th07")
        report["titles"]["th07"] = {
            "source": str(th07),
            "rawOpcodeSymbolCount": len(entries),
            **named_opcode_coverage(entries, profile),
            "firstSymbols": [name for name, _ in entries[:8]],
            "lastSymbols": [name for name, _ in entries[-8:]],
        }

    if th08_low.exists():
        low_text = th08_low.read_text(errors="ignore")
        low_case_labels = [
            int(value)
            for value in unique_preserving(
                re.findall(r"\bcase\s+([0-9]+)\s*:", low_text)
            )
        ]
        high_case_labels: list[int] = []
        if th08_high.exists():
            high_text = th08_high.read_text(errors="ignore")
            high_case_labels = [
                int(value)
                for value in unique_preserving(
                    re.findall(r"\bcase\s+([0-9]+)\s*:", high_text)
                )
            ]
        case_labels = unique_preserving(
            [str(value) for value in low_case_labels + high_case_labels]
        )
        case_labels = [int(value) for value in case_labels]
        profile = modeled_profile_opcodes("th08")
        modeled_values = set(profile["values"])
        source_values = set(case_labels)
        modeled_cases = [value for value in case_labels if value in modeled_values]
        missing_cases = [value for value in case_labels if value not in modeled_values]
        report["titles"]["th08"] = {
            "source": str(th08_low),
            "highSource": str(th08_high) if th08_high.exists() else None,
            "runSource": str(th08_run) if th08_run.exists() else None,
            "lowOpcodeCaseLabelCount": len(low_case_labels),
            "highOpcodeCaseLabelCount": len(high_case_labels),
            "rawOpcodeCaseLabelCount": len(case_labels),
            "profileSource": profile["source"],
            "profileOpcodeValues": profile["values"],
            "profileOpcodeConstantsByValue": profile["constantsByValue"],
            "unresolvedProfileConstants": profile["unresolvedConstants"],
            "profileOpcodesAbsentFromSource": sorted(modeled_values - source_values),
            "modeledOpcodeSpecificCases": [f"case {value}" for value in modeled_cases],
            "modeledOpcodeSpecificValues": modeled_cases,
            "modeledOpcodeSpecificCount": len(modeled_cases),
            "notYetOpcodeBodyModeledCases": [f"case {value}" for value in missing_cases],
            "notYetOpcodeBodyModeledValues": missing_cases,
            "notYetOpcodeBodyModeledCountLowerBound": len(missing_cases),
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

    if isinstance(data.get("wine_probe"), dict):
        wine_probe = data["wine_probe"]
        oracle = wine_probe.get("oracle", {})
        patched = data.get("patched", {}).get("patched_archive", {})
        cfg = data.get("cfg", {})
        source_result_path = Path(str(data.get("source_result", "")))
        source_result = load_json_if_exists(source_result_path) if source_result_path.is_file() else None
        symex = source_result.get("symex", {}) if isinstance(source_result, dict) else {}
        mutation = source_result.get("mutation_metadata", {}) if isinstance(source_result, dict) else {}
        fixture = symex.get("fixture", {}) if isinstance(symex, dict) else {}
        summary.update(
            {
                "schema": source_result.get("schema") if isinstance(source_result, dict) else data.get("schema", "boss-read-retail-report"),
                "sourceResult": str(source_result_path) if source_result_path else None,
                "classification": oracle.get("classification"),
                "interesting": oracle.get("interesting"),
                "retailSignatureKey": oracle.get("wine_log_primary_signature"),
                "symexPath": mutation.get("symex_path"),
                "mutationFamily": mutation.get("family"),
                "bossReadFamily": mutation.get("boss_read_family"),
                "leanModel": source_result.get("lean_model") if isinstance(source_result, dict) else None,
                "witnessHex": fixture.get("hex") if isinstance(fixture, dict) else None,
                "patchedArchiveSha256": patched.get("sha256") if isinstance(patched, dict) else None,
                "cfgSha256": cfg.get("sha256") if isinstance(cfg, dict) else None,
                "timedOut": wine_probe.get("timed_out"),
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
        summarize_retail_report(
            "TH08 boss-int null-deref",
            retail_root / "formal-th08-boss-int-boss-int-null-deref-20260901T024506Z" / "report.json",
        ),
        summarize_retail_report(
            "TH07 boss-float null-deref",
            retail_root / "formal-th07-boss-float-boss-float-null-deref-20260901T034027Z" / "report.json",
        ),
        summarize_retail_report(
            "TH07 boss-float index-at-or-past-array",
            retail_root / "formal-th07-boss-float-boss-float-index-at-or-past-array-20260901T034254Z" / "report.json",
        ),
        summarize_retail_report(
            "TH08 boss-float null-guarded-skip",
            retail_root / "formal-th08-boss-float-boss-float-null-guarded-skip-20260901T034119Z" / "report.json",
        ),
        summarize_retail_report(
            "TH08 boss-float index-at-or-past-array",
            retail_root / "formal-th08-boss-float-boss-float-index-at-or-past-array-20260901T034207Z" / "report.json",
        ),
    ]


def fuzz_comparison() -> dict[str, Any]:
    return {
        "formalCurrentlyBeatsFuzzFor": [
            "exhaustively enumerating the implemented raw-step path classes instead of waiting for random mutation to hit each class",
            "exhaustively enumerating the implemented JUMPDEC and integer conditional jump taken/not-taken cursor classes plus immediate integer div/mod zero-divisor faults",
            "separating operandFlags resolver branches, including TH06's no-mask behavior and TH07/TH08's mask-clear/mask-set selector behavior",
            "enumerating title-specific integer lvalue/binary arithmetic paths, including resolver-driven zero divisors and signed idiv overflow",
            "enumerating boss-indexed integer-read hazards, including bosses[8] underflow/overflow and null boss dereferences without seeding concrete indices by hand",
            "enumerating boss-indexed float-read hazards and proving the TH07 unguarded versus TH08 guarded null-policy split with paired sat/unsat controls",
            "separating CALL/RET stack write/read hazards from subTable lookup faults and TH08 child-context RET exits",
            "separating TH06 conditional CALL guard-false fallthrough from guard-true CALL stack/subTable hazards",
            "returning satisfiable/unsatisfiable path facts with concrete byte-realizable witnesses",
            "keeping TH06/TH07/TH08 differences in shared profiles, reducing per-title semantic drift",
            "explaining exact invariants such as cursor must progress and remain in-bounds",
        ],
        "fuzzCurrentlyBeatsFormalFor": [
            "full gameplay side effects through bullets, lasers, EnemyManager/ItemManager runtime state, ANM, rendering, input, and callbacks",
            "unknown opcode-body behavior that has not yet been source-modeled",
            "large multi-resource interactions where a retail oracle is easier to observe than to prove",
            "empirical prioritization of which formally reachable witnesses are retail-visible bugs",
        ],
        "currentVerdict": (
            "The current Lean+SMT baseline is stronger than prior fuzzing on the modeled VM-core skeleton, "
            "because all 14 raw-step path classes, all 17 current body-step path classes, and all 8 title-specific integer resolver candidates "
            "plus all 39 title/environment-specific integer-binary arithmetic candidates, all 18 boss integer-read candidates, all 18 boss float-read candidates, all 41 CALL/RET candidates, and all 16 TH06 conditional-CALL candidates "
            "are solved and materialized for the default environments. "
            "Several additional gameplay-effect opcode families are source-modeled and Lean-checked, including enemy lifecycle, item/drop, and boss/spellcard lifecycle effects, but they are not yet dedicated solver/materializer lanes. "
            "It is not yet stronger than fuzzing for the full ECL/ANM VM, because remaining opcode bodies and host-state branches "
            "remain outside the semantics."
        ),
        "nextHighValueFormalWork": [
            "compose integer arithmetic writes with bounded multi-step execution to see which self-writes and host writes become later control/state hazards",
            "improve retail ranking for boss-read OOB/null candidates by selecting execution sites whose host boss-slot state is forced by the stage timeline",
            "add bounded multi-step raw ECL contexts for nested CALL/RET reachability, callbacks, and stacked jumps",
            "model float division/fmod preconditions and C/C++-faithful non-finite behavior",
            "extend the reusable retail lowering pipeline to the next host-boundary opcode family",
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
        "--resolver-queue-json",
        help="reuse an existing symex_int_resolver_queue.py JSON payload instead of rerunning the resolver solver",
    )
    parser.add_argument(
        "--int-binary-queue-json",
        help="reuse an existing symex_int_binary_candidate_queue.py JSON payload instead of rerunning the integer-binary solver",
    )
    parser.add_argument(
        "--callret-queue-json",
        help="reuse an existing symex_callret_candidate_queue.py JSON payload instead of rerunning the CALL/RET solver",
    )
    parser.add_argument(
        "--condcall-queue-json",
        help="reuse an existing symex_condcall_candidate_queue.py JSON payload instead of rerunning the conditional CALL solver",
    )
    parser.add_argument(
        "--boss-int-queue-json",
        help="reuse an existing symex_boss_int_candidate_queue.py JSON payload instead of rerunning the boss integer-read solver",
    )
    parser.add_argument(
        "--boss-float-queue-json",
        help="reuse an existing symex_boss_float_candidate_queue.py JSON payload instead of rerunning the boss float-read solver",
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
    resolver_queue, resolver_command = load_int_resolver_queue(args)
    commands["intResolverQueue"] = resolver_command
    resolver_queue_summary = summarize_int_resolver_queue(resolver_queue)
    int_binary_queue, int_binary_command = load_int_binary_queue(args)
    commands["intBinaryCandidateQueue"] = int_binary_command
    int_binary_queue_summary = summarize_int_binary_queue(int_binary_queue)
    callret_queue, callret_command = load_callret_queue(args)
    commands["callRetCandidateQueue"] = callret_command
    callret_queue_summary = summarize_callret_queue(callret_queue)
    condcall_queue, condcall_command = load_condcall_queue(args)
    commands["conditionalCallCandidateQueue"] = condcall_command
    condcall_queue_summary = summarize_condcall_queue(condcall_queue)
    boss_int_queue, boss_int_command = load_boss_int_queue(args)
    commands["bossIntCandidateQueue"] = boss_int_command
    boss_int_queue_summary = summarize_boss_int_queue(boss_int_queue)
    boss_float_queue, boss_float_command = load_boss_float_queue(args)
    commands["bossFloatCandidateQueue"] = boss_float_command
    boss_float_queue_summary = summarize_boss_float_queue(boss_float_queue)

    payload = {
        "schema": "touhou-formal-symex-effectiveness-v1",
        "date": "2026-09-01",
        "commands": commands,
        "rawStepSymbolicCoverage": queue_summary,
        "rawBodySymbolicCoverage": body_queue_summary,
        "rawIntResolverCoverage": resolver_queue_summary,
        "rawIntBinaryCoverage": int_binary_queue_summary,
        "rawBossIntReadCoverage": boss_int_queue_summary,
        "rawBossFloatReadCoverage": boss_float_queue_summary,
        "rawCallRetCoverage": callret_queue_summary,
        "rawConditionalCallCoverage": condcall_queue_summary,
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
