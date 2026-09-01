import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawLaserIntInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawLaserFloatInput where
  rawBits : Int
  hostBits : Int := 0
deriving Repr, DecidableEq

structure RawLaserOperands where
  intInputs : List RawLaserIntInput := []
  floatInputs : List RawLaserFloatInput := []
  laserPresent : Bool := true
  laserInUse : Bool := true
  laserState : Int := 0
  currentWidthBits : Int := 0
  playerAngleBits : Int := 0
deriving Repr, DecidableEq

inductive RawLaserIntResolution where
  | intRValue : RawIntOperandResolution -> RawLaserIntResolution
  | rawI32 : Int -> RawLaserIntResolution
  | rawByte : Int -> RawLaserIntResolution
deriving Repr, DecidableEq

def RawLaserIntResolution.value : RawLaserIntResolution -> Int
  | .intRValue value => value.value
  | .rawI32 value
  | .rawByte value => value

inductive RawLaserFloatResolution where
  | floatRValue : RawFloatOperandResolution -> RawLaserFloatResolution
  | rawBits : Int -> RawLaserFloatResolution
deriving Repr, DecidableEq

def RawLaserFloatResolution.bits : RawLaserFloatResolution -> Int
  | .floatRValue value => value.value
  | .rawBits value => value

structure RawLaserResolvedIntInput where
  shape : RawLaserIntInputShape
  resolution : RawLaserIntResolution
deriving Repr, DecidableEq

structure RawLaserResolvedFloatInput where
  shape : RawLaserFloatInputShape
  resolution : RawLaserFloatResolution
deriving Repr, DecidableEq

structure RawLaserVector3Bits where
  x : Int
  y : Int
  z : Int
deriving Repr, DecidableEq

structure RawLaserAngleWrite where
  slot : Int
  mode : RawLaserAngleMode
  operandBits : Int
  playerAngleBits : Option Int := none
deriving Repr, DecidableEq

structure RawLaserPositionWrite where
  slot : Int
  relativeDelta : RawLaserVector3Bits
deriving Repr, DecidableEq

structure RawLaserTestWrite where
  target : RawLaserTestTarget
  value : Int
deriving Repr, DecidableEq

structure RawLaserStopWrite where
  slot : Int
  stateWrite : Int
  timerWrite : Int
  widthWriteBits : Option Int := none
deriving Repr, DecidableEq

structure RawLaserStartLengthWrite where
  slot : Int
  startLengthBits : Int
deriving Repr, DecidableEq

structure RawLaserOffsetsWrite where
  slot : Int
  startOffsetBits : Int
  endOffsetBits : Int
deriving Repr, DecidableEq

structure RawLaserHideWarningWrite where
  slot : Int
  value : Int
deriving Repr, DecidableEq

structure RawLaserEffect where
  selectedSlotWrite : Option Int := none
  clearAllSlots : Option Nat := none
  angleWrite : Option RawLaserAngleWrite := none
  positionWrite : Option RawLaserPositionWrite := none
  testWrite : Option RawLaserTestWrite := none
  stopWrite : Option RawLaserStopWrite := none
  startLengthWrite : Option RawLaserStartLengthWrite := none
  offsetsWrite : Option RawLaserOffsetsWrite := none
  hideWarningWrite : Option RawLaserHideWarningWrite := none
deriving Repr, DecidableEq

inductive RawLaserAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawLaserPrepared where
  op : RawLaserOpShape
  intResolutions : List RawLaserResolvedIntInput
  floatResolutions : List RawLaserResolvedFloatInput
  effect : RawLaserEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawLaserOutcome where
  action : RawLaserAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawLaserEffect := none
  fault : Option Fault := none
  prepared : Option RawLaserPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laser"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedLaserShapeFault
    (shape : HeaderShape)
    (op : RawLaserOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laser"
    detail := "laser opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingLaserIntOperandFault
    (shape : HeaderShape)
    (op : RawLaserOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laser"
    detail :=
      "laser opcode " ++ op.kind.name ++
        " did not receive integer source occurrence " ++
        toString occurrence ++ " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def missingLaserFloatOperandFault
    (shape : HeaderShape)
    (op : RawLaserOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laser"
    detail :=
      "laser opcode " ++ op.kind.name ++
        " did not receive float source occurrence " ++
        toString occurrence ++ " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def laserSlotReadFault
    (shape : HeaderShape)
    (op : RawLaserOpShape)
    (slot : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.laser.slotTable"
    detail :=
      "source reads an enemy laser pointer slot without checking the index"
    index := some slot
    bound := some op.slotCount }

private def rawLaserCursorOutcome
    (action : RawLaserAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawLaserEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawLaserPrepared := none) : RawLaserOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def rawLaserU8FromWord (rawValue : Int) (byteIndex : Nat) : Int :=
  (TouhouFormal.toWord32Bits rawValue / (2 ^ (8 * byteIndex))) % 256

private def resolveLaserIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawLaserIntInputShape)
    (input : RawLaserIntInput) : Except Fault RawLaserResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .intRValue => do
        let value <-
          resolveIntRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawValue
            input.hostValue
        .ok (.intRValue value)
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .rawByte =>
        .ok (.rawByte (rawLaserU8FromWord input.rawValue inputShape.byteIndex))
  .ok { shape := inputShape, resolution := resolution }

private def resolveLaserIntOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserOpShape)
    (operands : RawLaserOperands)
    (occurrence : Nat)
    (inputShape : RawLaserIntInputShape) :
    Except Fault RawLaserResolvedIntInput := do
  let input <-
    match operands.intInputs[occurrence]? with
    | none =>
        .error
          (missingLaserIntOperandFault
            shape op occurrence inputShape.operandIndex)
    | some input => .ok input
  resolveLaserIntInput shape rawPrefix inputShape input

private def resolveLaserFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawLaserFloatInputShape)
    (input : RawLaserFloatInput) : Except Fault RawLaserResolvedFloatInput := do
  let resolution <-
    match inputShape.policy with
    | .floatRValue => do
        let value <-
          resolveFloatRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawBits
            input.hostBits
        .ok (.floatRValue value)
    | .rawBits => .ok (.rawBits input.rawBits)
  .ok { shape := inputShape, resolution := resolution }

private def resolveLaserFloatOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserOpShape)
    (operands : RawLaserOperands)
    (occurrence : Nat)
    (inputShape : RawLaserFloatInputShape) :
    Except Fault RawLaserResolvedFloatInput := do
  let input <-
    match operands.floatInputs[occurrence]? with
    | none =>
        .error
          (missingLaserFloatOperandFault
            shape op occurrence inputShape.operandIndex)
    | some input => .ok input
  resolveLaserFloatInput shape rawPrefix inputShape input

private def laserSlotInBounds (op : RawLaserOpShape) (slot : Int) : Bool :=
  decide (0 <= slot ∧ slot < Int.ofNat op.slotCount)

private def firstIntShape
    (shape : HeaderShape)
    (op : RawLaserOpShape) : Except Fault RawLaserIntInputShape :=
  match op.intInputs with
  | first :: _ => .ok first
  | [] =>
      .error
        (malformedLaserShapeFault
          shape op "indexed laser opcode has no index input")

private def intShapeAt
    (shape : HeaderShape)
    (op : RawLaserOpShape)
    (index : Nat) : Except Fault RawLaserIntInputShape :=
  match op.intInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedLaserShapeFault
          shape op ("missing integer input shape " ++ toString index))

private def floatShapeAt
    (shape : HeaderShape)
    (op : RawLaserOpShape)
    (index : Nat) : Except Fault RawLaserFloatInputShape :=
  match op.floatInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedLaserShapeFault
          shape op ("missing float input shape " ++ toString index))

private def laserFaultPrepared
    (op : RawLaserOpShape)
    (intResolutions : List RawLaserResolvedIntInput)
    (floatResolutions : List RawLaserResolvedFloatInput)
    (effect : RawLaserEffect)
    (fault : Fault) : RawLaserPrepared :=
  { op := op
    intResolutions := intResolutions
    floatResolutions := floatResolutions
    effect := effect
    hostFault := some fault }

private def prepareLaserClearAll
    (op : RawLaserOpShape) : RawLaserPrepared :=
  { op := op
    intResolutions := []
    floatResolutions := []
    effect := { clearAllSlots := some op.slotCount } }

private def prepareLaserSetSelectedSlot
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserOpShape)
    (operands : RawLaserOperands) : Except Fault RawLaserPrepared := do
  let slotShape <- firstIntShape shape op
  let slotRead <-
    resolveLaserIntOccurrence shape rawPrefix op operands 0 slotShape
  let slot := slotRead.resolution.value
  .ok
    { op := op
      intResolutions := [slotRead]
      floatResolutions := []
      effect := { selectedSlotWrite := some slot } }

private def prepareIndexedLaserOp
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserOpShape)
    (operands : RawLaserOperands)
    (slot : Int)
    (slotRead : RawLaserResolvedIntInput) :
    Except Fault RawLaserPrepared := do
  if !laserSlotInBounds op slot then
    let fault := laserSlotReadFault shape op slot
    .ok (laserFaultPrepared op [slotRead] [] {} fault)
  else
    match op.kind with
    | .writeAngle mode =>
        if !operands.laserPresent then
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := []
              effect := {} }
        else
          let valueShape <- floatShapeAt shape op 0
          let valueRead <-
            resolveLaserFloatOccurrence
              shape rawPrefix op operands 0 valueShape
          let effect : RawLaserEffect :=
            { angleWrite :=
                some
                  { slot := slot
                    mode := mode
                    operandBits := valueRead.resolution.bits
                    playerAngleBits :=
                      match mode with
                      | .aimAtPlayer => some operands.playerAngleBits
                      | _ => none } }
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := [valueRead]
              effect := effect }
    | .writeRelativePosition =>
        if !operands.laserPresent then
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := []
              effect := {} }
        else
          let xShape <- floatShapeAt shape op 0
          let yShape <- floatShapeAt shape op 1
          let zShape <- floatShapeAt shape op 2
          let xRead <-
            resolveLaserFloatOccurrence shape rawPrefix op operands 0 xShape
          let yRead <-
            resolveLaserFloatOccurrence shape rawPrefix op operands 1 yShape
          let zRead <-
            resolveLaserFloatOccurrence shape rawPrefix op operands 2 zShape
          let effect : RawLaserEffect :=
            { positionWrite :=
                some
                  { slot := slot
                    relativeDelta :=
                      { x := xRead.resolution.bits
                        y := yRead.resolution.bits
                        z := zRead.resolution.bits } } }
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := [xRead, yRead, zRead]
              effect := effect }
    | .testInUse =>
        let value :=
          if operands.laserPresent && operands.laserInUse then
            op.testActiveValue
          else
            op.testInactiveValue
        .ok
          { op := op
            intResolutions := [slotRead]
            floatResolutions := []
            effect :=
              { testWrite :=
                  some { target := op.testTarget, value := value } } }
    | .stop =>
        let shouldStop :=
          operands.laserPresent &&
            operands.laserInUse &&
            decide (operands.laserState < 2)
        let stopWrite :=
          if shouldStop then
            some
              { slot := slot
                stateWrite := 2
                timerWrite := 0
                widthWriteBits :=
                  if op.stopCopiesCurrentWidth then
                    some operands.currentWidthBits
                  else
                    none }
          else
            none
        .ok
          { op := op
            intResolutions := [slotRead]
            floatResolutions := []
            effect := { stopWrite := stopWrite } }
    | .writeStartLength =>
        if !operands.laserPresent then
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := []
              effect := {} }
        else
          let valueShape <- floatShapeAt shape op 0
          let valueRead <-
            resolveLaserFloatOccurrence
              shape rawPrefix op operands 0 valueShape
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := [valueRead]
              effect :=
                { startLengthWrite :=
                    some
                      { slot := slot
                        startLengthBits := valueRead.resolution.bits } } }
    | .writeOffsets =>
        if !operands.laserPresent then
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := []
              effect := {} }
        else
          let startShape <- floatShapeAt shape op 0
          let endShape <- floatShapeAt shape op 1
          let startRead <-
            resolveLaserFloatOccurrence
              shape rawPrefix op operands 0 startShape
          let endRead <-
            resolveLaserFloatOccurrence
              shape rawPrefix op operands 1 endShape
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := [startRead, endRead]
              effect :=
                { offsetsWrite :=
                    some
                      { slot := slot
                        startOffsetBits := startRead.resolution.bits
                        endOffsetBits := endRead.resolution.bits } } }
    | .writeHideWarning =>
        if !operands.laserPresent then
          .ok
            { op := op
              intResolutions := [slotRead]
              floatResolutions := []
              effect := {} }
        else
          let valueShape <- intShapeAt shape op 1
          let valueRead <-
            resolveLaserIntOccurrence shape rawPrefix op operands 1 valueShape
          let value :=
            if op.hideTruncatesToU8 then
              TouhouFormal.truncateUnsignedBits valueRead.resolution.value 8
            else
              valueRead.resolution.value
          .ok
            { op := op
              intResolutions := [slotRead, valueRead]
              floatResolutions := []
              effect :=
                { hideWarningWrite :=
                    some { slot := slot, value := value } } }
    | .setSelectedSlot | .clearAll =>
        .error
          (malformedLaserShapeFault
            shape op "non-indexed opcode reached indexed laser prepare")

def rawLaserPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserOpShape)
    (operands : RawLaserOperands) : Except Fault RawLaserPrepared := do
  match op.kind with
  | .setSelectedSlot =>
      prepareLaserSetSelectedSlot shape rawPrefix op operands
  | .clearAll => .ok (prepareLaserClearAll op)
  | _ =>
      let indexShape <- firstIntShape shape op
      let slotRead <-
        resolveLaserIntOccurrence shape rawPrefix op operands 0 indexShape
      prepareIndexedLaserOp
        shape rawPrefix op operands slotRead.resolution.value slotRead

def rawLaserStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawLaserOperands) : Except Fault RawLaserOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawLaserCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawLaserCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findLaserOp? rawPrefix.opcode with
          | none =>
              .ok (rawLaserCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawLaserPrepare shape rawPrefix op operands
              let action :=
                match prepared.hostFault with
                | none => .advanced
                | some _ => .hostFault
              .ok
                (rawLaserCursorOutcome
                  action
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  prepared.hostFault
                  (some prepared))

end TouhouFormal.ECL
