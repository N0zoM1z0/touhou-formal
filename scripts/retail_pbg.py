#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
import hashlib
from pathlib import Path
from typing import Mapping, Sequence


class PbgError(ValueError):
    """Raised when a TH07/TH08 retail archive cannot be decoded."""


@dataclass(frozen=True)
class PbgEntry:
    raw_name: bytes
    data_offset: int
    decompressed_size: int
    metadata: int

    @property
    def name(self) -> str:
        return self.raw_name.decode("ascii")


class _BitReader:
    def __init__(self, data: bytes) -> None:
        self._data = data
        self._bit_offset = 0

    def read_bits(self, count: int) -> int:
        if count < 0:
            raise PbgError("negative bit count")
        value = 0
        for _ in range(count):
            if self._bit_offset >= len(self._data) * 8:
                bit = 0
            else:
                byte = self._data[self._bit_offset // 8]
                bit = (byte >> (7 - self._bit_offset % 8)) & 1
            value = (value << 1) | bit
            self._bit_offset += 1
        return value


class _BitWriter:
    def __init__(self) -> None:
        self._output = bytearray()
        self._current = 0
        self._count = 0

    def write_bits(self, value: int, count: int) -> None:
        if count < 0:
            raise ValueError("negative bit count")
        for shift in range(count - 1, -1, -1):
            self._current = (self._current << 1) | ((value >> shift) & 1)
            self._count += 1
            if self._count == 8:
                self._output.append(self._current)
                self._current = 0
                self._count = 0

    def finish(self) -> bytes:
        if self._count:
            self._output.append(self._current << (8 - self._count))
            self._current = 0
            self._count = 0
        return bytes(self._output)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def lzss_decode(data: bytes, expected_size: int) -> bytes:
    reader = _BitReader(data)
    dictionary = bytearray(1 << 13)
    dictionary_head = 1
    output = bytearray()

    def write_byte(value: int) -> None:
        nonlocal dictionary_head
        if len(output) >= expected_size:
            raise PbgError("LZSS stream expands past the declared output size")
        output.append(value & 0xFF)
        dictionary[dictionary_head] = value & 0xFF
        dictionary_head = (dictionary_head + 1) & 0x1FFF

    while True:
        flag = reader.read_bits(1)
        if flag:
            write_byte(reader.read_bits(8))
            continue

        match_offset = reader.read_bits(13)
        if match_offset == 0:
            break
        match_length = reader.read_bits(4) + 3
        for index in range(match_length):
            write_byte(dictionary[(match_offset + index) & 0x1FFF])

    if len(output) != expected_size:
        raise PbgError(
            f"LZSS size mismatch: got {len(output)}, expected {expected_size}"
        )
    return bytes(output)


def lzss_encode_literal(data: bytes) -> bytes:
    writer = _BitWriter()
    for byte in data:
        writer.write_bits(1, 1)
        writer.write_bits(byte, 8)
    writer.write_bits(0, 1)
    writer.write_bits(0, 13)
    return writer.finish()


def th08_decrypt(data: bytes, xor_value: int, xor_inc: int, chunk_size: int, max_bytes: int) -> bytes:
    out = bytearray(len(data))
    in_cursor = 0
    out_cursor = 0
    size = len(data)
    num_unencrypted = size % chunk_size if size % chunk_size < chunk_size // 4 else 0
    num_unencrypted += size & 1
    size -= num_unencrypted

    while size > 0 and max_bytes > 0:
        current_chunk = min(chunk_size, size)
        out_cursor_backup = out_cursor
        write_cursor = out_cursor + current_chunk - 1
        for _ in range((current_chunk + 1) // 2):
            out[write_cursor] = data[in_cursor] ^ xor_value
            write_cursor -= 2
            in_cursor += 1
            xor_value = (xor_value + xor_inc) & 0xFF

        write_cursor = out_cursor_backup + current_chunk - 2
        for _ in range(current_chunk // 2):
            out[write_cursor] = data[in_cursor] ^ xor_value
            write_cursor -= 2
            in_cursor += 1
            xor_value = (xor_value + xor_inc) & 0xFF

        size -= current_chunk
        out_cursor = out_cursor_backup + current_chunk
        max_bytes -= current_chunk

    size += num_unencrypted
    if size > 0:
        out[out_cursor:out_cursor + size] = data[in_cursor:in_cursor + size]
    return bytes(out)


def th08_encrypt(plain: bytes, xor_value: int, xor_inc: int, chunk_size: int, max_bytes: int) -> bytes:
    out = bytearray(len(plain))
    in_cursor = 0
    out_cursor = 0
    size = len(plain)
    num_unencrypted = size % chunk_size if size % chunk_size < chunk_size // 4 else 0
    num_unencrypted += size & 1
    size -= num_unencrypted

    while size > 0 and max_bytes > 0:
        current_chunk = min(chunk_size, size)
        out_cursor_backup = out_cursor
        read_cursor = out_cursor + current_chunk - 1
        for _ in range((current_chunk + 1) // 2):
            out[in_cursor] = plain[read_cursor] ^ xor_value
            read_cursor -= 2
            in_cursor += 1
            xor_value = (xor_value + xor_inc) & 0xFF

        read_cursor = out_cursor_backup + current_chunk - 2
        for _ in range(current_chunk // 2):
            out[in_cursor] = plain[read_cursor] ^ xor_value
            read_cursor -= 2
            in_cursor += 1
            xor_value = (xor_value + xor_inc) & 0xFF

        size -= current_chunk
        out_cursor = out_cursor_backup + current_chunk
        max_bytes -= current_chunk

    size += num_unencrypted
    if size > 0:
        out[in_cursor:in_cursor + size] = plain[out_cursor:out_cursor + size]
    return bytes(out)


TH08_CRYPT_SIGNATURE = bytes((0x85 - 0x20, 0xA4 - 0x40, 0xDA - 0x60))
TH08_DECRYPT_PARAMS = (
    (0x5D, 0x1B, 0x37, 0x0040, 0x2800),
    (0x74, 0x51, 0xE9, 0x0040, 0x3000),
    (0x71, 0xC1, 0x51, 0x1400, 0x2000),
    (0x8A, 0x03, 0x19, 0x1400, 0x7800),
    (0x95, 0xAB, 0xCD, 0x0200, 0x1000),
    (0xB7, 0x12, 0x34, 0x0400, 0x2800),
    (0x9D, 0x35, 0x97, 0x0080, 0x2800),
    (0xAA, 0x99, 0x37, 0x0400, 0x1000),
)


def th08_try_decrypt_blob(data: bytes) -> tuple[bytes, int | None]:
    if len(data) < 4 or data[:3] != TH08_CRYPT_SIGNATURE:
        return data, None
    for index, (key, xor_value, xor_inc, chunk_size, max_bytes) in enumerate(TH08_DECRYPT_PARAMS):
        encoded_key = (key - (index << 4) - 0x10) & 0xFF
        if data[3] == encoded_key:
            return th08_decrypt(data[4:], xor_value, xor_inc, chunk_size, max_bytes), index
    return data, None


def th08_encrypt_blob(plain: bytes, key_index: int) -> bytes:
    key, xor_value, xor_inc, chunk_size, max_bytes = TH08_DECRYPT_PARAMS[key_index]
    encoded_key = (key - (key_index << 4) - 0x10) & 0xFF
    return TH08_CRYPT_SIGNATURE + bytes((encoded_key,)) + th08_encrypt(
        plain,
        xor_value,
        xor_inc,
        chunk_size,
        max_bytes,
    )


def _u32(data: bytes, offset: int) -> int:
    if offset < 0 or offset + 4 > len(data):
        raise PbgError(f"truncated u32 at {offset:#x}")
    return int.from_bytes(data[offset:offset + 4], "little", signed=False)


def _i32(data: bytes, offset: int) -> int:
    if offset < 0 or offset + 4 > len(data):
        raise PbgError(f"truncated i32 at {offset:#x}")
    return int.from_bytes(data[offset:offset + 4], "little", signed=True)


def _table_entries(table: bytes, count: int, sentinel_offset: int) -> tuple[tuple[PbgEntry, ...], bytes]:
    entries: list[PbgEntry] = []
    cursor = 0
    for _ in range(count):
        end = table.find(b"\0", cursor)
        if end < 0:
            raise PbgError("unterminated archive table filename")
        raw_name = table[cursor:end]
        cursor = end + 1
        data_offset = _u32(table, cursor)
        decompressed_size = _u32(table, cursor + 4)
        metadata = _u32(table, cursor + 8)
        cursor += 12
        try:
            raw_name.decode("ascii")
        except UnicodeDecodeError as exc:
            raise PbgError(f"archive filename is not ASCII: {raw_name!r}") from exc
        entries.append(PbgEntry(raw_name, data_offset, decompressed_size, metadata))

    padding = table[cursor:]
    if any(padding):
        raise PbgError(f"archive table has {len(padding)} non-zero trailing bytes")
    data_offsets = [entry.data_offset for entry in entries] + [sentinel_offset]
    if any(left >= right for left, right in zip(data_offsets, data_offsets[1:], strict=False)):
        raise PbgError("archive entry data offsets are not strictly increasing")
    return tuple(entries), padding


def _render_table(entries: Sequence[PbgEntry]) -> bytes:
    output = bytearray()
    for entry in entries:
        output += entry.raw_name + b"\0"
        output += int(entry.data_offset).to_bytes(4, "little")
        output += int(entry.decompressed_size).to_bytes(4, "little")
        output += int(entry.metadata).to_bytes(4, "little")
    return bytes(output)


def _entry_key(value: str | bytes) -> bytes:
    raw = value if isinstance(value, bytes) else value.encode("ascii")
    raw = raw.replace(b"\\", b"/")
    return raw.rsplit(b"/", 1)[-1].lower()


@dataclass(frozen=True)
class RetailArchive:
    kind: str
    data: bytes
    entries: tuple[PbgEntry, ...]
    table_offset: int
    table_padding: bytes = b""

    @classmethod
    def from_bytes(cls, data: bytes) -> "RetailArchive":
        if data[:4] == b"PBG4":
            count = _u32(data, 4)
            table_offset = _u32(data, 8)
            table_size = _u32(data, 12)
            if count <= 0 or table_offset >= len(data) or table_offset < 16:
                raise PbgError("invalid TH07 PBG4 header")
            table = lzss_decode(data[table_offset:], table_size)
            entries, padding = _table_entries(table, count, table_offset)
            return cls("th07-pbg4", data, entries, table_offset, padding)

        if data[:4] == b"PBGZ":
            header = th08_decrypt(data[4:16], 0x1B, 0x37, 12, 0x400)
            count = _i32(header, 0) - 123456
            table_offset = _i32(header, 4) - 345678
            table_size = _i32(header, 8) - 567891
            if count <= 0 or table_offset >= len(data) or table_offset < 16:
                raise PbgError("invalid TH08 PBGZ header")
            encrypted_table = data[table_offset:]
            compressed_table = th08_decrypt(encrypted_table, 0x3E, 0x9B, 0x80, 0x400)
            table = lzss_decode(compressed_table, table_size)
            entries, padding = _table_entries(table, count, table_offset)
            return cls("th08-pbgz", data, entries, table_offset, padding)

        raise PbgError(f"unsupported archive magic: {data[:4]!r}")

    @classmethod
    def from_path(cls, path: Path) -> "RetailArchive":
        return cls.from_bytes(path.read_bytes())

    def _entry_index(self, name: str) -> int:
        wanted = _entry_key(name)
        for index, entry in enumerate(self.entries):
            if _entry_key(entry.raw_name) == wanted:
                return index
        raise KeyError(name)

    def _compressed_bounds(self, index: int) -> tuple[int, int]:
        entry = self.entries[index]
        next_offset = self.entries[index + 1].data_offset if index + 1 < len(self.entries) else self.table_offset
        return entry.data_offset, next_offset

    def names(self) -> list[str]:
        return [entry.name for entry in self.entries]

    def compressed_entry(self, index: int) -> bytes:
        start, end = self._compressed_bounds(index)
        return self.data[start:end]

    def extract(self, name: str) -> bytes:
        index = self._entry_index(name)
        entry = self.entries[index]
        return lzss_decode(self.compressed_entry(index), entry.decompressed_size)

    def replace(self, replacements: Mapping[str, bytes]) -> bytes:
        by_key = {_entry_key(name): payload for name, payload in replacements.items()}
        missing = sorted(
            key.decode("ascii", errors="replace")
            for key in by_key
            if all(_entry_key(entry.raw_name) != key for entry in self.entries)
        )
        if missing:
            raise KeyError(f"archive is missing replacement entries: {missing}")

        compressed_blobs: list[bytes] = []
        rebuilt_entries: list[PbgEntry] = []
        cursor = 16
        for index, entry in enumerate(self.entries):
            payload = by_key.get(_entry_key(entry.raw_name))
            if payload is None:
                compressed = self.compressed_entry(index)
                decompressed_size = entry.decompressed_size
            else:
                compressed = lzss_encode_literal(payload)
                decompressed_size = len(payload)
            compressed_blobs.append(compressed)
            rebuilt_entries.append(
                PbgEntry(
                    raw_name=entry.raw_name,
                    data_offset=cursor,
                    decompressed_size=decompressed_size,
                    metadata=entry.metadata,
                )
            )
            cursor += len(compressed)

        table = _render_table(rebuilt_entries) + self.table_padding
        compressed_table = lzss_encode_literal(table)
        if self.kind == "th07-pbg4":
            return (
                b"PBG4"
                + len(rebuilt_entries).to_bytes(4, "little")
                + cursor.to_bytes(4, "little")
                + len(table).to_bytes(4, "little")
                + b"".join(compressed_blobs)
                + compressed_table
            )

        header = (
            (len(rebuilt_entries) + 123456).to_bytes(4, "little", signed=True)
            + (cursor + 345678).to_bytes(4, "little", signed=True)
            + (len(table) + 567891).to_bytes(4, "little", signed=True)
        )
        return (
            b"PBGZ"
            + th08_encrypt(header, 0x1B, 0x37, 12, 0x400)
            + b"".join(compressed_blobs)
            + th08_encrypt(compressed_table, 0x3E, 0x9B, 0x80, 0x400)
        )


def replace_archive_entry(archive_path: Path, entry_name: str, payload: bytes) -> dict[str, object]:
    original = RetailArchive.from_path(archive_path)
    rebuilt = original.replace({entry_name: payload})
    archive_path.write_bytes(rebuilt)
    reparsed = RetailArchive.from_bytes(rebuilt)
    extracted = reparsed.extract(entry_name)
    if extracted != payload:
        raise PbgError(f"rebuilt archive does not reproduce {entry_name}")
    return {
        "archive": str(archive_path.resolve()),
        "archive_kind": reparsed.kind,
        "sha256": sha256_bytes(rebuilt),
        "entry_name": entry_name,
        "entry_size": len(payload),
    }
