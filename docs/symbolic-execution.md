# Symbolic Execution Baseline

The baseline symbolic executor is SMT-backed and profile-driven. Lean owns the
source-backed VM model and emits SMT-LIB path queries; Z3 solves the path
constraints and returns concrete witnesses.

## Current scope

Current coverage is the raw ECL single-step skeleton shared by TH06, TH07, and
TH08:

1. instruction dispatch is gated by `currentTime == instruction.time`;
2. the title's raw difficulty-mask policy decides execute versus skip;
3. `UNIMP` returns VM error;
4. the profile's fixed jump opcode jumps by its raw displacement operand;
5. all other modeled opcodes advance by `nextOffset`;
6. resulting cursor transfers are classified as before-buffer, non-progress,
   in-bounds, or at/past-end.

This intentionally avoids hand-selecting a suspicious bug site. The executor
enumerates generic path classes and asks Z3 for witnesses.

## Commands

List path classes:

```bash
lake exe symex list-paths
```

Emit and solve one query:

```bash
lake exe symex query th08 jumped-before-buffer 1 0 | z3 -in
```

Run a matrix for one title and difficulty environment:

```bash
./scripts/symex_raw_step.sh th08 1 2
```

The optional numeric arguments are `activeMask` and `overrideMask`; both must fit
in an unsigned byte. `overrideMask` is semantically relevant to TH08 raw ECL and
ignored by the TH06/TH07 active-bit-intersection policy.

## Baseline interpretation

Representative Z3 witnesses already covered by `scripts/check.sh`:

- TH06 `advanced-before-buffer`: ordinary opcode, executing difficulty mask, and
  `nextOffset = -1`.
- TH07 `vm-error`: executing difficulty mask and `opcode = 1`.
- TH08 `jumped-before-buffer`: `opcode = 4` and `jumpDisplacement = -1`.
- TH08 `skipped-in-bounds` with `activeMask = 1`, `overrideMask = 2`: a
  difficulty-mask skip path where cursor advancement itself is in-bounds.
- TH08 `advanced-non-progress`: executing ordinary opcode with `nextOffset = 0`.

These are not final retail findings by themselves. They are the baseline path
coverage that later bounded opcode semantics, full subroutine state, and
metamorphic checks should reuse.
