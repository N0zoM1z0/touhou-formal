import TouhouFormal.ECL.Item
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Item

open TouhouFormal.ECL

def itemOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.itemOps.length

def outcomeEffect? (result : Except TouhouFormal.Fault RawItemOutcome) :
    Option RawItemEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeLoop?
    (result : Except TouhouFormal.Fault RawItemOutcome) :
    Option RawItemLoopSpawn :=
  (outcomeEffect? result).bind (fun effect => effect.loopSpawn)

def outcomeSingle?
    (result : Except TouhouFormal.Fault RawItemOutcome) :
    Option RawItemSingleSpawn :=
  (outcomeEffect? result).bind (fun effect => effect.singleSpawn)

def outcomeStateWrite?
    (result : Except TouhouFormal.Fault RawItemOutcome) :
    Option RawItemStateWrite :=
  (outcomeEffect? result).bind (fun effect => effect.stateWrite)

def th06DropItemsPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeDropItems
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06DropItemsOutcome : Except TouhouFormal.Fault RawItemOutcome :=
  rawItemStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06DropItemsPrefix
    { intInputs := [ { rawValue := 3 } ] }

def th06DropItemIdPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeDropItemId
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06DropItemIdOutcome : Except TouhouFormal.Fault RawItemOutcome :=
  rawItemStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06DropItemIdPrefix
    { intInputs := [ { rawValue := 7 } ] }

def th07PointItemsPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSpawnPointItems
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07PointItemsOutcome : Except TouhouFormal.Fault RawItemOutcome :=
  rawItemStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07PointItemsPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 5 } ] }

def th08DropCountsPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetItemDropCounts
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def th08DropCountsOutcome : Except TouhouFormal.Fault RawItemOutcome :=
  rawItemStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08DropCountsPrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 9 },
          { rawValue := 10001, hostValue := 10 } ] }

def th08SpawnItemPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSpawnItem
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th08SpawnItemOutcome : Except TouhouFormal.Fault RawItemOutcome :=
  rawItemStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08SpawnItemPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 42 } ] }

theorem th06_item_profile_count :
    itemOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_item_profile_count :
    itemOpcodeCount TouhouFormal.TH07.headerShape = 3 := by
  rfl

theorem th08_item_profile_count :
    itemOpcodeCount TouhouFormal.TH08.headerShape = 5 := by
  rfl

theorem th06_drop_items_keeps_raw_count_and_spread :
    (outcomeLoop? th06DropItemsOutcome).map
      (fun loop =>
        (loop.kind,
          loop.count,
          loop.spreadFullWidth,
          loop.spreadHalfWidth,
          loop.powerThreshold)) =
      some
        (RawItemLoopKind.powerOrPointByPlayerPower,
          3,
          144,
          72,
          128) := by
  rfl

theorem th06_drop_item_id_uses_raw_item_type :
    (outcomeSingle? th06DropItemIdOutcome).map
      (fun single => (single.itemType, single.itemStateDefault)) =
      some (7, true) := by
  rfl

theorem th07_point_items_resolve_count :
    (outcomeLoop? th07PointItemsOutcome).map
      (fun loop =>
        (loop.kind,
          loop.count,
          loop.spreadFullWidth,
          loop.spreadHalfWidth,
          loop.powerThreshold)) =
      some
        (RawItemLoopKind.pointOnly,
          5,
          128,
          64,
          128) := by
  rfl

theorem th08_drop_counts_write_two_resolved_fields :
    (outcomeStateWrite? th08DropCountsOutcome).map
      (fun write =>
        (write.pointItemDropCount, write.powerOrPointItemDropCount)) =
      some (some 9, some 10) := by
  rfl

theorem th08_spawn_item_uses_default_item_state :
    (outcomeSingle? th08SpawnItemOutcome).map
      (fun single => (single.itemType, single.itemStateDefault)) =
      some (42, true) := by
  rfl

end TouhouFormal.Search.Item
