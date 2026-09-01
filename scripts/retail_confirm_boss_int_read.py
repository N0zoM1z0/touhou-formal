#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess
import struct
import sys
import time
from typing import Any

from ecl_wire_patch import EclWireFile
from retail_pbg import (
    RetailArchive,
    replace_archive_entry,
    sha256_bytes,
    th08_encrypt_blob,
    th08_try_decrypt_blob,
)


FORMAL_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_ROOT = FORMAL_ROOT.parent
DEFAULT_RETAIL_ROOT = WORKSPACE_ROOT / "retail_validation"
DEFAULT_SOURCE_GAME_DIRS = {
    "th07": WORKSPACE_ROOT / "retail_extract" / "th07-20260901-unar" / "[th07] 东方妖妖梦 (日文版)",
    "th08": WORKSPACE_ROOT / "retail_extract" / "th08-20260901-unar" / "[th08] 东方永夜抄 (日文版)",
}
ARCHIVE_NAMES = {"th07": "th07.dat", "th08": "th08.dat"}
EXECUTABLE_NAMES = {"th07": "th07.exe", "th08": "th08.exe"}
WINDOW_NAME_TOKENS = {
    "th07": ("東方妖々夢", "Perfect Cherry Blossom", "th07"),
    "th08": ("東方永夜抄", "Imperishable Night", "th08"),
}
DEFAULT_ACTIVE_MASK = 8
DEFAULT_OVERRIDE_MASK = 0
DEFAULT_FAMILY = "boss-int"
FAMILY_CONFIGS = {
    "boss-int": {
        "artifact_label": "boss-int",
        "default_symex_path": "boss-int-null-deref",
        "materializer": "symex_materialize_boss_int_read.py",
        "schema": "touhou-formal-retail-boss-int-read-candidate-v1",
        "formal_id_tag": "ECL-BOSS-INT",
        "lean_model": "TouhouFormal.ECL.rawBossIntReadStep",
        "mutation_family": "boss-int-read-symbolic-step",
        "description": "Lower a boss-int symbolic witness into a TH07/TH08 retail DAT mutation.",
    },
    "boss-float": {
        "artifact_label": "boss-float",
        "default_symex_path": "boss-float-null-deref",
        "materializer": "symex_materialize_boss_float_read.py",
        "schema": "touhou-formal-retail-boss-float-read-candidate-v1",
        "formal_id_tag": "ECL-BOSS-FLOAT",
        "lean_model": "TouhouFormal.ECL.rawBossFloatReadStep",
        "mutation_family": "boss-float-read-symbolic-step",
        "description": "Lower a boss-float symbolic witness into a TH07/TH08 retail DAT mutation.",
    },
}
DISPLAY_BASE = 210
DEFAULT_SCREEN_SIZE = "1024x768x24"
CFG_LAYOUTS = {
    "th07": {
        "filename": "th07.cfg",
        "size": 0x38,
        "version": 0x70002,
        "shot_slow": 1,
        "music_volume": None,
        "sfx_volume": None,
        "opts_offset": 0x34,
    },
    "th08": {
        "filename": "th08.cfg",
        "size": 0x3C,
        "version": 0x80001,
        "shot_slow": 0,
        "music_volume": 100,
        "sfx_volume": 80,
        "opts_offset": 0x38,
    },
}
CFG_CONTROLLER_MAPPING = (0, 1, 2, 4, -1, -1, -1, -1, 3)
CFG_COLOR_MODE_OFFSET = 0x1E
CFG_WINDOWED_OFFSET = 0x22
CFG_FRAMESKIP_OFFSET = 0x23
CFG_OPTS_USE_SW_TEXTURE_BLENDING = 1 << 0
CFG_OPTS_DONT_USE_VERTEX_BUF = 1 << 1
CFG_OPTS_DISABLE_DEPTH_TEST = 1 << 6
CFG_OPTS_DISABLE_FOG = 1 << 10
CFG_OPTS_DISABLE_VSYNC = 1 << 14
CFG_SAFE_VIDEO_FLAGS = (
    CFG_OPTS_DONT_USE_VERTEX_BUF
    | CFG_OPTS_DISABLE_DEPTH_TEST
    | CFG_OPTS_DISABLE_FOG
    | CFG_OPTS_DISABLE_VSYNC
)


def _utc_stamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def _family_config(family: str) -> dict[str, str]:
    config = FAMILY_CONFIGS.get(family)
    if config is None:
        raise ValueError(f"unsupported boss-read family: {family}")
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
) -> dict[str, Any]:
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
        raise RuntimeError("symex materializer did not return a JSON object")
    if record.get("status") != "sat":
        raise RuntimeError(f"symex path is not satisfiable: {record.get('status')}")
    fixture = record.get("fixture")
    if not isinstance(fixture, dict) or fixture.get("matchesPath") != "true":
        raise RuntimeError(f"symex fixture did not replay into the requested path: {fixture!r}")
    return record


def _find_archive_entry(archive: RetailArchive, seed_name: str) -> str:
    wanted = seed_name.lower()
    for name in archive.names():
        basename = name.replace("\\", "/").rsplit("/", 1)[-1].lower()
        if basename == wanted:
            return name
    raise KeyError(seed_name)


def _choose_display(base: int = DISPLAY_BASE) -> str:
    x11_root = Path("/tmp/.X11-unix")
    for value in range(base, base + 100):
        if not (x11_root / f"X{value}").exists():
            return f":{value}"
    raise RuntimeError(f"could not find a free X display starting at {base}")


def _wine_environment(prefix: Path, display: str | None = None) -> dict[str, str]:
    environment = os.environ.copy()
    environment.update(
        {
            "WINEPREFIX": str(prefix.resolve()),
            "WINEARCH": "win32",
            "WINEDEBUG": "-all",
            "WINEDLLOVERRIDES": "mscoree,mshtml=",
            "LANG": "ja_JP.UTF-8",
            "LC_ALL": "ja_JP.UTF-8",
            "MESA_GLTHREAD": "false",
            "LIBGL_ALWAYS_SOFTWARE": "1",
        }
    )
    if display is not None:
        environment["DISPLAY"] = display
    return environment


def _start_xvfb(artifact_dir: Path, display: str, screen_size: str) -> tuple[subprocess.Popen[bytes], Any]:
    log_path = artifact_dir / "xvfb.log"
    log_handle = log_path.open("wb")
    try:
        process = subprocess.Popen(
            ["Xvfb", display, "-screen", "0", screen_size, "-nolisten", "tcp"],
            stdin=subprocess.DEVNULL,
            stdout=log_handle,
            stderr=subprocess.STDOUT,
        )
    except BaseException:
        log_handle.close()
        raise
    time.sleep(0.5)
    if process.poll() is not None:
        log_handle.close()
        raise RuntimeError(f"Xvfb exited early with {process.returncode}")
    return process, log_handle


def _capture_size(screen_size: str) -> str:
    parts = screen_size.split("x")
    if len(parts) != 3:
        raise ValueError("screen size must be WIDTHxHEIGHTxDEPTH")
    width, height, _depth = parts
    return f"{int(width)}x{int(height)}"


def _capture_screenshot(display: str, artifact_dir: Path, name: str, screen_size: str) -> str | None:
    screenshot = artifact_dir / f"{name}.png"
    completed = subprocess.run(
        [
            "ffmpeg",
            "-loglevel",
            "error",
            "-y",
            "-f",
            "x11grab",
            "-video_size",
            _capture_size(screen_size),
            "-i",
            display,
            "-frames:v",
            "1",
            str(screenshot),
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return str(screenshot.resolve()) if completed.returncode == 0 and screenshot.is_file() else None


def _inspect_screenshot(path: str) -> dict[str, object]:
    screenshot = Path(path)
    completed = subprocess.run(
        [
            "ffmpeg",
            "-loglevel",
            "error",
            "-i",
            str(screenshot),
            "-f",
            "rawvideo",
            "-pix_fmt",
            "rgb24",
            "-",
        ],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if completed.returncode != 0 or not completed.stdout:
        return {
            "path": str(screenshot.resolve()),
            "sha256": sha256_bytes(screenshot.read_bytes()) if screenshot.is_file() else None,
            "decoded": False,
        }
    raw = completed.stdout
    pixel_count = len(raw) // 3
    nonblack_pixels = 0
    for offset in range(0, pixel_count * 3, 3):
        if raw[offset] != 0 or raw[offset + 1] != 0 or raw[offset + 2] != 0:
            nonblack_pixels += 1
    return {
        "path": str(screenshot.resolve()),
        "sha256": sha256_bytes(screenshot.read_bytes()),
        "decoded": True,
        "pixel_count": pixel_count,
        "nonblack_pixels": nonblack_pixels,
        "black_ratio": 1.0 - (nonblack_pixels / pixel_count if pixel_count else 0.0),
        "max_byte": max(raw),
        "mean_byte": sum(raw) / len(raw),
    }


def _summarize_screenshots(paths: list[str]) -> dict[str, object]:
    inspections = [_inspect_screenshot(path) for path in paths]
    decoded = [item for item in inspections if item.get("decoded") is True]
    all_black = bool(decoded) and all(
        isinstance(item.get("black_ratio"), float) and item["black_ratio"] >= 0.999
        for item in decoded
    )
    return {
        "count": len(paths),
        "decoded_count": len(decoded),
        "all_decoded_black": all_black,
        "captures": inspections,
    }


def _default_cfg_bytes(title: str) -> bytes:
    layout = CFG_LAYOUTS[title]
    cfg = bytearray(int(layout["size"]))
    for index, value in enumerate(CFG_CONTROLLER_MAPPING):
        cfg[index * 2 : index * 2 + 2] = struct.pack("<h", value)
    cfg[0x14:0x18] = struct.pack("<I", int(layout["version"]))
    cfg[0x18:0x1A] = struct.pack("<h", 600)
    cfg[0x1A:0x1C] = struct.pack("<h", 600)
    cfg[0x1C] = 2
    cfg[0x1D] = 3
    cfg[CFG_COLOR_MODE_OFFSET] = 0
    cfg[0x1F] = 1
    cfg[0x20] = 1
    cfg[0x21] = 1
    cfg[CFG_WINDOWED_OFFSET] = 0
    cfg[CFG_FRAMESKIP_OFFSET] = 0
    cfg[0x24] = 2
    cfg[0x25] = 0
    cfg[0x26] = int(layout["shot_slow"])
    if layout["music_volume"] is not None:
        cfg[0x27] = int(layout["music_volume"])
    if layout["sfx_volume"] is not None:
        cfg[0x28] = int(layout["sfx_volume"])
    opts_offset = int(layout["opts_offset"])
    cfg[opts_offset : opts_offset + 4] = struct.pack("<I", CFG_OPTS_USE_SW_TEXTURE_BLENDING)
    return bytes(cfg)


def prepare_retail_cfg(args: argparse.Namespace, game_dir: Path) -> dict[str, object]:
    layout = CFG_LAYOUTS[args.title]
    cfg_path = game_dir / str(layout["filename"])
    expected_size = int(layout["size"])
    before: bytes | None = None
    source = "generated-source-backed-default"
    if cfg_path.is_file():
        candidate = cfg_path.read_bytes()
        if len(candidate) == expected_size:
            before = candidate
            cfg = bytearray(candidate)
            source = "patched-existing"
        else:
            cfg = bytearray(_default_cfg_bytes(args.title))
            source = f"replaced-invalid-size-{len(candidate)}"
    else:
        cfg = bytearray(_default_cfg_bytes(args.title))

    cfg[CFG_WINDOWED_OFFSET] = 1 if args.cfg_windowed else 0
    if args.cfg_color_mode == "32bit":
        cfg[CFG_COLOR_MODE_OFFSET] = 0
    elif args.cfg_color_mode == "16bit":
        cfg[CFG_COLOR_MODE_OFFSET] = 1
    cfg[CFG_FRAMESKIP_OFFSET] = 0

    opts_offset = int(layout["opts_offset"])
    opts = struct.unpack("<I", cfg[opts_offset : opts_offset + 4])[0]
    opts |= CFG_OPTS_USE_SW_TEXTURE_BLENDING
    if args.cfg_safe_video_flags:
        opts |= CFG_SAFE_VIDEO_FLAGS
    cfg[opts_offset : opts_offset + 4] = struct.pack("<I", opts)

    cfg_path.write_bytes(cfg)
    return {
        "path": str(cfg_path.resolve()),
        "source": source,
        "size": len(cfg),
        "sha256": sha256_bytes(bytes(cfg)),
        "before_sha256": sha256_bytes(before) if before is not None else None,
        "windowed": cfg[CFG_WINDOWED_OFFSET],
        "colorMode16bit": cfg[CFG_COLOR_MODE_OFFSET],
        "frameskipConfig": cfg[CFG_FRAMESKIP_OFFSET],
        "opts_offset": opts_offset,
        "opts": opts,
        "safe_video_flags": args.cfg_safe_video_flags,
        "source_offsets": {
            "colorMode16bit": CFG_COLOR_MODE_OFFSET,
            "windowed": CFG_WINDOWED_OFFSET,
            "frameskipConfig": CFG_FRAMESKIP_OFFSET,
            "opts": opts_offset,
        },
    }


def _window_ids(display: str) -> list[str]:
    completed = subprocess.run(
        ["xdotool", "search", "--all", "--name", ".*"],
        env={**os.environ, "DISPLAY": display},
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
        check=False,
    )
    return [line.strip() for line in completed.stdout.splitlines() if line.strip()]


def _window_name(display: str, window_id: str) -> str:
    completed = subprocess.run(
        ["xdotool", "getwindowname", window_id],
        env={**os.environ, "DISPLAY": display},
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
        check=False,
    )
    return completed.stdout.strip()


def _wait_for_game_window(title: str, display: str, timeout_seconds: float) -> str:
    tokens = WINDOW_NAME_TOKENS[title]
    deadline = time.monotonic() + timeout_seconds
    last: list[tuple[str, str]] = []
    while time.monotonic() < deadline:
        last = [(window_id, _window_name(display, window_id)) for window_id in _window_ids(display)]
        for window_id, name in last:
            if any(token in name for token in tokens):
                return window_id
        time.sleep(0.05)
    raise TimeoutError(f"{title} retail window not found; last windows={last!r}")


def _tap(display: str, window_id: str, key: str, hold_seconds: float, settle_seconds: float) -> None:
    env = {**os.environ, "DISPLAY": display}
    subprocess.run(
        ["xdotool", "windowfocus", window_id],
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    subprocess.run(
        ["xdotool", "keydown", key],
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    time.sleep(hold_seconds)
    subprocess.run(
        ["xdotool", "keyup", key],
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True,
    )
    time.sleep(settle_seconds)


def _capture_window_census(display: str, artifact_dir: Path) -> dict[str, object]:
    windows = [
        {"window_id": window_id, "name": _window_name(display, window_id)}
        for window_id in _window_ids(display)
    ]
    names_path = artifact_dir / "window-names.txt"
    census_path = artifact_dir / "window-census.json"
    names_path.write_text(
        "\n".join(window["name"] for window in windows) + ("\n" if windows else ""),
        encoding="utf-8",
    )
    census = {
        "display": display,
        "windows": windows,
        "window_names_path": str(names_path.resolve()),
    }
    census_path.write_text(json.dumps(census, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return census


def _summarize_wine_log(log_path: Path) -> dict[str, object]:
    text = log_path.read_text(encoding="utf-8", errors="replace") if log_path.is_file() else ""
    crash_lines: list[str] = []
    error_lines: list[str] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        lowered = line.lower()
        if any(token in lowered for token in ("unhandled page fault", "unhandled exception", "starting debugger")):
            if line not in crash_lines:
                crash_lines.append(line)
        elif "err:" in lowered and line not in error_lines:
            error_lines.append(line)
    return {
        "path": str(log_path.resolve()),
        "classification": "wine-crash-log" if crash_lines else "no-crash-signature",
        "primary_signature": crash_lines[0] if crash_lines else None,
        "crash_lines": crash_lines[:8],
        "error_lines": error_lines[:8],
    }


def _classify(census: dict[str, object], wine_log: dict[str, object], returncode: int | None, timed_out: bool) -> dict[str, object]:
    windows = census.get("windows") if isinstance(census.get("windows"), list) else []
    names = [
        window.get("name")
        for window in windows
        if isinstance(window, dict) and isinstance(window.get("name"), str)
    ]
    crash_titles = [
        name for name in names if any(token in name for token in ("プログラム エラー", "Program Error", "Wine Debugger"))
    ]
    if crash_titles:
        classification = "crash-dialog"
        interesting = True
    elif wine_log.get("classification") == "wine-crash-log":
        classification = "wine-crash-log"
        interesting = True
    elif returncode not in (None, 0):
        classification = "abnormal-exit"
        interesting = True
    elif any("東方" in name or "Touhou" in name for name in names):
        classification = "game-window-live"
        interesting = False
    elif timed_out:
        classification = "retail-timeout"
        interesting = False
    elif returncode == 0:
        classification = "clean-exit"
        interesting = False
    else:
        classification = "no-game-window"
        interesting = False
    return {
        "classification": classification,
        "interesting": interesting,
        "window_names": names,
        "crash_titles": crash_titles,
        "wine_log_classification": wine_log.get("classification"),
        "wine_log_primary_signature": wine_log.get("primary_signature"),
        "returncode": returncode,
        "timed_out": timed_out,
    }


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
    )
    fixture = symex_record["fixture"]
    fixture_hex = str(fixture["hex"])
    replacement = bytes.fromhex(fixture_hex)

    archive = RetailArchive.from_path(source_archive_path)
    entry_name = _find_archive_entry(archive, args.seed_name)
    source_payload = archive.extract(entry_name)
    source_payload_sha256 = sha256_bytes(source_payload)
    plain_payload, crypt_key = (
        th08_try_decrypt_blob(source_payload) if args.title == "th08" else (source_payload, None)
    )
    ecl = EclWireFile(args.title, plain_payload)
    timeline_site = None
    if args.sub_index is None and args.instruction_index is None and args.site_selection == "reachable-timeline-spawn":
        selected = ecl.timeline_spawn_patch_site(
            len(replacement),
            active_mask=args.active_mask,
        )
        site = selected.raw_site
        timeline_site = selected.timeline_site
    else:
        site = ecl.select_patch_site(
            len(replacement),
            sub_index=args.sub_index,
            instruction_index=args.instruction_index,
        )
    plain_mutant_payload = ecl.patch_raw_instruction(site, replacement)
    payload = (
        th08_encrypt_blob(plain_mutant_payload, crypt_key)
        if crypt_key is not None
        else plain_mutant_payload
    )
    payload_sha256 = sha256_bytes(payload)
    config = _family_config(args.family)
    artifact_label = config["artifact_label"]

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
        "case_name": f"formal-{args.title}-{artifact_label}-{args.symex_path}",
        "mutant_name": (
            f"{artifact_label}-{args.symex_path}-s{site.sub_index:02d}-i{site.instruction_index:04d}"
        ),
        "source_game_dir": str(source_game_dir),
        "source_archive": str(source_archive_path),
        "source_archive_sha256": sha256_bytes(source_archive_path.read_bytes()),
        "source_payload_sha256": source_payload_sha256,
        "source_plain_payload_sha256": sha256_bytes(plain_payload),
        "seed_name": entry_name,
        "override_dir": str((source_result_dir / "override").resolve()),
        "payload_sha256": payload_sha256,
        "symex": symex_record,
        "mutation_metadata": {
            "family": config["mutation_family"],
            "boss_read_family": args.family,
            "symex_path": args.symex_path,
            "active_mask": args.active_mask,
            "override_mask": args.override_mask,
            "site_selection": args.site_selection,
            "fixture_hex": fixture_hex,
            "fixture_size": len(replacement),
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
                "hex": fixture_hex,
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
            "Retail execution is a black-box Wine probe for TH07/TH08, not yet the TH06 address-level oracle.",
        ],
    }
    result_path = source_result_dir / "result.json"
    result_path.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return result_path


def _copy_game_tree(source_game_dir: Path, destination_game_dir: Path) -> None:
    if destination_game_dir.exists():
        raise FileExistsError(f"destination game directory already exists: {destination_game_dir}")
    shutil.copytree(source_game_dir, destination_game_dir)


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


def run_wine_probe(args: argparse.Namespace, game_dir: Path, artifact_dir: Path) -> dict[str, object]:
    executable = game_dir / EXECUTABLE_NAMES[args.title]
    if not executable.is_file():
        raise FileNotFoundError(executable)
    prefix = artifact_dir / "prefix"
    prefix.mkdir(parents=True, exist_ok=True)
    display = _choose_display()
    wineboot_log = artifact_dir / "wineboot.log"
    wine_log = artifact_dir / "wine.log"
    xvfb_process = None
    xvfb_log_handle = None
    game_process = None
    timed_out = False
    returncode: int | None = None
    control_error: str | None = None
    census: dict[str, object] = {"windows": []}
    screenshots: list[str] = []
    started = time.time()
    try:
        xvfb_process, xvfb_log_handle = _start_xvfb(artifact_dir, display, args.xvfb_screen_size)
        environment = _wine_environment(prefix, display)
        with wineboot_log.open("wb") as log_handle:
            completed = subprocess.run(
                ["wineboot", "-u"],
                env=environment,
                stdin=subprocess.DEVNULL,
                stdout=log_handle,
                stderr=subprocess.STDOUT,
                timeout=60,
                check=False,
            )
        if completed.returncode != 0:
            raise RuntimeError(f"wineboot failed with {completed.returncode}")
        with wine_log.open("wb") as log_handle:
            game_process = subprocess.Popen(
                ["wine", executable.name],
                cwd=game_dir,
                env=environment,
                stdin=subprocess.DEVNULL,
                stdout=log_handle,
                stderr=subprocess.STDOUT,
            )
            try:
                window_id = _wait_for_game_window(args.title, display, args.startup_seconds)
                if args.window_settle_seconds > 0:
                    time.sleep(args.window_settle_seconds)
                launch_screenshot = _capture_screenshot(
                    display,
                    artifact_dir,
                    "probe-00-launch-window",
                    args.xvfb_screen_size,
                )
                if launch_screenshot is not None:
                    screenshots.append(launch_screenshot)
                for key in args.keys:
                    if game_process.poll() is not None:
                        break
                    _tap(display, window_id, key, args.key_hold_seconds, args.key_settle_seconds)
                after_input_screenshot = _capture_screenshot(
                    display,
                    artifact_dir,
                    "probe-01-after-input",
                    args.xvfb_screen_size,
                )
                if after_input_screenshot is not None:
                    screenshots.append(after_input_screenshot)
            except Exception as exc:
                control_error = f"{type(exc).__name__}: {exc}"
            deadline = time.monotonic() + args.post_input_wait_seconds
            while time.monotonic() < deadline:
                if game_process.poll() is not None:
                    break
                census = _capture_window_census(display, artifact_dir)
                names = [
                    window.get("name")
                    for window in census.get("windows", [])
                    if isinstance(window, dict)
                ]
                if any(
                    isinstance(name, str)
                    and any(token in name for token in ("プログラム エラー", "Program Error", "Wine Debugger"))
                    for name in names
                ):
                    break
                time.sleep(0.25)
            returncode = game_process.poll()
            if returncode is None:
                timed_out = True
            census = _capture_window_census(display, artifact_dir)
            final_screenshot = _capture_screenshot(
                display,
                artifact_dir,
                "probe-02-final",
                args.xvfb_screen_size,
            )
            if final_screenshot is not None:
                screenshots.append(final_screenshot)
    finally:
        subprocess.run(
            ["wineserver", "-k"],
            env=_wine_environment(prefix, display if "display" in locals() else None),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if game_process is not None and game_process.poll() is None:
            game_process.kill()
            game_process.wait(timeout=5)
        subprocess.run(
            ["wineserver", "-w"],
            env=_wine_environment(prefix, display if "display" in locals() else None),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if xvfb_process is not None:
            xvfb_process.terminate()
            try:
                xvfb_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                xvfb_process.kill()
                xvfb_process.wait(timeout=5)
        if xvfb_log_handle is not None:
            xvfb_log_handle.close()

    wine_summary = _summarize_wine_log(wine_log)
    oracle = _classify(census, wine_summary, returncode, timed_out)
    screenshot_summary = _summarize_screenshots(screenshots)
    if (
        oracle["classification"] == "game-window-live"
        and screenshot_summary.get("all_decoded_black") is True
    ):
        oracle = {**oracle, "classification": "game-window-live-black-screen", "interesting": False}
    if control_error is not None and oracle["classification"] not in ("crash-dialog", "wine-crash-log"):
        oracle = {**oracle, "classification": "retail-control-error", "interesting": False}
    report = {
        "mode": "generic-new-game-key-probe",
        "title": args.title,
        "command": ["wine", executable.name],
        "cwd": str(game_dir.resolve()),
        "display": display,
        "wine_prefix": str(prefix.resolve()),
        "wineboot_log": str(wineboot_log.resolve()),
        "wine_log": str(wine_log.resolve()),
        "keys": args.keys,
        "returncode": returncode,
        "timed_out": timed_out,
        "control_error": control_error,
        "screenshots": screenshots,
        "screenshot_summary": screenshot_summary,
        "elapsed_seconds": time.time() - started,
        "window_census": census,
        "wine_summary": wine_summary,
        "oracle": oracle,
    }
    (artifact_dir / "wine-probe.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return report


def parse_args(
    argv: list[str] | None = None,
    *,
    default_family: str = DEFAULT_FAMILY,
) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Lower a boss-read symbolic witness into a TH07/TH08 retail DAT mutation."
    )
    parser.add_argument("title", choices=("th07", "th08"))
    parser.add_argument("--family", choices=tuple(FAMILY_CONFIGS), default=default_family)
    parser.add_argument("--source-game-dir", type=Path)
    parser.add_argument("--artifact-dir", type=Path)
    parser.add_argument("--symex-path")
    parser.add_argument("--active-mask", type=int, default=DEFAULT_ACTIVE_MASK)
    parser.add_argument("--override-mask", type=int, default=DEFAULT_OVERRIDE_MASK)
    parser.add_argument("--seed-name", default="ecldata1.ecl")
    parser.add_argument("--sub-index", type=int)
    parser.add_argument("--instruction-index", type=int)
    parser.add_argument(
        "--site-selection",
        choices=("reachable-timeline-spawn", "sub-first", "any-first"),
        default="reachable-timeline-spawn",
        help="raw instruction site selector when --sub-index/--instruction-index are not supplied",
    )
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--run-wine", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument("--startup-seconds", type=float, default=10.0)
    parser.add_argument("--window-settle-seconds", type=float, default=5.0)
    parser.add_argument("--post-input-wait-seconds", type=float, default=12.0)
    parser.add_argument("--key-hold-seconds", type=float, default=0.03)
    parser.add_argument("--key-settle-seconds", type=float, default=0.35)
    parser.add_argument("--xvfb-screen-size", default=DEFAULT_SCREEN_SIZE)
    parser.add_argument(
        "--cfg-windowed",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="write a valid retail cfg before Wine launch and set the windowed flag",
    )
    parser.add_argument(
        "--cfg-color-mode",
        choices=("32bit", "16bit", "preserve"),
        default="32bit",
        help="colorMode16bit value written into the retail cfg",
    )
    parser.add_argument(
        "--cfg-safe-video-flags",
        action="store_true",
        help="also set no-vertex-buffer/depth/fog/vsync compatibility flags in the retail cfg",
    )
    parser.add_argument(
        "--keys",
        nargs="+",
        default=["z", "z", "Down", "Down", "Down", "z", "z", "z", "z", "z", "z"],
        help="xdotool key sequence used by the generic new-game probe",
    )
    args = parser.parse_args(argv)
    if args.symex_path is None:
        args.symex_path = str(_family_config(args.family)["default_symex_path"])
    if args.source_game_dir is None:
        args.source_game_dir = DEFAULT_SOURCE_GAME_DIRS[args.title]
    if args.artifact_dir is None:
        args.artifact_dir = _default_artifact_dir(args.title, args.family, args.symex_path)
    if args.active_mask < 0 or args.active_mask > 255:
        raise ValueError("--active-mask must fit in a byte")
    if args.override_mask < 0 or args.override_mask > 255:
        raise ValueError("--override-mask must fit in a byte")
    if args.site_selection == "any-first" and args.sub_index is None:
        args.sub_index = -1
    return args


def main(
    argv: list[str] | None = None,
    *,
    default_family: str = DEFAULT_FAMILY,
) -> int:
    args = parse_args(argv, default_family=default_family)
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
