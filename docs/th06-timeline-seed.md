# TH06 Timeline Seed

This seed models the smallest source-backed path behind the known `arg0 = 256`
retail failure:

```text
EclTimelineInstr.arg0
  -> EnemyManager::SpawnEnemy(eclSubId)
  -> EclManager::CallEclSub(ctx, subId)
  -> this->subTable[subId]
```

The current Lean model starts from a decoded timeline instruction, not raw ECL
bytes. That keeps the first experiment focused on the unsafe semantic boundary.
Raw byte decoding belongs in the next phase.

## Implemented Relation

For TH06, `CallEclSub` has no negative-id or upper-bound guard. Therefore:

```text
safe(subId, subCount) := 0 <= subId && subId < subCount
fault(subId, subCount) := not safe(subId, subCount)
```

`TouhouFormal.TH06.arg0_256_counterexample` proves that a timeline spawn
instruction with `arg0 = 256`, one available subroutine, matching timeline time,
and no boss present reaches an out-of-bounds sub-table read within one bounded
step.

`TouhouFormal.TH06.arg0_0_advances` is a negative control: the same state shape
with `arg0 = 0` advances and records one spawned enemy.

## Current Host Assumptions

- Boss presence is a Boolean input.
- Enemy-slot allocation is summarized as success.
- The spawned enemy's `RunEcl` body is not executed yet.
- Position, item, score, RNG, GUI, and ANM side effects are outside this seed.
