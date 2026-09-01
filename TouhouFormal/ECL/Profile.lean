import TouhouFormal.Core.Evidence
import TouhouFormal.Core.Scalar

namespace TouhouFormal.ECL

inductive NegativeSubIdPolicy where
  | unchecked
  | noOp
deriving Repr, DecidableEq

inductive DifficultyMaskPolicy where
  | intersectsActive
  | containsActiveAndOverride
deriving Repr, DecidableEq

def NegativeSubIdPolicy.name : NegativeSubIdPolicy -> String
  | .unchecked => "unchecked"
  | .noOp => "no-op"

def DifficultyMaskPolicy.name : DifficultyMaskPolicy -> String
  | .intersectsActive => "intersects-active"
  | .containsActiveAndOverride => "contains-active-and-override"

structure TimelineShape where
  fixedSize : Nat
  timeOffset : Nat
  timeWidth : ScalarWidth
  opcodeOffset : Nat
  opcodeWidth : ScalarWidth
  sizeOffset : Nat
  sizeWidth : ScalarWidth
  firstArgOffset : Option Nat := none
  firstArgWidth : Option ScalarWidth := none
deriving Repr, DecidableEq

structure RawFixedJumpShape where
  opcode : Int
  targetTimeOperandIndex : Nat
  displacementOperandIndex : Nat
deriving Repr, DecidableEq

structure RawDecJumpShape where
  opcode : Int
  targetTimeOperandIndex : Nat
  displacementOperandIndex : Nat
  counterOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawIntDivisorHazardKind where
  | div
  | mod
deriving Repr, DecidableEq

def RawIntDivisorHazardKind.name : RawIntDivisorHazardKind -> String
  | .div => "div"
  | .mod => "mod"

structure RawIntDivisorHazard where
  opcode : Int
  kind : RawIntDivisorHazardKind
  divisorOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawScalarKind where
  | int
  | float
deriving Repr, DecidableEq

def RawScalarKind.name : RawScalarKind -> String
  | .int => "int"
  | .float => "float"

inductive RawScalarAssignOutputPolicy where
  | intLValue
  | floatLValue
  | sourceSetVar
deriving Repr, DecidableEq

def RawScalarAssignOutputPolicy.name : RawScalarAssignOutputPolicy -> String
  | .intLValue => "int-lvalue"
  | .floatLValue => "float-lvalue"
  | .sourceSetVar => "source-set-var"

inductive RawScalarAssignRValuePolicy where
  | intBits
  | floatBits
deriving Repr, DecidableEq

def RawScalarAssignRValuePolicy.name : RawScalarAssignRValuePolicy -> String
  | .intBits => "int-bits"
  | .floatBits => "float-bits"

structure RawScalarAssignShape where
  opcode : Int
  outputPolicy : RawScalarAssignOutputPolicy
  rvaluePolicy : RawScalarAssignRValuePolicy
  outputOperandIndex : Nat
  valueOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawIntUnaryUpdateKind where
  | inc
  | dec
deriving Repr, DecidableEq

def RawIntUnaryUpdateKind.name : RawIntUnaryUpdateKind -> String
  | .inc => "inc"
  | .dec => "dec"

inductive RawIntUnaryUpdateOutputPolicy where
  | intLValue
  | sourceGetVarPointer
deriving Repr, DecidableEq

def RawIntUnaryUpdateOutputPolicy.name : RawIntUnaryUpdateOutputPolicy -> String
  | .intLValue => "int-lvalue"
  | .sourceGetVarPointer => "source-getvar-pointer"

structure RawIntUnaryUpdateShape where
  opcode : Int
  kind : RawIntUnaryUpdateKind
  outputPolicy : RawIntUnaryUpdateOutputPolicy
  outputOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawBinaryOpKind where
  | add
  | sub
  | mul
  | div
  | mod
deriving Repr, DecidableEq

abbrev RawIntBinaryOpKind := RawBinaryOpKind

def RawBinaryOpKind.name : RawBinaryOpKind -> String
  | .add => "add"
  | .sub => "sub"
  | .mul => "mul"
  | .div => "div"
  | .mod => "mod"

def RawBinaryOpKind.isDivisorHazard : RawBinaryOpKind -> Bool
  | .div | .mod => true
  | _ => false

inductive RawBinaryOpMode where
  | assign
  | updateInPlace
deriving Repr, DecidableEq

abbrev RawIntBinaryOpMode := RawBinaryOpMode

def RawBinaryOpMode.name : RawBinaryOpMode -> String
  | .assign => "assign"
  | .updateInPlace => "update-in-place"

structure RawIntBinaryOpShape where
  opcode : Int
  kind : RawBinaryOpKind
  mode : RawBinaryOpMode
  outputOperandIndex : Nat
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

structure RawFloatBinaryOpShape where
  opcode : Int
  kind : RawBinaryOpKind
  mode : RawBinaryOpMode
  outputOperandIndex : Nat
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawFloatFunctionKind where
  | sin
  | cos
  | atan2
  | vectorAngle
  | normalizeAngle
deriving Repr, DecidableEq

def RawFloatFunctionKind.name : RawFloatFunctionKind -> String
  | .sin => "sin"
  | .cos => "cos"
  | .atan2 => "atan2"
  | .vectorAngle => "vector-angle"
  | .normalizeAngle => "normalize-angle"

inductive RawFloatFunctionInputPolicy where
  | floatRValues
  | sourceGetVarPointerBits
deriving Repr, DecidableEq

def RawFloatFunctionInputPolicy.name : RawFloatFunctionInputPolicy -> String
  | .floatRValues => "float-rvalues"
  | .sourceGetVarPointerBits => "source-getvar-pointer-bits"

structure RawFloatFunctionShape where
  opcode : Int
  kind : RawFloatFunctionKind
  outputPolicy : RawScalarAssignOutputPolicy
  inputPolicy : RawFloatFunctionInputPolicy
  outputOperandIndex : Nat
  inputOperandIndices : List Nat
deriving Repr, DecidableEq

inductive RawRandomOpKind where
  | intRange
  | intRangeAdd
  | floatRange
  | floatRangeAdd
  | intSign
  | floatSign
deriving Repr, DecidableEq

def RawRandomOpKind.name : RawRandomOpKind -> String
  | .intRange => "int-range"
  | .intRangeAdd => "int-range-add"
  | .floatRange => "float-range"
  | .floatRangeAdd => "float-range-add"
  | .intSign => "int-sign"
  | .floatSign => "float-sign"

def RawRandomOpKind.scalarKind : RawRandomOpKind -> RawScalarKind
  | .intRange | .intRangeAdd | .intSign => .int
  | .floatRange | .floatRangeAdd | .floatSign => .float

inductive RawRandomEntropyKind where
  | u32Range
  | floatZeroToOne
  | u16Parity
deriving Repr, DecidableEq

def RawRandomEntropyKind.name : RawRandomEntropyKind -> String
  | .u32Range => "u32-range"
  | .floatZeroToOne => "float-zero-to-one"
  | .u16Parity => "u16-parity"

def RawRandomOpKind.entropyKind : RawRandomOpKind -> RawRandomEntropyKind
  | .intRange | .intRangeAdd => .u32Range
  | .floatRange | .floatRangeAdd => .floatZeroToOne
  | .intSign | .floatSign => .u16Parity

def RawRandomOpKind.requiresAddend : RawRandomOpKind -> Bool
  | .intRangeAdd | .floatRangeAdd => true
  | _ => false

inductive RawRandomWritePolicy where
  | direct
  | sourceSetVarResolvesResultBits
deriving Repr, DecidableEq

def RawRandomWritePolicy.name : RawRandomWritePolicy -> String
  | .direct => "direct"
  | .sourceSetVarResolvesResultBits => "source-setvar-resolves-result-bits"

structure RawRandomOpShape where
  opcode : Int
  kind : RawRandomOpKind
  outputPolicy : RawScalarAssignOutputPolicy
  writePolicy : RawRandomWritePolicy
  outputOperandIndex : Nat
  valueOperandIndex : Nat
  addendOperandIndex : Option Nat := none
deriving Repr, DecidableEq

inductive RawMovementOpKind where
  | setPosition
  | setAxisVelocity
  | setPolarVelocity
  | setAngularVelocity
  | setSpeed
  | setAcceleration
  | moveAtPlayer
  | setBounds
  | disableBounds
deriving Repr, DecidableEq

def RawMovementOpKind.name : RawMovementOpKind -> String
  | .setPosition => "set-position"
  | .setAxisVelocity => "set-axis-velocity"
  | .setPolarVelocity => "set-polar-velocity"
  | .setAngularVelocity => "set-angular-velocity"
  | .setSpeed => "set-speed"
  | .setAcceleration => "set-acceleration"
  | .moveAtPlayer => "move-at-player"
  | .setBounds => "set-bounds"
  | .disableBounds => "disable-bounds"

inductive RawMovementFloatInputPolicy where
  | floatRValue
  | rawBits
deriving Repr, DecidableEq

def RawMovementFloatInputPolicy.name : RawMovementFloatInputPolicy -> String
  | .floatRValue => "float-rvalue"
  | .rawBits => "raw-bits"

structure RawMovementFloatInputShape where
  operandIndex : Nat
  policy : RawMovementFloatInputPolicy
deriving Repr, DecidableEq

inductive RawMovementAnglePolicy where
  | unchanged
  | firstInput
  | derivedAtan2
  | derivedNormalizedInput
  | derivedPlayerRelative
  | derivedNormalizedPlayerRelative
deriving Repr, DecidableEq

def RawMovementAnglePolicy.name : RawMovementAnglePolicy -> String
  | .unchanged => "unchanged"
  | .firstInput => "first-input"
  | .derivedAtan2 => "derived-atan2"
  | .derivedNormalizedInput => "derived-normalized-input"
  | .derivedPlayerRelative => "derived-player-relative"
  | .derivedNormalizedPlayerRelative => "derived-normalized-player-relative"

inductive RawMovementMode where
  | axis
  | polar
  | interpolation
  | orbit
deriving Repr, DecidableEq

def RawMovementMode.name : RawMovementMode -> String
  | .axis => "axis"
  | .polar => "polar"
  | .interpolation => "interpolation"
  | .orbit => "orbit"

structure RawMovementOpShape where
  opcode : Int
  kind : RawMovementOpKind
  floatInputs : List RawMovementFloatInputShape := []
  anglePolicy : RawMovementAnglePolicy := .unchanged
  modeUpdate : Option RawMovementMode := none
  clampPosition : Bool := false
  zeroPositionZ : Bool := false
  resetMovementTimers : Bool := false
deriving Repr, DecidableEq

inductive RawTimedMovementKind where
  | direction
  | hostDirection
  | position
  | currentDirection
  | playerDirection
deriving Repr, DecidableEq

def RawTimedMovementKind.name : RawTimedMovementKind -> String
  | .direction => "direction"
  | .hostDirection => "host-direction"
  | .position => "position"
  | .currentDirection => "current-direction"
  | .playerDirection => "player-direction"

inductive RawTimedMovementFloatRole where
  | angle
  | speed
  | targetX
  | targetY
  | targetZ
deriving Repr, DecidableEq

def RawTimedMovementFloatRole.name : RawTimedMovementFloatRole -> String
  | .angle => "angle"
  | .speed => "speed"
  | .targetX => "target-x"
  | .targetY => "target-y"
  | .targetZ => "target-z"

inductive RawTimedMovementValuePolicy where
  | rawBits
  | rValue
deriving Repr, DecidableEq

def RawTimedMovementValuePolicy.name : RawTimedMovementValuePolicy -> String
  | .rawBits => "raw-bits"
  | .rValue => "rvalue"

structure RawTimedMovementFloatInputShape where
  role : RawTimedMovementFloatRole
  operandIndex : Nat
  policy : RawTimedMovementValuePolicy
deriving Repr, DecidableEq

inductive RawTimedMovementDurationPolicy where
  | rawI32
  | intRValue
deriving Repr, DecidableEq

def RawTimedMovementDurationPolicy.name : RawTimedMovementDurationPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"

inductive RawTimedMovementEasingPolicy where
  | opcodeOffset (firstValue : Int)
  | intRValue (operandIndex : Nat)
deriving Repr, DecidableEq

inductive RawTimedMovementNonpositivePolicy where
  | alwaysInterpolate
  | immediatePolarZeroTimers
  | immediatePolarResolvedTimers
deriving Repr, DecidableEq

def RawTimedMovementNonpositivePolicy.name :
    RawTimedMovementNonpositivePolicy -> String
  | .alwaysInterpolate => "always-interpolate"
  | .immediatePolarZeroTimers => "immediate-polar-zero-timers"
  | .immediatePolarResolvedTimers => "immediate-polar-resolved-timers"

inductive RawTimedMovementVectorSource where
  | position
  | worldPosition
deriving Repr, DecidableEq

def RawTimedMovementVectorSource.name : RawTimedMovementVectorSource -> String
  | .position => "position"
  | .worldPosition => "world-position"

/--
One consecutive timed-movement opcode family.  TH06 encodes easing in three
opcode ranges; TH07/TH08 use singleton families whose easing is an operand.
-/
structure RawTimedMovementFamilyShape where
  firstOpcode : Int
  lastOpcode : Int
  kind : RawTimedMovementKind
  floatInputs : List RawTimedMovementFloatInputShape := []
  durationOperandIndex : Nat := 0
  durationPolicy : RawTimedMovementDurationPolicy
  easingPolicy : RawTimedMovementEasingPolicy
  nonpositivePolicy : RawTimedMovementNonpositivePolicy := .alwaysInterpolate
  originSource : RawTimedMovementVectorSource := .position
  deltaBaseSource : RawTimedMovementVectorSource := .position
  normalizeDirectionAngle : Bool := false
  halfDurationDisplacement : Bool := false
  mirrorDeltaX : Bool := false
  zeroVelocity : Bool := false
  zeroTargetZ : Bool := false
  zeroDirectionDeltaZ : Bool := true
deriving Repr, DecidableEq

structure RawTimedMovementFamilyMatch where
  family : RawTimedMovementFamilyShape
  opcode : Int
  easingFromOpcode : Option Int
deriving Repr, DecidableEq

def RawTimedMovementFamilyShape.matches
    (family : RawTimedMovementFamilyShape)
    (opcode : Int) : Bool :=
  decide (family.firstOpcode <= opcode ∧ opcode <= family.lastOpcode)

def RawTimedMovementFamilyShape.easingFromOpcode?
    (family : RawTimedMovementFamilyShape)
    (opcode : Int) : Option Int :=
  if !family.matches opcode then
    none
  else
    match family.easingPolicy with
    | .opcodeOffset firstValue => some (firstValue + opcode - family.firstOpcode)
    | .intRValue _ => none

inductive RawOrbitMovementKind where
  | startFull
  | startFromCurrentPosition
  | setRadius
  | setAngle
  | setModeTimer (mode : RawMovementMode)
  | setVelocities
deriving Repr, DecidableEq

def RawOrbitMovementKind.name : RawOrbitMovementKind -> String
  | .startFull => "start-full"
  | .startFromCurrentPosition => "start-from-current-position"
  | .setRadius => "set-radius"
  | .setAngle => "set-angle"
  | .setModeTimer mode => "set-" ++ mode.name ++ "-timer"
  | .setVelocities => "set-velocities"

inductive RawOrbitMovementFloatRole where
  | originX
  | originY
  | originZ
  | angle
  | angularVelocity
  | radius
  | radialVelocity
deriving Repr, DecidableEq

def RawOrbitMovementFloatRole.name : RawOrbitMovementFloatRole -> String
  | .originX => "origin-x"
  | .originY => "origin-y"
  | .originZ => "origin-z"
  | .angle => "angle"
  | .angularVelocity => "angular-velocity"
  | .radius => "radius"
  | .radialVelocity => "radial-velocity"

structure RawOrbitMovementFloatInputShape where
  role : RawOrbitMovementFloatRole
  operandIndex : Nat
  policy : RawTimedMovementValuePolicy := .rValue
deriving Repr, DecidableEq

structure RawOrbitMovementOpShape where
  opcode : Int
  kind : RawOrbitMovementKind
  floatInputs : List RawOrbitMovementFloatInputShape := []
  durationOperandIndex : Option Nat := none
  durationPolicy : RawTimedMovementDurationPolicy := .intRValue
  originZFromOperand : Bool := true
deriving Repr, DecidableEq

inductive RawEnemyStateFloatInputPolicy where
  | floatRValue
  | rawBits
deriving Repr, DecidableEq

def RawEnemyStateFloatInputPolicy.name : RawEnemyStateFloatInputPolicy -> String
  | .floatRValue => "float-rvalue"
  | .rawBits => "raw-bits"

structure RawEnemyStateFloatInputShape where
  operandIndex : Nat
  policy : RawEnemyStateFloatInputPolicy
deriving Repr, DecidableEq

inductive RawEnemyStateField where
  | interactable
  | collidable
  | damageable
  | contactHitbox
  | canBeDamaged
  | hittable
  | canDie
  | deathMode
  | acceptsDamage
  | collision
  | noSprite
  | allowOffscreen
  | noDeath
deriving Repr, DecidableEq

def RawEnemyStateField.name : RawEnemyStateField -> String
  | .interactable => "interactable"
  | .collidable => "collidable"
  | .damageable => "damageable"
  | .contactHitbox => "contact-hitbox"
  | .canBeDamaged => "can-be-damaged"
  | .hittable => "hittable"
  | .canDie => "can-die"
  | .deathMode => "death-mode"
  | .acceptsDamage => "accepts-damage"
  | .collision => "collision"
  | .noSprite => "no-sprite"
  | .allowOffscreen => "allow-offscreen"
  | .noDeath => "no-death"

def RawEnemyStateField.bitWidth : RawEnemyStateField -> Nat
  | .deathMode => 3
  | _ => 1

inductive RawEnemyStateOpKind where
  | setPrimaryHitbox (dimensions : Nat)
  | setSecondaryHitbox (dimensions : Nat)
  | setField (field : RawEnemyStateField)
  | replaceFlagMask
  | disableFlagMask
  | enableFlagMask
  | setLife
  | setTimer
deriving Repr, DecidableEq

def RawEnemyStateOpKind.name : RawEnemyStateOpKind -> String
  | .setPrimaryHitbox dimensions =>
      "set-primary-hitbox-" ++ toString dimensions ++ "d"
  | .setSecondaryHitbox dimensions =>
      "set-secondary-hitbox-" ++ toString dimensions ++ "d"
  | .setField field => "set-" ++ field.name
  | .replaceFlagMask => "replace-flag-mask"
  | .disableFlagMask => "disable-flag-mask"
  | .enableFlagMask => "enable-flag-mask"
  | .setLife => "set-life"
  | .setTimer => "set-timer"

def RawEnemyStateOpKind.hitboxDimensions? : RawEnemyStateOpKind -> Option Nat
  | .setPrimaryHitbox dimensions | .setSecondaryHitbox dimensions =>
      some dimensions
  | _ => none

def RawEnemyStateOpKind.requiresIntInput (kind : RawEnemyStateOpKind) : Bool :=
  kind.hitboxDimensions?.isNone

inductive RawEnemyStateIntInputPolicy where
  | rawI32
  | rawByte
  | intRValue
deriving Repr, DecidableEq

def RawEnemyStateIntInputPolicy.name : RawEnemyStateIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .rawByte => "raw-byte"
  | .intRValue => "int-rvalue"

structure RawEnemyStateOpShape where
  opcode : Int
  kind : RawEnemyStateOpKind
  floatInputs : List RawEnemyStateFloatInputShape := []
  intOperandIndex : Nat := 0
  intInputPolicy : Option RawEnemyStateIntInputPolicy := none
  presentationGuard : Bool := false
  writePhaseStartingLife : Bool := false
  clearBossGaugeForPrimaryBoss : Bool := false
deriving Repr, DecidableEq

inductive RawShootingOpKind where
  | setInterval
  | setRandomizedInterval
  | disableShooting
  | enableShooting
  | spawnPreviousPattern
  | setShootOffset
deriving Repr, DecidableEq

def RawShootingOpKind.name : RawShootingOpKind -> String
  | .setInterval => "set-interval"
  | .setRandomizedInterval => "set-randomized-interval"
  | .disableShooting => "disable-shooting"
  | .enableShooting => "enable-shooting"
  | .spawnPreviousPattern => "spawn-previous-pattern"
  | .setShootOffset => "set-shoot-offset"

inductive RawShootingIntInputPolicy where
  | rawI32
  | intRValue
deriving Repr, DecidableEq

def RawShootingIntInputPolicy.name : RawShootingIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"

inductive RawShootingFloatInputPolicy where
  | floatRValue
  | rawBits
deriving Repr, DecidableEq

def RawShootingFloatInputPolicy.name : RawShootingFloatInputPolicy -> String
  | .floatRValue => "float-rvalue"
  | .rawBits => "raw-bits"

structure RawShootingFloatInputShape where
  operandIndex : Nat
  policy : RawShootingFloatInputPolicy
deriving Repr, DecidableEq

inductive RawShootingIntervalGuardPolicy where
  | alwaysApplyRank
  | onlyWhenBaseNonzero
deriving Repr, DecidableEq

def RawShootingIntervalGuardPolicy.name :
    RawShootingIntervalGuardPolicy -> String
  | .alwaysApplyRank => "always-apply-rank"
  | .onlyWhenBaseNonzero => "only-when-base-nonzero"

inductive RawShootingGatePolicy where
  | suppressSpawn
  | deferPattern
deriving Repr, DecidableEq

def RawShootingGatePolicy.name : RawShootingGatePolicy -> String
  | .suppressSpawn => "suppress-spawn"
  | .deferPattern => "defer-pattern"

structure RawShootingOpShape where
  opcode : Int
  kind : RawShootingOpKind
  intOperandIndex : Nat := 0
  intInputPolicy : Option RawShootingIntInputPolicy := none
  floatInputs : List RawShootingFloatInputShape := []
  intervalGuardPolicy : RawShootingIntervalGuardPolicy := .onlyWhenBaseNonzero
  gatePolicy : RawShootingGatePolicy := .suppressSpawn
  zeroOffsetZ : Bool := false
deriving Repr, DecidableEq

inductive RawBulletPatternPackedTypePolicy where
  | rawI16
  | intRValue
deriving Repr, DecidableEq

def RawBulletPatternPackedTypePolicy.name :
    RawBulletPatternPackedTypePolicy -> String
  | .rawI16 => "raw-i16"
  | .intRValue => "int-rvalue"

inductive RawBulletPatternRankPolicy where
  | always
  | unlessSpellcardActive
deriving Repr, DecidableEq

def RawBulletPatternRankPolicy.name : RawBulletPatternRankPolicy -> String
  | .always => "always"
  | .unlessSpellcardActive => "unless-spellcard-active"

/--
One source switch family whose consecutive opcodes select aim modes 0 through
`lastOpcode - firstOpcode`.  The serialized descriptor operands have the same
packed order in TH06, TH07, and TH08; title profiles contain only genuine
semantic deltas.
-/
structure RawBulletPatternFamilyShape where
  firstOpcode : Int
  lastOpcode : Int
  bulletTypePolicy : RawBulletPatternPackedTypePolicy
  normalizePrimaryAngle : Bool := false
  rankPolicy : RawBulletPatternRankPolicy
  skipWhenEnemyDead : Bool := false
  gatePolicy : RawShootingGatePolicy := .suppressSpawn
  deferredCopyBytes : Nat := 0
  filterPlayerAlignment : Bool := false
  filterMinimumPlayerDistance : Bool := false
deriving Repr, DecidableEq

def RawBulletPatternFamilyShape.opcodeCount
    (family : RawBulletPatternFamilyShape) : Nat :=
  if family.lastOpcode < family.firstOpcode then
    0
  else
    (family.lastOpcode - family.firstOpcode + 1).toNat

def RawBulletPatternFamilyShape.aimMode?
    (family : RawBulletPatternFamilyShape)
    (opcode : Int) : Option Int :=
  if decide (family.firstOpcode <= opcode ∧ opcode <= family.lastOpcode) then
    some (opcode - family.firstOpcode)
  else
    none

structure RawBulletPatternFamilyMatch where
  family : RawBulletPatternFamilyShape
  aimMode : Int
deriving Repr, DecidableEq

inductive RawCallbackConfigOpKind where
  | setDeathSub
  | setLifeThreshold
  | setLifeSub
  | setLifePairIndexed
  | setTimerThreshold
  | setTimerSub
  | setTimerPair
  | setPeriodic
  | bindTimerToDeath
deriving Repr, DecidableEq

def RawCallbackConfigOpKind.name : RawCallbackConfigOpKind -> String
  | .setDeathSub => "set-death-sub"
  | .setLifeThreshold => "set-life-threshold"
  | .setLifeSub => "set-life-sub"
  | .setLifePairIndexed => "set-life-pair-indexed"
  | .setTimerThreshold => "set-timer-threshold"
  | .setTimerSub => "set-timer-sub"
  | .setTimerPair => "set-timer-pair"
  | .setPeriodic => "set-periodic"
  | .bindTimerToDeath => "bind-timer-to-death"

inductive RawCallbackConfigIntPolicy where
  | rawI32
  | rawU8
  | rawU16ToI16
  | intRValue
deriving Repr, DecidableEq

def RawCallbackConfigIntPolicy.name : RawCallbackConfigIntPolicy -> String
  | .rawI32 => "raw-i32"
  | .rawU8 => "raw-u8"
  | .rawU16ToI16 => "raw-u16-to-i16"
  | .intRValue => "int-rvalue"

structure RawCallbackConfigOpShape where
  opcode : Int
  kind : RawCallbackConfigOpKind
  intPolicy : RawCallbackConfigIntPolicy := .intRValue
  lifeSlotCount : Nat := 4
  guardAllWritesByPresentation : Bool := false
  guardSubWriteByPresentation : Bool := false
  resetBossTimer : Bool := false
deriving Repr, DecidableEq

inductive RawInterruptOpKind where
  | setTableEntry
  | run
  | setStackDisabled
deriving Repr, DecidableEq

def RawInterruptOpKind.name : RawInterruptOpKind -> String
  | .setTableEntry => "set-table-entry"
  | .run => "run"
  | .setStackDisabled => "set-stack-disabled"

inductive RawInterruptIntPolicy where
  | rawI32
  | rawU8
  | intRValue
deriving Repr, DecidableEq

def RawInterruptIntPolicy.name : RawInterruptIntPolicy -> String
  | .rawI32 => "raw-i32"
  | .rawU8 => "raw-u8"
  | .intRValue => "int-rvalue"

structure RawInterruptOpShape where
  opcode : Int
  kind : RawInterruptOpKind
  intPolicy : RawInterruptIntPolicy
  tableEntryCount : Nat := 0
  truncateStoredSubToI16 : Bool := false
  truncateRunIndexToI16 : Bool := false
deriving Repr, DecidableEq

structure IntSelectorRange where
  first : Int
  last : Int
deriving Repr, DecidableEq

def IntSelectorRange.contains (range : IntSelectorRange) (value : Int) : Bool :=
  decide (range.first <= value ∧ value <= range.last)

structure IntSelectorSet where
  ranges : List IntSelectorRange := []
  exclusions : List Int := []
  excludedRanges : List IntSelectorRange := []
deriving Repr, DecidableEq

def IntSelectorSet.contains (set : IntSelectorSet) (value : Int) : Bool :=
  set.ranges.any (fun range => range.contains value) &&
    !set.exclusions.contains value &&
    !set.excludedRanges.any (fun range => range.contains value)

inductive RawBossReadNullPolicy where
  | unguardedDeref
  | guardedSkip
deriving Repr, DecidableEq

def RawBossReadNullPolicy.name : RawBossReadNullPolicy -> String
  | .unguardedDeref => "unguarded-deref"
  | .guardedSkip => "guarded-skip"

structure RawBossIntReadShape where
  opcode : Int
  outputOperandIndex : Nat
  valueOperandIndex : Nat
  bossIndexOperandIndex : Nat
  bossSlotCount : Nat
  nullDerefValueSelectors : IntSelectorSet := {}
deriving Repr, DecidableEq

inductive RawIntOperandMaskPolicy where
  | noMaskAlwaysResolve
  | bitSetMeansResolve
deriving Repr, DecidableEq

def RawIntOperandMaskPolicy.name : RawIntOperandMaskPolicy -> String
  | .noMaskAlwaysResolve => "no-mask-always-resolve"
  | .bitSetMeansResolve => "bit-set-means-resolve"

structure RawIntOperandResolverShape where
  maskPolicy : RawIntOperandMaskPolicy
  knownRValueSelectors : IntSelectorSet
  knownLValueSelectors : IntSelectorSet := {}
deriving Repr, DecidableEq

structure RawFloatOperandResolverShape where
  maskPolicy : RawIntOperandMaskPolicy
  knownRValueSelectors : IntSelectorSet
  knownLValueSelectors : IntSelectorSet := {}
deriving Repr, DecidableEq

structure RawBossFloatReadShape where
  opcode : Int
  outputOperandIndex : Nat
  valueOperandIndex : Nat
  bossIndexOperandIndex : Nat
  bossSlotCount : Nat
  nullPolicy : RawBossReadNullPolicy
  nullDerefValueSelectors : IntSelectorSet := {}
deriving Repr, DecidableEq

inductive RawIntCompareOp where
  | eq
  | neq
  | lt
  | le
  | gt
  | ge
deriving Repr, DecidableEq

def RawIntCompareOp.name : RawIntCompareOp -> String
  | .eq => "eq"
  | .neq => "neq"
  | .lt => "lt"
  | .le => "le"
  | .gt => "gt"
  | .ge => "ge"

def RawIntCompareOp.holds (op : RawIntCompareOp) (lhs rhs : Int) : Bool :=
  match op with
  | .eq => lhs == rhs
  | .neq => lhs != rhs
  | .lt => decide (lhs < rhs)
  | .le => decide (lhs <= rhs)
  | .gt => decide (lhs > rhs)
  | .ge => decide (lhs >= rhs)

inductive RawFloatOrder where
  | less
  | equal
  | greater
  | unordered
deriving Repr, DecidableEq

def RawFloatOrder.name : RawFloatOrder -> String
  | .less => "less"
  | .equal => "equal"
  | .greater => "greater"
  | .unordered => "unordered"

def RawIntCompareOp.holdsFloatOrder
    (op : RawIntCompareOp)
    (order : RawFloatOrder) : Bool :=
  match op, order with
  | .eq, .equal => true
  | .neq, .equal => false
  | .neq, _ => true
  | .lt, .less => true
  | .le, .less | .le, .equal => true
  | .gt, .greater => true
  | .ge, .greater | .ge, .equal => true
  | _, _ => false

def RawFloatOrder.compareRegister : RawFloatOrder -> Int
  | .less => -1
  | .equal => 0
  | .greater | .unordered => 1

structure RawCompareRegisterShape where
  opcode : Int
  scalarKind : RawScalarKind
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawIntConditionSource where
  | compareRegister
  | resolvedOperands
deriving Repr, DecidableEq

def RawIntConditionSource.name : RawIntConditionSource -> String
  | .compareRegister => "compare-register"
  | .resolvedOperands => "resolved-operands"

structure RawIntConditionJumpShape where
  opcode : Int
  op : RawIntCompareOp
  source : RawIntConditionSource
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
  targetTimeOperandIndex : Nat
  displacementOperandIndex : Nat
deriving Repr, DecidableEq

structure RawFloatConditionJumpShape where
  opcode : Int
  op : RawIntCompareOp
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
  targetTimeOperandIndex : Nat
  displacementOperandIndex : Nat
deriving Repr, DecidableEq

structure RawConditionalCallShape where
  opcode : Int
  op : RawIntCompareOp
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawRetUnderflowPolicy where
  | uncheckedSavedContextRead
  | th08ChildContextExit
deriving Repr, DecidableEq

def RawRetUnderflowPolicy.name : RawRetUnderflowPolicy -> String
  | .uncheckedSavedContextRead => "unchecked-saved-context-read"
  | .th08ChildContextExit => "th08-child-context-exit"

structure RawCallRetShape where
  callOpcode : Int
  retOpcode : Int
  subIdOperandIndex : Nat
  stackEntryCount : Nat
  stackIncrementGuardExclusive : Nat
  retUnderflowPolicy : RawRetUnderflowPolicy
  childContextSlotCount : Nat := 0
deriving Repr, DecidableEq

structure RawInstrShape where
  fixedPrefixBytes : Nat
  timeOffset : Nat
  timeWidth : ScalarWidth
  opcodeOffset : Nat
  opcodeWidth : ScalarWidth
  unimplementedOpcode : Option Int := none
  nextOffsetOffset : Nat
  nextOffsetWidth : ScalarWidth
  difficultyMaskOffset : Option Nat := none
  difficultyMaskWidth : Option ScalarWidth := none
  difficultyMaskPolicy : Option DifficultyMaskPolicy := none
  operandMaskOffset : Option Nat := none
  operandMaskWidth : Option ScalarWidth := none
  fixedI32OperandBaseOffset : Option Nat := none
  fixedI32OperandStride : Nat := 4
  fixedJumpShape : Option RawFixedJumpShape := none
  fixedDecJumpShape : Option RawDecJumpShape := none
  intRValueResolver : Option RawIntOperandResolverShape := none
  floatRValueResolver : Option RawFloatOperandResolverShape := none
  compareRegisterOps : List RawCompareRegisterShape := []
  intConditionJumps : List RawIntConditionJumpShape := []
  floatConditionJumps : List RawFloatConditionJumpShape := []
  callRetShape : Option RawCallRetShape := none
  conditionalCallShapes : List RawConditionalCallShape := []
  scalarAssignments : List RawScalarAssignShape := []
  intUnaryUpdates : List RawIntUnaryUpdateShape := []
  intBinaryOps : List RawIntBinaryOpShape := []
  floatBinaryOps : List RawFloatBinaryOpShape := []
  floatFunctions : List RawFloatFunctionShape := []
  randomOps : List RawRandomOpShape := []
  movementOps : List RawMovementOpShape := []
  timedMovementFamilies : List RawTimedMovementFamilyShape := []
  orbitMovementOps : List RawOrbitMovementOpShape := []
  enemyStateOps : List RawEnemyStateOpShape := []
  shootingOps : List RawShootingOpShape := []
  bulletPatternFamilies : List RawBulletPatternFamilyShape := []
  callbackConfigOps : List RawCallbackConfigOpShape := []
  interruptOps : List RawInterruptOpShape := []
  bossIntReads : List RawBossIntReadShape := []
  bossFloatReads : List RawBossFloatReadShape := []
  intDivisorHazards : List RawIntDivisorHazard := []
deriving Repr, DecidableEq

def RawInstrShape.findBossIntRead?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBossIntReadShape :=
  rawShape.bossIntReads.find? (fun read => read.opcode == opcode)

def RawInstrShape.findBossFloatRead?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBossFloatReadShape :=
  rawShape.bossFloatReads.find? (fun read => read.opcode == opcode)

def RawInstrShape.findIntBinaryOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntBinaryOpShape :=
  rawShape.intBinaryOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findFloatBinaryOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawFloatBinaryOpShape :=
  rawShape.floatBinaryOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findFloatFunction?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawFloatFunctionShape :=
  rawShape.floatFunctions.find? (fun op => op.opcode == opcode)

def RawInstrShape.findRandomOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawRandomOpShape :=
  rawShape.randomOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findMovementOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawMovementOpShape :=
  rawShape.movementOps.find? (fun op => op.opcode == opcode)

private def findTimedMovementFamilyInList?
    (families : List RawTimedMovementFamilyShape)
    (opcode : Int) : Option RawTimedMovementFamilyMatch :=
  match families with
  | [] => none
  | family :: rest =>
      if family.matches opcode then
        some
          { family := family
            opcode := opcode
            easingFromOpcode := family.easingFromOpcode? opcode }
      else
        findTimedMovementFamilyInList? rest opcode

def RawInstrShape.findTimedMovementFamily?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawTimedMovementFamilyMatch :=
  findTimedMovementFamilyInList? rawShape.timedMovementFamilies opcode

def RawInstrShape.findOrbitMovementOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawOrbitMovementOpShape :=
  rawShape.orbitMovementOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findEnemyStateOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawEnemyStateOpShape :=
  rawShape.enemyStateOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findShootingOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawShootingOpShape :=
  rawShape.shootingOps.find? (fun op => op.opcode == opcode)

private def findBulletPatternFamilyInList?
    (families : List RawBulletPatternFamilyShape)
    (opcode : Int) : Option RawBulletPatternFamilyMatch :=
  match families with
  | [] => none
  | family :: rest =>
      match family.aimMode? opcode with
      | some aimMode => some { family := family, aimMode := aimMode }
      | none => findBulletPatternFamilyInList? rest opcode

def RawInstrShape.findBulletPatternFamily?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBulletPatternFamilyMatch :=
  findBulletPatternFamilyInList? rawShape.bulletPatternFamilies opcode

def RawInstrShape.findCallbackConfigOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawCallbackConfigOpShape :=
  rawShape.callbackConfigOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findInterruptOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawInterruptOpShape :=
  rawShape.interruptOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findIntDivisorHazard?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntDivisorHazard :=
  rawShape.intDivisorHazards.find? (fun hazard => hazard.opcode == opcode)

def RawInstrShape.findIntConditionJump?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntConditionJumpShape :=
  rawShape.intConditionJumps.find? (fun jump => jump.opcode == opcode)

def RawInstrShape.findFloatConditionJump?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawFloatConditionJumpShape :=
  rawShape.floatConditionJumps.find? (fun jump => jump.opcode == opcode)

def RawInstrShape.findCompareRegisterOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawCompareRegisterShape :=
  rawShape.compareRegisterOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findConditionalCall?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawConditionalCallShape :=
  rawShape.conditionalCallShapes.find? (fun call => call.opcode == opcode)

def RawInstrShape.findScalarAssign?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawScalarAssignShape :=
  rawShape.scalarAssignments.find? (fun op => op.opcode == opcode)

def RawInstrShape.findIntUnaryUpdate?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntUnaryUpdateShape :=
  rawShape.intUnaryUpdates.find? (fun op => op.opcode == opcode)

structure HeaderShape where
  title : String
  hasVersionField : Bool
  versionOffset : Option Nat := none
  expectedVersion : Option Nat := none
  subCountOffset : Nat
  timelineCountOffset : Nat
  timelineTableOffset : Nat
  fixedHeaderBytes : Nat
  timelineSlots : Nat
  loaderTimelineSlots : Nat
  subTableField : String
  negativeSubIdPolicy : NegativeSubIdPolicy
  timelineShape : Option TimelineShape := none
  rawInstrShape : Option RawInstrShape := none
  evidence : List TouhouFormal.SourceRef := []
deriving Repr, DecidableEq

private def showOptNat : Option Nat -> String
  | none => "-"
  | some value => toString value

def HeaderShape.summary (shape : HeaderShape) : String :=
  shape.title ++
    " headerBytes=" ++ toString shape.fixedHeaderBytes ++
    " timelineSlots=" ++ toString shape.timelineSlots ++
    " loaderTimelineSlots=" ++ toString shape.loaderTimelineSlots ++
    " expectedVersion=" ++ showOptNat shape.expectedVersion ++
    " negativeSubId=" ++ shape.negativeSubIdPolicy.name

def HeaderShape.timelineTableEnd (shape : HeaderShape) : Nat :=
  shape.timelineTableOffset + 4 * shape.timelineSlots

end TouhouFormal.ECL
