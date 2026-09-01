import TouhouFormal.ECL.EnemyLifecycle
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.EnemyLifecycle

open TouhouFormal.ECL

def enemyLifecycleOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.enemyLifecycleOps.length

def outcomeEffect? (result : Except TouhouFormal.Fault RawEnemyLifecycleOutcome) :
    Option RawEnemyLifecycleEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawEnemyLifecycleOutcome) :
    Option RawEnemyLifecyclePrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def outcomeSpawn?
    (result : Except TouhouFormal.Fault RawEnemyLifecycleOutcome) :
    Option RawEnemySpawnRequest :=
  (outcomeEffect? result).bind (fun effect => effect.spawnRequest)

def outcomeRemoveAll?
    (result : Except TouhouFormal.Fault RawEnemyLifecycleOutcome) :
    Option RawEnemyRemoveAllEffect :=
  (outcomeEffect? result).bind (fun effect => effect.removeAll)

def removeAllSummary?
    (result : Except TouhouFormal.Fault RawEnemyLifecycleOutcome) :
    Option
      (RawEnemyRemoveAllImplementation × Nat × Int × Int × Bool × Bool ×
        Bool × Bool) :=
  (outcomeRemoveAll? result).map
    (fun remove =>
      (remove.implementation,
        remove.poolSearchSlots,
        remove.scoreMax,
        remove.initialScore,
        remove.mayCallDeathCallbacks,
        remove.skipsNoDeathFlag,
        remove.maySpawnPointItems,
        remove.detachesParentChains))

def spawnSuppressed?
    (result : Except TouhouFormal.Fault RawEnemyLifecycleOutcome) : Bool :=
  match outcomeEffect? result with
  | none => false
  | some effect => effect.spawnSuppressedByParentLife

def th06SpawnPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeEnemyCreate
    nextOffset := 32
    difficultyMask := some 1
    operandMask := none }

def th06SpawnOutcome : Except TouhouFormal.Fault RawEnemyLifecycleOutcome :=
  rawEnemyLifecycleStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 96
    th06SpawnPrefix
    { intInputs :=
        [ { rawValue := 70000 },
          { rawValue := 65535 },
          { rawValue := 255 },
          { rawValue := 1234 } ]
      floatInputs :=
        [ { rawBits := 3323741184, hostBits := 11 },
          { rawBits := 3323741184, hostBits := 12 },
          { rawBits := 3323741184, hostBits := 13 } ] }

def th06RemoveAllPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeEnemyKillAll
    nextOffset := 12
    difficultyMask := some 1
    operandMask := none }

def th06RemoveAllOutcome :
    Except TouhouFormal.Fault RawEnemyLifecycleOutcome :=
  rawEnemyLifecycleStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 96
    th06RemoveAllPrefix
    {}

def th07SpawnAbsPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSpawnEnemyAbs
    nextOffset := 40
    difficultyMask := some 1
    operandMask := some 126 }

def th07SpawnAbsOutcome : Except TouhouFormal.Fault RawEnemyLifecycleOutcome :=
  rawEnemyLifecycleStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 96
    th07SpawnAbsPrefix
    { intInputs :=
        [ { rawValue := 42 },
          { rawValue := 10000, hostValue := 99 },
          { rawValue := 10001, hostValue := 255 },
          { rawValue := 10002, hostValue := 123 } ]
      floatInputs :=
        [ { rawBits := 1176260608, hostBits := 21 },
          { rawBits := 1176260608, hostBits := 22 },
          { rawBits := 1176260608, hostBits := 23 } ] }

def th07SpawnRelDeadParentPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSpawnEnemyRel
    nextOffset := 40
    difficultyMask := some 1
    operandMask := some 126 }

def th07SpawnRelDeadParentOutcome :
    Except TouhouFormal.Fault RawEnemyLifecycleOutcome :=
  rawEnemyLifecycleStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 96
    th07SpawnRelDeadParentPrefix
    { runtime := { parentLife := 0 } }

def th07RemoveAllPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeRemoveAllEnemies
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 0 }

def th07RemoveAllOutcome :
    Except TouhouFormal.Fault RawEnemyLifecycleOutcome :=
  rawEnemyLifecycleStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 96
    th07RemoveAllPrefix
    {}

def th08SpawnRelPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSpawnEnemyRel
    nextOffset := 40
    difficultyMask := some 1
    operandMask := some 126 }

def th08SpawnRelOutcome : Except TouhouFormal.Fault RawEnemyLifecycleOutcome :=
  rawEnemyLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 96
    th08SpawnRelPrefix
    { intInputs :=
        [ { rawValue := 70000 },
          { rawValue := 10000, hostValue := 150 },
          { rawValue := 10001, hostValue := 255 },
          { rawValue := 10002, hostValue := 2500 } ]
      floatInputs :=
        [ { rawBits := 1176272896, hostBits := 31 },
          { rawBits := 1176272896, hostBits := 32 },
          { rawBits := 1176272896, hostBits := 33 } ]
      runtime :=
        { parentLife := 10
          enemyPositionBits := { x := 1, y := 2, z := 3 }
          relativePositionResultBits := { x := 101, y := 202, z := 303 } } }

def th08RemoveAllPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeKillAllNonBossEnemies
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 0 }

def th08RemoveAllOutcome :
    Except TouhouFormal.Fault RawEnemyLifecycleOutcome :=
  rawEnemyLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 96
    th08RemoveAllPrefix
    {}

theorem th06_enemy_lifecycle_profile_count :
    enemyLifecycleOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_enemy_lifecycle_profile_count :
    enemyLifecycleOpcodeCount TouhouFormal.TH07.headerShape = 3 := by
  rfl

theorem th08_enemy_lifecycle_profile_count :
    enemyLifecycleOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem th06_spawn_uses_source_packet_widths :
    (outcomeSpawn? th06SpawnOutcome).map
      (fun request =>
        (request.subId,
          request.hostCallSubId,
          request.life,
          request.itemDrop,
          request.hostItemDrop,
          request.score,
          request.poolSearchSlots,
          request.position.finalPositionBits)) =
      some
        (70000,
          4464,
          -1,
          255,
          255,
          1234,
          256,
          { x := 11, y := 12, z := 13 }) := by
  rfl

theorem th07_spawn_resolves_operands_and_truncates_item_drop :
    (outcomeSpawn? th07SpawnAbsOutcome).map
      (fun request =>
        (request.hostCallSubId,
          request.life,
          request.hostItemDrop,
          request.score,
          request.contextCopy,
          request.position.finalPositionBits,
          request.poolSearchSlots)) =
      some
        (42,
          99,
          -1,
          123,
          RawEnemySpawnContextCopy.eclContextArgs,
          { x := 21, y := 22, z := 23 },
          480) := by
  rfl

theorem th07_spawn_dead_parent_suppresses_operand_reads :
    (spawnSuppressed? th07SpawnRelDeadParentOutcome,
      (outcomePrepared? th07SpawnRelDeadParentOutcome).map
        (fun prepared =>
          (prepared.intResolutions.length,
            prepared.floatResolutions.length,
            prepared.effect.spawnRequest))) =
      (true, some (0, 0, none)) := by
  rfl

theorem th08_relative_spawn_records_host_boundary :
    (outcomeSpawn? th08SpawnRelOutcome).map
      (fun request =>
        (request.hostCallSubId,
          request.life,
          request.hostItemDrop,
          request.score,
          request.contextCopy,
          request.position.mode,
          request.position.resolvedPacketBits,
          request.position.enemyPositionBits,
          request.position.finalPositionBits,
          request.runSpawnedEclImmediately,
          request.poolSearchSlots)) =
      some
        (4464,
          150,
          -1,
          2500,
          RawEnemySpawnContextCopy.activeIntVariables,
          RawEnemySpawnPositionMode.relativeToEnemy,
          { x := 31, y := 32, z := 33 },
          { x := 1, y := 2, z := 3 },
          { x := 101, y := 202, z := 303 },
          true,
          480) := by
  rfl

theorem remove_all_policy_differs_by_title :
    (removeAllSummary? th06RemoveAllOutcome,
      removeAllSummary? th07RemoveAllOutcome,
      removeAllSummary? th08RemoveAllOutcome) =
      (some
        (RawEnemyRemoveAllImplementation.inlineTH06Loop,
          256,
          8000,
          0,
          true,
          false,
          false,
          false),
        some
          (RawEnemyRemoveAllImplementation.removeAllEnemies,
            480,
            8000,
            0,
            true,
            false,
            true,
            false),
        some
          (RawEnemyRemoveAllImplementation.killAllNonBossEnemies,
            480,
            8000,
            0,
            true,
            true,
            true,
            true)) := by
  rfl

end TouhouFormal.Search.EnemyLifecycle
