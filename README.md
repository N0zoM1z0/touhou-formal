# touhou-formal

Formal models for Touhou script VMs, starting with the ECL VM family in TH06,
TH07, and TH08.

The goal is not to replace ZUN's VM with a safer one. The goal is to model the
original behavior closely enough that formal search can produce counterexamples
for properties the retail VM does not satisfy, then validate the interesting
ones against the original games.

## First slice

The initial executable slice targets a retail-confirmed TH06 failure path:

1. A stage timeline instruction uses `arg0` as an ECL subroutine id.
2. `EnemyManager::SpawnEnemy` passes that id to `EclManager::CallEclSub`.
3. `CallEclSub` reads `subTable[subId]` without a range check.

The Lean model treats the first invalid operation as a `Fault`. It does not try
to predict arbitrary C++ undefined behavior after that point.

## Repository layout

- `TouhouFormal/Core/`: generic fault, evidence, and bounded transition-system
  definitions.
- `TouhouFormal/TH06/`: TH06 ECL wire facts and executable semantics.
- `TouhouFormal/TH07/`, `TouhouFormal/TH08/`: version-specific model homes.
- `TouhouFormal/Search/`: SMT and symbolic-search bridges.
- `docs/`: modeling policy, source evidence, and roadmap notes.
- `scripts/`: reproducible local checks.
- `tests/`: future regression fixtures.

## Commands

```bash
lake build
lake exe check
```

After the SMT bridge lands, `scripts/check.sh` will run the Lean checks and Z3
queries together.
