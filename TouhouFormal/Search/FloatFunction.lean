import TouhouFormal.ECL.FloatFunction
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.FloatFunction

open TouhouFormal.ECL

def f32ZeroBits : Int := 0
def f32OneBits : Int := 1065353216
def f32PiOverTwoBits : Int := 1070141403
def f32PiOverFourBits : Int := 1061752795

def floatFunctionOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.floatFunctions.length

def floatFunctionKind? (shape : HeaderShape) (opcode : Int) :
    Option RawFloatFunctionKind :=
  match shape.rawInstrShape with
  | none => none
  | some rawShape =>
      match rawShape.findFloatFunction? opcode with
      | none => none
      | some op => some op.kind

def outcomeAction? (result : Except TouhouFormal.Fault RawFloatFunctionOutcome) :
    Option RawFloatFunctionAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeResultBits? (result : Except TouhouFormal.Fault RawFloatFunctionOutcome) :
    Option Int :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.result.map (fun value => value.resultBits)

def outcomeWrittenKind? (result : Except TouhouFormal.Fault RawFloatFunctionOutcome) :
    Option RawScalarKind :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.writtenKind

def th06Atan2Prefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeMathAtan2
    nextOffset := 32
    difficultyMask := some 1
    operandMask := none }

def th06Atan2Operands : RawFloatFunctionOperands :=
  { outputRaw := -10005
    outputIntHostBefore := 0
    outputFloatHostBefore := f32ZeroBits
    inputs :=
      [ { rawValue := f32ZeroBits, hostValue := f32ZeroBits },
        { rawValue := f32ZeroBits, hostValue := f32ZeroBits },
        { rawValue := f32OneBits, hostValue := f32OneBits },
        { rawValue := f32OneBits, hostValue := f32OneBits } ]
    resultBits := f32PiOverFourBits }

def th06Atan2Outcome : Except TouhouFormal.Fault RawFloatFunctionOutcome :=
  rawFloatFunctionStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06Atan2Prefix
    th06Atan2Operands

def th07SinPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSin
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def th07SinOperands : RawFloatFunctionOperands :=
  { outputRaw := 1176260608
    outputIntHostBefore := 0
    outputFloatHostBefore := f32ZeroBits
    inputs :=
      [ { rawValue := f32PiOverTwoBits
          hostValue := f32PiOverTwoBits } ]
    resultBits := f32OneBits }

def th07SinOutcome : Except TouhouFormal.Fault RawFloatFunctionOutcome :=
  rawFloatFunctionStep
    TouhouFormal.TH07.headerShape
    0
    1
    0
    8
    64
    th07SinPrefix
    th07SinOperands

def th08VectorAnglePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeVectorAngle
    nextOffset := 32
    difficultyMask := some 1
    operandMask := some 1 }

def th08VectorAngleOperands : RawFloatFunctionOperands :=
  { outputRaw := 1176272896
    outputIntHostBefore := 0
    outputFloatHostBefore := f32ZeroBits
    inputs :=
      [ { rawValue := f32ZeroBits, hostValue := f32ZeroBits },
        { rawValue := f32ZeroBits, hostValue := f32ZeroBits },
        { rawValue := f32OneBits, hostValue := f32OneBits },
        { rawValue := f32OneBits, hostValue := f32OneBits } ]
    resultBits := f32PiOverFourBits }

def th08VectorAngleOutcome : Except TouhouFormal.Fault RawFloatFunctionOutcome :=
  rawFloatFunctionStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08VectorAnglePrefix
    th08VectorAngleOperands

theorem th06_float_function_profile_count :
    floatFunctionOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_float_function_profile_count :
    floatFunctionOpcodeCount TouhouFormal.TH07.headerShape = 4 := by
  rfl

theorem th08_float_function_profile_count :
    floatFunctionOpcodeCount TouhouFormal.TH08.headerShape = 4 := by
  rfl

theorem th08_vector_angle_profiled_separately_from_atan2 :
    floatFunctionKind?
      TouhouFormal.TH08.headerShape
      TouhouFormal.TH08.eclOpcodeVectorAngle = some .vectorAngle := by
  rfl

theorem th06_atan2_advances :
    outcomeAction? th06Atan2Outcome = some .advanced := by
  rfl

theorem th06_atan2_result_bits_recorded :
    outcomeResultBits? th06Atan2Outcome = some f32PiOverFourBits := by
  rfl

theorem th07_sin_advances :
    outcomeAction? th07SinOutcome = some .advanced := by
  rfl

theorem th07_sin_result_bits_recorded :
    outcomeResultBits? th07SinOutcome = some f32OneBits := by
  rfl

theorem th08_vector_angle_advances :
    outcomeAction? th08VectorAngleOutcome = some .advanced := by
  rfl

theorem th08_vector_angle_writes_float :
    outcomeWrittenKind? th08VectorAngleOutcome = some .float := by
  rfl

end TouhouFormal.Search.FloatFunction
