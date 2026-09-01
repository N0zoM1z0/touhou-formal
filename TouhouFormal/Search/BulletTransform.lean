import TouhouFormal.ECL.BulletTransform
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.BulletTransform

open TouhouFormal.ECL

def bulletTransformOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.bulletTransformOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawBulletTransformOutcome) :
    Option RawBulletTransformEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawBulletTransformOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def preparedIntReadCount
    (result : Except TouhouFormal.Fault RawBulletTransformOutcome) : Nat :=
  match result with
  | .error _ => 0
  | .ok outcome =>
      match outcome.prepared with
      | none => 0
      | some prepared => prepared.intResolutions.length

def th07CommandPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeInitBulletCommand
    nextOffset := 40
    difficultyMask := some 1
    operandMask := some 1 }

def th07Index6Outcome :
    Except TouhouFormal.Fault RawBulletTransformOutcome :=
  rawBulletTransformStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07CommandPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 6 } ] }

def th08TransformPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeInitBulletTransform
    nextOffset := 40
    difficultyMask := some 1
    operandMask := some 0 }

def th08Index17Outcome :
    Except TouhouFormal.Fault RawBulletTransformOutcome :=
  rawBulletTransformStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08TransformPrefix
    { intInputs :=
        [ { rawValue := 17 }, { rawValue := -1 }, { rawValue := 1 },
          { rawValue := 2 }, { rawValue := 3 } ]
      floatInputs := [ { rawValue := 4 }, { rawValue := 5 } ] }

def th08Index18Outcome :
    Except TouhouFormal.Fault RawBulletTransformOutcome :=
  rawBulletTransformStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08TransformPrefix
    { intInputs := [ { rawValue := 18 } ] }

theorem th06_bullet_transform_profile_count :
    bulletTransformOpcodeCount TouhouFormal.TH06.headerShape = 0 := by
  rfl

theorem th07_bullet_transform_profile_count :
    bulletTransformOpcodeCount TouhouFormal.TH07.headerShape = 1 := by
  rfl

theorem th08_bullet_transform_profile_count :
    bulletTransformOpcodeCount TouhouFormal.TH08.headerShape = 1 := by
  rfl

theorem th07_index_6_is_oob :
    (outcomeFault? th07Index6Outcome).map (fun fault => fault.kind) =
      some .outOfBoundsWrite := by
  rfl

theorem th07_oob_suppresses_later_reads :
    preparedIntReadCount th07Index6Outcome = 1 := by
  rfl

theorem th08_index_17_is_in_bounds :
    ((outcomeEffect? th08Index17Outcome).bind
      (fun effect => effect.entryWrite)).map
        (fun write => (write.index, write.kind, write.payloadFloat1Bits)) =
      some (17, 4294967295, some 5) := by
  rfl

theorem th08_index_18_is_oob :
    (outcomeFault? th08Index18Outcome).map (fun fault => fault.kind) =
      some .outOfBoundsWrite := by
  rfl

end TouhouFormal.Search.BulletTransform
