import TouhouFormal.ECL.NumericSpecial
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.NumericSpecial

open TouhouFormal.ECL

def numericSpecialOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.numericSpecialOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawNumericSpecialOutcome) :
    Option RawNumericSpecialEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def th06SelfYPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetVarSelfY
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06SelfYOutcome :
    Except TouhouFormal.Fault RawNumericSpecialOutcome :=
  rawNumericSpecialStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06SelfYPrefix
    { outputs := [ { rawValue := -10005 } ]
      enemyPositionYBits := 0x42F00000 }

def th07LerpPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeLerp
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th07LerpOutcome :
    Except TouhouFormal.Fault RawNumericSpecialOutcome :=
  rawNumericSpecialStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07LerpPrefix
    { outputs := [ { rawValue := 1176260608 } ]
      floatInputs :=
        [ { rawValue := 1176260608, hostValue := 10 },
          { rawValue := 1176261632, hostValue := 20 },
          { rawValue := 1176262656, hostValue := 30 },
          { rawValue := 1176261632, hostValue := 20 } ]
      hostResultBits := [99] }

def th08VectorPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeVectorFromAngleMagnitude
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th08VectorOutcome :
    Except TouhouFormal.Fault RawNumericSpecialOutcome :=
  rawNumericSpecialStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08VectorPrefix
    { outputs :=
        [ { rawValue := 1176272896 },
          { rawValue := 1176273920 } ]
      floatInputs :=
        [ { rawValue := 1176274944, hostValue := 10 },
          { rawValue := 1176275968, hostValue := 20 },
          { rawValue := 1176274944, hostValue := 10 },
          { rawValue := 1176275968, hostValue := 20 } ]
      hostResultBits := [111, 222] }

theorem th06_numeric_special_profile_count :
    numericSpecialOpcodeCount TouhouFormal.TH06.headerShape = 3 := by
  rfl

theorem th07_numeric_special_profile_count :
    numericSpecialOpcodeCount TouhouFormal.TH07.headerShape = 2 := by
  rfl

theorem th08_numeric_special_profile_count :
    numericSpecialOpcodeCount TouhouFormal.TH08.headerShape = 4 := by
  rfl

theorem th06_self_y_copies_position_bits :
    ((outcomeEffect? th06SelfYOutcome).bind
      (fun effect => effect.writes[0]?)).map (fun write => write.resultBits) =
      some 0x42F00000 := by
  rfl

theorem th07_lerp_preserves_repeated_operand_two_read :
    ((outcomeEffect? th07LerpOutcome).map (fun effect => effect.inputBits)) =
      some [10, 20, 30, 20] := by
  rfl

theorem th08_vector_writes_y_before_x :
    ((outcomeEffect? th08VectorOutcome).map
      (fun effect => effect.writes.map (fun write => write.operandIndex))) =
      some [1, 0] := by
  rfl

end TouhouFormal.Search.NumericSpecial
