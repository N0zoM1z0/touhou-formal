import TouhouFormal.ECL.Assignment
import TouhouFormal.Search.FloatArithmetic
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.ScalarAssignment

open TouhouFormal.ECL

def scalarAssignOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.scalarAssignments.length

def scalarAssignOutputPolicy?
    (shape : HeaderShape)
    (opcode : Int) : Option RawScalarAssignOutputPolicy :=
  match shape.rawInstrShape with
  | none => none
  | some rawShape =>
      match rawShape.findScalarAssign? opcode with
      | none => none
      | some op => some op.outputPolicy

def outcomeAction? (result : Except TouhouFormal.Fault RawScalarAssignOutcome) :
    Option RawScalarAssignAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeWrittenKind? (result : Except TouhouFormal.Fault RawScalarAssignOutcome) :
    Option RawScalarKind :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.writtenKind

def outcomeValueBits? (result : Except TouhouFormal.Fault RawScalarAssignOutcome) :
    Option Int :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.valueBits

def th06SetFloatPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetFloat
    nextOffset := 12
    difficultyMask := some 1
    operandMask := none }

def th06SetFloatOperands : RawScalarAssignOperands :=
  { outputRaw := -10005
    outputIntHostBefore := 0
    outputFloatHostBefore := 0
    valueRaw := TouhouFormal.Search.FloatArithmetic.f32OneBits
    valueHost := TouhouFormal.Search.FloatArithmetic.f32OneBits }

def th06SetFloatOutcome : Except TouhouFormal.Fault RawScalarAssignOutcome :=
  rawScalarAssignStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06SetFloatPrefix
    th06SetFloatOperands

def th07SetFloatPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetFloat
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 3 }

def th07SetFloatOperands : RawScalarAssignOperands :=
  { outputRaw := 1176260608
    outputIntHostBefore := 0
    outputFloatHostBefore := 0
    valueRaw := 1176261632
    valueHost := TouhouFormal.Search.FloatArithmetic.f32OneBits }

def th07SetFloatOutcome : Except TouhouFormal.Fault RawScalarAssignOutcome :=
  rawScalarAssignStep
    TouhouFormal.TH07.headerShape
    0
    1
    0
    8
    64
    th07SetFloatPrefix
    th07SetFloatOperands

def th08SetIntPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetInt
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 3 }

def th08SetIntOperands : RawScalarAssignOperands :=
  { outputRaw := 10000
    outputIntHostBefore := 0
    outputFloatHostBefore := 0
    valueRaw := 10001
    valueHost := 42 }

def th08SetIntOutcome : Except TouhouFormal.Fault RawScalarAssignOutcome :=
  rawScalarAssignStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08SetIntPrefix
    th08SetIntOperands

theorem th06_scalar_assign_profile_count :
    scalarAssignOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_scalar_assign_profile_count :
    scalarAssignOpcodeCount TouhouFormal.TH07.headerShape = 2 := by
  rfl

theorem th08_scalar_assign_profile_count :
    scalarAssignOpcodeCount TouhouFormal.TH08.headerShape = 2 := by
  rfl

theorem th06_set_float_uses_source_setvar_policy :
    scalarAssignOutputPolicy? TouhouFormal.TH06.headerShape
      TouhouFormal.TH06.eclOpcodeSetFloat = some .sourceSetVar := by
  rfl

theorem th07_set_float_uses_float_lvalue_policy :
    scalarAssignOutputPolicy? TouhouFormal.TH07.headerShape
      TouhouFormal.TH07.eclOpcodeSetFloat = some .floatLValue := by
  rfl

theorem th06_set_float_writes_float :
    outcomeWrittenKind? th06SetFloatOutcome = some .float := by
  rfl

theorem th06_set_float_value_bits :
    outcomeValueBits? th06SetFloatOutcome =
      some TouhouFormal.Search.FloatArithmetic.f32OneBits := by
  rfl

theorem th07_set_float_advances :
    outcomeAction? th07SetFloatOutcome = some .advanced := by
  rfl

theorem th07_set_float_value_bits :
    outcomeValueBits? th07SetFloatOutcome =
      some TouhouFormal.Search.FloatArithmetic.f32OneBits := by
  rfl

theorem th08_set_int_writes_int :
    outcomeWrittenKind? th08SetIntOutcome = some .int := by
  rfl

theorem th08_set_int_value_bits :
    outcomeValueBits? th08SetIntOutcome = some 42 := by
  rfl

end TouhouFormal.Search.ScalarAssignment
