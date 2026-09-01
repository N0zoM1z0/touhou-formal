# Architecture

## Modeling Contract

This repository models the original game VMs as observed systems. A model may
expose a `Fault` for the first invalid operation, but it should not silently
repair that operation or replace it with a safer validation rule.

The intended loop is:

1. Extract source-backed semantics from the TH06/TH07/TH08 reconstructions.
2. Encode a small executable model in Lean.
3. Search bounded state spaces with Lean evaluation, symbolic execution, or SMT.
4. Reduce solver outputs into concrete script mutations.
5. Validate high-value counterexamples against retail binaries under Wine.

## Layers

`TouhouFormal/Core` contains title-independent transition-system machinery:
faults, little-endian byte reads, bounded execution, traces, and evidence
references, and cursor-transfer classification.

`TouhouFormal/ECL` contains the shared ECL core: scalar byte reads,
profile-driven header loading, subTable lookup policy, timeline-prefix decoding,
timeline cursor advancement, raw instruction-prefix decoding, and profile-driven
fixed-operand jump decoding. It also owns profile-driven operand resolution,
scalar assignment, integer unary updates, and single-step integer/float binary
arithmetic, scalar float functions, and random-value dispatch so TH06/TH07/TH08
title deltas stay in profile data instead of one-off opcode implementations. These
definitions encode the original unsafe boundary and return a structured `Fault`
at the first invalid modeled operation.

Comparison semantics use one relation vocabulary across titles. TH06 profiles
the two instructions that produce its persistent compare register; TH07/TH08
profile direct integer and float branch opcodes. Float comparisons consume an
explicit IEEE order class (`less`, `equal`, `greater`, or `unordered`) so NaN
behavior is preserved without embedding a second ad hoc float evaluator.

Movement opcodes emit a shared `RawMovementEffect` rather than mutating three
title-specific enemy structs. The effect names stable writes—position,
velocity, angle, speed, acceleration, bounds, mode, and timers—while profiles
own operand slots, raw-versus-resolved reads, forced values, and title-only
side effects. Host math such as `atan2f`, normalized player-relative angles,
and position clamping remains an explicit boundary value/event.

Primary bullet-pattern opcodes use one consecutive-family profile rather than
27 copied cases. The opcode delta becomes aim mode; a shared descriptor effect
owns packed operand resolution, signed-i16 writes, rank/clamp control flow, and
spawn disposition. Profiles own only real deltas: TH06 raw bullet type and
angle normalization, TH07/TH08 spellcard bypass and dead gate, and TH08's
deferred raw copy plus alignment/distance filters. Source-side float arithmetic
results remain explicit host-boundary values, while IEEE binary32 zero, NaN,
and ordered minimum-speed comparisons execute directly from their bits.

Callback configuration emits typed writes independently of callback dispatch.
The shared layer covers scalar and indexed life callbacks, timer callbacks,
death binding, and TH07 periodic state. Indexed operands retain per-occurrence
host values because source macros may resolve an RNG selector more than once;
an outcome can therefore carry both writes completed before the first invalid
host access and the resulting fault. Interrupt-driven context switching can
consume this state later without redefining callback storage semantics.

`TouhouFormal/TH06`, `TouhouFormal/TH07`, and `TouhouFormal/TH08` should mostly
contain profile facts and title deltas. Similar names across titles are not
assumed equivalent; a title module should justify differences by filling a
shared profile field before adding one-off logic.

`TouhouFormal/ANM` follows the same pattern for animation resources. The first
shared ANM layer decodes raw entry headers and next-entry cursor policy only;
script opcodes should be added after the source-backed VM boundary is clear.

`TouhouFormal/Search` is allowed to duplicate a bounded query in SMT-LIB when
the duplicated relation is small and source-linked. Larger encodings should be
generated from Lean-side definitions or a shared intermediate representation.
Finite Lean-side sweeps live here when they are small enough to keep as
executable regression guards, including cross-title call-policy and
cursor-transfer searches.

`lake exe symex` is the current path for forward symbolic execution. It starts
from shared Lean profile/step semantics and emits SMT path constraints for Z3,
instead of adding isolated hand-written bug queries.

Raw ECL witness materialization keeps the same ownership split. Z3 chooses
values; Python may parse solver output and orchestrate commands; only Lean may
turn witness fields into title-specific raw bytes, because Lean owns the
`HeaderShape.rawInstrShape` offsets, widths, and concrete replay check. The same
rule applies when wrapping a raw instruction in a minimal one-sub ECL file:
`HeaderShape` owns the header size, version field, counts, and sub offset.

## Future VMs

Nontraditional bullet-hell VMs should enter through the same boundary: raw
input, decoded instruction stream, host state assumptions, small-step semantics,
fault outcomes, and retail validation evidence.
