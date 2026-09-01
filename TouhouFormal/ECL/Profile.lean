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

inductive RawNumericSpecialSource where
  | enemyPositionX
  | enemyPositionY
  | enemyPositionZ
deriving Repr, DecidableEq

def RawNumericSpecialSource.name : RawNumericSpecialSource -> String
  | .enemyPositionX => "enemy-position-x"
  | .enemyPositionY => "enemy-position-y"
  | .enemyPositionZ => "enemy-position-z"

inductive RawNumericSpecialOpKind where
  | copyHostFloat (source : RawNumericSpecialSource)
  | lerp
  | polarToCartesian
  | distance2d
deriving Repr, DecidableEq

def RawNumericSpecialOpKind.name : RawNumericSpecialOpKind -> String
  | .copyHostFloat source => "copy-" ++ source.name
  | .lerp => "lerp"
  | .polarToCartesian => "polar-to-cartesian"
  | .distance2d => "distance-2d"

structure RawNumericSpecialOpShape where
  opcode : Int
  kind : RawNumericSpecialOpKind
  outputPolicy : RawScalarAssignOutputPolicy
  outputOperandIndices : List Nat
  inputOperandIndices : List Nat := []
deriving Repr, DecidableEq

structure RawInterpolationOpShape where
  opcode : Int
  affectedVariableOperandIndex : Nat := 0
  durationOperandIndex : Nat := 1
  callbackIndexOperandIndex : Nat := 2
  easingOperandIndex : Nat := 3
  parameterOperandIndices : List Nat := [4, 5, 6, 7]
  slotCount : Nat := 8
  callbackTableCount : Nat := 8
deriving Repr, DecidableEq

inductive RawRandomOpKind where
  | intRange
  | intRangeAdd
  | floatRange
  | floatRangeAdd
  | floatBetween
  | intSign
  | floatSign
deriving Repr, DecidableEq

def RawRandomOpKind.name : RawRandomOpKind -> String
  | .intRange => "int-range"
  | .intRangeAdd => "int-range-add"
  | .floatRange => "float-range"
  | .floatRangeAdd => "float-range-add"
  | .floatBetween => "float-between"
  | .intSign => "int-sign"
  | .floatSign => "float-sign"

def RawRandomOpKind.scalarKind : RawRandomOpKind -> RawScalarKind
  | .intRange | .intRangeAdd | .intSign => .int
  | .floatRange | .floatRangeAdd | .floatBetween | .floatSign => .float

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
  | .floatRange | .floatRangeAdd | .floatBetween => .floatZeroToOne
  | .intSign | .floatSign => .u16Parity

def RawRandomOpKind.requiresAddend : RawRandomOpKind -> Bool
  | .intRangeAdd | .floatRangeAdd | .floatBetween => true
  | _ => false

def RawRandomOpKind.repeatsAddend : RawRandomOpKind -> Bool
  | .floatBetween => true
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

inductive RawRandomDirectionGeneratorKind where
  | operandRange
  | playerSide
  | arenaExit
  | hostCandidate
deriving Repr, DecidableEq

def RawRandomDirectionGeneratorKind.name :
    RawRandomDirectionGeneratorKind -> String
  | .operandRange => "operand-range"
  | .playerSide => "player-side"
  | .arenaExit => "arena-exit"
  | .hostCandidate => "host-candidate"

inductive RawRandomDirectionRightPositiveSource where
  | candidateAngle
  | currentEnemyAngle
deriving Repr, DecidableEq

def RawRandomDirectionRightPositiveSource.name :
    RawRandomDirectionRightPositiveSource -> String
  | .candidateAngle => "candidate-angle"
  | .currentEnemyAngle => "current-enemy-angle"

inductive RawRandomDirectionBoundaryPolicy where
  | none
  | rectangle (rightPositiveSource : RawRandomDirectionRightPositiveSource)
  | vertical
deriving Repr, DecidableEq

def RawRandomDirectionBoundaryPolicy.name :
    RawRandomDirectionBoundaryPolicy -> String
  | .none => "none"
  | .rectangle source => "rectangle-" ++ source.name
  | .vertical => "vertical"

inductive RawRandomDirectionOutputPolicy where
  | enemyAngle
  | floatLValue (operandIndex : Nat)
  | hostAngle
deriving Repr, DecidableEq

def RawRandomDirectionOutputPolicy.name :
    RawRandomDirectionOutputPolicy -> String
  | .enemyAngle => "enemy-angle"
  | .floatLValue operandIndex => "float-lvalue-" ++ toString operandIndex
  | .hostAngle => "host-angle"

structure RawRandomDirectionOpShape where
  opcode : Int
  generator : RawRandomDirectionGeneratorKind
  floatInputs : List RawMovementFloatInputShape := []
  boundaryPolicy : RawRandomDirectionBoundaryPolicy := .none
  outputPolicy : RawRandomDirectionOutputPolicy
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

inductive RawBulletControlIntInputPolicy where
  | intRValue
  | rawI32
deriving Repr, DecidableEq

def RawBulletControlIntInputPolicy.name :
    RawBulletControlIntInputPolicy -> String
  | .intRValue => "int-rvalue"
  | .rawI32 => "raw-i32"

structure RawBulletControlIntInputShape where
  operandIndex : Nat
  policy : RawBulletControlIntInputPolicy
deriving Repr, DecidableEq

inductive RawBulletControlFloatInputPolicy where
  | floatRValue
  | rawBits
deriving Repr, DecidableEq

def RawBulletControlFloatInputPolicy.name :
    RawBulletControlFloatInputPolicy -> String
  | .floatRValue => "float-rvalue"
  | .rawBits => "raw-bits"

structure RawBulletControlFloatInputShape where
  operandIndex : Nat
  policy : RawBulletControlFloatInputPolicy
deriving Repr, DecidableEq

inductive RawBulletClearMode where
  | turnAllIntoPoints
  | removeAll (awardItems : Bool)
  | removeAllMode (mode : Int)
  | clearForTransition
  | removeRadius
deriving Repr, DecidableEq

def RawBulletClearMode.name : RawBulletClearMode -> String
  | .turnAllIntoPoints => "turn-all-into-points"
  | .removeAll true => "remove-all-award-items"
  | .removeAll false => "remove-all-no-items"
  | .removeAllMode mode => "remove-all-mode-" ++ toString mode
  | .clearForTransition => "clear-for-transition"
  | .removeRadius => "remove-radius"

inductive RawBulletSoundTarget where
  | enemyBulletProps
  | bulletSpawnDescriptor
deriving Repr, DecidableEq

def RawBulletSoundTarget.name : RawBulletSoundTarget -> String
  | .enemyBulletProps => "enemy-bullet-props"
  | .bulletSpawnDescriptor => "bullet-spawn-descriptor"

inductive RawBulletControlOpKind where
  | clear (mode : RawBulletClearMode)
  | setSound
  | setRankInfluence
deriving Repr, DecidableEq

def RawBulletControlOpKind.name : RawBulletControlOpKind -> String
  | .clear mode => "clear-" ++ mode.name
  | .setSound => "set-sound"
  | .setRankInfluence => "set-rank-influence"

structure RawBulletControlOpShape where
  opcode : Int
  kind : RawBulletControlOpKind
  intInputs : List RawBulletControlIntInputShape := []
  floatInputs : List RawBulletControlFloatInputShape := []
  soundTarget : RawBulletSoundTarget := .enemyBulletProps
  soundHasOverride : Bool := false
  soundRepeatsPrimaryOnEnable : Bool := false
  soundFlagMask : Int := 0x200
  rankIntValuesTruncateToI16 : Bool := true
deriving Repr, DecidableEq

inductive RawBulletTransformIntRole where
  | index
  | kind
  | flag
  | duration
  | loopCount
  | allowWhileActive
  | payloadInt0
  | payloadInt1
deriving Repr, DecidableEq

def RawBulletTransformIntRole.name : RawBulletTransformIntRole -> String
  | .index => "index"
  | .kind => "kind"
  | .flag => "flag"
  | .duration => "duration"
  | .loopCount => "loop-count"
  | .allowWhileActive => "allow-while-active"
  | .payloadInt0 => "payload-int-0"
  | .payloadInt1 => "payload-int-1"

inductive RawBulletTransformFloatRole where
  | speed
  | angle
  | payloadFloat0
  | payloadFloat1
deriving Repr, DecidableEq

def RawBulletTransformFloatRole.name :
    RawBulletTransformFloatRole -> String
  | .speed => "speed"
  | .angle => "angle"
  | .payloadFloat0 => "payload-float-0"
  | .payloadFloat1 => "payload-float-1"

structure RawBulletTransformIntInputShape where
  role : RawBulletTransformIntRole
  operandIndex : Nat
deriving Repr, DecidableEq

structure RawBulletTransformFloatInputShape where
  role : RawBulletTransformFloatRole
  operandIndex : Nat
deriving Repr, DecidableEq

inductive RawBulletTransformOpKind where
  | legacyCommand
  | transformRecord
deriving Repr, DecidableEq

def RawBulletTransformOpKind.name : RawBulletTransformOpKind -> String
  | .legacyCommand => "legacy-command"
  | .transformRecord => "transform-record"

structure RawBulletTransformOpShape where
  opcode : Int
  kind : RawBulletTransformOpKind
  intInputs : List RawBulletTransformIntInputShape
  floatInputs : List RawBulletTransformFloatInputShape
  tableCount : Nat
deriving Repr, DecidableEq

inductive RawLaserSpawnDescriptorTarget where
  | enemyLaserShooter
  | bulletSpawnDescriptor
deriving Repr, DecidableEq

def RawLaserSpawnDescriptorTarget.name :
    RawLaserSpawnDescriptorTarget -> String
  | .enemyLaserShooter => "enemy-laser-shooter"
  | .bulletSpawnDescriptor => "bullet-spawn-descriptor"

inductive RawLaserSpawnAimKind where
  | fixed
  | aimedAtPlayer
deriving Repr, DecidableEq

def RawLaserSpawnAimKind.name : RawLaserSpawnAimKind -> String
  | .fixed => "fixed"
  | .aimedAtPlayer => "aimed-at-player"

def RawLaserSpawnAimKind.storedValue : RawLaserSpawnAimKind -> Int
  | .fixed => 1
  | .aimedAtPlayer => 0

inductive RawLaserSpawnIntInputPolicy where
  | raw
  | intRValue
deriving Repr, DecidableEq

def RawLaserSpawnIntInputPolicy.name :
    RawLaserSpawnIntInputPolicy -> String
  | .raw => "raw"
  | .intRValue => "int-rvalue"

inductive RawLaserSpawnIntStorePolicy where
  | i32
  | signedI16
  | u32
deriving Repr, DecidableEq

def RawLaserSpawnIntStorePolicy.name :
    RawLaserSpawnIntStorePolicy -> String
  | .i32 => "i32"
  | .signedI16 => "signed-i16"
  | .u32 => "u32"

structure RawLaserSpawnIntInputShape where
  operandIndex : Nat
  flagIndex : Nat
  policy : RawLaserSpawnIntInputPolicy
  storePolicy : RawLaserSpawnIntStorePolicy := .i32
deriving Repr, DecidableEq

inductive RawLaserSpawnFloatInputPolicy where
  | rawBits
  | floatRValue
deriving Repr, DecidableEq

def RawLaserSpawnFloatInputPolicy.name :
    RawLaserSpawnFloatInputPolicy -> String
  | .rawBits => "raw-bits"
  | .floatRValue => "float-rvalue"

structure RawLaserSpawnFloatInputShape where
  operandIndex : Nat
  flagIndex : Nat
  policy : RawLaserSpawnFloatInputPolicy
deriving Repr, DecidableEq

inductive RawLaserSpawnPositionSource where
  | enemyPositionPlusShootOffset
  | enemyWorldPositionPlusShootOffset
deriving Repr, DecidableEq

def RawLaserSpawnPositionSource.name :
    RawLaserSpawnPositionSource -> String
  | .enemyPositionPlusShootOffset => "enemy-position-plus-shoot-offset"
  | .enemyWorldPositionPlusShootOffset =>
      "enemy-world-position-plus-shoot-offset"

structure RawLaserSpawnOpShape where
  opcode : Int
  descriptorTarget : RawLaserSpawnDescriptorTarget
  aimKind : RawLaserSpawnAimKind
  positionSource : RawLaserSpawnPositionSource :=
    .enemyPositionPlusShootOffset
  intInputs : List RawLaserSpawnIntInputShape := []
  floatInputs : List RawLaserSpawnFloatInputShape := []
  slotCount : Nat := 32
deriving Repr, DecidableEq

inductive RawLaserIntInputPolicy where
  | intRValue
  | rawI32
  | rawByte
deriving Repr, DecidableEq

def RawLaserIntInputPolicy.name : RawLaserIntInputPolicy -> String
  | .intRValue => "int-rvalue"
  | .rawI32 => "raw-i32"
  | .rawByte => "raw-byte"

structure RawLaserIntInputShape where
  operandIndex : Nat
  policy : RawLaserIntInputPolicy
  byteIndex : Nat := 0
deriving Repr, DecidableEq

inductive RawLaserFloatInputPolicy where
  | floatRValue
  | rawBits
deriving Repr, DecidableEq

def RawLaserFloatInputPolicy.name : RawLaserFloatInputPolicy -> String
  | .floatRValue => "float-rvalue"
  | .rawBits => "raw-bits"

structure RawLaserFloatInputShape where
  operandIndex : Nat
  policy : RawLaserFloatInputPolicy
deriving Repr, DecidableEq

inductive RawLaserAngleMode where
  | add
  | addNormalized
  | set
  | aimAtPlayer
deriving Repr, DecidableEq

def RawLaserAngleMode.name : RawLaserAngleMode -> String
  | .add => "add"
  | .addNormalized => "add-normalized"
  | .set => "set"
  | .aimAtPlayer => "aim-at-player"

inductive RawLaserTestTarget where
  | compareRegister
  | laserNotInUse
  | extraIntVariable (index : Nat)
deriving Repr, DecidableEq

def RawLaserTestTarget.name : RawLaserTestTarget -> String
  | .compareRegister => "compare-register"
  | .laserNotInUse => "laser-not-in-use"
  | .extraIntVariable index => "extra-int-" ++ toString index

inductive RawLaserOpKind where
  | setSelectedSlot
  | writeAngle (mode : RawLaserAngleMode)
  | writeRelativePosition
  | testInUse
  | stop
  | clearAll
  | writeStartLength
  | writeOffsets
  | writeHideWarning
deriving Repr, DecidableEq

def RawLaserOpKind.name : RawLaserOpKind -> String
  | .setSelectedSlot => "set-selected-slot"
  | .writeAngle mode => "write-angle-" ++ mode.name
  | .writeRelativePosition => "write-relative-position"
  | .testInUse => "test-in-use"
  | .stop => "stop"
  | .clearAll => "clear-all"
  | .writeStartLength => "write-start-length"
  | .writeOffsets => "write-offsets"
  | .writeHideWarning => "write-hide-warning"

structure RawLaserOpShape where
  opcode : Int
  kind : RawLaserOpKind
  slotCount : Nat := 32
  intInputs : List RawLaserIntInputShape := []
  floatInputs : List RawLaserFloatInputShape := []
  stopCopiesCurrentWidth : Bool := false
  hideTruncatesToU8 : Bool := false
  testTarget : RawLaserTestTarget := .compareRegister
  testActiveValue : Int := 0
  testInactiveValue : Int := 1
deriving Repr, DecidableEq

inductive RawAnimationBank where
  | primary
  | alternate
deriving Repr, DecidableEq

def RawAnimationBank.name : RawAnimationBank -> String
  | .primary => "primary"
  | .alternate => "alternate"

inductive RawAnimationBankPolicy where
  | fixed (bank : RawAnimationBank)
  | runtimeFlag
deriving Repr, DecidableEq

def RawAnimationBankPolicy.name : RawAnimationBankPolicy -> String
  | .fixed bank => "fixed-" ++ bank.name
  | .runtimeFlag => "runtime-flag"

inductive RawAnimationScriptSource where
  | intRValue (operandIndex : Nat)
  | rawI32 (operandIndex : Nat)
  | runtimeSpecial
deriving Repr, DecidableEq

def RawAnimationScriptSource.name : RawAnimationScriptSource -> String
  | .intRValue operandIndex => "int-rvalue-" ++ toString operandIndex
  | .rawI32 operandIndex => "raw-i32-" ++ toString operandIndex
  | .runtimeSpecial => "runtime-special"

inductive RawAnimationIntInputPolicy where
  | intRValue
  | rawI32
  | rawByte
  | rawU16ToI16
  | rawI16
deriving Repr, DecidableEq

def RawAnimationIntInputPolicy.name : RawAnimationIntInputPolicy -> String
  | .intRValue => "int-rvalue"
  | .rawI32 => "raw-i32"
  | .rawByte => "raw-byte"
  | .rawU16ToI16 => "raw-u16-to-i16"
  | .rawI16 => "raw-i16"

structure RawAnimationIntInputShape where
  operandIndex : Nat
  policy : RawAnimationIntInputPolicy
  byteIndex : Nat := 0
  halfIndex : Nat := 0
deriving Repr, DecidableEq

inductive RawAnimationFloatInputPolicy where
  | floatRValue
  | rawBits
deriving Repr, DecidableEq

def RawAnimationFloatInputPolicy.name : RawAnimationFloatInputPolicy -> String
  | .floatRValue => "float-rvalue"
  | .rawBits => "raw-bits"

structure RawAnimationFloatInputShape where
  operandIndex : Nat
  policy : RawAnimationFloatInputPolicy
deriving Repr, DecidableEq

inductive RawAnimationSecondaryScriptMode where
  | alwaysRun
  | runWhenNonnegativeElseClear
deriving Repr, DecidableEq

def RawAnimationSecondaryScriptMode.name :
    RawAnimationSecondaryScriptMode -> String
  | .alwaysRun => "always-run"
  | .runWhenNonnegativeElseClear => "run-when-nonnegative-else-clear"

structure RawAnimationSecondaryAccessShape where
  slotCount : Nat
  diagnoseHighOnly : Bool := true
  slotInput : RawAnimationIntInputShape
  scriptInput : RawAnimationIntInputShape :=
    { operandIndex := 1, policy := .rawI32 }
  scriptMode : RawAnimationSecondaryScriptMode := .alwaysRun
  interruptInput : RawAnimationIntInputShape :=
    { operandIndex := 1, policy := .rawI32 }
  repeatedSlotReadForAccess : Bool := false
  repeatedScriptReadForHostCall : Bool := false
  scriptBase : Int := 0
  clearScriptIndexValue : Int := -1
deriving Repr, DecidableEq

inductive RawAnimationOpKind where
  | setPrimaryScript
  | setSecondaryScript
  | setPrimaryScriptTableSequential
  | setPrimaryScriptTableExplicit
  | playPrimarySpecialScript
  | setMovementScripts
  | setDeathScripts
  | setAutoRotate
  | setPrimaryInterrupt
  | setSecondaryInterrupt
  | setPrimaryRotationZ
deriving Repr, DecidableEq

def RawAnimationOpKind.name : RawAnimationOpKind -> String
  | .setPrimaryScript => "set-primary-script"
  | .setSecondaryScript => "set-secondary-script"
  | .setPrimaryScriptTableSequential => "set-primary-script-table-sequential"
  | .setPrimaryScriptTableExplicit => "set-primary-script-table-explicit"
  | .playPrimarySpecialScript => "play-primary-special-script"
  | .setMovementScripts => "set-movement-scripts"
  | .setDeathScripts => "set-death-scripts"
  | .setAutoRotate => "set-auto-rotate"
  | .setPrimaryInterrupt => "set-primary-interrupt"
  | .setSecondaryInterrupt => "set-secondary-interrupt"
  | .setPrimaryRotationZ => "set-primary-rotation-z"

structure RawAnimationOpShape where
  opcode : Int
  kind : RawAnimationOpKind
  bankPolicy : RawAnimationBankPolicy := .fixed .primary
  scriptSource : Option RawAnimationScriptSource := none
  scriptBase : Int := 0
  intInputs : List RawAnimationIntInputShape := []
  floatInputs : List RawAnimationFloatInputShape := []
  secondaryAccess : Option RawAnimationSecondaryAccessShape := none
  setAlternateBankFlag : Option Bool := none
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

inductive RawExtensionOpKind where
  | callNow
  | installPerFrame
deriving Repr, DecidableEq

def RawExtensionOpKind.name : RawExtensionOpKind -> String
  | .callNow => "call-now"
  | .installPerFrame => "install-per-frame"

inductive RawExtensionIntPolicy where
  | rawI32
  | intRValue
deriving Repr, DecidableEq

def RawExtensionIntPolicy.name : RawExtensionIntPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"

structure RawExtensionOpShape where
  opcode : Int
  kind : RawExtensionOpKind
  intPolicy : RawExtensionIntPolicy
  tableEntryCount : Nat
  repeatIndexReadOnInstall : Bool := false
deriving Repr, DecidableEq

inductive RawChildContextIntPolicy where
  | rawI32
  | intRValue
deriving Repr, DecidableEq

def RawChildContextIntPolicy.name : RawChildContextIntPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"

structure RawChildContextOpShape where
  opcode : Int
  intPolicy : RawChildContextIntPolicy
  slotOperandIndex : Nat := 0
  subOperandIndex : Nat := 1
  slotCount : Nat
  repeatSubReadAfterAllocation : Bool := true
  truncateCallSubToI16 : Bool := true
  blockByteCount : Nat
  copiedVariableBytes : Nat
deriving Repr, DecidableEq

/-!
Shared profile for small but semantically important ECL handlers that mutate
enemy, manager, stage, or GUI state.  These handlers live at very different
opcode numbers in the three games, but their operand resolution, C-width
stores, timer assignment, and host-call boundaries are common enough to keep
in one semantic family.
-/

inductive RawMiscIntInputPolicy where
  | rawI32
  | rawByte
  | intRValue
deriving Repr, DecidableEq

def RawMiscIntInputPolicy.name : RawMiscIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .rawByte => "raw-byte"
  | .intRValue => "int-rvalue"

inductive RawMiscFloatInputPolicy where
  | rawBits
  | floatRValue
deriving Repr, DecidableEq

def RawMiscFloatInputPolicy.name : RawMiscFloatInputPolicy -> String
  | .rawBits => "raw-bits"
  | .floatRValue => "float-rvalue"

structure RawMiscIntInputShape where
  operandIndex : Nat
  policy : RawMiscIntInputPolicy
deriving Repr, DecidableEq

structure RawMiscFloatInputShape where
  operandIndex : Nat
  policy : RawMiscFloatInputPolicy
deriving Repr, DecidableEq

inductive RawMiscStorePolicy where
  | identityI32
  | unsignedBits (width : Nat)
  | signedI16
deriving Repr, DecidableEq

def RawMiscStorePolicy.name : RawMiscStorePolicy -> String
  | .identityI32 => "identity-i32"
  | .unsignedBits width => "u" ++ toString width
  | .signedI16 => "signed-i16"

inductive RawMiscIntTarget where
  | enemyInvisible
  | enemyHasNoCollision
  | enemyIsProjectile
  | enemyDisableOobDespawn
  | enemyFreezeDuringBomb
  | enemyDrawGroup
  | enemyZLayer
  | enemySpecialInteraction
  | enemyPauseTimer
  | enemyNoDamageDuringStop
  | enemyFormEffect
  | enemyExtraVmFixedOffset
  | enemyManagerUnused
  | enemyManagerOpcode163
  | backgroundPendingLabel
  | suppressTimelineSpawns
deriving Repr, DecidableEq

def RawMiscIntTarget.name : RawMiscIntTarget -> String
  | .enemyInvisible => "enemy-invisible"
  | .enemyHasNoCollision => "enemy-has-no-collision"
  | .enemyIsProjectile => "enemy-is-projectile"
  | .enemyDisableOobDespawn => "enemy-disable-oob-despawn"
  | .enemyFreezeDuringBomb => "enemy-freeze-during-bomb"
  | .enemyDrawGroup => "enemy-draw-group"
  | .enemyZLayer => "enemy-z-layer"
  | .enemySpecialInteraction => "enemy-special-interaction"
  | .enemyPauseTimer => "enemy-pause-timer"
  | .enemyNoDamageDuringStop => "enemy-no-damage-during-stop"
  | .enemyFormEffect => "enemy-form-effect"
  | .enemyExtraVmFixedOffset => "enemy-extra-vm-fixed-offset"
  | .enemyManagerUnused => "enemy-manager-unused"
  | .enemyManagerOpcode163 => "enemy-manager-opcode-163"
  | .backgroundPendingLabel => "background-pending-label"
  | .suppressTimelineSpawns => "suppress-timeline-spawns"

inductive RawMiscTimerTarget where
  | invincibility
  | damageReduction
deriving Repr, DecidableEq

def RawMiscTimerTarget.name : RawMiscTimerTarget -> String
  | .invincibility => "invincibility"
  | .damageReduction => "damage-reduction"

inductive RawMiscGuiAction where
  | startStageBackgroundSequence
  | hideClockTime
deriving Repr, DecidableEq

def RawMiscGuiAction.name : RawMiscGuiAction -> String
  | .startStageBackgroundSequence => "start-stage-background-sequence"
  | .hideClockTime => "hide-clock-time"

inductive RawMiscOpKind where
  | noOp
  | writeInt (target : RawMiscIntTarget) (store : RawMiscStorePolicy)
  | writeTimer (target : RawMiscTimerTarget)
  | setProjectile
  | setSpecialInteraction
  | configureTrail
  | addCherry
  | stageUnpause
  | configurePause
  | setMinimumPlayerDistance
  | gui (action : RawMiscGuiAction)
  | advanceClock
deriving Repr, DecidableEq

def RawMiscOpKind.name : RawMiscOpKind -> String
  | .noOp => "no-op"
  | .writeInt target store =>
      "write-" ++ target.name ++ "-" ++ store.name
  | .writeTimer target => "write-" ++ target.name ++ "-timer"
  | .setProjectile => "set-projectile"
  | .setSpecialInteraction => "set-special-interaction"
  | .configureTrail => "configure-trail"
  | .addCherry => "add-cherry"
  | .stageUnpause => "stage-unpause"
  | .configurePause => "configure-pause"
  | .setMinimumPlayerDistance => "set-minimum-player-distance"
  | .gui action => "gui-" ++ action.name
  | .advanceClock => "advance-clock"

structure RawMiscOpShape where
  opcode : Int
  kind : RawMiscOpKind
  intInputs : List RawMiscIntInputShape := []
  floatInputs : List RawMiscFloatInputShape := []
  trailRenderMask : Nat := 8
deriving Repr, DecidableEq

/-!
TH08's cross-enemy boss dispatch uses the same operand resolver and call-stack
machinery as ordinary ECL, but it operates on another enemy's active context
through an unchecked fixed boss table.  Keeping it separate from boss field
reads makes the inter-enemy mutation and its partial-fault order explicit.
-/

inductive RawBossDispatchIntPolicy where
  | rawI32
  | intRValue
deriving Repr, DecidableEq

def RawBossDispatchIntPolicy.name : RawBossDispatchIntPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"

inductive RawBossDispatchOpKind where
  | callSubOnBoss
  | setPendingSubOnBoss
deriving Repr, DecidableEq

def RawBossDispatchOpKind.name : RawBossDispatchOpKind -> String
  | .callSubOnBoss => "call-sub-on-boss"
  | .setPendingSubOnBoss => "set-pending-sub-on-boss"

structure RawBossDispatchOpShape where
  opcode : Int
  kind : RawBossDispatchOpKind
  bossIndexOperandIndex : Nat := 0
  subIdOperandIndex : Nat := 1
  bossIndexPolicy : RawBossDispatchIntPolicy := .intRValue
  subIdPolicy : RawBossDispatchIntPolicy
  bossSlotCount : Nat
  repeatBossIndexRead : Bool := false
  truncateSubIdToI16 : Bool := true
  callStackEntryCount : Nat := 16
  callStackIncrementGuardExclusive : Nat := 15
  callParameterCopyBytes : Nat := 0x20
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

inductive RawTimeControlIntInputPolicy where
  | rawI32
  | intRValue
deriving Repr, DecidableEq

def RawTimeControlIntInputPolicy.name :
    RawTimeControlIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"

structure RawTimeControlIntInputShape where
  operandIndex : Nat
  policy : RawTimeControlIntInputPolicy
deriving Repr, DecidableEq

inductive RawTimeControlTarget where
  | contextTime
  | contextWaitTimer
  | contextSecondaryTime
  | stageScriptWaitTime
deriving Repr, DecidableEq

def RawTimeControlTarget.name : RawTimeControlTarget -> String
  | .contextTime => "context-time"
  | .contextWaitTimer => "context-wait-timer"
  | .contextSecondaryTime => "context-secondary-time"
  | .stageScriptWaitTime => "stage-script-wait-time"

inductive RawTimeControlOpKind where
  | noOp
  | addToTime
  | setTimer (target : RawTimeControlTarget)
deriving Repr, DecidableEq

def RawTimeControlOpKind.name : RawTimeControlOpKind -> String
  | .noOp => "no-op"
  | .addToTime => "add-to-time"
  | .setTimer target => "set-" ++ target.name

structure RawTimeControlOpShape where
  opcode : Int
  kind : RawTimeControlOpKind
  intInput : Option RawTimeControlIntInputShape := none
deriving Repr, DecidableEq

inductive RawEnemyLifecycleIntInputPolicy where
  | rawI32
  | rawI16
  | intRValue
deriving Repr, DecidableEq

def RawEnemyLifecycleIntInputPolicy.name :
    RawEnemyLifecycleIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .rawI16 => "raw-i16"
  | .intRValue => "int-rvalue"

inductive RawEnemyLifecycleFloatInputPolicy where
  | rawBits
  | floatRValue
deriving Repr, DecidableEq

def RawEnemyLifecycleFloatInputPolicy.name :
    RawEnemyLifecycleFloatInputPolicy -> String
  | .rawBits => "raw-bits"
  | .floatRValue => "float-rvalue"

inductive RawEnemyLifecycleIntRole where
  | subId
  | life
  | itemDrop
  | score
deriving Repr, DecidableEq

def RawEnemyLifecycleIntRole.name : RawEnemyLifecycleIntRole -> String
  | .subId => "sub-id"
  | .life => "life"
  | .itemDrop => "item-drop"
  | .score => "score"

inductive RawEnemyLifecycleFloatRole where
  | positionX
  | positionY
  | positionZ
deriving Repr, DecidableEq

def RawEnemyLifecycleFloatRole.name : RawEnemyLifecycleFloatRole -> String
  | .positionX => "position-x"
  | .positionY => "position-y"
  | .positionZ => "position-z"

structure RawEnemyLifecycleIntInputShape where
  role : RawEnemyLifecycleIntRole
  operandIndex : Nat
  policy : RawEnemyLifecycleIntInputPolicy
deriving Repr, DecidableEq

structure RawEnemyLifecycleFloatInputShape where
  role : RawEnemyLifecycleFloatRole
  operandIndex : Nat
  policy : RawEnemyLifecycleFloatInputPolicy
deriving Repr, DecidableEq

inductive RawEnemySpawnPositionMode where
  | absolute
  | relativeToEnemy
deriving Repr, DecidableEq

def RawEnemySpawnPositionMode.name : RawEnemySpawnPositionMode -> String
  | .absolute => "absolute"
  | .relativeToEnemy => "relative-to-enemy"

inductive RawEnemySpawnContextCopy where
  | none
  | eclContextArgs
  | activeIntVariables
deriving Repr, DecidableEq

def RawEnemySpawnContextCopy.name : RawEnemySpawnContextCopy -> String
  | .none => "none"
  | .eclContextArgs => "ecl-context-args"
  | .activeIntVariables => "active-int-variables"

inductive RawEnemyRemoveAllImplementation where
  | inlineTH06Loop
  | removeAllEnemies
  | killAllNonBossEnemies
deriving Repr, DecidableEq

def RawEnemyRemoveAllImplementation.name :
    RawEnemyRemoveAllImplementation -> String
  | .inlineTH06Loop => "inline-th06-loop"
  | .removeAllEnemies => "remove-all-enemies"
  | .killAllNonBossEnemies => "kill-all-non-boss-enemies"

inductive RawEnemyLifecycleOpKind where
  | spawn (positionMode : RawEnemySpawnPositionMode)
  | removeAllNonBoss
deriving Repr, DecidableEq

def RawEnemyLifecycleOpKind.name : RawEnemyLifecycleOpKind -> String
  | .spawn positionMode => "spawn-" ++ positionMode.name
  | .removeAllNonBoss => "remove-all-non-boss"

structure RawEnemyLifecycleOpShape where
  opcode : Int
  kind : RawEnemyLifecycleOpKind
  intInputs : List RawEnemyLifecycleIntInputShape := []
  floatInputs : List RawEnemyLifecycleFloatInputShape := []
  spawnRequiresPositiveParentLife : Bool := false
  contextCopy : RawEnemySpawnContextCopy := .none
  hostSubIdTruncatesToI16 : Bool := true
  hostItemDropTruncatesToI8 : Bool := false
  poolSearchSlots : Nat := 0
  removeImplementation : RawEnemyRemoveAllImplementation :=
    .killAllNonBossEnemies
  removeScoreMax : Int := 8000
  removeInitialScore : Int := 0
deriving Repr, DecidableEq

def rawEnemySpawnPacketIntInputs
    (subIdPolicy lifePolicy itemDropPolicy scorePolicy :
      RawEnemyLifecycleIntInputPolicy) :
    List RawEnemyLifecycleIntInputShape :=
  [ { role := .subId
      operandIndex := 0
      policy := subIdPolicy },
    { role := .life
      operandIndex := 4
      policy := lifePolicy },
    { role := .itemDrop
      operandIndex := 5
      policy := itemDropPolicy },
    { role := .score
      operandIndex := 6
      policy := scorePolicy } ]

def rawEnemySpawnPacketFloatInputs
    (policy : RawEnemyLifecycleFloatInputPolicy) :
    List RawEnemyLifecycleFloatInputShape :=
  [ { role := .positionX
      operandIndex := 1
      policy := policy },
    { role := .positionY
      operandIndex := 2
      policy := policy },
    { role := .positionZ
      operandIndex := 3
      policy := policy } ]

def rawEnemyLifecycleSpawnOp
    (opcode : Int)
    (positionMode : RawEnemySpawnPositionMode)
    (intInputs : List RawEnemyLifecycleIntInputShape)
    (floatInputs : List RawEnemyLifecycleFloatInputShape)
    (poolSearchSlots : Nat)
    (spawnRequiresPositiveParentLife : Bool := false)
    (contextCopy : RawEnemySpawnContextCopy := .none)
    (hostItemDropTruncatesToI8 : Bool := false)
    (hostSubIdTruncatesToI16 : Bool := true) :
    RawEnemyLifecycleOpShape :=
  { opcode := opcode
    kind := .spawn positionMode
    intInputs := intInputs
    floatInputs := floatInputs
    spawnRequiresPositiveParentLife := spawnRequiresPositiveParentLife
    contextCopy := contextCopy
    hostSubIdTruncatesToI16 := hostSubIdTruncatesToI16
    hostItemDropTruncatesToI8 := hostItemDropTruncatesToI8
    poolSearchSlots := poolSearchSlots }

def rawEnemyLifecycleRemoveAllOp
    (opcode : Int)
    (implementation : RawEnemyRemoveAllImplementation)
    (poolSearchSlots : Nat)
    (scoreMax : Int := 8000)
    (initialScore : Int := 0) :
    RawEnemyLifecycleOpShape :=
  { opcode := opcode
    kind := .removeAllNonBoss
    poolSearchSlots := poolSearchSlots
    removeImplementation := implementation
    removeScoreMax := scoreMax
    removeInitialScore := initialScore }

inductive RawItemIntInputPolicy where
  | rawI32
  | intRValue
deriving Repr, DecidableEq

def RawItemIntInputPolicy.name : RawItemIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"

inductive RawItemIntRole where
  | count
  | itemType
  | pointCount
  | powerOrPointCount
deriving Repr, DecidableEq

def RawItemIntRole.name : RawItemIntRole -> String
  | .count => "count"
  | .itemType => "item-type"
  | .pointCount => "point-count"
  | .powerOrPointCount => "power-or-point-count"

structure RawItemIntInputShape where
  role : RawItemIntRole
  operandIndex : Nat
  policy : RawItemIntInputPolicy
deriving Repr, DecidableEq

inductive RawItemLoopKind where
  | powerOrPointByPlayerPower
  | pointOnly
deriving Repr, DecidableEq

def RawItemLoopKind.name : RawItemLoopKind -> String
  | .powerOrPointByPlayerPower => "power-or-point-by-player-power"
  | .pointOnly => "point-only"

inductive RawItemOpKind where
  | spawnLoop (loopKind : RawItemLoopKind)
  | spawnSingle
  | setItemDropType
  | setItemDropCounts
deriving Repr, DecidableEq

def RawItemOpKind.name : RawItemOpKind -> String
  | .spawnLoop loopKind => "spawn-loop-" ++ loopKind.name
  | .spawnSingle => "spawn-single"
  | .setItemDropType => "set-item-drop-type"
  | .setItemDropCounts => "set-item-drop-counts"

structure RawItemOpShape where
  opcode : Int
  kind : RawItemOpKind
  intInputs : List RawItemIntInputShape := []
  spreadFullWidth : Int := 128
  spreadHalfWidth : Int := 64
  powerThreshold : Int := 128
  itemStateDefault : Bool := true
deriving Repr, DecidableEq

def rawItemLoopCountInputs
    (policy : RawItemIntInputPolicy) : List RawItemIntInputShape :=
  [ { role := .count
      operandIndex := 0
      policy := policy } ]

def rawItemSingleInputs
    (policy : RawItemIntInputPolicy) : List RawItemIntInputShape :=
  [ { role := .itemType
      operandIndex := 0
      policy := policy } ]

def rawItemDropCountInputs
    (policy : RawItemIntInputPolicy) : List RawItemIntInputShape :=
  [ { role := .pointCount
      operandIndex := 0
      policy := policy },
    { role := .powerOrPointCount
      operandIndex := 1
      policy := policy } ]

def rawItemLoopOp
    (opcode : Int)
    (loopKind : RawItemLoopKind)
    (intInputs : List RawItemIntInputShape)
    (spreadFullWidth spreadHalfWidth : Int)
    (powerThreshold : Int := 128) : RawItemOpShape :=
  { opcode := opcode
    kind := .spawnLoop loopKind
    intInputs := intInputs
    spreadFullWidth := spreadFullWidth
    spreadHalfWidth := spreadHalfWidth
    powerThreshold := powerThreshold }

def rawItemSingleOp
    (opcode : Int)
    (intInputs : List RawItemIntInputShape) : RawItemOpShape :=
  { opcode := opcode
    kind := .spawnSingle
    intInputs := intInputs }

def rawItemDropTypeOp
    (opcode : Int)
    (intInputs : List RawItemIntInputShape) : RawItemOpShape :=
  { opcode := opcode
    kind := .setItemDropType
    intInputs := intInputs }

def rawItemDropCountsOp
    (opcode : Int)
    (intInputs : List RawItemIntInputShape) : RawItemOpShape :=
  { opcode := opcode
    kind := .setItemDropCounts
    intInputs := intInputs }

inductive RawBossLifecycleIntInputPolicy where
  | rawI32
  | rawI16
  | rawU16
  | rawU8
  | intRValue
deriving Repr, DecidableEq

def RawBossLifecycleIntInputPolicy.name :
    RawBossLifecycleIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .rawI16 => "raw-i16"
  | .rawU16 => "raw-u16"
  | .rawU8 => "raw-u8"
  | .intRValue => "int-rvalue"

inductive RawBossLifecycleFloatInputPolicy where
  | rawBits
  | floatRValue
deriving Repr, DecidableEq

def RawBossLifecycleFloatInputPolicy.name :
    RawBossLifecycleFloatInputPolicy -> String
  | .rawBits => "raw-bits"
  | .floatRValue => "float-rvalue"

inductive RawBossLifecycleIntRole where
  | bossSlot
  | spellSprite
  | spellId
  | spellBonus
  | lifeMarkerCount
  | gaugeSlot
  | gaugeStart
  | gaugeStop
  | gaugeColor
  | flagValue
  | runInterruptSlot
  | runInterruptSub
  | phaseStartingLife
deriving Repr, DecidableEq

def RawBossLifecycleIntRole.name : RawBossLifecycleIntRole -> String
  | .bossSlot => "boss-slot"
  | .spellSprite => "spell-sprite"
  | .spellId => "spell-id"
  | .spellBonus => "spell-bonus"
  | .lifeMarkerCount => "life-marker-count"
  | .gaugeSlot => "gauge-slot"
  | .gaugeStart => "gauge-start"
  | .gaugeStop => "gauge-stop"
  | .gaugeColor => "gauge-color"
  | .flagValue => "flag-value"
  | .runInterruptSlot => "run-interrupt-slot"
  | .runInterruptSub => "run-interrupt-sub"
  | .phaseStartingLife => "phase-starting-life"

inductive RawBossLifecycleFloatRole where
  | storedVectorX
  | storedVectorY
  | storedVectorZ
deriving Repr, DecidableEq

def RawBossLifecycleFloatRole.name : RawBossLifecycleFloatRole -> String
  | .storedVectorX => "stored-vector-x"
  | .storedVectorY => "stored-vector-y"
  | .storedVectorZ => "stored-vector-z"

structure RawBossLifecycleIntInputShape where
  role : RawBossLifecycleIntRole
  operandIndex : Nat
  policy : RawBossLifecycleIntInputPolicy
  byteIndex : Nat := 0
  halfIndex : Nat := 0
deriving Repr, DecidableEq

structure RawBossLifecycleFloatInputShape where
  role : RawBossLifecycleFloatRole
  operandIndex : Nat
  policy : RawBossLifecycleFloatInputPolicy
deriving Repr, DecidableEq

inductive RawBossSlotStoragePolicy where
  | i32
  | u8
deriving Repr, DecidableEq

def RawBossSlotStoragePolicy.name : RawBossSlotStoragePolicy -> String
  | .i32 => "i32"
  | .u8 => "u8"

inductive RawBossPresentSetPolicy where
  | everyNonnegativeSlot
  | primarySlotOnly
deriving Repr, DecidableEq

def RawBossPresentSetPolicy.name : RawBossPresentSetPolicy -> String
  | .everyNonnegativeSlot => "every-nonnegative-slot"
  | .primarySlotOnly => "primary-slot-only"

inductive RawBossPresentClearPolicy where
  | always
  | currentSlotBelowGuiSlots
deriving Repr, DecidableEq

def RawBossPresentClearPolicy.name : RawBossPresentClearPolicy -> String
  | .always => "always"
  | .currentSlotBelowGuiSlots => "current-slot-below-gui-slots"

inductive RawBossSpellTextPolicy where
  | th06InlineTail
  | xorInline (byteCount : Nat) (xorValue : Nat)
  | th08EncodedRecord (nameBytes ownerBytes commentBytes : Nat)
deriving Repr, DecidableEq

def RawBossSpellTextPolicy.name : RawBossSpellTextPolicy -> String
  | .th06InlineTail => "th06-inline-tail"
  | .xorInline byteCount xorValue =>
      "xor-inline-" ++ toString byteCount ++ "-xor-" ++ toString xorValue
  | .th08EncodedRecord nameBytes ownerBytes commentBytes =>
      "th08-encoded-record-" ++ toString nameBytes ++ "-" ++
        toString ownerBytes ++ "-" ++ toString commentBytes

inductive RawBossSpellBulletClear where
  | turnAllIntoPoints
  | removeAllWithItems
  | despawnWithItems (scoreMax : Int)
deriving Repr, DecidableEq

def RawBossSpellBulletClear.name : RawBossSpellBulletClear -> String
  | .turnAllIntoPoints => "turn-all-into-points"
  | .removeAllWithItems => "remove-all-with-items"
  | .despawnWithItems scoreMax =>
      "despawn-with-items-" ++ toString scoreMax

inductive RawBossSpellStageState where
  | running
  | starting
  | inactive
deriving Repr, DecidableEq

def RawBossSpellStageState.name : RawBossSpellStageState -> String
  | .running => "running"
  | .starting => "starting"
  | .inactive => "inactive"

inductive RawBossLifecycleOpKind where
  | setBoss
  | beginSpellcard
  | endSpellcard
  | setBossGauge
  | setLifeMarkerCount
  | setTimeoutSpell
  | setSurvivalSpellcard
  | setBossRunInterrupt
  | setSpellcardEffectTracking
  | setSpellcardBonusUpdatesDisabled
  | setPhaseStartingLife
deriving Repr, DecidableEq

def RawBossLifecycleOpKind.name : RawBossLifecycleOpKind -> String
  | .setBoss => "set-boss"
  | .beginSpellcard => "begin-spellcard"
  | .endSpellcard => "end-spellcard"
  | .setBossGauge => "set-boss-gauge"
  | .setLifeMarkerCount => "set-life-marker-count"
  | .setTimeoutSpell => "set-timeout-spell"
  | .setSurvivalSpellcard => "set-survival-spellcard"
  | .setBossRunInterrupt => "set-boss-run-interrupt"
  | .setSpellcardEffectTracking => "set-spellcard-effect-tracking"
  | .setSpellcardBonusUpdatesDisabled =>
      "set-spellcard-bonus-updates-disabled"
  | .setPhaseStartingLife => "set-phase-starting-life"

structure RawBossLifecycleOpShape where
  opcode : Int
  kind : RawBossLifecycleOpKind
  intInputs : List RawBossLifecycleIntInputShape := []
  floatInputs : List RawBossLifecycleFloatInputShape := []
  bossSlotCount : Nat := 8
  guiBossSlotCount : Nat := 4
  bossGaugeSlotCount : Nat := 8
  bossSlotStoragePolicy : RawBossSlotStoragePolicy := .i32
  setBossPresentPolicy : RawBossPresentSetPolicy := .everyNonnegativeSlot
  clearBossPresentPolicy : RawBossPresentClearPolicy := .always
  setHealthBarToFull : Bool := false
  resetMinimumPlayerDistance : Bool := false
  markerInterruptOnSet : Option Int := none
  markerInterruptOnClear : Option Int := none
  resetEffectArrayOnClear : Bool := false
  releaseAttachedEffectsOnClear : Bool := false
  moveMarkerOffscreenOnClear : Bool := false
  spellTextPolicy : Option RawBossSpellTextPolicy := none
  beginBulletClear : Option RawBossSpellBulletClear := none
  beginStageState : Option RawBossSpellStageState := none
  beginSetsLegacySpellInfo : Bool := false
  beginResetsStageSpellTimer : Bool := false
  beginResetsBulletRank : Bool := false
  beginSetsScoreDrainRate : Bool := false
  beginRunsSpellcardBackgroundVms : Bool := false
  beginHostStartSpell : Bool := false
  endRequiresActiveSpell : Bool := false
  endStageState : Option RawBossSpellStageState := none
  endBulletClear : Option RawBossSpellBulletClear := none
  endRemovesEnemies : Bool := false
  endDeactivatesLegacySpellInfo : Bool := false
  endPlaysSound : Bool := false
  endHostEndSpell : Bool := false
  lifeMarkerTimeBonus : Int := 0
  lifeMarkerHistoryBonusDelta : Option Int := none
  timeoutScoreLimit : Option Int := none
  effectTrackingStoresVectorWhenZero : Bool := false
deriving Repr, DecidableEq

/-!
Shared profile for the ECL boundary where VM operands become sound, particle,
and effect-manager requests.  The profile deliberately keeps host array and
pointer hazards visible instead of replacing the original behavior with safe
containers.
-/

inductive RawHostEffectIntInputPolicy where
  | rawI32
  | intRValue
  | intPointerValue
deriving Repr, DecidableEq

def RawHostEffectIntInputPolicy.name :
    RawHostEffectIntInputPolicy -> String
  | .rawI32 => "raw-i32"
  | .intRValue => "int-rvalue"
  | .intPointerValue => "int-pointer-value"

inductive RawHostEffectFloatInputPolicy where
  | rawBits
  | floatRValue
deriving Repr, DecidableEq

def RawHostEffectFloatInputPolicy.name :
    RawHostEffectFloatInputPolicy -> String
  | .rawBits => "raw-bits"
  | .floatRValue => "float-rvalue"

inductive RawHostEffectIntRole where
  | effectId
  | count
  | color
  | soundId
  | customPositionFlag
  | extra (index : Nat)
deriving Repr, DecidableEq

def RawHostEffectIntRole.name : RawHostEffectIntRole -> String
  | .effectId => "effect-id"
  | .count => "count"
  | .color => "color"
  | .soundId => "sound-id"
  | .customPositionFlag => "custom-position-flag"
  | .extra index => "extra-int-" ++ toString index

inductive RawHostEffectFloatRole where
  | vectorX
  | vectorY
  | vectorZ
  | distance
  | colorR
  | colorG
  | colorB
  | colorA
  | extra (index : Nat)
deriving Repr, DecidableEq

def RawHostEffectFloatRole.name : RawHostEffectFloatRole -> String
  | .vectorX => "vector-x"
  | .vectorY => "vector-y"
  | .vectorZ => "vector-z"
  | .distance => "distance"
  | .colorR => "color-r"
  | .colorG => "color-g"
  | .colorB => "color-b"
  | .colorA => "color-a"
  | .extra index => "extra-float-" ++ toString index

structure RawHostEffectIntInputShape where
  role : RawHostEffectIntRole
  operandIndex : Nat
  policy : RawHostEffectIntInputPolicy
deriving Repr, DecidableEq

structure RawHostEffectFloatInputShape where
  role : RawHostEffectFloatRole
  operandIndex : Nat
  policy : RawHostEffectFloatInputPolicy
deriving Repr, DecidableEq

inductive RawHostEffectPositionSource where
  | enemyPosition
  | enemyWorldPosition
deriving Repr, DecidableEq

def RawHostEffectPositionSource.name :
    RawHostEffectPositionSource -> String
  | .enemyPosition => "enemy-position"
  | .enemyWorldPosition => "enemy-world-position"

inductive RawHostEffectOpKind where
  | setBulletExtras
  | spawnTrackedEffect
  | playSound
  | spawnParticles (moving : Bool)
  | setGlobalColorMultiplier
  | setSpecialEffectPosition
  | spawnAlignmentEffect
deriving Repr, DecidableEq

def RawHostEffectOpKind.name : RawHostEffectOpKind -> String
  | .setBulletExtras => "set-bullet-extras"
  | .spawnTrackedEffect => "spawn-tracked-effect"
  | .playSound => "play-sound"
  | .spawnParticles false => "spawn-particles"
  | .spawnParticles true => "spawn-moving-particles"
  | .setGlobalColorMultiplier => "set-global-color-multiplier"
  | .setSpecialEffectPosition => "set-special-effect-position"
  | .spawnAlignmentEffect => "spawn-alignment-effect"

structure RawHostEffectOpShape where
  opcode : Int
  kind : RawHostEffectOpKind
  intInputs : List RawHostEffectIntInputShape := []
  floatInputs : List RawHostEffectFloatInputShape := []
  positionSource : RawHostEffectPositionSource := .enemyPosition
  trackedSlotCount : Nat := 0
  colorTableCount : Option Nat := none
  fixedEffectId : Option Int := none
  fixedCount : Option Int := none
  fixedColor : Option Int := none
  effectIdBase : Int := 0
  positionedSound : Bool := false
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
  numericSpecialOps : List RawNumericSpecialOpShape := []
  interpolationOps : List RawInterpolationOpShape := []
  randomOps : List RawRandomOpShape := []
  movementOps : List RawMovementOpShape := []
  randomDirectionOps : List RawRandomDirectionOpShape := []
  timedMovementFamilies : List RawTimedMovementFamilyShape := []
  orbitMovementOps : List RawOrbitMovementOpShape := []
  enemyStateOps : List RawEnemyStateOpShape := []
  enemyLifecycleOps : List RawEnemyLifecycleOpShape := []
  itemOps : List RawItemOpShape := []
  bossLifecycleOps : List RawBossLifecycleOpShape := []
  hostEffectOps : List RawHostEffectOpShape := []
  shootingOps : List RawShootingOpShape := []
  timeControlOps : List RawTimeControlOpShape := []
  bulletControlOps : List RawBulletControlOpShape := []
  bulletTransformOps : List RawBulletTransformOpShape := []
  laserSpawnOps : List RawLaserSpawnOpShape := []
  laserOps : List RawLaserOpShape := []
  animationOps : List RawAnimationOpShape := []
  bulletPatternFamilies : List RawBulletPatternFamilyShape := []
  callbackConfigOps : List RawCallbackConfigOpShape := []
  interruptOps : List RawInterruptOpShape := []
  extensionOps : List RawExtensionOpShape := []
  childContextOps : List RawChildContextOpShape := []
  miscOps : List RawMiscOpShape := []
  bossDispatchOps : List RawBossDispatchOpShape := []
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

def RawInstrShape.findNumericSpecialOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawNumericSpecialOpShape :=
  rawShape.numericSpecialOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findInterpolationOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawInterpolationOpShape :=
  rawShape.interpolationOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findRandomOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawRandomOpShape :=
  rawShape.randomOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findMovementOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawMovementOpShape :=
  rawShape.movementOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findRandomDirectionOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawRandomDirectionOpShape :=
  rawShape.randomDirectionOps.find? (fun op => op.opcode == opcode)

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

def RawInstrShape.findEnemyLifecycleOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawEnemyLifecycleOpShape :=
  rawShape.enemyLifecycleOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findItemOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawItemOpShape :=
  rawShape.itemOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findBossLifecycleOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBossLifecycleOpShape :=
  rawShape.bossLifecycleOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findHostEffectOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawHostEffectOpShape :=
  rawShape.hostEffectOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findShootingOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawShootingOpShape :=
  rawShape.shootingOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findTimeControlOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawTimeControlOpShape :=
  rawShape.timeControlOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findBulletControlOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBulletControlOpShape :=
  rawShape.bulletControlOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findBulletTransformOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBulletTransformOpShape :=
  rawShape.bulletTransformOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findLaserSpawnOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawLaserSpawnOpShape :=
  rawShape.laserSpawnOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findLaserOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawLaserOpShape :=
  rawShape.laserOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findAnimationOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawAnimationOpShape :=
  rawShape.animationOps.find? (fun op => op.opcode == opcode)

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

def RawInstrShape.findExtensionOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawExtensionOpShape :=
  rawShape.extensionOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findChildContextOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawChildContextOpShape :=
  rawShape.childContextOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findMiscOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawMiscOpShape :=
  rawShape.miscOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findBossDispatchOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBossDispatchOpShape :=
  rawShape.bossDispatchOps.find? (fun op => op.opcode == opcode)

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
