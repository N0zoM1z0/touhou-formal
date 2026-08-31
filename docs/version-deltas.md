# ECL Version Deltas

The first cross-title Lean data lives in `TouhouFormal.ECL.HeaderShape` and the
title-specific `Wire.lean` modules. Shared loader, timeline-prefix, and subTable
lookup semantics now consume these profiles directly.

## Initial Profiles

| Title | Header | Loader timeline slots | Timeline prefix | Raw instruction prefix | Version gate | Negative `CallEclSub` id |
| --- | ---: | ---: | --- | --- | --- | --- |
| TH06 | `0x10` | 1 of 3 | `i16 time`, `i16 arg0`, `i16 opcode`, `i16 size` | `i32 time`, `i16 opcode`, `i16 offsetToNext`, difficulty byte | none observed | unchecked |
| TH07 | `0x44` | 16 of 16 | `i16 time`, `i16 arg0`, `i16 opcode`, `i16 size` | `u32 time`, `i16 opcode`, `i16 size`, difficulty byte, `u16 paramMask` | none observed | unchecked |
| TH08 | `0x48` | 16 of 16 | `i32 time`, `i16 opcode`, `u8 size`, `args.ints[0]` first operand | `i32 time`, `i16 opcode`, `i16 nextOffset`, difficulty byte, `u16 operandFlags` | must equal `0x800` | successful no-op |

## Modeling Impact

The TH06/TH07 negative-sub-id path should be a table-underflow fault in the
first-operation model. TH08 differs: negative ids return `ZUN_SUCCESS` before
the table read, so upper-bound checks remain interesting but negative ids are
not counterexamples for that specific boundary.

These deltas matter for any SMT generator. A property proved for TH06's
`CallEclSub` cannot be copied to TH08 without carrying the negative-id policy.

Lean currently checks these deltas as executable theorems: TH06 raw bytes flow
through the shared loader/decoder/lookup path, TH07 preserves unchecked negative
lookup, and TH08 rejects wrong versions before rebasing and treats negative
sub ids as no-ops.
