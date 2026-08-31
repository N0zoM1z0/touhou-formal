# touhou-formal

Formal models for Touhou script VMs, starting with the ECL VM family in TH06,
TH07, and TH08.

The goal is not to replace ZUN's VM with a safer one. The goal is to model the
original behavior closely enough that formal search can produce counterexamples
for properties the retail VM does not satisfy, then validate the interesting
ones against the original games.

## Current slice

The executable model currently covers these source-backed boundaries:

- TH06 raw bytes flow through the shared ECL loader, timeline-prefix decoder,
  and `CallEclSub` lookup to reproduce the `arg0 = 256` subTable fault.
- TH07 and TH08 reuse the same lookup semantics while preserving their
  negative-sub-id policy difference.
- Loader and cursor checks expose first missing-byte, zero-size, and
  before-buffer boundaries as executable theorems.
- Timeline `size` and raw instruction `nextOffset` cursor sweeps are generated
  from shared profile widths, so TH08's unsigned timeline-size delta is recorded
  without title-local search logic.
- Raw ECL difficulty-mask semantics are modeled as profile policy; TH08's
  override-mask rule is proven distinct from the TH06/TH07 active-bit
  intersection rule.
- Raw ECL instruction prefixes and ANM entry headers are decoded through shared
  profile-driven code across TH06/TH07/TH08.

The Lean model treats the first invalid operation as a `Fault`. It does not try
to predict arbitrary C++ undefined behavior after that point.

## Repository layout

- `TouhouFormal/Core/`: byte/scalar reads, faults, evidence, and bounded
  transition-system definitions.
- `TouhouFormal/ECL/`: shared ECL profile, loader, lookup, timeline, and raw
  instruction-prefix semantics.
- `TouhouFormal/ANM/`: shared ANM entry profile and entry-header decoding.
- `TouhouFormal/TH06/`, `TouhouFormal/TH07/`, `TouhouFormal/TH08/`:
  title-specific profile facts, fixtures, and deltas.
- `TouhouFormal/Search/`: bounded checks and SMT bridges.
- `docs/`: modeling policy, source evidence, and roadmap notes.
- `scripts/`: reproducible local checks.

## Commands

```bash
lake build
lake exe check
lake exe smt th06-sub-oob | z3 -in
lake exe smt th08-negative-noop-unsat | z3 -in
lake exe smt th08-timeline-size-before-buffer-unsat | z3 -in
lake exe smt th08-raw-difficulty-override-delta | z3 -in
./scripts/check.sh
./scripts/retail_inventory.sh
./scripts/extract_retail_th06.sh
python3 scripts/retail_confirm_th06_arg0_256.py --prepare-only
```

`scripts/check.sh` runs the Lean build, executable counterexample check, and
the current Z3 controls together. `scripts/retail_inventory.sh` is read-only and
records archive hashes plus executable/data CRCs before any Wine validation.
Retail validation scripts operate on isolated copies under
`/home/yann/yann/touhou/formal/retail_extract` and
`/home/yann/yann/touhou/formal/retail_validation`.

Current retained results are summarized in
[`docs/formal-results.md`](docs/formal-results.md).
