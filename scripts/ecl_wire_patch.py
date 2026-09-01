#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence


class EclWireError(ValueError):
    """Raised when an ECL file cannot be patched in place."""


@dataclass(frozen=True)
class RawInstructionSite:
    sub_index: int
    instruction_index: int
    file_offset: int
    time: int
    opcode: int
    size: int
    difficulty_mask: int
    operand_mask: int


@dataclass(frozen=True)
class TimelineSite:
    timeline_index: int
    instruction_index: int
    file_offset: int
    time: int
    opcode: int
    size: int
    first_arg: int | None
    difficulty_mask: int | None


@dataclass(frozen=True)
class TimelineSpawnPatchSite:
    timeline_site: TimelineSite
    raw_site: RawInstructionSite


def _i16(data: bytes, offset: int) -> int:
    if offset < 0 or offset + 2 > len(data):
        raise EclWireError(f"truncated i16 at {offset:#x}")
    return int.from_bytes(data[offset:offset + 2], "little", signed=True)


def _u8(data: bytes, offset: int) -> int:
    if offset < 0 or offset + 1 > len(data):
        raise EclWireError(f"truncated u8 at {offset:#x}")
    return data[offset]


def _u16(data: bytes, offset: int) -> int:
    if offset < 0 or offset + 2 > len(data):
        raise EclWireError(f"truncated u16 at {offset:#x}")
    return int.from_bytes(data[offset:offset + 2], "little", signed=False)


def _u32(data: bytes, offset: int) -> int:
    if offset < 0 or offset + 4 > len(data):
        raise EclWireError(f"truncated u32 at {offset:#x}")
    return int.from_bytes(data[offset:offset + 4], "little", signed=False)


def _i32(data: bytes, offset: int) -> int:
    if offset < 0 or offset + 4 > len(data):
        raise EclWireError(f"truncated i32 at {offset:#x}")
    return int.from_bytes(data[offset:offset + 4], "little", signed=True)


def _next_boundary(offset: int, boundaries: Sequence[int], payload_size: int) -> int:
    for boundary in boundaries:
        if boundary > offset:
            return boundary
    return payload_size


class EclWireFile:
    def __init__(self, title: str, data: bytes) -> None:
        if title not in ("th07", "th08"):
            raise EclWireError(f"unsupported ECL title: {title}")
        self.title = title
        self.data = data
        self.header_size = 0x44 if title == "th07" else 0x48
        if len(data) < self.header_size:
            raise EclWireError("ECL payload is smaller than the fixed header")
        if title == "th08" and _u32(data, 0) != 0x800:
            raise EclWireError(f"TH08 ECL version is {_u32(data, 0):#x}, expected 0x800")
        self.sub_count = _i16(data, 0 if title == "th07" else 4)
        self.timeline_count = _i16(data, 2 if title == "th07" else 6)
        if self.sub_count <= 0:
            raise EclWireError(f"invalid sub count: {self.sub_count}")
        if not 0 <= self.timeline_count <= 16:
            raise EclWireError(f"invalid timeline count: {self.timeline_count}")
        if len(data) < self.header_size + 4 * self.sub_count:
            raise EclWireError("ECL payload is smaller than its sub table")

        timeline_table = 4 if title == "th07" else 8
        self.timeline_offsets = tuple(_u32(data, timeline_table + 4 * index) for index in range(16))
        self.sub_offsets = tuple(_u32(data, self.header_size + 4 * index) for index in range(self.sub_count))
        all_offsets = [
            offset
            for offset in (*self.timeline_offsets, *self.sub_offsets)
            if offset != 0
        ]
        if any(offset > len(data) for offset in all_offsets):
            raise EclWireError("ECL table contains an offset outside the payload")
        self.boundaries = sorted(set(all_offsets + [len(data)]))

    def raw_instruction_sites(self) -> list[RawInstructionSite]:
        sites: list[RawInstructionSite] = []
        for sub_index, sub_offset in enumerate(self.sub_offsets):
            end = _next_boundary(sub_offset, self.boundaries, len(self.data))
            cursor = sub_offset
            instruction_index = 0
            while cursor + 12 <= end:
                size = _i16(self.data, cursor + 6)
                if size < 12 or cursor + size > end:
                    raise EclWireError(
                        f"invalid raw instruction size at {cursor:#x}: {size}"
                    )
                sites.append(
                    RawInstructionSite(
                        sub_index=sub_index,
                        instruction_index=instruction_index,
                        file_offset=cursor,
                        time=_i32(self.data, cursor),
                        opcode=_i16(self.data, cursor + 4),
                        size=size,
                        difficulty_mask=_u8(self.data, cursor + 9),
                        operand_mask=_u16(self.data, cursor + 10),
                    )
                )
                cursor += size
                instruction_index += 1
        return sites

    def timeline_sites(self) -> list[TimelineSite]:
        sites: list[TimelineSite] = []
        fixed_size = 0x20 if self.title == "th07" else 0x24
        for timeline_index, timeline_offset in enumerate(self.timeline_offsets[:self.timeline_count]):
            if timeline_offset == 0:
                continue
            end = _next_boundary(timeline_offset, self.boundaries, len(self.data))
            cursor = timeline_offset
            instruction_index = 0
            while cursor + 8 <= end:
                if self.title == "th07":
                    time = _i16(self.data, cursor)
                    opcode = _i16(self.data, cursor + 4)
                    size = _i16(self.data, cursor + 6)
                    first_arg = _i16(self.data, cursor + 2)
                    difficulty_mask = None
                else:
                    time = _i32(self.data, cursor)
                    opcode = _i16(self.data, cursor + 4)
                    size = _u8(self.data, cursor + 6)
                    difficulty_mask = _u8(self.data, cursor + 7)
                    first_arg = _i32(self.data, cursor + 8) if cursor + 12 <= end else None
                if size <= 0:
                    size = fixed_size
                if size < 8 or cursor + size > end:
                    raise EclWireError(
                        f"invalid timeline instruction size at {cursor:#x}: {size}"
                    )
                sites.append(
                    TimelineSite(
                        timeline_index=timeline_index,
                        instruction_index=instruction_index,
                        file_offset=cursor,
                        time=time,
                        opcode=opcode,
                        size=size,
                        first_arg=first_arg,
                        difficulty_mask=difficulty_mask,
                    )
                )
                cursor += size
                instruction_index += 1
                if time < 0:
                    break
        return sites

    def select_patch_site(
        self,
        replacement_size: int,
        *,
        sub_index: int | None = None,
        instruction_index: int | None = None,
    ) -> RawInstructionSite:
        sites = self.raw_instruction_sites()
        if sub_index is not None and instruction_index is not None:
            for site in sites:
                if site.sub_index == sub_index and site.instruction_index == instruction_index:
                    if site.size != replacement_size:
                        raise EclWireError(
                            "requested raw instruction site has size "
                            f"{site.size}, replacement has size {replacement_size}"
                        )
                    return site
            raise EclWireError(
                f"no raw instruction site sub={sub_index} instruction={instruction_index}"
            )
        for site in sites:
            if site.sub_index == (sub_index or 0) and site.size == replacement_size:
                return site
        for site in sites:
            if site.size == replacement_size:
                return site
        raise EclWireError(f"no raw instruction site with size {replacement_size}")

    def timeline_spawn_patch_site(
        self,
        replacement_size: int,
        *,
        active_mask: int | None = None,
    ) -> TimelineSpawnPatchSite:
        """Select an early raw patch site in a subroutine reached by timeline spawn.

        TH07 `EnemyManager::RunEclTimeline` spawns enemies for timeline opcodes
        0..7 and uses `arg0` as the ECL sub id. TH08 `EclTimeline::Run` uses
        `args.ints[0]` for opcodes 0, 1, 2, 3, 4, 5, 11, 12, and 15, with a
        timeline difficulty-mask gate before dispatch. This selector does not
        prove long-run reachability; it picks a source-backed stage-entry target
        instead of the first same-sized instruction in the file.
        """
        spawn_opcodes = (
            set(range(0, 8))
            if self.title == "th07"
            else {0, 1, 2, 3, 4, 5, 11, 12, 15}
        )
        raw_sites_by_sub: dict[int, list[RawInstructionSite]] = {}
        for site in self.raw_instruction_sites():
            raw_sites_by_sub.setdefault(site.sub_index, []).append(site)
        for timeline_site in sorted(
            self.timeline_sites(),
            key=lambda site: (site.time, site.timeline_index, site.instruction_index),
        ):
            if timeline_site.time < 0:
                continue
            if timeline_site.opcode not in spawn_opcodes:
                continue
            if (
                self.title == "th08"
                and active_mask is not None
                and timeline_site.difficulty_mask is not None
                and (timeline_site.difficulty_mask & active_mask) == 0
            ):
                continue
            sub_index = timeline_site.first_arg
            if sub_index is None or sub_index < 0 or sub_index >= self.sub_count:
                continue
            for raw_site in raw_sites_by_sub.get(sub_index, []):
                if raw_site.size == replacement_size:
                    return TimelineSpawnPatchSite(
                        timeline_site=timeline_site,
                        raw_site=raw_site,
                    )
        raise EclWireError(
            "no source-backed timeline-spawn raw instruction site with size "
            f"{replacement_size}"
        )

    def patch_raw_instruction(self, site: RawInstructionSite, replacement: bytes) -> bytes:
        if len(replacement) != site.size:
            raise EclWireError(
                f"replacement size {len(replacement)} does not match site size {site.size}"
            )
        output = bytearray(self.data)
        output[site.file_offset:site.file_offset + site.size] = replacement
        return bytes(output)
