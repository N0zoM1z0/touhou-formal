import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawHostEffectIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawHostEffectFloatInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawHostEffectOperands where
  intInputs : List RawHostEffectIntInput := []
  floatInputs : List RawHostEffectFloatInput := []
  trackedSlot : Int := 0
  specialEffectPresent : Bool := true
  alignmentEffectPresent : Bool := false
  enemyIndexOdd : Bool := false
  playerIsYoukai : Bool := false
deriving Repr, DecidableEq

inductive RawHostEffectIntResolution where
  | rawI32 : Int -> RawHostEffectIntResolution
  | intRValue : RawIntOperandResolution -> RawHostEffectIntResolution
  | intPointerValue : RawIntLValueResolution -> RawHostEffectIntResolution
deriving Repr, DecidableEq

def RawHostEffectIntResolution.value? :
    RawHostEffectIntResolution -> Option Int
  | .rawI32 value => some value
  | .intRValue value => some value.value
  | .intPointerValue value => value.valueBefore

inductive RawHostEffectFloatResolution where
  | rawBits : Int -> RawHostEffectFloatResolution
  | floatRValue : RawFloatOperandResolution -> RawHostEffectFloatResolution
deriving Repr, DecidableEq

def RawHostEffectFloatResolution.bits :
    RawHostEffectFloatResolution -> Int
  | .rawBits value => value
  | .floatRValue value => value.value

structure RawHostEffectResolvedIntInput where
  shape : RawHostEffectIntInputShape
  resolution : RawHostEffectIntResolution
deriving Repr, DecidableEq

structure RawHostEffectResolvedFloatInput where
  shape : RawHostEffectFloatInputShape
  resolution : RawHostEffectFloatResolution
deriving Repr, DecidableEq

structure RawHostEffectVector3Bits where
  x : Int
  y : Int
  z : Int
deriving Repr, DecidableEq

structure RawHostEffectTrackedWrite where
  slot : Int
  slotCount : Nat
deriving Repr, DecidableEq

structure RawHostEffectSpawnRequest where
  effectId : Int
  count : Int
  directColor : Option Int := none
  colorTableIndex : Option Int := none
  positionSource : RawHostEffectPositionSource
  vector : Option RawHostEffectVector3Bits := none
  velocity : Option RawHostEffectVector3Bits := none
  distanceBits : Option Int := none
  trackedWrite : Option RawHostEffectTrackedWrite := none
deriving Repr, DecidableEq

structure RawHostEffectSoundRequest where
  soundId : Int
  positionedByEnemyX : Bool
deriving Repr, DecidableEq

structure RawHostEffectBulletExtras where
  intValues : List Int
  floatBits : List Int
deriving Repr, DecidableEq

structure RawHostEffectColorMultiplier where
  rBits : Int
  gBits : Int
  bBits : Int
  aBits : Int
deriving Repr, DecidableEq

structure RawHostEffectSpecialPosition where
  customPositionFlag : Int
  writesPosition : Bool
  specialEffectPresent : Bool
  positionBits : Option RawHostEffectVector3Bits := none
deriving Repr, DecidableEq

structure RawHostEffectAlignment where
  deactivatesExisting : Bool
  effectId : Int
  positionSource : RawHostEffectPositionSource
  interrupt : Int
  negatesAngularVelocityZ : Bool
deriving Repr, DecidableEq

structure RawHostEffect where
  bulletExtras : Option RawHostEffectBulletExtras := none
  spawnRequest : Option RawHostEffectSpawnRequest := none
  soundRequest : Option RawHostEffectSoundRequest := none
  colorMultiplier : Option RawHostEffectColorMultiplier := none
  specialPosition : Option RawHostEffectSpecialPosition := none
  alignment : Option RawHostEffectAlignment := none
deriving Repr, DecidableEq

inductive RawHostEffectAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawHostEffectPrepared where
  op : RawHostEffectOpShape
  intResolutions : List RawHostEffectResolvedIntInput := []
  floatResolutions : List RawHostEffectResolvedFloatInput := []
  effect : RawHostEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawHostEffectOutcome where
  action : RawHostEffectAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawHostEffect := none
  fault : Option Fault := none
  prepared : Option RawHostEffectPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.hostEffect"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedHostEffectFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.hostEffect"
    detail := "host-effect opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingIntOperandFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (occurrence operandIndex : Nat) : Fault :=
  malformedHostEffectFault shape op
    ("missing integer occurrence " ++ toString occurrence ++
      " for operand slot " ++ toString operandIndex)

private def missingFloatOperandFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (occurrence operandIndex : Nat) : Fault :=
  malformedHostEffectFault shape op
    ("missing float occurrence " ++ toString occurrence ++
      " for operand slot " ++ toString operandIndex)

private def missingIntRoleFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (role : RawHostEffectIntRole) : Fault :=
  malformedHostEffectFault shape op ("missing integer role " ++ role.name)

private def missingFloatRoleFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (role : RawHostEffectFloatRole) : Fault :=
  malformedHostEffectFault shape op ("missing float role " ++ role.name)

private def missingPointerValueFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (role : RawHostEffectIntRole) : Fault :=
  malformedHostEffectFault shape op
    ("integer pointer role " ++ role.name ++ " has no readable value")

private def trackedSlotFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (slot : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.hostEffect.trackedEffects"
    detail :=
      "source stores the spawned effect pointer in a fixed enemy effect array without checking the running index"
    index := some slot
    bound := some op.trackedSlotCount }

private def colorTableFault
    (shape : HeaderShape)
    (_op : RawHostEffectOpShape)
    (index : Int)
    (bound : Nat) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.hostEffect.colorTable"
    detail :=
      "source indexes the fixed bullet/effect color table without checking the color id"
    index := some index
    bound := some bound }

private def specialEffectNullFault
    (shape : HeaderShape)
    (op : RawHostEffectOpShape) : Fault :=
  { kind := .nullDereference
    title := shape.title
    component := "EclRun.hostEffect.specialEffect"
    detail :=
      "source writes specialEffect->pos when custom positioning is disabled without checking specialEffect"
    index := some op.opcode }

private def rawHostEffectCursorOutcome
    (action : RawHostEffectAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawHostEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawHostEffectPrepared := none) :
    RawHostEffectOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def resolveIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawHostEffectIntInputShape)
    (input : RawHostEffectIntInput) :
    Except Fault RawHostEffectResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix inputShape.operandIndex
            input.rawValue input.hostValue
        .ok (.intRValue value)
    | .intPointerValue => do
        let value <-
          resolveIntPointerLValue shape rawPrefix inputShape.operandIndex
            input.rawValue input.hostValue
        .ok (.intPointerValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawHostEffectFloatInputShape)
    (input : RawHostEffectFloatInput) :
    Except Fault RawHostEffectResolvedFloatInput := do
  let resolution <-
    match inputShape.policy with
    | .rawBits => .ok (.rawBits input.rawValue)
    | .floatRValue => do
        let value <-
          resolveFloatRValue shape rawPrefix inputShape.operandIndex
            input.rawValue input.hostValue
        .ok (.floatRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveIntInputsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Nat -> List RawHostEffectIntInputShape ->
      Except Fault (List RawHostEffectResolvedIntInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let input <-
        match operands.intInputs[occurrence]? with
        | some value => .ok value
        | none =>
            .error
              (missingIntOperandFault
                shape op occurrence inputShape.operandIndex)
      let head <- resolveIntInput shape rawPrefix inputShape input
      let tail <-
        resolveIntInputsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def resolveFloatInputsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Nat -> List RawHostEffectFloatInputShape ->
      Except Fault (List RawHostEffectResolvedFloatInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let input <-
        match operands.floatInputs[occurrence]? with
        | some value => .ok value
        | none =>
            .error
              (missingFloatOperandFault
                shape op occurrence inputShape.operandIndex)
      let head <- resolveFloatInput shape rawPrefix inputShape input
      let tail <-
        resolveFloatInputsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def resolveIntInputs
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :=
  resolveIntInputsAux shape rawPrefix op operands 0 op.intInputs

private def resolveFloatInputs
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :=
  resolveFloatInputsAux shape rawPrefix op operands 0 op.floatInputs

private def intByRole?
    (inputs : List RawHostEffectResolvedIntInput)
    (role : RawHostEffectIntRole) :=
  inputs.find? (fun input => input.shape.role == role)

private def floatByRole?
    (inputs : List RawHostEffectResolvedFloatInput)
    (role : RawHostEffectFloatRole) :=
  inputs.find? (fun input => input.shape.role == role)

private def requireIntValue
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (inputs : List RawHostEffectResolvedIntInput)
    (role : RawHostEffectIntRole) : Except Fault Int := do
  let input <-
    match intByRole? inputs role with
    | some value => .ok value
    | none => .error (missingIntRoleFault shape op role)
  match input.resolution.value? with
  | some value => .ok value
  | none => .error (missingPointerValueFault shape op role)

private def requireFloatBits
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (inputs : List RawHostEffectResolvedFloatInput)
    (role : RawHostEffectFloatRole) : Except Fault Int :=
  match floatByRole? inputs role with
  | some input => .ok input.resolution.bits
  | none => .error (missingFloatRoleFault shape op role)

private def requireVector
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (inputs : List RawHostEffectResolvedFloatInput) :
    Except Fault RawHostEffectVector3Bits := do
  let x <- requireFloatBits shape op inputs .vectorX
  let y <- requireFloatBits shape op inputs .vectorY
  let z <- requireFloatBits shape op inputs .vectorZ
  .ok { x := x, y := y, z := z }

private def resolveEffectId
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (inputs : List RawHostEffectResolvedIntInput) : Except Fault Int :=
  match op.fixedEffectId with
  | some value => .ok value
  | none => requireIntValue shape op inputs .effectId

private def resolveCount
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (inputs : List RawHostEffectResolvedIntInput) : Except Fault Int :=
  match op.fixedCount with
  | some value => .ok value
  | none => requireIntValue shape op inputs .count

private def resolveColor
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (inputs : List RawHostEffectResolvedIntInput) :
    Except Fault (Option Int × Option Int) :=
  match op.fixedColor with
  | some value => .ok (some value, none)
  | none => do
      let value <- requireIntValue shape op inputs .color
      match op.colorTableCount with
      | some _ => .ok (none, some value)
      | none => .ok (some value, none)

private def indexInBounds (index : Int) (bound : Nat) : Bool :=
  decide (0 <= index ∧ index.toNat < bound)

private def trackedFault?
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (slot : Int) : Option Fault :=
  if indexInBounds slot op.trackedSlotCount then
    none
  else
    some (trackedSlotFault shape op slot)

private def colorFault?
    (shape : HeaderShape)
    (op : RawHostEffectOpShape)
    (index? : Option Int) : Option Fault :=
  match op.colorTableCount, index? with
  | some bound, some index =>
      if indexInBounds index bound then none
      else some (colorTableFault shape op index bound)
  | _, _ => none

private def firstFault (lhs rhs : Option Fault) : Option Fault :=
  match lhs with
  | some fault => some fault
  | none => rhs

private def prepareSetBulletExtras
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectPrepared := do
  let ints <- resolveIntInputs shape rawPrefix op operands
  let floats <- resolveFloatInputs shape rawPrefix op operands
  let intValues <-
    ints.mapM (fun input =>
      match input.resolution.value? with
      | some value => .ok value
      | none => .error (missingPointerValueFault shape op input.shape.role))
  let effect :=
    { bulletExtras :=
        some
          { intValues := intValues
            floatBits := floats.map (fun input => input.resolution.bits) } }
  .ok
    { op := op
      intResolutions := ints
      floatResolutions := floats
      effect := effect }

private def prepareTrackedEffect
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectPrepared := do
  let ints <- resolveIntInputs shape rawPrefix op operands
  let floats <- resolveFloatInputs shape rawPrefix op operands
  let effectId <- resolveEffectId shape op ints
  let count <- resolveCount shape op ints
  let (directColor, colorTableIndex) <- resolveColor shape op ints
  let vector <- requireVector shape op floats
  let distance <- requireFloatBits shape op floats .distance
  let slotFault := trackedFault? shape op operands.trackedSlot
  let lookupFault := colorFault? shape op colorTableIndex
  let fault := firstFault lookupFault slotFault
  let trackedWrite :=
    if slotFault.isSome then none
    else
      some
        { slot := operands.trackedSlot
          slotCount := op.trackedSlotCount }
  let effect :=
    { spawnRequest :=
        some
          { effectId := effectId
            count := count
            directColor := directColor
            colorTableIndex := colorTableIndex
            positionSource := op.positionSource
            vector := some vector
            distanceBits := some distance
            trackedWrite := trackedWrite } }
  .ok
    { op := op
      intResolutions := ints
      floatResolutions := floats
      effect := effect
      hostFault := fault }

private def prepareSound
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectPrepared := do
  let ints <- resolveIntInputs shape rawPrefix op operands
  let soundId <- requireIntValue shape op ints .soundId
  .ok
    { op := op
      intResolutions := ints
      effect :=
        { soundRequest :=
            some
              { soundId := soundId
                positionedByEnemyX := op.positionedSound } } }

private def prepareParticles
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands)
    (moving : Bool) : Except Fault RawHostEffectPrepared := do
  let ints <- resolveIntInputs shape rawPrefix op operands
  let floats <- resolveFloatInputs shape rawPrefix op operands
  let effectId <- resolveEffectId shape op ints
  let count <- resolveCount shape op ints
  let (directColor, colorTableIndex) <- resolveColor shape op ints
  let velocity : Option RawHostEffectVector3Bits <-
    if moving then
      do
        let vector <- requireVector shape op floats
        .ok (some vector)
    else
      .ok none
  let fault := colorFault? shape op colorTableIndex
  .ok
    { op := op
      intResolutions := ints
      floatResolutions := floats
      effect :=
        { spawnRequest :=
            some
              { effectId := effectId
                count := count
                directColor := directColor
                colorTableIndex := colorTableIndex
                positionSource := op.positionSource
                velocity := velocity } }
      hostFault := fault }

private def prepareColorMultiplier
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectPrepared := do
  let floats <- resolveFloatInputs shape rawPrefix op operands
  let r <- requireFloatBits shape op floats .colorR
  let g <- requireFloatBits shape op floats .colorG
  let b <- requireFloatBits shape op floats .colorB
  let a <- requireFloatBits shape op floats .colorA
  .ok
    { op := op
      floatResolutions := floats
      effect :=
        { colorMultiplier :=
            some { rBits := r, gBits := g, bBits := b, aBits := a } } }

private def prepareSpecialPosition
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectPrepared := do
  let ints <- resolveIntInputs shape rawPrefix op operands
  let floats <- resolveFloatInputs shape rawPrefix op operands
  let custom <- requireIntValue shape op ints .customPositionFlag
  let writes := custom == 0
  let position : Option RawHostEffectVector3Bits <-
    if writes then
      do
        let vector <- requireVector shape op floats
        .ok (some vector)
    else
      .ok none
  let fault :=
    if writes && !operands.specialEffectPresent then
      some (specialEffectNullFault shape op)
    else
      none
  .ok
    { op := op
      intResolutions := ints
      floatResolutions := floats
      effect :=
        { specialPosition :=
            some
              { customPositionFlag := custom
                writesPosition := writes
                specialEffectPresent := operands.specialEffectPresent
                positionBits := position } }
      hostFault := fault }

private def prepareAlignment
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectPrepared := do
  let ints <- resolveIntInputs shape rawPrefix op operands
  let effectId <- resolveEffectId shape op ints
  .ok
    { op := op
      intResolutions := ints
      effect :=
        { alignment :=
            some
              { deactivatesExisting := operands.alignmentEffectPresent
                effectId := effectId + op.effectIdBase
                positionSource := op.positionSource
                interrupt := if operands.playerIsYoukai then 2 else 1
                negatesAngularVelocityZ := operands.enemyIndexOdd } } }

def rawHostEffectPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawHostEffectOpShape)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectPrepared := do
  match op.kind with
  | .setBulletExtras =>
      prepareSetBulletExtras shape rawPrefix op operands
  | .spawnTrackedEffect =>
      prepareTrackedEffect shape rawPrefix op operands
  | .playSound =>
      prepareSound shape rawPrefix op operands
  | .spawnParticles moving =>
      prepareParticles shape rawPrefix op operands moving
  | .setGlobalColorMultiplier =>
      prepareColorMultiplier shape rawPrefix op operands
  | .setSpecialEffectPosition =>
      prepareSpecialPosition shape rawPrefix op operands
  | .spawnAlignmentEffect =>
      prepareAlignment shape rawPrefix op operands

def rawHostEffectStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawHostEffectOperands) :
    Except Fault RawHostEffectOutcome :=
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
          .ok (rawHostEffectCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawHostEffectCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findHostEffectOp? rawPrefix.opcode with
          | none =>
              .ok (rawHostEffectCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawHostEffectPrepare shape rawPrefix op operands
              let action :=
                if prepared.hostFault.isSome then
                  RawHostEffectAction.hostFault
                else
                  RawHostEffectAction.advanced
              .ok
                (rawHostEffectCursorOutcome
                  action rawPrefix bufferSize
                  (some prepared.effect) prepared.hostFault (some prepared))

end TouhouFormal.ECL
