import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawBulletTransformIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawBulletTransformFloatInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawBulletTransformOperands where
  intInputs : List RawBulletTransformIntInput := []
  floatInputs : List RawBulletTransformFloatInput := []
deriving Repr, DecidableEq

structure RawBulletTransformResolvedIntInput where
  shape : RawBulletTransformIntInputShape
  resolution : RawIntOperandResolution
deriving Repr, DecidableEq

structure RawBulletTransformResolvedFloatInput where
  shape : RawBulletTransformFloatInputShape
  resolution : RawFloatOperandResolution
deriving Repr, DecidableEq

structure RawBulletTransformEntryWrite where
  index : Int
  kind : Int
  flag : Option Int := none
  duration : Option Int := none
  loopCount : Option Int := none
  allowWhileActive : Option Int := none
  payloadInt0 : Option Int := none
  payloadInt1 : Option Int := none
  speedBits : Option Int := none
  angleBits : Option Int := none
  payloadFloat0Bits : Option Int := none
  payloadFloat1Bits : Option Int := none
deriving Repr, DecidableEq

structure RawBulletTransformEffect where
  selectedIndex : Int
  tableCount : Nat
  entryWrite : Option RawBulletTransformEntryWrite := none
deriving Repr, DecidableEq

inductive RawBulletTransformAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawBulletTransformPrepared where
  op : RawBulletTransformOpShape
  intResolutions : List RawBulletTransformResolvedIntInput := []
  floatResolutions : List RawBulletTransformResolvedFloatInput := []
  effect : RawBulletTransformEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawBulletTransformOutcome where
  action : RawBulletTransformAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawBulletTransformEffect := none
  fault : Option Fault := none
  prepared : Option RawBulletTransformPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bulletTransform"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedBulletTransformFault
    (shape : HeaderShape)
    (op : RawBulletTransformOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bulletTransform"
    detail := op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def tableWriteFault
    (shape : HeaderShape)
    (op : RawBulletTransformOpShape)
    (index : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.bulletTransform.table"
    detail :=
      "source writes a fixed bullet command/transform table without checking the resolved index"
    index := some index
    bound := some op.tableCount }

private def rawBulletTransformCursorOutcome
    (action : RawBulletTransformAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawBulletTransformEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawBulletTransformPrepared := none) :
    RawBulletTransformOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def expectedIntRoles :
    RawBulletTransformOpKind -> List RawBulletTransformIntRole
  | .legacyCommand => [.index, .kind, .flag, .duration, .loopCount]
  | .transformRecord =>
      [.index, .kind, .allowWhileActive, .payloadInt0, .payloadInt1]

private def expectedFloatRoles :
    RawBulletTransformOpKind -> List RawBulletTransformFloatRole
  | .legacyCommand => [.speed, .angle]
  | .transformRecord => [.payloadFloat0, .payloadFloat1]

private def resolveIntAt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletTransformOpShape)
    (operands : RawBulletTransformOperands)
    (occurrence : Nat)
    (inputShape : RawBulletTransformIntInputShape) :
    Except Fault RawBulletTransformResolvedIntInput := do
  let input <-
    match operands.intInputs[occurrence]? with
    | some value => .ok value
    | none =>
        .error
          (malformedBulletTransformFault shape op
            ("missing integer role " ++ inputShape.role.name))
  let resolution <-
    resolveIntRValue shape rawPrefix inputShape.operandIndex
      input.rawValue input.hostValue
  .ok { shape := inputShape, resolution := resolution }

private def resolveFloatAt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletTransformOpShape)
    (operands : RawBulletTransformOperands)
    (occurrence : Nat)
    (inputShape : RawBulletTransformFloatInputShape) :
    Except Fault RawBulletTransformResolvedFloatInput := do
  let input <-
    match operands.floatInputs[occurrence]? with
    | some value => .ok value
    | none =>
        .error
          (malformedBulletTransformFault shape op
            ("missing float role " ++ inputShape.role.name))
  let resolution <-
    resolveFloatRValue shape rawPrefix inputShape.operandIndex
      input.rawValue input.hostValue
  .ok { shape := inputShape, resolution := resolution }

private def resolveRemainingIntsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletTransformOpShape)
    (operands : RawBulletTransformOperands) :
    Nat -> List RawBulletTransformIntInputShape ->
      Except Fault (List RawBulletTransformResolvedIntInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let head <-
        resolveIntAt shape rawPrefix op operands occurrence inputShape
      let tail <-
        resolveRemainingIntsAux shape rawPrefix op operands
          (occurrence + 1) rest
      .ok (head :: tail)

private def resolveFloatsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletTransformOpShape)
    (operands : RawBulletTransformOperands) :
    Nat -> List RawBulletTransformFloatInputShape ->
      Except Fault (List RawBulletTransformResolvedFloatInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let head <-
        resolveFloatAt shape rawPrefix op operands occurrence inputShape
      let tail <-
        resolveFloatsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def intByRole?
    (inputs : List RawBulletTransformResolvedIntInput)
    (role : RawBulletTransformIntRole) : Option Int :=
  (inputs.find? (fun input => input.shape.role == role)).map
    (fun input => input.resolution.value)

private def floatByRole?
    (inputs : List RawBulletTransformResolvedFloatInput)
    (role : RawBulletTransformFloatRole) : Option Int :=
  (inputs.find? (fun input => input.shape.role == role)).map
    (fun input => input.resolution.value)

private def indexInBounds (index : Int) (bound : Nat) : Bool :=
  decide (0 <= index ∧ index.toNat < bound)

def rawBulletTransformPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletTransformOpShape)
    (operands : RawBulletTransformOperands) :
    Except Fault RawBulletTransformPrepared := do
  if op.intInputs.map (fun input => input.role) != expectedIntRoles op.kind ||
      op.floatInputs.map (fun input => input.role) != expectedFloatRoles op.kind then
    .error
      (malformedBulletTransformFault shape op
        "profile roles do not match the source record layout")
  else
    let indexShape <-
      match op.intInputs[0]? with
      | some value => .ok value
      | none =>
          .error
            (malformedBulletTransformFault shape op "missing index role")
    let indexRead <-
      resolveIntAt shape rawPrefix op operands 0 indexShape
    let index := indexRead.resolution.value
    let baseEffect : RawBulletTransformEffect :=
      { selectedIndex := index, tableCount := op.tableCount }
    if !indexInBounds index op.tableCount then
      .ok
        { op := op
          intResolutions := [indexRead]
          effect := baseEffect
          hostFault := some (tableWriteFault shape op index) }
    else
      let remainingInts <-
        resolveRemainingIntsAux shape rawPrefix op operands 1
          (op.intInputs.drop 1)
      let intReads := indexRead :: remainingInts
      let floats <-
        resolveFloatsAux shape rawPrefix op operands 0 op.floatInputs
      let kind := (intByRole? intReads .kind).getD 0
      let entry : RawBulletTransformEntryWrite :=
        { index := index
          kind := TouhouFormal.toWord32Bits kind
          flag := intByRole? intReads .flag
          duration := intByRole? intReads .duration
          loopCount := intByRole? intReads .loopCount
          allowWhileActive := intByRole? intReads .allowWhileActive
          payloadInt0 := intByRole? intReads .payloadInt0
          payloadInt1 := intByRole? intReads .payloadInt1
          speedBits := floatByRole? floats .speed
          angleBits := floatByRole? floats .angle
          payloadFloat0Bits := floatByRole? floats .payloadFloat0
          payloadFloat1Bits := floatByRole? floats .payloadFloat1 }
      .ok
        { op := op
          intResolutions := intReads
          floatResolutions := floats
          effect := { baseEffect with entryWrite := some entry } }

def rawBulletTransformStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawBulletTransformOperands) :
    Except Fault RawBulletTransformOutcome :=
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
          .ok (rawBulletTransformCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawBulletTransformCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findBulletTransformOp? rawPrefix.opcode with
          | none =>
              .ok
                (rawBulletTransformCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawBulletTransformPrepare shape rawPrefix op operands
              let action :=
                if prepared.hostFault.isSome then
                  RawBulletTransformAction.hostFault
                else
                  RawBulletTransformAction.advanced
              .ok
                (rawBulletTransformCursorOutcome
                  action rawPrefix bufferSize
                  (some prepared.effect) prepared.hostFault (some prepared))

end TouhouFormal.ECL
