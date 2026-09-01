# Roadmap

## Phase 0: Executable Counterexample Seed

Model the TH06 timeline spawn path from decoded timeline instruction to
`CallEclSub`. Prove that `arg0 = 256` with one subroutine is outside the sub
table and emit the same relation as an SMT query.

## Phase 1: Raw TH06 ECL Loader Model

Add little-endian byte decoding for the TH06 header, timeline records, and raw
ECL instruction headers. Preserve loader rebasing behavior and expose malformed
or undersized files as first-operation faults.

Current status: the byte reader and loader are shared ECL code, with TH06 raw
bytes already flowing through loader, timeline-prefix decoding, and shared
subTable lookup. Bounded loader checks also record first missing-byte faults for
undersized files. Timeline cursor advancement is now shared, with TH06 fixtures
covering zero-size nonprogress and negative-size before-buffer decode faults.
The cursor classifier now supports finite searches over relative jump
displacements.

## Phase 2: TH07 and TH08 Deltas

Encode title-specific differences:

- TH07 uses sixteen timeline pointers and a variable-argument raw instruction
  encoding with `paramMask`.
- TH08 adds an ECL version field, rebases sixteen timeline offsets, and treats
  negative `CallEclSub` ids as a successful no-op.

Current status: these deltas are profile facts consumed by shared Lean and SMT
checks. TH08's timeline prefix is represented as `i32 time`, `i16 opcode`,
`u8 size`, and `args.ints[0]` as the first spawn operand. Raw ECL instruction
prefixes are also decoded by one profile-driven decoder across TH06/TH07/TH08.
The first bounded call-policy sweep is shared across all three title profiles.
TH08 raw jump operands are now modeled through the same fixed i32 operand-slot
decoder used for TH06/TH07, while keeping operandFlags as resolver metadata.
The unconditional jump operand indices now live in the shared raw-instruction
profile rather than in title-specific proof fixtures.

## Phase 3: Rich VM Semantics

Add call/return stack behavior, jumps, arithmetic, divide/modulo checks,
host-indexed operations, enemy child contexts, and ANM interactions. Each new
host boundary should have an explicit assumption or a model.

Current status: the shared ECL body now includes control flow, arithmetic,
randoms, movement, time/wait controls, primary bullet patterns, bullet-control
host effects, laser spawn descriptors, laser slot controls, enemy state, enemy
lifecycle spawn/remove requests, item/drop requests, callbacks, interrupts,
boss reads, and the first ECL-to-ANM bridge layer. ANM bridge coverage
currently records
primary VM host calls, packed move/death animation fields, TH08 primary script
tables, bank flag writes, primary/secondary pending interrupts, secondary slot
host calls/clears, high-index diagnostics, negative/high slot faults, and
rotation-Z writes.

## Phase 4: Search and Validation

Generate solver queries from the Lean-side relation where practical. Keep
handwritten SMT only for small audit-friendly seeds. Convert solver models into
script mutations and validate selected cases on retail binaries under Wine.

## Phase 5: Beyond Traditional Danmaku

Use the same transition-system interface for ANM and other script-like game
systems, including nontraditional bullet-hell designs where scripts manipulate
timelines, entities, or visual state without a standard enemy-bullet loop.

Current status: ANM has a shared entry-header decoder and title profiles for
TH06/TH07/TH08. Full ANM script execution is intentionally not modeled yet.
