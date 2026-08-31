# SMT Seeds

The first SMT bridge was deliberately narrow. Lean owns the executable timeline
and loader models, while `TouhouFormal.Search.SMT` emits audit-friendly SMT-LIB
queries for the shared `CallEclSub` sub-table safety relation.

The forward symbolic execution baseline now lives in `lake exe symex`; see
`docs/symbolic-execution.md`. New instruction-level work should prefer
extending that executor over adding one-off SMT seeds here.

```text
unchecked: safe(subId, subCount) := 0 <= subId && subId < subCount
no-op:     safe(subId, subCount) := subId < 0 || (0 <= subId && subId < subCount)
```

`lake exe smt th06-sub-oob | z3 -in` checks the retail-calibrated seed
`subCount = 1, arg0 = 256`.

`lake exe smt th06-find-oob | z3 -in` asks Z3 for any signed 16-bit
timeline argument that violates the same relation for a bounded positive
`subCount`.

`lake exe smt th07-negative-oob | z3 -in` confirms that TH07's unchecked
negative sub id is a counterexample.

`lake exe smt th08-negative-noop-unsat | z3 -in` confirms that the same
negative id is not a counterexample under TH08's source-backed no-op policy.

`lake exe smt th08-positive-oob | z3 -in` keeps TH08's positive upper-bound
fault path live.

`lake exe smt th06-jump-minus-one-oob | z3 -in`,
`lake exe smt th07-jump-minus-one-oob | z3 -in`, and
`lake exe smt th08-jump-minus-one-oob | z3 -in` check relative jump cursor
counterexamples backed by the shared cursor-transfer semantics.

Cursor-delta query generation also reuses profile scalar widths. These commands
ask the solver for field values that reach a named cursor class:

```bash
lake exe smt th06-timeline-size-before-buffer | z3 -in
lake exe smt th07-timeline-size-before-buffer | z3 -in
lake exe smt th08-timeline-size-before-buffer-unsat | z3 -in
lake exe smt th08-timeline-size-nonprogress | z3 -in
lake exe smt th06-nextoffset-before-buffer | z3 -in
lake exe smt th07-nextoffset-before-buffer | z3 -in
lake exe smt th08-nextoffset-before-buffer | z3 -in
lake exe smt th08-raw-difficulty-override-delta | z3 -in
```

The important negative control is
`th08-timeline-size-before-buffer-unsat`: TH08's timeline size is modeled as
`u8`, so a single timeline-size field cannot produce a negative cursor transfer.
The adjacent `th08-timeline-size-nonprogress` query remains `sat` with
`size = 0`.

`th08-raw-difficulty-override-delta` is a bit-vector query. It asks Z3 for an
instruction mask that would pass the TH06/TH07-style active-bit intersection
test while failing TH08 raw ECL's stronger
`instructionMask ⊇ difficultyMask | eclDifficultyMaskOverride` test. Z3 returns
`instructionMask = #x01` for `activeMask = #x01`, `overrideMask = #x02`.

The next step is to generate larger instruction-level SMT queries from shared
Lean-side transition facts once more of the VM is encoded.
