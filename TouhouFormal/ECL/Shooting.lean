import TouhouFormal.ECL.EnemyState
import TouhouFormal.ECL.Random

namespace TouhouFormal.ECL

structure RawShootingFloatInput where
  rawValue : Int
  hostValue : Int
deriving Repr, DecidableEq

structure RawShootingOperands where
  intRaw : Int := 0
  intHost : Int := 0
  floatInputs : List RawShootingFloatInput := []
  rank : Int := 0
  rngWord : Int := 0
deriving Repr, DecidableEq

inductive RawShootingIntResolution where
  | rawI32 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawShootingIntResolution.value : RawShootingIntResolution -> Int
  | .rawI32 value => value
  | .intRValue value => value.value

inductive RawShootingFloatResolution where
  | rawBits (value : Int)
  | floatRValue (value : RawFloatOperandResolution)
deriving Repr, DecidableEq

def RawShootingFloatResolution.bits : RawShootingFloatResolution -> Int
  | .rawBits value => value
  | .floatRValue value => value.value

structure RawShootOffsetBits where
  x : Int
  y : Int
  z : Int
deriving Repr, DecidableEq

structure RawShootingGateWrite where
  policy : RawShootingGatePolicy
  enabled : Bool
deriving Repr, DecidableEq

structure RawShootingEffect where
  shootIntervalWrite : Option Int := none
  shootIntervalTimerWrite : Option RawEnemyTimerWrite := none
  shootingGateWrite : Option RawShootingGateWrite := none
  spawnPreviousPattern : Bool := false
  refreshPatternPosition : Bool := false
  shootOffsetWrite : Option RawShootOffsetBits := none
deriving Repr, DecidableEq

structure RawShootingPrepared where
  op : RawShootingOpShape
  intResolution : Option RawShootingIntResolution
  baseInterval : Option Int
  rankAdjustment : Option Int
  adjustedInterval : Option Int
  floatResolutions : List RawShootingFloatResolution
  floatBits : List Int
  effect : RawShootingEffect
deriving Repr, DecidableEq

inductive RawShootingAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawShootingOutcome where
  action : RawShootingAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawShootingEffect := none
  prepared : Option RawShootingPrepared := none
deriving Repr, DecidableEq

def shootIntervalRankAdjustment (baseInterval rank : Int) : Int :=
  let upper := baseInterval / 5
  let lower := (-baseInterval) / 5
  rank * (lower - upper) / 32 + upper

def shootIntervalAfterRank (baseInterval rank : Int) : Int :=
  baseInterval + shootIntervalRankAdjustment baseInterval rank

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.shooting"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedShootingShapeFault
    (shape : HeaderShape)
    (op : RawShootingOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.shooting"
    detail := "shooting opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def rawShootingCursorOutcome
    (action : RawShootingAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawShootingEffect := none)
    (prepared : Option RawShootingPrepared := none) : RawShootingOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def RawShootingOpKind.requiresIntInput : RawShootingOpKind -> Bool
  | .setInterval | .setRandomizedInterval => true
  | _ => false

private def RawShootingOpShape.expectedFloatInputCount
    (op : RawShootingOpShape) : Nat :=
  match op.kind with
  | .setShootOffset => if op.zeroOffsetZ then 2 else 3
  | _ => 0

private def resolveShootingIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawShootingOpShape)
    (operands : RawShootingOperands) :
    Except Fault (Option RawShootingIntResolution) :=
  match op.intInputPolicy with
  | none => .ok none
  | some .rawI32 => .ok (some (.rawI32 operands.intRaw))
  | some .intRValue => do
      let value <-
        resolveIntRValue
          shape rawPrefix op.intOperandIndex operands.intRaw operands.intHost
      .ok (some (.intRValue value))

private def resolveShootingFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawShootingFloatInputShape)
    (input : RawShootingFloatInput) :
    Except Fault RawShootingFloatResolution :=
  match inputShape.policy with
  | .rawBits => .ok (.rawBits input.rawValue)
  | .floatRValue => do
      let value <-
        resolveFloatRValue
          shape rawPrefix inputShape.operandIndex input.rawValue input.hostValue
      .ok (.floatRValue value)

private def shouldApplyRank
    (policy : RawShootingIntervalGuardPolicy)
    (baseInterval : Int) : Bool :=
  match policy with
  | .alwaysApplyRank => true
  | .onlyWhenBaseNonzero => baseInterval != 0

private def shouldWriteIntervalTimer
    (op : RawShootingOpShape)
    (baseInterval adjustedInterval : Int) : Bool :=
  match op.kind, op.intervalGuardPolicy with
  | .setInterval, .alwaysApplyRank => true
  | .setRandomizedInterval, .alwaysApplyRank => adjustedInterval != 0
  | .setInterval, .onlyWhenBaseNonzero
  | .setRandomizedInterval, .onlyWhenBaseNonzero => baseInterval != 0
  | _, _ => false

private def intervalTimerValue
    (kind : RawShootingOpKind)
    (adjustedInterval rngWord : Int) : Int :=
  match kind with
  | .setRandomizedInterval =>
      TouhouFormal.word32BitsToInt
        (randomU32InRangeWord rngWord adjustedInterval)
  | _ => 0

private def shootingEffect
    (op : RawShootingOpShape)
    (baseInterval adjustedInterval : Option Int)
    (floatBits : List Int)
    (operands : RawShootingOperands) : RawShootingEffect :=
  let base := baseInterval.getD 0
  let adjusted := adjustedInterval.getD 0
  match op.kind with
  | .setInterval | .setRandomizedInterval =>
      { shootIntervalWrite := some adjusted
        shootIntervalTimerWrite :=
          if shouldWriteIntervalTimer op base adjusted then
            some
              { current := intervalTimerValue op.kind adjusted operands.rngWord
                subFrameBits := 0
                previous := -999 }
          else
            none }
  | .disableShooting =>
      { shootingGateWrite :=
          some { policy := op.gatePolicy, enabled := true } }
  | .enableShooting =>
      { shootingGateWrite :=
          some { policy := op.gatePolicy, enabled := false } }
  | .spawnPreviousPattern =>
      { spawnPreviousPattern := true
        refreshPatternPosition := true }
  | .setShootOffset =>
      { shootOffsetWrite :=
          some
            { x := floatBits[0]!
              y := floatBits[1]!
              z := if op.zeroOffsetZ then 0 else floatBits[2]! } }

def rawShootingPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawShootingOpShape)
    (operands : RawShootingOperands) : Except Fault RawShootingPrepared := do
  let expectedFloatCount := op.expectedFloatInputCount
  if op.kind.requiresIntInput != op.intInputPolicy.isSome then
    .error
      (malformedShootingShapeFault
        shape op "integer input policy does not match opcode kind")
  else if op.floatInputs.length != expectedFloatCount then
    .error
      (malformedShootingShapeFault
        shape op
        ("profile declares " ++ toString op.floatInputs.length ++
          " float inputs, expected " ++ toString expectedFloatCount))
  else if operands.floatInputs.length != expectedFloatCount then
    .error
      (malformedShootingShapeFault
        shape op
        ("step supplied " ++ toString operands.floatInputs.length ++
          " float inputs, expected " ++ toString expectedFloatCount))
  else
    let intResolution <- resolveShootingIntInput shape rawPrefix op operands
    let baseInterval := intResolution.map RawShootingIntResolution.value
    let rankAdjustment :=
      baseInterval.map
        (fun base =>
          if shouldApplyRank op.intervalGuardPolicy base then
            shootIntervalRankAdjustment base operands.rank
          else
            0)
    let adjustedInterval :=
      baseInterval.map
        (fun base =>
          if shouldApplyRank op.intervalGuardPolicy base then
            shootIntervalAfterRank base operands.rank
          else
            base)
    let floatResolutions <-
      (List.zip op.floatInputs operands.floatInputs).mapM
        (fun (inputShape, input) =>
          resolveShootingFloatInput shape rawPrefix inputShape input)
    let floatBits := floatResolutions.map RawShootingFloatResolution.bits
    let effect :=
      shootingEffect op baseInterval adjustedInterval floatBits operands
    .ok
      { op := op
        intResolution := intResolution
        baseInterval := baseInterval
        rankAdjustment := rankAdjustment
        adjustedInterval := adjustedInterval
        floatResolutions := floatResolutions
        floatBits := floatBits
        effect := effect }

def rawShootingStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawShootingOperands) : Except Fault RawShootingOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawShootingCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawShootingCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findShootingOp? rawPrefix.opcode with
          | none =>
              .ok (rawShootingCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawShootingPrepare shape rawPrefix op operands
              .ok
                (rawShootingCursorOutcome
                  .advanced rawPrefix bufferSize
                  (some prepared.effect) (some prepared))

end TouhouFormal.ECL
