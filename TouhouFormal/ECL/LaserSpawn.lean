import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawLaserSpawnIntInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawLaserSpawnFloatInput where
  rawBits : Int
  hostBits : Int := 0
deriving Repr, DecidableEq

structure RawLaserSpawnVector3Bits where
  x : Int
  y : Int
  z : Int
deriving Repr, DecidableEq

structure RawLaserSpawnOperands where
  intInputs : List RawLaserSpawnIntInput := []
  floatInputs : List RawLaserSpawnFloatInput := []
  positionBits : RawLaserSpawnVector3Bits := { x := 0, y := 0, z := 0 }
  selectedSlot : Int := 0
deriving Repr, DecidableEq

inductive RawLaserSpawnIntResolution where
  | raw : Int -> RawLaserSpawnIntResolution
  | intRValue : RawIntOperandResolution -> RawLaserSpawnIntResolution
deriving Repr, DecidableEq

def RawLaserSpawnIntResolution.sourceValue :
    RawLaserSpawnIntResolution -> Int
  | .raw value => value
  | .intRValue value => value.value

def RawLaserSpawnIntResolution.storedValue
    (policy : RawLaserSpawnIntStorePolicy)
    (resolution : RawLaserSpawnIntResolution) : Int :=
  match policy with
  | .i32 => TouhouFormal.word32BitsToInt resolution.sourceValue
  | .signedI16 =>
      TouhouFormal.word16BitsToInt
        (TouhouFormal.toWord16Bits resolution.sourceValue)
  | .u32 => TouhouFormal.toWord32Bits resolution.sourceValue

inductive RawLaserSpawnFloatResolution where
  | rawBits : Int -> RawLaserSpawnFloatResolution
  | floatRValue : RawFloatOperandResolution -> RawLaserSpawnFloatResolution
deriving Repr, DecidableEq

def RawLaserSpawnFloatResolution.bits :
    RawLaserSpawnFloatResolution -> Int
  | .rawBits value => value
  | .floatRValue value => value.value

structure RawLaserSpawnResolvedIntInput where
  shape : RawLaserSpawnIntInputShape
  resolution : RawLaserSpawnIntResolution
deriving Repr, DecidableEq

def RawLaserSpawnResolvedIntInput.storedValue
    (input : RawLaserSpawnResolvedIntInput) : Int :=
  input.resolution.storedValue input.shape.storePolicy

structure RawLaserSpawnResolvedFloatInput where
  shape : RawLaserSpawnFloatInputShape
  resolution : RawLaserSpawnFloatResolution
deriving Repr, DecidableEq

structure RawLaserSpawnDescriptor where
  target : RawLaserSpawnDescriptorTarget
  positionSource : RawLaserSpawnPositionSource
  positionBits : RawLaserSpawnVector3Bits
  spriteOrBulletType : Int
  color : Int
  angleBits : Int
  speedBits : Int
  startOffsetBits : Int
  endOffsetBits : Int
  startLengthBits : Int
  widthBits : Int
  startTime : Int
  duration : Int
  despawnOrEndTime : Int
  hitboxStartTime : Int
  hitboxEndDelayOrTime : Int
  flagsOrTransformFlags : Int
  aimKind : RawLaserSpawnAimKind
  storedAimValue : Int
deriving Repr, DecidableEq

structure RawLaserSpawnSlotWrite where
  slot : Int
  slotCount : Nat
  descriptorTarget : RawLaserSpawnDescriptorTarget
deriving Repr, DecidableEq

structure RawLaserSpawnEffect where
  descriptorWrite : Option RawLaserSpawnDescriptor := none
  spawnRequest : Bool := false
  slotWrite : Option RawLaserSpawnSlotWrite := none
deriving Repr, DecidableEq

inductive RawLaserSpawnAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawLaserSpawnPrepared where
  op : RawLaserSpawnOpShape
  intResolutions : List RawLaserSpawnResolvedIntInput
  floatResolutions : List RawLaserSpawnResolvedFloatInput
  effect : RawLaserSpawnEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawLaserSpawnOutcome where
  action : RawLaserSpawnAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawLaserSpawnEffect := none
  fault : Option Fault := none
  prepared : Option RawLaserSpawnPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laserSpawn"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedLaserSpawnShapeFault
    (shape : HeaderShape)
    (op : RawLaserSpawnOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laserSpawn"
    detail :=
      "laser-spawn opcode " ++ op.aimKind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingLaserSpawnIntOperandFault
    (shape : HeaderShape)
    (op : RawLaserSpawnOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laserSpawn"
    detail :=
      "laser-spawn opcode " ++ op.aimKind.name ++
        " did not receive integer source occurrence " ++
        toString occurrence ++ " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def missingLaserSpawnFloatOperandFault
    (shape : HeaderShape)
    (op : RawLaserSpawnOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.laserSpawn"
    detail :=
      "laser-spawn opcode " ++ op.aimKind.name ++
        " did not receive float source occurrence " ++
        toString occurrence ++ " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def laserSpawnSlotWriteFault
    (shape : HeaderShape)
    (op : RawLaserSpawnOpShape)
    (slot : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.laserSpawn.slotTable"
    detail :=
      "source writes the spawned laser pointer into an enemy laser slot without checking the selected index"
    index := some slot
    bound := some op.slotCount }

private def rawLaserSpawnCursorOutcome
    (action : RawLaserSpawnAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawLaserSpawnEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawLaserSpawnPrepared := none) :
    RawLaserSpawnOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def resolveLaserSpawnIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawLaserSpawnIntInputShape)
    (input : RawLaserSpawnIntInput) :
    Except Fault RawLaserSpawnResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .raw => .ok (.raw input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue
            shape
            rawPrefix
            inputShape.flagIndex
            input.rawValue
            input.hostValue
        .ok (.intRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveLaserSpawnIntOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserSpawnOpShape)
    (operands : RawLaserSpawnOperands)
    (occurrence : Nat)
    (inputShape : RawLaserSpawnIntInputShape) :
    Except Fault RawLaserSpawnResolvedIntInput := do
  let input <-
    match operands.intInputs[occurrence]? with
    | none =>
        .error
          (missingLaserSpawnIntOperandFault
            shape op occurrence inputShape.operandIndex)
    | some input => .ok input
  resolveLaserSpawnIntInput shape rawPrefix inputShape input

private def resolveLaserSpawnFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawLaserSpawnFloatInputShape)
    (input : RawLaserSpawnFloatInput) :
    Except Fault RawLaserSpawnResolvedFloatInput := do
  let resolution <-
    match inputShape.policy with
    | .rawBits => .ok (.rawBits input.rawBits)
    | .floatRValue => do
        let value <-
          resolveFloatRValue
            shape
            rawPrefix
            inputShape.flagIndex
            input.rawBits
            input.hostBits
        .ok (.floatRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveLaserSpawnFloatOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserSpawnOpShape)
    (operands : RawLaserSpawnOperands)
    (occurrence : Nat)
    (inputShape : RawLaserSpawnFloatInputShape) :
    Except Fault RawLaserSpawnResolvedFloatInput := do
  let input <-
    match operands.floatInputs[occurrence]? with
    | none =>
        .error
          (missingLaserSpawnFloatOperandFault
            shape op occurrence inputShape.operandIndex)
    | some input => .ok input
  resolveLaserSpawnFloatInput shape rawPrefix inputShape input

private def laserSpawnIntShapeAt
    (shape : HeaderShape)
    (op : RawLaserSpawnOpShape)
    (index : Nat) : Except Fault RawLaserSpawnIntInputShape :=
  match op.intInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedLaserSpawnShapeFault
          shape op ("missing integer input shape " ++ toString index))

private def laserSpawnFloatShapeAt
    (shape : HeaderShape)
    (op : RawLaserSpawnOpShape)
    (index : Nat) : Except Fault RawLaserSpawnFloatInputShape :=
  match op.floatInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedLaserSpawnShapeFault
          shape op ("missing float input shape " ++ toString index))

private def laserSpawnSlotInBounds
    (op : RawLaserSpawnOpShape)
    (slot : Int) : Bool :=
  decide (0 <= slot ∧ slot < Int.ofNat op.slotCount)

def rawLaserSpawnPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLaserSpawnOpShape)
    (operands : RawLaserSpawnOperands) :
    Except Fault RawLaserSpawnPrepared := do
  let spriteShape <- laserSpawnIntShapeAt shape op 0
  let colorShape <- laserSpawnIntShapeAt shape op 1
  let startTimeShape <- laserSpawnIntShapeAt shape op 2
  let durationShape <- laserSpawnIntShapeAt shape op 3
  let despawnShape <- laserSpawnIntShapeAt shape op 4
  let hitboxStartShape <- laserSpawnIntShapeAt shape op 5
  let hitboxEndShape <- laserSpawnIntShapeAt shape op 6
  let flagsShape <- laserSpawnIntShapeAt shape op 7
  let angleShape <- laserSpawnFloatShapeAt shape op 0
  let speedShape <- laserSpawnFloatShapeAt shape op 1
  let startOffsetShape <- laserSpawnFloatShapeAt shape op 2
  let endOffsetShape <- laserSpawnFloatShapeAt shape op 3
  let startLengthShape <- laserSpawnFloatShapeAt shape op 4
  let widthShape <- laserSpawnFloatShapeAt shape op 5
  let spriteRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 0 spriteShape
  let colorRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 1 colorShape
  let angleRead <-
    resolveLaserSpawnFloatOccurrence
      shape rawPrefix op operands 0 angleShape
  let speedRead <-
    resolveLaserSpawnFloatOccurrence
      shape rawPrefix op operands 1 speedShape
  let startOffsetRead <-
    resolveLaserSpawnFloatOccurrence
      shape rawPrefix op operands 2 startOffsetShape
  let endOffsetRead <-
    resolveLaserSpawnFloatOccurrence
      shape rawPrefix op operands 3 endOffsetShape
  let startLengthRead <-
    resolveLaserSpawnFloatOccurrence
      shape rawPrefix op operands 4 startLengthShape
  let widthRead <-
    resolveLaserSpawnFloatOccurrence
      shape rawPrefix op operands 5 widthShape
  let startTimeRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 2 startTimeShape
  let durationRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 3 durationShape
  let despawnRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 4 despawnShape
  let hitboxStartRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 5 hitboxStartShape
  let hitboxEndRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 6 hitboxEndShape
  let flagsRead <-
    resolveLaserSpawnIntOccurrence
      shape rawPrefix op operands 7 flagsShape
  let intReads :=
    [ spriteRead,
      colorRead,
      startTimeRead,
      durationRead,
      despawnRead,
      hitboxStartRead,
      hitboxEndRead,
      flagsRead ]
  let floatReads :=
    [ angleRead,
      speedRead,
      startOffsetRead,
      endOffsetRead,
      startLengthRead,
      widthRead ]
  let descriptor : RawLaserSpawnDescriptor :=
    { target := op.descriptorTarget
      positionSource := op.positionSource
      positionBits := operands.positionBits
      spriteOrBulletType := spriteRead.storedValue
      color := colorRead.storedValue
      angleBits := angleRead.resolution.bits
      speedBits := speedRead.resolution.bits
      startOffsetBits := startOffsetRead.resolution.bits
      endOffsetBits := endOffsetRead.resolution.bits
      startLengthBits := startLengthRead.resolution.bits
      widthBits := widthRead.resolution.bits
      startTime := startTimeRead.storedValue
      duration := durationRead.storedValue
      despawnOrEndTime := despawnRead.storedValue
      hitboxStartTime := hitboxStartRead.storedValue
      hitboxEndDelayOrTime := hitboxEndRead.storedValue
      flagsOrTransformFlags := flagsRead.storedValue
      aimKind := op.aimKind
      storedAimValue := op.aimKind.storedValue }
  let baseEffect : RawLaserSpawnEffect :=
    { descriptorWrite := some descriptor
      spawnRequest := true }
  if !laserSpawnSlotInBounds op operands.selectedSlot then
    let fault := laserSpawnSlotWriteFault shape op operands.selectedSlot
    .ok
      { op := op
        intResolutions := intReads
        floatResolutions := floatReads
        effect := baseEffect
        hostFault := some fault }
  else
    .ok
      { op := op
        intResolutions := intReads
        floatResolutions := floatReads
        effect :=
          { baseEffect with
            slotWrite :=
              some
                { slot := operands.selectedSlot
                  slotCount := op.slotCount
                  descriptorTarget := op.descriptorTarget } } }

def rawLaserSpawnStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawLaserSpawnOperands) :
    Except Fault RawLaserSpawnOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawLaserSpawnCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawLaserSpawnCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findLaserSpawnOp? rawPrefix.opcode with
          | none =>
              .ok (rawLaserSpawnCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawLaserSpawnPrepare shape rawPrefix op operands
              let action :=
                match prepared.hostFault with
                | none => RawLaserSpawnAction.advanced
                | some _ => RawLaserSpawnAction.hostFault
              .ok
                (rawLaserSpawnCursorOutcome
                  action
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  prepared.hostFault
                  (some prepared))

end TouhouFormal.ECL
