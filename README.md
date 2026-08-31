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
- Shared integer operand resolution covers TH06's always-`GetVar` behavior and
  TH07/TH08 `operandFlags` mask branches, including known selector fallthrough
  to raw immediates.
- The first opcode-body slice includes `JUMPDEC`, integer conditional jumps,
  and immediate/raw integer div/mod zero-divisor hazards.
- Plain CALL/RET stack behavior is modeled with shared semantics for stack
  saves/restores, depth guards, subTable lookup, and TH08 child-context RET
  exits.
- TH06 conditional CALL opcodes are modeled as guard predicates that reuse the
  same shared CALL stack/subTable body when taken.
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
lake exe symex list-paths
lake exe symex query th08 jumped-before-buffer 1 0 | z3 -in
lake exe symex query-values th08 jumped-before-buffer 1 0 | z3 -in
lake exe symex list-body-paths
lake exe symex query-body-values th08 int-divisor-zero 1 2 | z3 -in
lake exe symex list-int-resolver-paths
lake exe symex query-int-resolver-values th07 resolved-default-raw 0 | z3 -in
lake exe symex list-callret-paths
lake exe symex query-callret-values th08 ret-child-index-before-array 1 0 | z3 -in
lake exe symex list-condcall-paths
lake exe symex query-condcall-values th06 condcall-lookup-fault 1 0 | z3 -in
./scripts/symex_raw_step.sh th08 1 2
./scripts/symex_materialize_raw_step.py th08 jumped-before-buffer 1 0
./scripts/symex_materialize_raw_step.py th06 jumped-before-buffer 8 0 --ecl-file
./scripts/symex_candidate_queue.py --env th06:8:0:retail-lunatic-bit3 --path jumped-before-buffer
./scripts/symex_materialize_body_step.py th08 all 1 2
./scripts/symex_body_candidate_queue.py
./scripts/symex_materialize_int_resolver.py th07 all 0
./scripts/symex_int_resolver_queue.py
./scripts/symex_materialize_callret_step.py th08 all 1 0
./scripts/symex_callret_candidate_queue.py
./scripts/symex_materialize_condcall_step.py th06 all 1 0
./scripts/symex_condcall_candidate_queue.py
python3 scripts/evaluate_symex_effectiveness.py
./scripts/check.sh
./scripts/retail_inventory.sh
./scripts/extract_retail_th06.sh
python3 scripts/retail_confirm_th06_arg0_256.py --prepare-only
python3 scripts/retail_confirm_th06_raw_symex.py --symex-path jumped-before-buffer --prepare-only
```

`scripts/check.sh` runs the Lean build, executable counterexample check, Z3
controls, and the current raw-ECL symbolic witness materializer. The
materializer solves a path, asks Lean to encode the witness into bytes from the
shared title profile, decodes it again, and checks that the concrete step lands
back in the requested path class. The body materializer does the same for the
first opcode-body layer: `JUMPDEC`, integer conditional jumps, and immediate/raw
integer div/mod zero-divisor faults. The resolver materializer covers integer
rvalue `operandFlags` branches separately from opcode-body effects. The CALL/RET
materializer covers stack write/read faults, subTable lookup faults, and TH08
child-context RET exits. The conditional-CALL materializer covers TH06
guard-false fallthrough and guard-true reuse of the same CALL stack/subTable
body.
`scripts/evaluate_symex_effectiveness.py` reruns the symbolic candidate queues
and reports which modeled branches are covered versus which source opcode/body
branches remain outside the current semantics. `scripts/retail_inventory.sh` is
read-only and records archive
hashes plus executable/data CRCs before any Wine validation. Retail validation
scripts operate on isolated copies under
`/home/yann/yann/touhou/formal/retail_extract` and
`/home/yann/yann/touhou/formal/retail_validation`.

Current retained results are summarized in
[`docs/formal-results.md`](docs/formal-results.md). The current formal-vs-fuzz
coverage assessment is in [`docs/effectiveness.md`](docs/effectiveness.md).
