# Fidelity Policy

## What Counts As Faithful

A faithful model preserves the original program's observable decisions and
unsafe boundaries. If the source indexes an array without checking the index,
the model should represent the unchecked access and expose out-of-range inputs
as counterexamples.

For C++ undefined behavior or wild pointer execution, the model stops at the
first invalid operation and returns a structured `Fault`. That is a modeling
boundary, not a claim that retail always crashes at that exact instruction.

## Host Effects

Timeline dispatch, enemy creation, bullet allocation, RNG, ANM state, sound, and
GUI state cross from the ECL VM into host game systems. Early models may replace
large host effects with explicit assumptions, but they must mark those
assumptions in the title-specific module or evidence notes.

## Validation

Wine validation is used after the formal model produces a concrete candidate.
Retail traces should be recorded as supporting evidence for a model, not as a
substitute for source-level semantics.
