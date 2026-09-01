import TouhouFormal.ECL.Arithmetic
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.FloatArithmetic

open TouhouFormal.ECL

def f32OneBits : Int := 1065353216
def f32TwoBits : Int := 1073741824
def f32ThreeBits : Int := 1077936128

def floatBinaryOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.floatBinaryOps.length

def floatBinaryKind? (shape : HeaderShape) (opcode : Int) : Option RawBinaryOpKind :=
  match shape.rawInstrShape with
  | none => none
  | some rawShape =>
      match rawShape.findFloatBinaryOp? opcode with
      | none => none
      | some op => some op.kind

def outcomeAction? (result : Except TouhouFormal.Fault RawFloatBinaryOpOutcome) :
    Option RawFloatBinaryOpAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeResultBits? (result : Except TouhouFormal.Fault RawFloatBinaryOpOutcome) :
    Option Int :=
  match result with
  | .error _ => none
  | .ok outcome =>
      match outcome.result with
      | none => none
      | some value => some value.resultBits

def th06FloatAddPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeMathFloatAdd
    nextOffset := 12
    difficultyMask := some 1
    operandMask := none }

def th06FloatAddOperands : RawFloatBinaryOpOperands :=
  { outputRaw := -10005
    outputHostBefore := 0
    lhsRaw := f32OneBits
    rhsRaw := f32TwoBits
    lhsHost := f32OneBits
    rhsHost := f32TwoBits
    resultBits := f32ThreeBits }

def th06FloatAddOutcome : Except TouhouFormal.Fault RawFloatBinaryOpOutcome :=
  rawFloatBinaryStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06FloatAddPrefix
    th06FloatAddOperands

def th07FloatAddPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeFloatAdd
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 7 }

def th07FloatAddOperands : RawFloatBinaryOpOperands :=
  { outputRaw := 1176260608
    outputHostBefore := 0
    lhsRaw := 1176260608
    rhsRaw := 1176261632
    lhsHost := f32OneBits
    rhsHost := f32TwoBits
    resultBits := f32ThreeBits }

def th07FloatAddOutcome : Except TouhouFormal.Fault RawFloatBinaryOpOutcome :=
  rawFloatBinaryStep
    TouhouFormal.TH07.headerShape
    0
    1
    0
    8
    64
    th07FloatAddPrefix
    th07FloatAddOperands

def th08FloatAddInPlacePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeFloatAddInPlace
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 3 }

def th08FloatAddInPlaceOperands : RawFloatBinaryOpOperands :=
  { outputRaw := 1176272896
    outputHostBefore := f32OneBits
    lhsRaw := 1176272896
    rhsRaw := 1176273920
    lhsHost := f32OneBits
    rhsHost := f32TwoBits
    resultBits := f32ThreeBits }

def th08FloatAddInPlaceOutcome : Except TouhouFormal.Fault RawFloatBinaryOpOutcome :=
  rawFloatBinaryStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08FloatAddInPlacePrefix
    th08FloatAddInPlaceOperands

theorem th06_float_binary_profile_count :
    floatBinaryOpcodeCount TouhouFormal.TH06.headerShape = 5 := by
  rfl

theorem th07_float_binary_profile_count :
    floatBinaryOpcodeCount TouhouFormal.TH07.headerShape = 5 := by
  rfl

theorem th08_float_binary_profile_count :
    floatBinaryOpcodeCount TouhouFormal.TH08.headerShape = 10 := by
  rfl

theorem th08_float_mod_in_place_profiled :
    floatBinaryKind? TouhouFormal.TH08.headerShape
      TouhouFormal.TH08.eclOpcodeFloatModInPlace = some .mod := by
  rfl

theorem th06_float_add_advances :
    outcomeAction? th06FloatAddOutcome = some .advanced := by
  rfl

theorem th06_float_add_result_bits_recorded :
    outcomeResultBits? th06FloatAddOutcome = some f32ThreeBits := by
  rfl

theorem th07_float_add_advances :
    outcomeAction? th07FloatAddOutcome = some .advanced := by
  rfl

theorem th07_float_add_result_bits_recorded :
    outcomeResultBits? th07FloatAddOutcome = some f32ThreeBits := by
  rfl

theorem th08_float_add_in_place_advances :
    outcomeAction? th08FloatAddInPlaceOutcome = some .advanced := by
  rfl

theorem th08_float_add_in_place_result_bits_recorded :
    outcomeResultBits? th08FloatAddInPlaceOutcome = some f32ThreeBits := by
  rfl

end TouhouFormal.Search.FloatArithmetic
