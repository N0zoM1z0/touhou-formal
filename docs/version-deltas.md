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

## Primary Bullet-Pattern Family

| Title | Opcodes | Bullet type | Dead enemy | Rank/clamp during spellcard | Shooting gate | Extra pre-dispatch filters |
| --- | --- | --- | --- | --- | --- | --- |
| TH06 | 67–75 | raw packed i16 | still builds descriptor | always applied | descriptor written, spawn suppressed | primary angle normalized |
| TH07 | 64–72 | mask-controlled resolver | skipped | bypassed | descriptor written, spawn suppressed | none |
| TH08 | 96–104 | mask-controlled resolver | skipped | bypassed | raw `0x2c` instruction copied for later dispatch | player alignment, then minimum distance |

All three ranges share the same semantic operand order and use
`opcode - firstOpcode` for aim mode. The Lean profile therefore stores one
range per title rather than nine independently maintained opcode records.

## Callback Configuration

| Title | Death sub input | Life callbacks | Timer callback | Periodic callback | Presentation guard |
| --- | --- | --- | --- | --- | --- |
| TH06 | raw i32 | one scalar threshold/sub pair | separate raw threshold/sub; threshold resets timer | none | none |
| TH07 | zero-extended raw byte | four slots; legacy slot-0 setters plus indexed pair | separate resolved threshold/sub | interval, sub id, counter reset, context-arg snapshot | none |
| TH08 | raw u16 assigned to signed i16 | one indexed four-slot pair | combined threshold/sub and timer reset | none | may suppress death/sub-id writes while retaining threshold/reset writes |

TH07/TH08 indexed life configuration re-evaluates the index expression for
each array write. The shared model therefore records resolver occurrences
instead of assuming one cached index.

## Interrupt Entry

| Title | Table | Operand policy | Stored sub/index width | Save-disable flag | Negative selected sub |
| --- | ---: | --- | --- | --- | --- |
| TH06 | 8 entries | raw i32 | i32 | `disableCallStack` bit | unchecked subTable read |
| TH07 | 32 entries | mask-resolved i32 | i32 | `noStackRet` bit | unchecked subTable read |
| TH08 | 32 entries | flag-resolved i32 | signed i16 | `disableEclCallStack` bit | `CallEclSub` no-op |

Every handler advances the current instruction first. When saving is enabled,
that advanced context is written before the unchecked interrupt-table read.
All three increment depth after a successful/no-op `CallEclSub` even when the
save-disable flag prevented the corresponding stack write.
