import TouhouFormal.ECL.Body
import TouhouFormal.ECL.Comparison
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Comparison

open TouhouFormal.ECL

def compareRegisterOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.compareRegisterOps.length

def floatConditionJumpOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.floatConditionJumps.length

def compareOutcomeRegister?
    (result : Except TouhouFormal.Fault RawCompareRegisterOutcome) : Option Int :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.compareRegister

def stepOutcomeAction?
    (result : Except TouhouFormal.Fault RawStepOutcome) : Option RawStepAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def stepOutcomeTargetTime?
    (result : Except TouhouFormal.Fault RawStepOutcome) : Option Int :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.targetTime

def th06CmpIntPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeCmpInt
    nextOffset := 20
    difficultyMask := some 1
    operandMask := none }

def th06CmpIntOperands : RawCompareRegisterOperands :=
  { lhsRaw := -10001
    rhsRaw := 7
    lhsHost := 5
    rhsHost := 7 }

def th06CmpIntOutcome : Except TouhouFormal.Fault RawCompareRegisterOutcome :=
  rawCompareRegisterStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06CmpIntPrefix
    th06CmpIntOperands

def th06CmpFloatUnorderedPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeCmpFloat
    nextOffset := 20
    difficultyMask := some 1
    operandMask := none }

def th06CmpFloatUnorderedOperands : RawCompareRegisterOperands :=
  { lhsRaw := 2143289344
    rhsRaw := 0
    lhsHost := 2143289344
    rhsHost := 0
    floatOrder := .unordered }

def th06CmpFloatUnorderedOutcome :
    Except TouhouFormal.Fault RawCompareRegisterOutcome :=
  rawCompareRegisterStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06CmpFloatUnorderedPrefix
    th06CmpFloatUnorderedOperands

def th07FloatNeqUnorderedPrefix : RawInstrPrefix :=
  { fileOffset := 4
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeJumpIfNeqFloat
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 0 }

def th07FloatNeqUnorderedOperands : RawFloatConditionJumpOperands :=
  { lhsRaw := 2143289344
    rhsRaw := 0
    lhsHost := 2143289344
    rhsHost := 0
    order := .unordered
    targetTime := 9
    displacement := 12 }

def th07FloatNeqUnorderedOutcome : Except TouhouFormal.Fault RawStepOutcome :=
  rawFloatConditionJumpStep
    TouhouFormal.TH07.headerShape
    0
    1
    0
    8
    64
    th07FloatNeqUnorderedPrefix
    th07FloatNeqUnorderedOperands

def th08FloatGeLessPrefix : RawInstrPrefix :=
  { fileOffset := 4
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeJumpIfGeqFloat
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 0 }

def th08FloatGeLessOperands : RawFloatConditionJumpOperands :=
  { lhsRaw := 0
    rhsRaw := 1065353216
    lhsHost := 0
    rhsHost := 1065353216
    order := .less
    targetTime := 9
    displacement := 12 }

def th08FloatGeLessOutcome : Except TouhouFormal.Fault RawStepOutcome :=
  rawFloatConditionJumpStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08FloatGeLessPrefix
    th08FloatGeLessOperands

theorem th06_compare_register_profile_count :
    compareRegisterOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_compare_register_profile_count :
    compareRegisterOpcodeCount TouhouFormal.TH07.headerShape = 0 := by
  rfl

theorem th08_compare_register_profile_count :
    compareRegisterOpcodeCount TouhouFormal.TH08.headerShape = 0 := by
  rfl

theorem th06_float_condition_jump_profile_count :
    floatConditionJumpOpcodeCount TouhouFormal.TH06.headerShape = 0 := by
  rfl

theorem th07_float_condition_jump_profile_count :
    floatConditionJumpOpcodeCount TouhouFormal.TH07.headerShape = 6 := by
  rfl

theorem th08_float_condition_jump_profile_count :
    floatConditionJumpOpcodeCount TouhouFormal.TH08.headerShape = 6 := by
  rfl

theorem unordered_float_only_satisfies_neq :
    RawIntCompareOp.eq.holdsFloatOrder .unordered = false /\
      RawIntCompareOp.neq.holdsFloatOrder .unordered = true /\
      RawIntCompareOp.lt.holdsFloatOrder .unordered = false /\
      RawIntCompareOp.le.holdsFloatOrder .unordered = false /\
      RawIntCompareOp.gt.holdsFloatOrder .unordered = false /\
      RawIntCompareOp.ge.holdsFloatOrder .unordered = false := by
  decide

theorem th06_cmp_int_sets_less :
    compareOutcomeRegister? th06CmpIntOutcome = some (-1) := by
  rfl

theorem th06_cmp_float_unordered_sets_greater :
    compareOutcomeRegister? th06CmpFloatUnorderedOutcome = some 1 := by
  rfl

theorem th07_float_neq_unordered_jumps :
    stepOutcomeAction? th07FloatNeqUnorderedOutcome = some .jumped := by
  rfl

theorem th07_float_neq_unordered_sets_target_time :
    stepOutcomeTargetTime? th07FloatNeqUnorderedOutcome = some 9 := by
  rfl

theorem th08_float_ge_less_advances :
    stepOutcomeAction? th08FloatGeLessOutcome = some .advanced := by
  rfl

end TouhouFormal.Search.Comparison
