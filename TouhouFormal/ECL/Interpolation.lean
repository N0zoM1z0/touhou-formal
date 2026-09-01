import TouhouFormal.Core.Float32
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawInterpolationIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawInterpolationFloatInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawInterpolationSlotObservation where
  callbackPresent : Bool := false
  affectedVariableBits : Int := 0
deriving Repr, DecidableEq

structure RawInterpolationOperands where
  affectedVariableBits : Int := 0
  intInputs : List RawInterpolationIntInput := []
  floatInputs : List RawInterpolationFloatInput := []
  slots : List RawInterpolationSlotObservation := []
deriving Repr, DecidableEq

structure RawInterpolationResolvedIntInput where
  operandIndex : Nat
  resolution : RawIntOperandResolution
deriving Repr, DecidableEq

structure RawInterpolationResolvedFloatInput where
  operandIndex : Nat
  resolution : RawFloatOperandResolution
deriving Repr, DecidableEq

structure RawInterpolationSlotWrite where
  slot : Nat
  affectedVariableBits : Int
  timerReset : Bool
  duration : Int
  callbackIndex : Int
  easing : Int
  callbackInstalled : Bool
  parameterBits : List Int
deriving Repr, DecidableEq

structure RawInterpolationEffect where
  selectedSlot : Option Nat := none
  noAvailableSlot : Bool := false
  slotWrite : Option RawInterpolationSlotWrite := none
deriving Repr, DecidableEq

inductive RawInterpolationAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawInterpolationPrepared where
  op : RawInterpolationOpShape
  intResolutions : List RawInterpolationResolvedIntInput := []
  floatResolutions : List RawInterpolationResolvedFloatInput := []
  effect : RawInterpolationEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawInterpolationOutcome where
  action : RawInterpolationAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawInterpolationEffect := none
  fault : Option Fault := none
  prepared : Option RawInterpolationPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.interpolation"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedInterpolationFault
    (shape : HeaderShape)
    (op : RawInterpolationOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.interpolation"
    detail := "interpolation opcode: " ++ detail
    index := some op.opcode }

private def callbackTableFault
    (shape : HeaderShape)
    (op : RawInterpolationOpShape)
    (index : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.interpolation.callbackTable"
    detail :=
      "source indexes the fixed interpolation callback table without checking the resolved callback index"
    index := some index
    bound := some op.callbackTableCount }

private def f32EqualBits (lhs rhs : Int) : Bool :=
  TouhouFormal.f32OrderedBits lhs rhs &&
    !TouhouFormal.f32LessThanBits lhs rhs &&
    !TouhouFormal.f32LessThanBits rhs lhs

private def rawInterpolationCursorOutcome
    (action : RawInterpolationAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawInterpolationEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawInterpolationPrepared := none) :
    RawInterpolationOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def slotEligible
    (affectedVariableBits : Int)
    (slot : RawInterpolationSlotObservation) : Bool :=
  !slot.callbackPresent ||
    f32EqualBits slot.affectedVariableBits affectedVariableBits

private def selectSlot
    (op : RawInterpolationOpShape)
    (operands : RawInterpolationOperands) : Option Nat :=
  (List.range op.slotCount).find? (fun index =>
    match operands.slots[index]? with
    | none => true
    | some slot => slotEligible operands.affectedVariableBits slot)

private def intInputAt
    (shape : HeaderShape)
    (op : RawInterpolationOpShape)
    (operands : RawInterpolationOperands)
    (occurrence operandIndex : Nat) : Except Fault RawInterpolationIntInput :=
  match operands.intInputs[occurrence]? with
  | some value => .ok value
  | none =>
      .error
        (malformedInterpolationFault shape op
          ("missing integer occurrence " ++ toString occurrence ++
            " for operand slot " ++ toString operandIndex))

private def floatInputAt
    (shape : HeaderShape)
    (op : RawInterpolationOpShape)
    (operands : RawInterpolationOperands)
    (occurrence operandIndex : Nat) : Except Fault RawInterpolationFloatInput :=
  match operands.floatInputs[occurrence]? with
  | some value => .ok value
  | none =>
      .error
        (malformedInterpolationFault shape op
          ("missing float occurrence " ++ toString occurrence ++
            " for operand slot " ++ toString operandIndex))

private def resolveIntOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterpolationOpShape)
    (operands : RawInterpolationOperands)
    (occurrence operandIndex : Nat) :
    Except Fault RawInterpolationResolvedIntInput := do
  let input <- intInputAt shape op operands occurrence operandIndex
  let resolution <-
    resolveIntRValue shape rawPrefix operandIndex
      input.rawValue input.hostValue
  .ok { operandIndex := operandIndex, resolution := resolution }

private def resolveFloatInputsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterpolationOpShape)
    (operands : RawInterpolationOperands) :
    Nat -> List Nat -> Except Fault (List RawInterpolationResolvedFloatInput)
  | _, [] => .ok []
  | occurrence, operandIndex :: rest => do
      let input <- floatInputAt shape op operands occurrence operandIndex
      let resolution <-
        resolveFloatRValue shape rawPrefix operandIndex
          input.rawValue input.hostValue
      let tail <-
        resolveFloatInputsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok ({ operandIndex := operandIndex, resolution := resolution } :: tail)

private def indexInBounds (index : Int) (bound : Nat) : Bool :=
  decide (0 <= index ∧ index.toNat < bound)

def rawInterpolationPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterpolationOpShape)
    (operands : RawInterpolationOperands) :
    Except Fault RawInterpolationPrepared := do
  if op.parameterOperandIndices.length != 4 then
    .error
      (malformedInterpolationFault shape op
        "source interpolation slot requires four parameters")
  else
    match selectSlot op operands with
    | none =>
        .ok
          { op := op
            effect := { noAvailableSlot := true } }
    | some slot => do
        let duration <-
          resolveIntOccurrence shape rawPrefix op operands 0
            op.durationOperandIndex
        let callbackIndex <-
          resolveIntOccurrence shape rawPrefix op operands 1
            op.callbackIndexOperandIndex
        let easing <-
          resolveIntOccurrence shape rawPrefix op operands 2
            op.easingOperandIndex
        let intResolutions := [duration, callbackIndex, easing]
        let callbackValue := callbackIndex.resolution.value
        let partialWrite : RawInterpolationSlotWrite :=
          { slot := slot
            affectedVariableBits := operands.affectedVariableBits
            timerReset := true
            duration := duration.resolution.value
            callbackIndex := callbackValue
            easing := easing.resolution.value
            callbackInstalled := false
            parameterBits := [] }
        if !indexInBounds callbackValue op.callbackTableCount then
          .ok
            { op := op
              intResolutions := intResolutions
              effect :=
                { selectedSlot := some slot
                  slotWrite := some partialWrite }
              hostFault := some (callbackTableFault shape op callbackValue) }
        else
          let floats <-
            resolveFloatInputsAux shape rawPrefix op operands 0
              op.parameterOperandIndices
          let write :=
            { partialWrite with
              callbackInstalled := true
              parameterBits :=
                floats.map (fun input => input.resolution.value) }
          .ok
            { op := op
              intResolutions := intResolutions
              floatResolutions := floats
              effect :=
                { selectedSlot := some slot
                  slotWrite := some write } }

def rawInterpolationStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawInterpolationOperands) :
    Except Fault RawInterpolationOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix
            activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawInterpolationCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawInterpolationCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findInterpolationOp? rawPrefix.opcode with
          | none =>
              .ok (rawInterpolationCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawInterpolationPrepare shape rawPrefix op operands
              let action :=
                if prepared.hostFault.isSome then
                  RawInterpolationAction.hostFault
                else
                  RawInterpolationAction.advanced
              .ok
                (rawInterpolationCursorOutcome
                  action rawPrefix bufferSize
                  (some prepared.effect) prepared.hostFault (some prepared))

end TouhouFormal.ECL
