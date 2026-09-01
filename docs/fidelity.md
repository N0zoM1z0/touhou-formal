# Fidelity Policy

## What Counts As Faithful

A faithful model preserves the original program's observable decisions and
unsafe boundaries. If the source indexes an array without checking the index,
the model should represent the unchecked access and expose out-of-range inputs
as counterexamples.

For C++ undefined behavior or wild pointer execution, the model stops at the
first invalid operation and returns a structured `Fault`. That is a modeling
boundary, not a claim that retail always crashes at that exact instruction.

The formal parser is intentionally not a defensive tooling parser. Prior
DanmakuFuzz IR code rejects truncated headers, bad offsets, and undersized
timeline instructions so the fuzzer can keep mutating valid-enough files. The
Lean model should not inherit those validations unless the original title source
performs them before the observed access.

Timeline `size` is modeled as decoded cursor arithmetic. A zero-size instruction
is non-progressing; a signed negative size can move the next decode cursor before
the ECL buffer. The model reports the next invalid decode boundary instead of
pretending the instruction stream is a safe array of records.

Float arithmetic is currently faithful at the VM boundary that matters for
opcode dispatch: output lvalue resolution, operand-flag-controlled rvalue
resolution, title-specific slot layouts, and the selected operation
`ADD/SUB/MUL/DIV/MOD`. Lean records the lhs/rhs bit patterns and accepts
`resultBits` from the host/SMT float-theory boundary; it does not yet claim to
implement IEEE-754 single-precision arithmetic or `fmodf` internally.

## Host Effects

Timeline dispatch, enemy creation, bullet allocation, RNG, ANM state, sound, and
GUI state cross from the ECL VM into host game systems. Early models may replace
large host effects with explicit assumptions, but they must mark those
assumptions in the title-specific module or evidence notes.

## Validation

Wine validation is used after the formal model produces a concrete candidate.
Retail traces should be recorded as supporting evidence for a model, not as a
substitute for source-level semantics.
