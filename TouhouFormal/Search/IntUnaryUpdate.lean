import TouhouFormal.ECL.Unary
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.IntUnaryUpdate

open TouhouFormal.ECL

def intUnaryUpdateOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | Option.none => 0
  | some rawShape => rawShape.intUnaryUpdates.length

def intUnaryUpdateOutputPolicy?
    (shape : HeaderShape)
    (opcode : Int) : Option RawIntUnaryUpdateOutputPolicy :=
  match shape.rawInstrShape with
  | Option.none => Option.none
  | some rawShape =>
      match rawShape.findIntUnaryUpdate? opcode with
      | Option.none => Option.none
      | some op => some op.outputPolicy

def outcomeAction? (result : Except TouhouFormal.Fault RawIntUnaryUpdateOutcome) :
    Option RawIntUnaryUpdateAction :=
  match result with
  | .error _ => Option.none
  | .ok outcome => some outcome.action

def outcomeResult? (result : Except TouhouFormal.Fault RawIntUnaryUpdateOutcome) :
    Option Int :=
  match result with
  | .error _ => Option.none
  | .ok outcome => outcome.result

def outcomeOutputKind?
    (result : Except TouhouFormal.Fault RawIntUnaryUpdateOutcome) :
    Option RawIntLValueResolutionKind :=
  match result with
  | .error _ => Option.none
  | .ok outcome =>
      match outcome.prepared with
      | Option.none => Option.none
      | some prepared => some prepared.output.kind

def th06IncUnknownPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeMathInc
    nextOffset := 12
    difficultyMask := some 1
    operandMask := none }

def th06IncUnknownOperands : RawIntUnaryUpdateOperands :=
  { outputRaw := 42
    outputHostBefore := 0 }

def th06IncUnknownOutcome : Except TouhouFormal.Fault RawIntUnaryUpdateOutcome :=
  rawIntUnaryUpdateStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06IncUnknownPrefix
    th06IncUnknownOperands

def th07IncResolvedPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeInc
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 1 }

def th07IncResolvedOperands : RawIntUnaryUpdateOperands :=
  { outputRaw := 10000
    outputHostBefore := 41 }

def th07IncResolvedOutcome : Except TouhouFormal.Fault RawIntUnaryUpdateOutcome :=
  rawIntUnaryUpdateStep
    TouhouFormal.TH07.headerShape
    0
    1
    0
    8
    64
    th07IncResolvedPrefix
    th07IncResolvedOperands

def th08DecRawCellPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeDec
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 0 }

def th08DecRawCellOperands : RawIntUnaryUpdateOperands :=
  { outputRaw := 43
    outputHostBefore := 0 }

def th08DecRawCellOutcome : Except TouhouFormal.Fault RawIntUnaryUpdateOutcome :=
  rawIntUnaryUpdateStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08DecRawCellPrefix
    th08DecRawCellOperands

theorem th06_int_unary_update_profile_count :
    intUnaryUpdateOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_int_unary_update_profile_count :
    intUnaryUpdateOpcodeCount TouhouFormal.TH07.headerShape = 2 := by
  rfl

theorem th08_int_unary_update_profile_count :
    intUnaryUpdateOpcodeCount TouhouFormal.TH08.headerShape = 2 := by
  rfl

theorem th06_inc_uses_source_getvar_pointer_policy :
    intUnaryUpdateOutputPolicy? TouhouFormal.TH06.headerShape
      TouhouFormal.TH06.eclOpcodeMathInc = some .sourceGetVarPointer := by
  rfl

theorem th07_inc_uses_int_lvalue_policy :
    intUnaryUpdateOutputPolicy? TouhouFormal.TH07.headerShape
      TouhouFormal.TH07.eclOpcodeInc = some .intLValue := by
  rfl

theorem th06_inc_unknown_output_updates_raw_cell :
    outcomeOutputKind? th06IncUnknownOutcome = some .resolvedDefaultRawCell := by
  rfl

theorem th06_inc_unknown_result :
    outcomeResult? th06IncUnknownOutcome = some 43 := by
  rfl

theorem th07_inc_resolved_result :
    outcomeResult? th07IncResolvedOutcome = some 42 := by
  rfl

theorem th08_dec_raw_cell_result :
    outcomeResult? th08DecRawCellOutcome = some 42 := by
  rfl

end TouhouFormal.Search.IntUnaryUpdate
