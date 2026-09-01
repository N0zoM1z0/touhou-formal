import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawBossLifecycleIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawBossLifecycleFloatInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawBossLifecycleOperands where
  intInputs : List RawBossLifecycleIntInput := []
  floatInputs : List RawBossLifecycleFloatInput := []
  currentBossSlot : Int := 0
  spellcardActive : Bool := true
  bossPointerPresent : Bool := true
  maxLife : Int := 1
deriving Repr, DecidableEq

inductive RawBossLifecycleIntResolution where
  | rawI32 : Int -> RawBossLifecycleIntResolution
  | rawI16 : Int -> RawBossLifecycleIntResolution
  | rawU16 : Int -> RawBossLifecycleIntResolution
  | rawU8 : Int -> RawBossLifecycleIntResolution
  | intRValue : RawIntOperandResolution -> RawBossLifecycleIntResolution
deriving Repr, DecidableEq

def RawBossLifecycleIntResolution.value :
    RawBossLifecycleIntResolution -> Int
  | .rawI32 value => value
  | .rawI16 value => value
  | .rawU16 value => value
  | .rawU8 value => value
  | .intRValue value => value.value

inductive RawBossLifecycleFloatResolution where
  | rawBits : Int -> RawBossLifecycleFloatResolution
  | floatRValue : RawFloatOperandResolution -> RawBossLifecycleFloatResolution
deriving Repr, DecidableEq

def RawBossLifecycleFloatResolution.bits :
    RawBossLifecycleFloatResolution -> Int
  | .rawBits value => value
  | .floatRValue value => value.value

structure RawBossLifecycleResolvedIntInput where
  shape : RawBossLifecycleIntInputShape
  resolution : RawBossLifecycleIntResolution
deriving Repr, DecidableEq

structure RawBossLifecycleResolvedFloatInput where
  shape : RawBossLifecycleFloatInputShape
  resolution : RawBossLifecycleFloatResolution
deriving Repr, DecidableEq

inductive RawBossHostSlotBoundary where
  | beforeArray
  | inBounds
  | atOrPastArray
deriving Repr, DecidableEq

def RawBossHostSlotBoundary.name : RawBossHostSlotBoundary -> String
  | .beforeArray => "before-array"
  | .inBounds => "in-bounds"
  | .atOrPastArray => "at-or-past-array"

def classifyBossHostSlot (index : Int) (slotCount : Nat) :
    RawBossHostSlotBoundary :=
  if index < 0 then
    .beforeArray
  else if slotCount <= index.toNat then
    .atOrPastArray
  else
    .inBounds

def rawBossStoredSlot
    (policy : RawBossSlotStoragePolicy)
    (value : Int) : Int :=
  match policy with
  | .i32 => value
  | .u8 => TouhouFormal.truncateUnsignedBits value 8

structure RawBossSetEffect where
  requestedSlot : Int
  storedBossSlot : Int
  slotBoundary : RawBossHostSlotBoundary
  bossPresentWrite : Option Bool := none
  healthBarSetToFull : Bool := false
  bossFlagWrite : Option Bool := some true
  markerInterrupt : Option Int := none
  resetMinimumPlayerDistance : Bool := false
deriving Repr, DecidableEq

structure RawBossClearEffect where
  currentBossSlot : Int
  slotBoundary : RawBossHostSlotBoundary
  bossPresentWrite : Option Bool := none
  bossFlagWrite : Option Bool := some false
  markerInterrupt : Option Int := none
  resetEffectArray : Bool := false
  releaseAttachedEffects : Bool := false
  moveMarkerOffscreen : Bool := false
deriving Repr, DecidableEq

structure RawSpellStartEffect where
  spellSprite : Option Int := none
  spellId : Option Int := none
  spellBonus : Option Int := none
  textPolicy : Option RawBossSpellTextPolicy := none
  bulletClear : Option RawBossSpellBulletClear := none
  stageState : Option RawBossSpellStageState := none
  setsLegacySpellInfo : Bool := false
  resetsStageSpellTimer : Bool := false
  resetsBulletRank : Bool := false
  scoreDrainRateUsesTimerCallbackThreshold : Bool := false
  runsSpellcardBackgroundVms : Bool := false
  hostStartSpell : Bool := false
deriving Repr, DecidableEq

structure RawSpellEndEffect where
  requiresActiveSpell : Bool := false
  spellWasActive : Bool := false
  activeBodyRuns : Bool := false
  stageState : Option RawBossSpellStageState := none
  bulletClear : Option RawBossSpellBulletClear := none
  removesEnemies : Bool := false
  deactivatesLegacySpellInfo : Bool := false
  playsEndSound : Bool := false
  hostEndSpell : Bool := false
deriving Repr, DecidableEq

structure RawBossGaugeEffect where
  gaugeSlot : Int
  slotBoundary : RawBossHostSlotBoundary
  startNumerator : Int
  stopNumerator : Int
  maxLifeDenominator : Int
  maxLifeZeroProducesNonfinite : Bool
  color : Int
deriving Repr, DecidableEq

structure RawBossLifeMarkerEffect where
  count : Int
  timeBonus : Int := 0
  historyBonusDelta : Option Int := none
deriving Repr, DecidableEq

inductive RawBossLifecycleFlagField where
  | timeoutSpell
  | survivalSpellcard
  | spellcardEffectTrackingDisabled
  | spellcardBonusUpdatesDisabled
deriving Repr, DecidableEq

def RawBossLifecycleFlagField.name : RawBossLifecycleFlagField -> String
  | .timeoutSpell => "timeout-spell"
  | .survivalSpellcard => "survival-spellcard"
  | .spellcardEffectTrackingDisabled =>
      "spellcard-effect-tracking-disabled"
  | .spellcardBonusUpdatesDisabled =>
      "spellcard-bonus-updates-disabled"

structure RawBossLifecycleFlagEffect where
  field : RawBossLifecycleFlagField
  value : Int
  scoreLimitWrite : Option Int := none
deriving Repr, DecidableEq

structure RawBossRunInterruptEffect where
  requestedSlot : Int
  slotBoundary : RawBossHostSlotBoundary
  bossPointerPresent : Bool
  subId : Int
  writesRunInterrupt : Bool
deriving Repr, DecidableEq

structure RawSpellcardStoredVectorEffect where
  xBits : Int
  yBits : Int
  zBits : Int
deriving Repr, DecidableEq

structure RawBossLifecycleEffect where
  bossSet : Option RawBossSetEffect := none
  bossClear : Option RawBossClearEffect := none
  spellStart : Option RawSpellStartEffect := none
  spellEnd : Option RawSpellEndEffect := none
  bossGauge : Option RawBossGaugeEffect := none
  lifeMarker : Option RawBossLifeMarkerEffect := none
  flagWrite : Option RawBossLifecycleFlagEffect := none
  runInterrupt : Option RawBossRunInterruptEffect := none
  storedVector : Option RawSpellcardStoredVectorEffect := none
  phaseStartingLifeWrite : Option Int := none
deriving Repr, DecidableEq

structure RawBossLifecyclePrepared where
  op : RawBossLifecycleOpShape
  intResolutions : List RawBossLifecycleResolvedIntInput := []
  floatResolutions : List RawBossLifecycleResolvedFloatInput := []
  effect : RawBossLifecycleEffect
deriving Repr, DecidableEq

inductive RawBossLifecycleAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawBossLifecycleOutcome where
  action : RawBossLifecycleAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawBossLifecycleEffect := none
  prepared : Option RawBossLifecyclePrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossLifecycle"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedBossLifecycleShapeFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossLifecycle"
    detail := "boss-lifecycle opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingBossLifecycleIntOperandFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossLifecycle"
    detail :=
      "boss-lifecycle opcode " ++ op.kind.name ++
        " did not receive integer occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def missingBossLifecycleFloatOperandFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossLifecycle"
    detail :=
      "boss-lifecycle opcode " ++ op.kind.name ++
        " did not receive float occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def missingBossLifecycleRoleFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (role : RawBossLifecycleIntRole) : Fault :=
  malformedBossLifecycleShapeFault
    shape
    op
    ("missing integer role " ++ role.name)

private def missingBossLifecycleFloatRoleFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (role : RawBossLifecycleFloatRole) : Fault :=
  malformedBossLifecycleShapeFault
    shape
    op
    ("missing float role " ++ role.name)

private def bossSlotOutOfBoundsFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (kind : FaultKind)
    (componentSuffix detail : String)
    (index : Int)
    (bound : Nat) : Fault :=
  { kind := kind
    title := shape.title
    component := "EclRun.bossLifecycle." ++ componentSuffix
    detail :=
      "source boss-lifecycle opcode " ++ toString op.opcode ++ ": " ++
        detail
    index := some index
    bound := some bound }

private def bossArrayOutOfBoundsWriteFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (index : Int) : Fault :=
  bossSlotOutOfBoundsFault
    shape
    op
    .outOfBoundsWrite
    "bosses"
    "unchecked write to g_EnemyManager.bosses[index]"
    index
    op.bossSlotCount

private def bossArrayOutOfBoundsReadFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (index : Int) : Fault :=
  bossSlotOutOfBoundsFault
    shape
    op
    .outOfBoundsRead
    "bosses"
    "unchecked read from g_EnemyManager.bosses[index]"
    index
    op.bossSlotCount

private def bossGaugeOutOfBoundsWriteFault
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (index : Int) : Fault :=
  bossSlotOutOfBoundsFault
    shape
    op
    .outOfBoundsWrite
    "guiBossGauge"
    "unchecked write to boss gauge slot"
    index
    op.bossGaugeSlotCount

private def rawBossLifecycleCursorOutcome
    (action : RawBossLifecycleAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawBossLifecycleEffect := none)
    (prepared : Option RawBossLifecyclePrepared := none) :
    RawBossLifecycleOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def intInputAt
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands)
    (occurrence : Nat)
    (operandIndex : Nat) : Except Fault RawBossLifecycleIntInput :=
  match operands.intInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (missingBossLifecycleIntOperandFault
          shape op occurrence operandIndex)

private def floatInputAt
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands)
    (occurrence : Nat)
    (operandIndex : Nat) : Except Fault RawBossLifecycleFloatInput :=
  match operands.floatInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (missingBossLifecycleFloatOperandFault
          shape op occurrence operandIndex)

private def resolveBossLifecycleIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawBossLifecycleIntInputShape)
    (input : RawBossLifecycleIntInput) :
    Except Fault RawBossLifecycleResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .rawI16 =>
        .ok (.rawI16 (TouhouFormal.word16BitsToInt input.rawValue))
    | .rawU16 => .ok (.rawU16 (TouhouFormal.toWord16Bits input.rawValue))
    | .rawU8 =>
        .ok
          (.rawU8 (TouhouFormal.truncateUnsignedBits input.rawValue 8))
    | .intRValue => do
        let value <-
          resolveIntRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawValue
            input.hostValue
        .ok (.intRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveBossLifecycleFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawBossLifecycleFloatInputShape)
    (input : RawBossLifecycleFloatInput) :
    Except Fault RawBossLifecycleResolvedFloatInput := do
  let resolution <-
    match inputShape.policy with
    | .rawBits => .ok (.rawBits input.rawValue)
    | .floatRValue => do
        let value <-
          resolveFloatRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawValue
            input.hostValue
        .ok (.floatRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveIntInputsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Nat ->
    List RawBossLifecycleIntInputShape ->
    Except Fault (List RawBossLifecycleResolvedIntInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let input <-
        intInputAt shape op operands occurrence inputShape.operandIndex
      let head <- resolveBossLifecycleIntInput shape rawPrefix inputShape input
      let tail <-
        resolveIntInputsAux
          shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def resolveFloatInputsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Nat ->
    List RawBossLifecycleFloatInputShape ->
    Except Fault (List RawBossLifecycleResolvedFloatInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let input <-
        floatInputAt shape op operands occurrence inputShape.operandIndex
      let head <- resolveBossLifecycleFloatInput shape rawPrefix inputShape input
      let tail <-
        resolveFloatInputsAux
          shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def resolveIntInputs
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault (List RawBossLifecycleResolvedIntInput) :=
  resolveIntInputsAux shape rawPrefix op operands 0 op.intInputs

private def resolveFloatInputs
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault (List RawBossLifecycleResolvedFloatInput) :=
  resolveFloatInputsAux shape rawPrefix op operands 0 op.floatInputs

private def intInputByRole?
    (inputs : List RawBossLifecycleResolvedIntInput)
    (role : RawBossLifecycleIntRole) :
    Option RawBossLifecycleResolvedIntInput :=
  inputs.find? (fun input => input.shape.role == role)

private def floatInputByRole?
    (inputs : List RawBossLifecycleResolvedFloatInput)
    (role : RawBossLifecycleFloatRole) :
    Option RawBossLifecycleResolvedFloatInput :=
  inputs.find? (fun input => input.shape.role == role)

private def requireIntInput
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (inputs : List RawBossLifecycleResolvedIntInput)
    (role : RawBossLifecycleIntRole) :
    Except Fault RawBossLifecycleResolvedIntInput :=
  match intInputByRole? inputs role with
  | some input => .ok input
  | none => .error (missingBossLifecycleRoleFault shape op role)

private def requireFloatInput
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (inputs : List RawBossLifecycleResolvedFloatInput)
    (role : RawBossLifecycleFloatRole) :
    Except Fault RawBossLifecycleResolvedFloatInput :=
  match floatInputByRole? inputs role with
  | some input => .ok input
  | none => .error (missingBossLifecycleFloatRoleFault shape op role)

private def bossPresentOnSet
    (op : RawBossLifecycleOpShape)
    (slot : Int) : Option Bool :=
  match op.setBossPresentPolicy with
  | .everyNonnegativeSlot => some true
  | .primarySlotOnly => if slot == 0 then some true else none

private def bossPresentOnClear
    (op : RawBossLifecycleOpShape)
    (slot : Int) : Option Bool :=
  match op.clearBossPresentPolicy with
  | .always => some false
  | .currentSlotBelowGuiSlots =>
      if decide (0 <= slot ∧ slot.toNat < op.guiBossSlotCount) then
        some false
      else
        none

private def ensureBossArraySlotInBounds
    (shape : HeaderShape)
    (op : RawBossLifecycleOpShape)
    (kind : FaultKind)
    (slot : Int) : Except Fault Unit :=
  match classifyBossHostSlot slot op.bossSlotCount with
  | .inBounds => .ok ()
  | .beforeArray | .atOrPastArray =>
      match kind with
      | .outOfBoundsRead =>
          .error (bossArrayOutOfBoundsReadFault shape op slot)
      | _ =>
          .error (bossArrayOutOfBoundsWriteFault shape op slot)

private def prepareSetBoss
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let slotInput <- requireIntInput shape op intResolutions .bossSlot
  let slot := slotInput.resolution.value
  if slot < 0 then
    let currentSlot :=
      rawBossStoredSlot op.bossSlotStoragePolicy operands.currentBossSlot
    ensureBossArraySlotInBounds
      shape op .outOfBoundsWrite currentSlot
    let effect :=
      { bossClear :=
          some
            { currentBossSlot := currentSlot
              slotBoundary :=
                classifyBossHostSlot currentSlot op.bossSlotCount
              bossPresentWrite := bossPresentOnClear op currentSlot
              markerInterrupt := op.markerInterruptOnClear
              resetEffectArray := op.resetEffectArrayOnClear
              releaseAttachedEffects := op.releaseAttachedEffectsOnClear
              moveMarkerOffscreen := op.moveMarkerOffscreenOnClear } }
    .ok
      { op := op
        intResolutions := intResolutions
        effect := effect }
  else
    ensureBossArraySlotInBounds shape op .outOfBoundsWrite slot
    let storedSlot := rawBossStoredSlot op.bossSlotStoragePolicy slot
    let effect :=
      { bossSet :=
          some
            { requestedSlot := slot
              storedBossSlot := storedSlot
              slotBoundary := classifyBossHostSlot slot op.bossSlotCount
              bossPresentWrite := bossPresentOnSet op slot
              healthBarSetToFull := op.setHealthBarToFull
              markerInterrupt := op.markerInterruptOnSet
              resetMinimumPlayerDistance :=
                op.resetMinimumPlayerDistance } }
    .ok
      { op := op
        intResolutions := intResolutions
        effect := effect }

private def prepareBeginSpellcard
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let sprite? :=
    (intInputByRole? intResolutions .spellSprite).map
      (fun input => input.resolution.value)
  let spellId? :=
    (intInputByRole? intResolutions .spellId).map
      (fun input => input.resolution.value)
  let bonus? :=
    (intInputByRole? intResolutions .spellBonus).map
      (fun input => input.resolution.value)
  let effect :=
    { spellStart :=
        some
          { spellSprite := sprite?
            spellId := spellId?
            spellBonus := bonus?
            textPolicy := op.spellTextPolicy
            bulletClear := op.beginBulletClear
            stageState := op.beginStageState
            setsLegacySpellInfo := op.beginSetsLegacySpellInfo
            resetsStageSpellTimer := op.beginResetsStageSpellTimer
            resetsBulletRank := op.beginResetsBulletRank
            scoreDrainRateUsesTimerCallbackThreshold :=
              op.beginSetsScoreDrainRate
            runsSpellcardBackgroundVms :=
              op.beginRunsSpellcardBackgroundVms
            hostStartSpell := op.beginHostStartSpell } }
  .ok
    { op := op
      intResolutions := intResolutions
      effect := effect }

private def prepareEndSpellcard
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    RawBossLifecyclePrepared :=
  let activeBodyRuns :=
    if op.endRequiresActiveSpell then operands.spellcardActive else true
  let effect :=
    { spellEnd :=
        some
          { requiresActiveSpell := op.endRequiresActiveSpell
            spellWasActive := operands.spellcardActive
            activeBodyRuns := activeBodyRuns
            stageState := op.endStageState
            bulletClear :=
              if activeBodyRuns then op.endBulletClear else none
            removesEnemies := activeBodyRuns && op.endRemovesEnemies
            deactivatesLegacySpellInfo :=
              activeBodyRuns && op.endDeactivatesLegacySpellInfo
            playsEndSound := activeBodyRuns && op.endPlaysSound
            hostEndSpell := op.endHostEndSpell } }
  { op := op
    effect := effect }

private def prepareBossGauge
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let slotInput <- requireIntInput shape op intResolutions .gaugeSlot
  let startInput <- requireIntInput shape op intResolutions .gaugeStart
  let stopInput <- requireIntInput shape op intResolutions .gaugeStop
  let colorInput <- requireIntInput shape op intResolutions .gaugeColor
  let slot := slotInput.resolution.value
  match classifyBossHostSlot slot op.bossGaugeSlotCount with
  | .inBounds =>
      let effect :=
        { bossGauge :=
            some
              { gaugeSlot := slot
                slotBoundary := .inBounds
                startNumerator := startInput.resolution.value
                stopNumerator := stopInput.resolution.value
                maxLifeDenominator := operands.maxLife
                maxLifeZeroProducesNonfinite := operands.maxLife == 0
                color := colorInput.resolution.value } }
      .ok
        { op := op
          intResolutions := intResolutions
          effect := effect }
  | .beforeArray | .atOrPastArray =>
      .error (bossGaugeOutOfBoundsWriteFault shape op slot)

private def prepareLifeMarker
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let countInput <- requireIntInput shape op intResolutions .lifeMarkerCount
  let effect :=
    { lifeMarker :=
        some
          { count := countInput.resolution.value
            timeBonus := op.lifeMarkerTimeBonus
            historyBonusDelta := op.lifeMarkerHistoryBonusDelta } }
  .ok
    { op := op
      intResolutions := intResolutions
      effect := effect }

private def prepareSimpleFlag
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands)
    (field : RawBossLifecycleFlagField)
    (scoreLimitWrite : Option Int := none) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let valueInput <- requireIntInput shape op intResolutions .flagValue
  let effect :=
    { flagWrite :=
        some
          { field := field
            value := valueInput.resolution.value
            scoreLimitWrite := scoreLimitWrite } }
  .ok
    { op := op
      intResolutions := intResolutions
      effect := effect }

private def prepareBossRunInterrupt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let slotInput <- requireIntInput shape op intResolutions .runInterruptSlot
  let subInput <- requireIntInput shape op intResolutions .runInterruptSub
  let slot := slotInput.resolution.value
  ensureBossArraySlotInBounds shape op .outOfBoundsRead slot
  let effect :=
    { runInterrupt :=
        some
          { requestedSlot := slot
            slotBoundary := classifyBossHostSlot slot op.bossSlotCount
            bossPointerPresent := operands.bossPointerPresent
            subId := subInput.resolution.value
            writesRunInterrupt := operands.bossPointerPresent } }
  .ok
    { op := op
      intResolutions := intResolutions
      effect := effect }

private def prepareEffectTracking
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let valueInput <- requireIntInput shape op intResolutions .flagValue
  let value := valueInput.resolution.value
  let floatResolutions <-
    if value == 0 && op.effectTrackingStoresVectorWhenZero then
      resolveFloatInputs shape rawPrefix op operands
    else
      .ok []
  let storedVector <-
    if value == 0 && op.effectTrackingStoresVectorWhenZero then
      let x <- requireFloatInput shape op floatResolutions .storedVectorX
      let y <- requireFloatInput shape op floatResolutions .storedVectorY
      let z <- requireFloatInput shape op floatResolutions .storedVectorZ
      .ok
        (some
          { xBits := x.resolution.bits
            yBits := y.resolution.bits
            zBits := z.resolution.bits })
    else
      .ok none
  let effect :=
    { flagWrite :=
        some
          { field := .spellcardEffectTrackingDisabled
            value := value }
      storedVector := storedVector }
  .ok
    { op := op
      intResolutions := intResolutions
      floatResolutions := floatResolutions
      effect := effect }

private def preparePhaseStartingLife
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  let intResolutions <- resolveIntInputs shape rawPrefix op operands
  let valueInput <- requireIntInput shape op intResolutions .phaseStartingLife
  let effect :=
    { phaseStartingLifeWrite := some valueInput.resolution.value }
  .ok
    { op := op
      intResolutions := intResolutions
      effect := effect }

def rawBossLifecyclePrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossLifecycleOpShape)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecyclePrepared := do
  match op.kind with
  | .setBoss =>
      prepareSetBoss shape rawPrefix op operands
  | .beginSpellcard =>
      prepareBeginSpellcard shape rawPrefix op operands
  | .endSpellcard =>
      .ok (prepareEndSpellcard op operands)
  | .setBossGauge =>
      prepareBossGauge shape rawPrefix op operands
  | .setLifeMarkerCount =>
      prepareLifeMarker shape rawPrefix op operands
  | .setTimeoutSpell =>
      prepareSimpleFlag
        shape rawPrefix op operands .timeoutSpell op.timeoutScoreLimit
  | .setSurvivalSpellcard =>
      prepareSimpleFlag shape rawPrefix op operands .survivalSpellcard
  | .setBossRunInterrupt =>
      prepareBossRunInterrupt shape rawPrefix op operands
  | .setSpellcardEffectTracking =>
      prepareEffectTracking shape rawPrefix op operands
  | .setSpellcardBonusUpdatesDisabled =>
      prepareSimpleFlag
        shape rawPrefix op operands .spellcardBonusUpdatesDisabled
  | .setPhaseStartingLife =>
      preparePhaseStartingLife shape rawPrefix op operands

def rawBossLifecycleStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawBossLifecycleOperands) :
    Except Fault RawBossLifecycleOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass
            shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawBossLifecycleCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawBossLifecycleCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findBossLifecycleOp? rawPrefix.opcode with
          | none =>
              .ok
                (rawBossLifecycleCursorOutcome
                  .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawBossLifecyclePrepare shape rawPrefix op operands
              .ok
                (rawBossLifecycleCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  (some prepared))

end TouhouFormal.ECL
