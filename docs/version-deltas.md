# ECL Version Deltas

The first cross-title Lean data lives in `TouhouFormal.ECL.HeaderShape` and the
title-specific `Wire.lean` modules. These are source-backed facts, not a shared
semantic model yet.

## Initial Profiles

| Title | Fixed header bytes | Timeline slots | Version gate | Negative `CallEclSub` id |
| --- | ---: | ---: | --- | --- |
| TH06 | `0x10` | 3 | none observed | unchecked |
| TH07 | `0x44` | 16 | none observed | unchecked |
| TH08 | `0x48` | 16 | must equal `0x800` | successful no-op |

## Modeling Impact

The TH06/TH07 negative-sub-id path should be a table-underflow fault in the
first-operation model. TH08 differs: negative ids return `ZUN_SUCCESS` before
the table read, so upper-bound checks remain interesting but negative ids are
not counterexamples for that specific boundary.

These deltas matter for any SMT generator. A property proved for TH06's
`CallEclSub` cannot be copied to TH08 without carrying the negative-id policy.
