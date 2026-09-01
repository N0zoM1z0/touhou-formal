import TouhouFormal.Core.Float32
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawBulletPatternIntInput where
  rawValue : Int
  hostValue : Int
deriving Repr, DecidableEq

structure RawBulletPatternFloatInput where
  rawValue : Int
  hostValue : Int
deriving Repr, DecidableEq

structure RawBulletPatternPositionBits where
  x : Int
  y : Int
  z : Int
deriving Repr, DecidableEq

/--
Results of source-side binary32 operations that the integer Lean core does not
pretend to recompute.  The VM still owns operand resolution, rank guards,
zero testing, IEEE ordered clamps, and every early-exit branch.
-/
structure RawBulletPatternFloatResults where
  position : RawBulletPatternPositionBits
  normalizedPrimaryAngleBits : Int
  rankedSpeed1Bits : Int
  rankedSpeed2Bits : Int
deriving Repr, DecidableEq

structure RawBulletPatternRuntime where
  enemyLife : Int := 1
  spellcardActive : Bool := false
  shootingGateEnabled : Bool := false
  rank : Int := 0
  count1Low : Int := 0
  count1High : Int := 0
  count2Low : Int := 0
  count2High : Int := 0
  rankSpeedLowBits : Int := 0
  rankSpeedHighBits : Int := 0
  enemyYoukaiAligned : Bool := false
  minimumPlayerDistancePositive : Bool := false
  playerInsideMinimumDistance : Bool := false
deriving Repr, DecidableEq

structure RawBulletPatternOperands where
  bulletType : RawBulletPatternIntInput
  color : RawBulletPatternIntInput
  count1 : RawBulletPatternIntInput
  count2 : RawBulletPatternIntInput
  speed1 : RawBulletPatternFloatInput
  speed2 : RawBulletPatternFloatInput
  primaryAngle : RawBulletPatternFloatInput
  angleStep : RawBulletPatternFloatInput
  transformFlagsRaw : Int
  floatResults : RawBulletPatternFloatResults
  runtime : RawBulletPatternRuntime := {}
deriving Repr, DecidableEq

inductive RawBulletPatternPackedResolution where
  | rawI16 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawBulletPatternPackedResolution.value :
    RawBulletPatternPackedResolution -> Int
  | .rawI16 value => value
  | .intRValue value => value.value

structure RawBulletPatternSerializedOperands where
  bulletTypeBits : Int
  colorBits : Int
  count1Bits : Int
  count2Bits : Int
  speed1Bits : Int
  speed2Bits : Int
  primaryAngleBits : Int
  angleStepBits : Int
  transformFlagsBits : Int
deriving Repr, DecidableEq

structure RawBulletPatternPendingCopy where
  rawPrefix : RawInstrPrefix
  operands : RawBulletPatternSerializedOperands
  byteCount : Nat
  sourceWithinBuffer : Bool
deriving Repr, DecidableEq

structure RawBulletPatternDescriptor where
  bulletType : Int
  color : Int
  position : RawBulletPatternPositionBits
  primaryAngleBits : Int
  angleStepBits : Int
  speed1Bits : Int
  speed2Bits : Int
  count1 : Int
  count2 : Int
  aimMode : Int
  clearedWord : Int
  transformFlagsBits : Int
deriving Repr, DecidableEq

structure RawBulletPatternPrepared where
  familyMatch : RawBulletPatternFamilyMatch
  bulletTypeResolution : RawBulletPatternPackedResolution
  colorResolution : RawIntOperandResolution
  count1Resolution : RawIntOperandResolution
  count2Resolution : RawIntOperandResolution
  speed1Resolution : RawFloatOperandResolution
  speed2Resolution : RawFloatOperandResolution
  primaryAngleResolution : RawFloatOperandResolution
  angleStepResolution : RawFloatOperandResolution
  rankApplied : Bool
  count1RankAdjustment : Int
  count2RankAdjustment : Int
  descriptor : RawBulletPatternDescriptor
deriving Repr, DecidableEq

inductive RawBulletPatternDisposition where
  | skippedDeadEnemy
  | deferredRawInstruction
  | filteredPlayerAlignment
  | filteredMinimumPlayerDistance
  | spawnSuppressed
  | spawned
deriving Repr, DecidableEq

def RawBulletPatternDisposition.name : RawBulletPatternDisposition -> String
  | .skippedDeadEnemy => "skipped-dead-enemy"
  | .deferredRawInstruction => "deferred-raw-instruction"
  | .filteredPlayerAlignment => "filtered-player-alignment"
  | .filteredMinimumPlayerDistance => "filtered-minimum-player-distance"
  | .spawnSuppressed => "spawn-suppressed"
  | .spawned => "spawned"

structure RawBulletPatternEffect where
  disposition : RawBulletPatternDisposition
  pendingInstructionWrite : Option RawBulletPatternPendingCopy := none
  descriptorWrite : Option RawBulletPatternDescriptor := none
  spawnCall : Bool := false
deriving Repr, DecidableEq

inductive RawBulletPatternAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawBulletPatternOutcome where
  action : RawBulletPatternAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawBulletPatternEffect := none
  prepared : Option RawBulletPatternPrepared := none
deriving Repr, DecidableEq

def bulletPatternMinimumSpeedBits : Int := 0x3e99999a

def bulletPatternRankIntAdjustment
    (rank low high : Int) : Int :=
  Int.tdiv (rank * (high - low)) 32 + low

def bulletPatternClampMinimumSpeedBits (value : Int) : Int :=
  if TouhouFormal.f32LessThanBits value bulletPatternMinimumSpeedBits then
    bulletPatternMinimumSpeedBits
  else
    TouhouFormal.toWord32Bits value

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bulletPattern"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def rawBulletPatternCursorOutcome
    (action : RawBulletPatternAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawBulletPatternEffect := none)
    (prepared : Option RawBulletPatternPrepared := none) :
    RawBulletPatternOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def resolveBulletPatternPackedInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (policy : RawBulletPatternPackedTypePolicy)
    (input : RawBulletPatternIntInput) :
    Except Fault RawBulletPatternPackedResolution :=
  let rawI16 := TouhouFormal.word16BitsToInt input.rawValue
  match policy with
  | .rawI16 => .ok (.rawI16 rawI16)
  | .intRValue => do
      let resolution <-
        resolveIntRValue shape rawPrefix slot rawI16 input.hostValue
      .ok (.intRValue resolution)

private def resolveBulletPatternIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (input : RawBulletPatternIntInput) :
    Except Fault RawIntOperandResolution :=
  resolveIntRValue shape rawPrefix slot input.rawValue input.hostValue

private def resolveBulletPatternFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (input : RawBulletPatternFloatInput) :
    Except Fault RawFloatOperandResolution :=
  resolveFloatRValue shape rawPrefix slot input.rawValue input.hostValue

private def bulletPatternRankApplies
    (policy : RawBulletPatternRankPolicy)
    (spellcardActive : Bool) : Bool :=
  match policy with
  | .always => true
  | .unlessSpellcardActive => !spellcardActive

private def bulletPatternCount
    (resolved rankAdjustment : Int)
    (rankApplied : Bool) : Int :=
  let base := TouhouFormal.word16BitsToInt resolved
  if rankApplied then
    let ranked := TouhouFormal.word16BitsToInt (base + rankAdjustment)
    if ranked <= 0 then 1 else ranked
  else
    base

private def bulletPatternSpeed1Bits
    (resolved ranked : Int)
    (rankApplied : Bool) : Int :=
  if !rankApplied || TouhouFormal.f32IsZeroBits resolved then
    TouhouFormal.toWord32Bits resolved
  else
    bulletPatternClampMinimumSpeedBits ranked

private def bulletPatternSpeed2Bits
    (resolved ranked : Int)
    (rankApplied : Bool) : Int :=
  if !rankApplied then
    TouhouFormal.toWord32Bits resolved
  else
    bulletPatternClampMinimumSpeedBits ranked

private def serializedBulletPatternOperands
    (operands : RawBulletPatternOperands) :
    RawBulletPatternSerializedOperands :=
  { bulletTypeBits := TouhouFormal.toWord16Bits operands.bulletType.rawValue
    colorBits := TouhouFormal.toWord16Bits operands.color.rawValue
    count1Bits := TouhouFormal.toWord32Bits operands.count1.rawValue
    count2Bits := TouhouFormal.toWord32Bits operands.count2.rawValue
    speed1Bits := TouhouFormal.toWord32Bits operands.speed1.rawValue
    speed2Bits := TouhouFormal.toWord32Bits operands.speed2.rawValue
    primaryAngleBits := TouhouFormal.toWord32Bits operands.primaryAngle.rawValue
    angleStepBits := TouhouFormal.toWord32Bits operands.angleStep.rawValue
    transformFlagsBits := TouhouFormal.toWord32Bits operands.transformFlagsRaw }

private def pendingBulletPatternCopy
    (family : RawBulletPatternFamilyShape)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (operands : RawBulletPatternOperands) : RawBulletPatternPendingCopy :=
  { rawPrefix := rawPrefix
    operands := serializedBulletPatternOperands operands
    byteCount := family.deferredCopyBytes
    sourceWithinBuffer :=
      decide (rawPrefix.fileOffset + family.deferredCopyBytes <= bufferSize) }

private def bulletPatternAlignmentMismatch
    (transformFlags : Int)
    (enemyYoukaiAligned : Bool) : Bool :=
  let onlyWhenYoukai := TouhouFormal.word32BitSet transformFlags 15
  let onlyWhenHuman := TouhouFormal.word32BitSet transformFlags 16
  (onlyWhenYoukai && !enemyYoukaiAligned) ||
    (onlyWhenHuman && enemyYoukaiAligned)

def rawBulletPatternPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (familyMatch : RawBulletPatternFamilyMatch)
    (operands : RawBulletPatternOperands) :
    Except Fault RawBulletPatternPrepared := do
  let family := familyMatch.family
  let bulletTypeResolution <-
    resolveBulletPatternPackedInput
      shape rawPrefix 0 family.bulletTypePolicy operands.bulletType
  let colorResolution <-
    resolveBulletPatternIntInput shape rawPrefix 1
      { rawValue := TouhouFormal.word16BitsToInt operands.color.rawValue
        hostValue := operands.color.hostValue }
  let count1Resolution <-
    resolveBulletPatternIntInput shape rawPrefix 2 operands.count1
  let count2Resolution <-
    resolveBulletPatternIntInput shape rawPrefix 3 operands.count2
  let speed1Resolution <-
    resolveBulletPatternFloatInput shape rawPrefix 4 operands.speed1
  let speed2Resolution <-
    resolveBulletPatternFloatInput shape rawPrefix 5 operands.speed2
  let primaryAngleResolution <-
    resolveBulletPatternFloatInput shape rawPrefix 6 operands.primaryAngle
  let angleStepResolution <-
    resolveBulletPatternFloatInput shape rawPrefix 7 operands.angleStep
  let runtime := operands.runtime
  let rankApplied :=
    bulletPatternRankApplies family.rankPolicy runtime.spellcardActive
  let count1RankAdjustment :=
    if rankApplied then
      bulletPatternRankIntAdjustment
        runtime.rank runtime.count1Low runtime.count1High
    else
      0
  let count2RankAdjustment :=
    if rankApplied then
      bulletPatternRankIntAdjustment
        runtime.rank runtime.count2Low runtime.count2High
    else
      0
  let descriptor : RawBulletPatternDescriptor :=
    { bulletType :=
        TouhouFormal.word16BitsToInt bulletTypeResolution.value
      color := TouhouFormal.word16BitsToInt colorResolution.value
      position := operands.floatResults.position
      primaryAngleBits :=
        if family.normalizePrimaryAngle then
          TouhouFormal.toWord32Bits
            operands.floatResults.normalizedPrimaryAngleBits
        else
          TouhouFormal.toWord32Bits primaryAngleResolution.value
      angleStepBits := TouhouFormal.toWord32Bits angleStepResolution.value
      speed1Bits :=
        bulletPatternSpeed1Bits
          speed1Resolution.value
          operands.floatResults.rankedSpeed1Bits
          rankApplied
      speed2Bits :=
        bulletPatternSpeed2Bits
          speed2Resolution.value
          operands.floatResults.rankedSpeed2Bits
          rankApplied
      count1 :=
        bulletPatternCount
          count1Resolution.value count1RankAdjustment rankApplied
      count2 :=
        bulletPatternCount
          count2Resolution.value count2RankAdjustment rankApplied
      aimMode := familyMatch.aimMode
      clearedWord := 0
      transformFlagsBits :=
        TouhouFormal.toWord32Bits operands.transformFlagsRaw }
  .ok
    { familyMatch := familyMatch
      bulletTypeResolution := bulletTypeResolution
      colorResolution := colorResolution
      count1Resolution := count1Resolution
      count2Resolution := count2Resolution
      speed1Resolution := speed1Resolution
      speed2Resolution := speed2Resolution
      primaryAngleResolution := primaryAngleResolution
      angleStepResolution := angleStepResolution
      rankApplied := rankApplied
      count1RankAdjustment := count1RankAdjustment
      count2RankAdjustment := count2RankAdjustment
      descriptor := descriptor }

def rawBulletPatternStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawBulletPatternOperands) :
    Except Fault RawBulletPatternOutcome :=
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
          .ok (rawBulletPatternCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawBulletPatternCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findBulletPatternFamily? rawPrefix.opcode with
          | none =>
              .ok (rawBulletPatternCursorOutcome .advanced rawPrefix bufferSize)
          | some familyMatch =>
              let family := familyMatch.family
              let runtime := operands.runtime
              if family.skipWhenEnemyDead && runtime.enemyLife <= 0 then
                .ok
                  (rawBulletPatternCursorOutcome .advanced rawPrefix bufferSize
                    (some { disposition := .skippedDeadEnemy }))
              else if family.gatePolicy == .deferPattern &&
                  runtime.shootingGateEnabled then
                let pending :=
                  pendingBulletPatternCopy family rawPrefix bufferSize operands
                .ok
                  (rawBulletPatternCursorOutcome .advanced rawPrefix bufferSize
                    (some
                      { disposition := .deferredRawInstruction
                        pendingInstructionWrite := some pending }))
              else if family.filterPlayerAlignment &&
                  bulletPatternAlignmentMismatch
                    operands.transformFlagsRaw runtime.enemyYoukaiAligned then
                .ok
                  (rawBulletPatternCursorOutcome .advanced rawPrefix bufferSize
                    (some { disposition := .filteredPlayerAlignment }))
              else if family.filterMinimumPlayerDistance &&
                  runtime.minimumPlayerDistancePositive &&
                  runtime.playerInsideMinimumDistance then
                .ok
                  (rawBulletPatternCursorOutcome .advanced rawPrefix bufferSize
                    (some { disposition := .filteredMinimumPlayerDistance }))
              else do
                let prepared <-
                  rawBulletPatternPrepare shape rawPrefix familyMatch operands
                let spawnSuppressed :=
                  family.gatePolicy == .suppressSpawn &&
                    runtime.shootingGateEnabled
                let disposition :=
                  if spawnSuppressed then
                    RawBulletPatternDisposition.spawnSuppressed
                  else
                    RawBulletPatternDisposition.spawned
                let effect : RawBulletPatternEffect :=
                  { disposition := disposition
                    descriptorWrite := some prepared.descriptor
                    spawnCall := !spawnSuppressed }
                .ok
                  (rawBulletPatternCursorOutcome .advanced rawPrefix bufferSize
                    (some effect) (some prepared))

end TouhouFormal.ECL
