import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawBulletControlIntInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawBulletControlFloatInput where
  rawBits : Int
  hostBits : Int := 0
deriving Repr, DecidableEq

structure RawBulletControlOperands where
  intInputs : List RawBulletControlIntInput := []
  floatInputs : List RawBulletControlFloatInput := []
deriving Repr, DecidableEq

inductive RawBulletControlIntResolution where
  | intRValue : RawIntOperandResolution -> RawBulletControlIntResolution
  | rawI32 : Int -> RawBulletControlIntResolution
deriving Repr, DecidableEq

def RawBulletControlIntResolution.value :
    RawBulletControlIntResolution -> Int
  | .intRValue value => value.value
  | .rawI32 value => value

inductive RawBulletControlFloatResolution where
  | floatRValue : RawFloatOperandResolution -> RawBulletControlFloatResolution
  | rawBits : Int -> RawBulletControlFloatResolution
deriving Repr, DecidableEq

def RawBulletControlFloatResolution.bits :
    RawBulletControlFloatResolution -> Int
  | .floatRValue value => value.value
  | .rawBits value => value

structure RawBulletControlResolvedIntInput where
  shape : RawBulletControlIntInputShape
  resolution : RawBulletControlIntResolution
deriving Repr, DecidableEq

structure RawBulletControlResolvedFloatInput where
  shape : RawBulletControlFloatInputShape
  resolution : RawBulletControlFloatResolution
deriving Repr, DecidableEq

structure RawBulletClearEffect where
  mode : RawBulletClearMode
  radiusBits : Option Int := none
deriving Repr, DecidableEq

structure RawBulletSoundEffect where
  target : RawBulletSoundTarget
  spawnSound : Option Int := none
  flagMask : Int
  flagEnabled : Bool
  overrideSound : Option Int := none
deriving Repr, DecidableEq

structure RawBulletRankInfluenceEffect where
  speedLowBits : Int
  speedHighBits : Int
  count1Low : Int
  count1High : Int
  count2Low : Int
  count2High : Int
deriving Repr, DecidableEq

structure RawBulletControlEffect where
  clear : Option RawBulletClearEffect := none
  sound : Option RawBulletSoundEffect := none
  rankInfluence : Option RawBulletRankInfluenceEffect := none
deriving Repr, DecidableEq

inductive RawBulletControlAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawBulletControlPrepared where
  op : RawBulletControlOpShape
  intResolutions : List RawBulletControlResolvedIntInput
  floatResolutions : List RawBulletControlResolvedFloatInput
  effect : RawBulletControlEffect
deriving Repr, DecidableEq

structure RawBulletControlOutcome where
  action : RawBulletControlAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawBulletControlEffect := none
  prepared : Option RawBulletControlPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bulletControl"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedBulletControlShapeFault
    (shape : HeaderShape)
    (op : RawBulletControlOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bulletControl"
    detail := "bullet-control opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingBulletControlIntOperandFault
    (shape : HeaderShape)
    (op : RawBulletControlOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bulletControl"
    detail :=
      "bullet-control opcode " ++ op.kind.name ++
        " did not receive integer occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def missingBulletControlFloatOperandFault
    (shape : HeaderShape)
    (op : RawBulletControlOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bulletControl"
    detail :=
      "bullet-control opcode " ++ op.kind.name ++
        " did not receive float occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def rawBulletControlCursorOutcome
    (action : RawBulletControlAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawBulletControlEffect := none)
    (prepared : Option RawBulletControlPrepared := none) :
    RawBulletControlOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def resolveBulletControlIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawBulletControlIntInputShape)
    (input : RawBulletControlIntInput) :
    Except Fault RawBulletControlResolvedIntInput := do
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
  .ok { shape := inputShape, resolution := resolution }

private def resolveBulletControlIntOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletControlOpShape)
    (operands : RawBulletControlOperands)
    (occurrence : Nat)
    (inputShape : RawBulletControlIntInputShape) :
    Except Fault RawBulletControlResolvedIntInput := do
  let input <-
    match operands.intInputs[occurrence]? with
    | none =>
        .error
          (missingBulletControlIntOperandFault
            shape op occurrence inputShape.operandIndex)
    | some input => .ok input
  resolveBulletControlIntInput shape rawPrefix inputShape input

private def resolveBulletControlFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawBulletControlFloatInputShape)
    (input : RawBulletControlFloatInput) :
    Except Fault RawBulletControlResolvedFloatInput := do
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

private def resolveBulletControlFloatOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletControlOpShape)
    (operands : RawBulletControlOperands)
    (occurrence : Nat)
    (inputShape : RawBulletControlFloatInputShape) :
    Except Fault RawBulletControlResolvedFloatInput := do
  let input <-
    match operands.floatInputs[occurrence]? with
    | none =>
        .error
          (missingBulletControlFloatOperandFault
            shape op occurrence inputShape.operandIndex)
    | some input => .ok input
  resolveBulletControlFloatInput shape rawPrefix inputShape input

private def intShapeAt
    (shape : HeaderShape)
    (op : RawBulletControlOpShape)
    (index : Nat) : Except Fault RawBulletControlIntInputShape :=
  match op.intInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedBulletControlShapeFault
          shape op ("missing integer input shape " ++ toString index))

private def floatShapeAt
    (shape : HeaderShape)
    (op : RawBulletControlOpShape)
    (index : Nat) : Except Fault RawBulletControlFloatInputShape :=
  match op.floatInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedBulletControlShapeFault
          shape op ("missing float input shape " ++ toString index))

private def signedI16 (value : Int) : Int :=
  TouhouFormal.word16BitsToInt (TouhouFormal.toWord16Bits value)

private def prepareBulletClear
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletControlOpShape)
    (mode : RawBulletClearMode)
    (operands : RawBulletControlOperands) :
    Except Fault RawBulletControlPrepared := do
  match mode with
  | .removeRadius =>
      let radiusShape <- floatShapeAt shape op 0
      let radiusRead <-
        resolveBulletControlFloatOccurrence
          shape rawPrefix op operands 0 radiusShape
      .ok
        { op := op
          intResolutions := []
          floatResolutions := [radiusRead]
          effect :=
            { clear :=
                some
                  { mode := mode
                    radiusBits := some radiusRead.resolution.bits } } }
  | _ =>
      .ok
        { op := op
          intResolutions := []
          floatResolutions := []
          effect := { clear := some { mode := mode } } }

private def prepareBulletSound
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletControlOpShape)
    (operands : RawBulletControlOperands) :
    Except Fault RawBulletControlPrepared := do
  let branchShape <- intShapeAt shape op 0
  let branchRead <-
    resolveBulletControlIntOccurrence
      shape rawPrefix op operands 0 branchShape
  let branchValue := branchRead.resolution.value
  if decide (0 <= branchValue) then
    let spawnRead <-
      if op.soundRepeatsPrimaryOnEnable then
        resolveBulletControlIntOccurrence
          shape rawPrefix op operands 1 branchShape
      else
        .ok branchRead
    let overrideRead <-
      if op.soundHasOverride then
        let overrideShape <- intShapeAt shape op 1
        let occurrence := if op.soundRepeatsPrimaryOnEnable then 2 else 1
        let read <-
          resolveBulletControlIntOccurrence
            shape rawPrefix op operands occurrence overrideShape
        .ok (some read)
      else
        .ok none
    let reads :=
      if op.soundRepeatsPrimaryOnEnable then
        match overrideRead with
        | none => [branchRead, spawnRead]
        | some override => [branchRead, spawnRead, override]
      else
        match overrideRead with
        | none => [branchRead]
        | some override => [branchRead, override]
    .ok
      { op := op
        intResolutions := reads
        floatResolutions := []
        effect :=
          { sound :=
              some
                { target := op.soundTarget
                  spawnSound := some spawnRead.resolution.value
                  flagMask := op.soundFlagMask
                  flagEnabled := true
                  overrideSound :=
                    overrideRead.map
                      (fun read => read.resolution.value) } } }
  else
    let overrideRead <-
      if op.soundHasOverride then
        let overrideShape <- intShapeAt shape op 1
        let occurrence := if op.soundRepeatsPrimaryOnEnable then 1 else 1
        let read <-
          resolveBulletControlIntOccurrence
            shape rawPrefix op operands occurrence overrideShape
        .ok (some read)
      else
        .ok none
    let reads :=
      match overrideRead with
      | none => [branchRead]
      | some override => [branchRead, override]
    .ok
      { op := op
        intResolutions := reads
        floatResolutions := []
        effect :=
          { sound :=
              some
                { target := op.soundTarget
                  spawnSound := none
                  flagMask := op.soundFlagMask
                  flagEnabled := false
                  overrideSound :=
                    overrideRead.map
                      (fun read => read.resolution.value) } } }

private def prepareRankInfluence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletControlOpShape)
    (operands : RawBulletControlOperands) :
    Except Fault RawBulletControlPrepared := do
  let speedLowShape <- floatShapeAt shape op 0
  let speedHighShape <- floatShapeAt shape op 1
  let speedLow <-
    resolveBulletControlFloatOccurrence
      shape rawPrefix op operands 0 speedLowShape
  let speedHigh <-
    resolveBulletControlFloatOccurrence
      shape rawPrefix op operands 1 speedHighShape
  let count1LowShape <- intShapeAt shape op 0
  let count1HighShape <- intShapeAt shape op 1
  let count2LowShape <- intShapeAt shape op 2
  let count2HighShape <- intShapeAt shape op 3
  let count1Low <-
    resolveBulletControlIntOccurrence
      shape rawPrefix op operands 0 count1LowShape
  let count1High <-
    resolveBulletControlIntOccurrence
      shape rawPrefix op operands 1 count1HighShape
  let count2Low <-
    resolveBulletControlIntOccurrence
      shape rawPrefix op operands 2 count2LowShape
  let count2High <-
    resolveBulletControlIntOccurrence
      shape rawPrefix op operands 3 count2HighShape
  let storeInt :=
    if op.rankIntValuesTruncateToI16 then signedI16 else id
  .ok
    { op := op
      intResolutions := [count1Low, count1High, count2Low, count2High]
      floatResolutions := [speedLow, speedHigh]
      effect :=
        { rankInfluence :=
            some
              { speedLowBits := speedLow.resolution.bits
                speedHighBits := speedHigh.resolution.bits
                count1Low := storeInt count1Low.resolution.value
                count1High := storeInt count1High.resolution.value
                count2Low := storeInt count2Low.resolution.value
                count2High := storeInt count2High.resolution.value } } }

def rawBulletControlPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBulletControlOpShape)
    (operands : RawBulletControlOperands) :
    Except Fault RawBulletControlPrepared := do
  match op.kind with
  | .clear mode => prepareBulletClear shape rawPrefix op mode operands
  | .setSound => prepareBulletSound shape rawPrefix op operands
  | .setRankInfluence =>
      prepareRankInfluence shape rawPrefix op operands

def rawBulletControlStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawBulletControlOperands) :
    Except Fault RawBulletControlOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawBulletControlCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawBulletControlCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findBulletControlOp? rawPrefix.opcode with
          | none =>
              .ok (rawBulletControlCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawBulletControlPrepare shape rawPrefix op operands
              .ok
                (rawBulletControlCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  (some prepared))

end TouhouFormal.ECL
