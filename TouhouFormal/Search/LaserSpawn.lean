import TouhouFormal.ECL.LaserSpawn
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.LaserSpawn

open TouhouFormal.ECL

def laserSpawnOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.laserSpawnOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawLaserSpawnOutcome) :
    Option RawLaserSpawnEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawLaserSpawnOutcome) :
    Option RawLaserSpawnPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def outcomeAction?
    (result : Except TouhouFormal.Fault RawLaserSpawnOutcome) :
    Option RawLaserSpawnAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeFault?
    (result : Except TouhouFormal.Fault RawLaserSpawnOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.fault

def outcomeDescriptor?
    (result : Except TouhouFormal.Fault RawLaserSpawnOutcome) :
    Option RawLaserSpawnDescriptor :=
  (outcomeEffect? result).bind RawLaserSpawnEffect.descriptorWrite

def mkPrefix (opcode : Int) (operandMask : Option Int := none) :
    RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := opcode
    nextOffset := 32
    difficultyMask := some 1
    operandMask := operandMask }

def th06FixedOutcome : Except TouhouFormal.Fault RawLaserSpawnOutcome :=
  rawLaserSpawnStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 96
    (mkPrefix TouhouFormal.TH06.eclOpcodeLaserCreate)
    { positionBits := { x := 10, y := 20, z := 30 }
      selectedSlot := 31
      intInputs :=
        [ { rawValue := 65535 },
          { rawValue := 2 },
          { rawValue := 3 },
          { rawValue := 4 },
          { rawValue := 5 },
          { rawValue := 6 },
          { rawValue := 7 },
          { rawValue := -1 } ]
      floatInputs :=
        [ { rawBits := 3323741184, hostBits := 11 },
          { rawBits := 3323741184, hostBits := 12 },
          { rawBits := 3323741184, hostBits := 13 },
          { rawBits := 3323741184, hostBits := 14 },
          { rawBits := 3323741184, hostBits := 15 },
          { rawBits := 1065353216 } ] }

def th06AimedOutcome : Except TouhouFormal.Fault RawLaserSpawnOutcome :=
  rawLaserSpawnStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 96
    (mkPrefix TouhouFormal.TH06.eclOpcodeLaserCreateAimed)
    { intInputs :=
        [ { rawValue := 1 },
          { rawValue := 2 },
          { rawValue := 3 },
          { rawValue := 4 },
          { rawValue := 5 },
          { rawValue := 6 },
          { rawValue := 7 },
          { rawValue := 8 } ]
      floatInputs :=
        [ { rawBits := 3323741184, hostBits := 11 },
          { rawBits := 3323741184, hostBits := 12 },
          { rawBits := 3323741184, hostBits := 13 },
          { rawBits := 3323741184, hostBits := 14 },
          { rawBits := 3323741184, hostBits := 15 },
          { rawBits := 16 } ] }

def th07FixedOutcome : Except TouhouFormal.Fault RawLaserSpawnOutcome :=
  rawLaserSpawnStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 96
    (mkPrefix TouhouFormal.TH07.eclOpcodeSpawnLaserPatternFixed (some 126))
    { positionBits := { x := 40, y := 50, z := 60 }
      selectedSlot := 5
      intInputs :=
        [ { rawValue := 1 },
          { rawValue := 10000, hostValue := 65535 },
          { rawValue := 7 },
          { rawValue := 8 },
          { rawValue := 9 },
          { rawValue := 10 },
          { rawValue := 11 },
          { rawValue := -1 } ]
      floatInputs :=
        [ { rawBits := 1176256512, hostBits := 21 },
          { rawBits := 1176256513, hostBits := 22 },
          { rawBits := 1176256514, hostBits := 23 },
          { rawBits := 1176256515, hostBits := 24 },
          { rawBits := 1176256516, hostBits := 25 },
          { rawBits := 1065353216 } ] }

def th07AimedSlotFaultOutcome :
    Except TouhouFormal.Fault RawLaserSpawnOutcome :=
  rawLaserSpawnStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 96
    (mkPrefix TouhouFormal.TH07.eclOpcodeSpawnLaserPatternMoving (some 126))
    { selectedSlot := 32
      intInputs :=
        [ { rawValue := 1 },
          { rawValue := 10000, hostValue := 2 },
          { rawValue := 7 },
          { rawValue := 8 },
          { rawValue := 9 },
          { rawValue := 10 },
          { rawValue := 11 },
          { rawValue := 12 } ]
      floatInputs :=
        [ { rawBits := 1176256512, hostBits := 21 },
          { rawBits := 1176256513, hostBits := 22 },
          { rawBits := 1176256514, hostBits := 23 },
          { rawBits := 1176256515, hostBits := 24 },
          { rawBits := 1176256516, hostBits := 25 },
          { rawBits := 26 } ] }

def th08AimedOutcome : Except TouhouFormal.Fault RawLaserSpawnOutcome :=
  rawLaserSpawnStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 96
    (mkPrefix TouhouFormal.TH08.eclOpcodeSpawnLaserAimed (some 2046))
    { positionBits := { x := 70, y := 80, z := 90 }
      selectedSlot := 4
      intInputs :=
        [ { rawValue := 65535 },
          { rawValue := 10000, hostValue := 3 },
          { rawValue := 10002, hostValue := 30 },
          { rawValue := 10003, hostValue := 40 },
          { rawValue := 10004, hostValue := 50 },
          { rawValue := 60 },
          { rawValue := 70 },
          { rawValue := -1 } ]
      floatInputs :=
        [ { rawBits := 1176256512, hostBits := 31 },
          { rawBits := 1176256513, hostBits := 32 },
          { rawBits := 1176256514, hostBits := 33 },
          { rawBits := 1176256515, hostBits := 34 },
          { rawBits := 1176256516, hostBits := 35 },
          { rawBits := 1176256517, hostBits := 36 } ] }

def th08FixedSlotFaultOutcome :
    Except TouhouFormal.Fault RawLaserSpawnOutcome :=
  rawLaserSpawnStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 96
    (mkPrefix TouhouFormal.TH08.eclOpcodeSpawnLaserFixed (some 2046))
    { selectedSlot := -1
      intInputs :=
        [ { rawValue := 1 },
          { rawValue := 10000, hostValue := 3 },
          { rawValue := 10002, hostValue := 30 },
          { rawValue := 10003, hostValue := 40 },
          { rawValue := 10004, hostValue := 50 },
          { rawValue := 60 },
          { rawValue := 70 },
          { rawValue := 80 } ]
      floatInputs :=
        [ { rawBits := 1176256512, hostBits := 31 },
          { rawBits := 1176256513, hostBits := 32 },
          { rawBits := 1176256514, hostBits := 33 },
          { rawBits := 1176256515, hostBits := 34 },
          { rawBits := 1176256516, hostBits := 35 },
          { rawBits := 1176256517, hostBits := 36 } ] }

theorem th06_laser_spawn_profile_count :
    laserSpawnOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_laser_spawn_profile_count :
    laserSpawnOpcodeCount TouhouFormal.TH07.headerShape = 2 := by
  rfl

theorem th08_laser_spawn_profile_count :
    laserSpawnOpcodeCount TouhouFormal.TH08.headerShape = 2 := by
  rfl

theorem th06_laser_spawn_preserves_raw_descriptor_and_resolved_floats :
    outcomeDescriptor? th06FixedOutcome =
      some
        { target := .enemyLaserShooter
          positionSource := .enemyPositionPlusShootOffset
          positionBits := { x := 10, y := 20, z := 30 }
          spriteOrBulletType := -1
          color := 2
          angleBits := 11
          speedBits := 12
          startOffsetBits := 13
          endOffsetBits := 14
          startLengthBits := 15
          widthBits := 1065353216
          startTime := 3
          duration := 4
          despawnOrEndTime := 5
          hitboxStartTime := 6
          hitboxEndDelayOrTime := 7
          flagsOrTransformFlags := 4294967295
          aimKind := .fixed
          storedAimValue := 1 } := by
  rfl

theorem th06_laser_spawn_aimed_opcode_stores_type_zero :
    (outcomeDescriptor? th06AimedOutcome).map
      (fun descriptor => (descriptor.aimKind, descriptor.storedAimValue)) =
      some (.aimedAtPlayer, 0) := by
  rfl

theorem th07_laser_spawn_uses_shifted_operand_flags :
    (outcomePrepared? th07FixedOutcome).map
      (fun prepared =>
        prepared.floatResolutions.map
          (fun input =>
            (input.shape.operandIndex,
              input.shape.flagIndex,
              input.resolution.bits))) =
      some
        [ (1, 2, 21),
          (2, 3, 22),
          (3, 4, 23),
          (4, 5, 24),
          (5, 6, 25),
          (6, 7, 1065353216) ] := by
  rfl

theorem th07_laser_spawn_color_resolves_then_truncates_to_i16 :
    (outcomeDescriptor? th07FixedOutcome).map
      (fun descriptor => descriptor.color) = some (-1) := by
  rfl

theorem th07_laser_spawn_slot_oob_happens_after_spawn_request :
    (outcomeAction? th07AimedSlotFaultOutcome,
      (outcomeEffect? th07AimedSlotFaultOutcome).map
        (fun effect => (effect.spawnRequest, effect.slotWrite.isSome)),
      (outcomeFault? th07AimedSlotFaultOutcome).map
        (fun fault => (fault.kind, fault.index, fault.bound))) =
      (some .hostFault, some (true, false),
        some (.outOfBoundsWrite, some 32, some 32)) := by
  rfl

theorem th08_laser_spawn_targets_bullet_descriptor_and_world_position :
    (outcomeDescriptor? th08AimedOutcome).map
      (fun descriptor =>
        (descriptor.target,
          descriptor.positionSource,
          descriptor.positionBits,
          descriptor.aimKind,
          descriptor.storedAimValue)) =
      some
        (.bulletSpawnDescriptor,
          .enemyWorldPositionPlusShootOffset,
          { x := 70, y := 80, z := 90 },
          .aimedAtPlayer,
          0) := by
  rfl

theorem th08_laser_spawn_resolves_width_and_time_flags :
    (outcomeDescriptor? th08AimedOutcome).map
      (fun descriptor =>
        (descriptor.widthBits,
          descriptor.startTime,
          descriptor.duration,
          descriptor.despawnOrEndTime,
          descriptor.flagsOrTransformFlags)) =
      some (36, 30, 40, 50, 4294967295) := by
  rfl

theorem th08_laser_spawn_slot_underflow_is_after_descriptor_write :
    (outcomeAction? th08FixedSlotFaultOutcome,
      ((outcomeEffect? th08FixedSlotFaultOutcome).bind
        (fun effect => effect.descriptorWrite)).map
        (fun descriptor => descriptor.storedAimValue),
      (outcomeFault? th08FixedSlotFaultOutcome).map
        (fun fault => (fault.kind, fault.index, fault.bound))) =
      (some .hostFault, some 1,
        some (.outOfBoundsWrite, some (-1), some 32)) := by
  rfl

end TouhouFormal.Search.LaserSpawn
