import TouhouFormal.ECL.Random
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Random

open TouhouFormal.ECL

def f32OneBits : Int := 1065353216
def f32TwoBits : Int := 1073741824
def f32TwoPointFiveBits : Int := 1075838976

def randomOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.randomOps.length

def randomKind? (shape : HeaderShape) (opcode : Int) : Option RawRandomOpKind :=
  match shape.rawInstrShape with
  | none => none
  | some rawShape =>
      match rawShape.findRandomOp? opcode with
      | none => none
      | some op => some op.kind

def outcomeAction? (result : Except TouhouFormal.Fault RawRandomOutcome) :
    Option RawRandomAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeGeneratedWord? (result : Except TouhouFormal.Fault RawRandomOutcome) :
    Option Int :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.result.map (fun value => value.generatedWord)

def outcomeWrittenWord? (result : Except TouhouFormal.Fault RawRandomOutcome) :
    Option Int :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.result.map (fun value => value.writtenWord)

def outcomePositiveSign? (result : Except TouhouFormal.Fault RawRandomOutcome) :
    Option Bool :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.result.bind (fun value => value.positiveSign)

def th06IntRandPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetIntRand
    nextOffset := 20
    difficultyMask := some 1
    operandMask := none }

def th06IntRandOperands : RawRandomOperands :=
  { outputRaw := -10001
    outputIntHostBefore := 0
    outputFloatHostBefore := 0
    valueRaw := 10
    valueHost := 10
    rngWord := 17 }

def th06IntRandOutcome : Except TouhouFormal.Fault RawRandomOutcome :=
  rawRandomStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06IntRandPrefix
    th06IntRandOperands

def th07FloatRandAddPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeRandFloatAdd
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 7 }

def th07FloatRandAddOperands : RawRandomOperands :=
  { outputRaw := 1176260608
    outputIntHostBefore := 0
    outputFloatHostBefore := 0
    valueRaw := f32TwoBits
    valueHost := f32TwoBits
    addendRaw := f32OneBits
    addendHost := f32OneBits
    rngWord := 1234
    floatResultBits := f32TwoPointFiveBits }

def th07FloatRandAddOutcome : Except TouhouFormal.Fault RawRandomOutcome :=
  rawRandomStep
    TouhouFormal.TH07.headerShape
    0
    1
    0
    8
    64
    th07FloatRandAddPrefix
    th07FloatRandAddOperands

def th08IntSignPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeRandSign
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def th08IntSignOperands : RawRandomOperands :=
  { outputRaw := 10000
    outputIntHostBefore := 0
    outputFloatHostBefore := 0
    valueRaw := 10001
    valueHost := 42
    rngWord := 2 }

def th08IntSignOutcome : Except TouhouFormal.Fault RawRandomOutcome :=
  rawRandomStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08IntSignPrefix
    th08IntSignOperands

theorem th06_random_profile_count :
    randomOpcodeCount TouhouFormal.TH06.headerShape = 4 := by
  rfl

theorem th07_random_profile_count :
    randomOpcodeCount TouhouFormal.TH07.headerShape = 6 := by
  rfl

theorem th08_random_profile_count :
    randomOpcodeCount TouhouFormal.TH08.headerShape = 2 := by
  rfl

theorem th06_random_write_reuses_source_setvar :
    match TouhouFormal.TH06.headerShape.rawInstrShape with
    | none => false
    | some rawShape =>
        match rawShape.findRandomOp? TouhouFormal.TH06.eclOpcodeSetIntRand with
        | none => false
        | some op => op.writePolicy == .sourceSetVarResolvesResultBits := by
  rfl

theorem th08_random_sign_profiled :
    randomKind?
      TouhouFormal.TH08.headerShape
      TouhouFormal.TH08.eclOpcodeRandSign = some .intSign := by
  rfl

theorem zero_integer_range_returns_zero :
    randomU32InRangeWord 4294967295 0 = 0 := by
  rfl

theorem th06_int_rand_advances :
    outcomeAction? th06IntRandOutcome = some .advanced := by
  rfl

theorem th06_int_rand_uses_unsigned_modulo :
    outcomeWrittenWord? th06IntRandOutcome = some 7 := by
  rfl

theorem th07_float_rand_add_records_external_result :
    outcomeGeneratedWord? th07FloatRandAddOutcome = some f32TwoPointFiveBits := by
  rfl

theorem th08_even_rng_word_selects_negative_sign :
    outcomePositiveSign? th08IntSignOutcome = some false := by
  rfl

theorem th08_negative_sign_wraps_to_i32_word :
    outcomeWrittenWord? th08IntSignOutcome = some 4294967254 := by
  rfl

end TouhouFormal.Search.Random
