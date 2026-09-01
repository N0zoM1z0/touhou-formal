import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawVec3Bits where
  x : Int
  y : Int
  z : Int
deriving Repr, DecidableEq

structure RawVec2Bits where
  x : Int
  y : Int
deriving Repr, DecidableEq

structure RawMovementBoundsBits where
  lowerX : Int
  lowerY : Int
  upperX : Int
  upperY : Int
deriving Repr, DecidableEq

structure RawMovementFloatInput where
  rawValue : Int
  hostValue : Int
deriving Repr, DecidableEq

structure RawMovementTimerWrite where
  current : Int
  subFrameBits : Int
  previous : Int
deriving Repr, DecidableEq

structure RawMovementOperands where
  floatInputs : List RawMovementFloatInput
  derivedAngleBits : Int := 0
deriving Repr, DecidableEq

inductive RawMovementFloatResolution where
  | floatRValue : RawFloatOperandResolution -> RawMovementFloatResolution
  | rawBits : Int -> RawMovementFloatResolution
deriving Repr, DecidableEq

def RawMovementFloatResolution.bits : RawMovementFloatResolution -> Int
  | .floatRValue value => value.value
  | .rawBits value => value

structure RawMovementEffect where
  positionWrite : Option RawVec3Bits := none
  velocityWrite : Option RawVec3Bits := none
  interpolationDeltaWrite : Option RawVec3Bits := none
  interpolationOriginWrite : Option RawVec3Bits := none
  interpolationOriginXYWrite : Option RawVec2Bits := none
  angleWrite : Option Int := none
  angularVelocityWrite : Option Int := none
  speedWrite : Option Int := none
  accelerationWrite : Option Int := none
  orbitAngleWrite : Option Int := none
  orbitAngularVelocityWrite : Option Int := none
  orbitRadiusWrite : Option Int := none
  radialVelocityWrite : Option Int := none
  easingWrite : Option Int := none
  boundsWrite : Option RawMovementBoundsBits := none
  boundsEnabledWrite : Option Bool := none
  modeWrite : Option RawMovementMode := none
  movementDurationWrite : Option Int := none
  movementTimerWrite : Option Int := none
  movementTimerStateWrite : Option RawMovementTimerWrite := none
  clampPosition : Bool := false
deriving Repr, DecidableEq

structure RawMovementPrepared where
  op : RawMovementOpShape
  inputResolutions : List RawMovementFloatResolution
  inputBits : List Int
  effect : RawMovementEffect
deriving Repr, DecidableEq

inductive RawMovementAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawMovementOutcome where
  action : RawMovementAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawMovementEffect := none
  prepared : Option RawMovementPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.movement"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedMovementShapeFault
    (shape : HeaderShape)
    (op : RawMovementOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.movement"
    detail := "movement opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def RawMovementOpShape.expectedFloatInputCount
    (op : RawMovementOpShape) : Nat :=
  match op.kind with
  | .setPosition => if op.zeroPositionZ then 2 else 3
  | .setAxisVelocity => 3
  | .setPolarVelocity | .moveAtPlayer => 2
  | .setAngularVelocity | .setSpeed | .setAcceleration => 1
  | .setBounds => 4
  | .disableBounds => 0

private def rawMovementCursorOutcome
    (action : RawMovementAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawMovementEffect := none)
    (prepared : Option RawMovementPrepared := none) : RawMovementOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset
        rawPrefix.nextCursor
        bufferSize)
    effect := effect
    prepared := prepared }

private def resolveMovementFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawMovementFloatInputShape)
    (input : RawMovementFloatInput) :
    Except Fault RawMovementFloatResolution :=
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

private def movementAngleWrite
    (op : RawMovementOpShape)
    (inputBits : List Int)
    (derivedAngleBits : Int) : Option Int :=
  match op.anglePolicy with
  | .unchanged => none
  | .firstInput => inputBits[0]?
  | .derivedAtan2
  | .derivedNormalizedInput
  | .derivedPlayerRelative
  | .derivedNormalizedPlayerRelative => some derivedAngleBits

private def movementEffect
    (op : RawMovementOpShape)
    (inputBits : List Int)
    (derivedAngleBits : Int) : RawMovementEffect :=
  let modeWrite := op.modeUpdate
  let durationWrite := if op.resetMovementTimers then some 0 else none
  let timerWrite := if op.resetMovementTimers then some 0 else none
  let timerStateWrite :=
    if op.resetMovementTimers then
      some { current := 0, subFrameBits := 0, previous := -999 }
    else
      none
  match op.kind with
  | .setPosition =>
      { positionWrite :=
          some
            { x := inputBits[0]!
              y := inputBits[1]!
              z := if op.zeroPositionZ then 0 else inputBits[2]! }
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite
        clampPosition := op.clampPosition }
  | .setAxisVelocity =>
      { velocityWrite :=
          some
            { x := inputBits[0]!
              y := inputBits[1]!
              z := inputBits[2]! }
        angleWrite := movementAngleWrite op inputBits derivedAngleBits
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }
  | .setPolarVelocity =>
      { angleWrite := movementAngleWrite op inputBits derivedAngleBits
        speedWrite := inputBits[1]?
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }
  | .setAngularVelocity =>
      { angularVelocityWrite := inputBits[0]?
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }
  | .setSpeed =>
      { speedWrite := inputBits[0]?
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }
  | .setAcceleration =>
      { accelerationWrite := inputBits[0]?
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }
  | .moveAtPlayer =>
      { angleWrite := movementAngleWrite op inputBits derivedAngleBits
        speedWrite := inputBits[1]?
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }
  | .setBounds =>
      { boundsWrite :=
          some
            { lowerX := inputBits[0]!
              lowerY := inputBits[1]!
              upperX := inputBits[2]!
              upperY := inputBits[3]! }
        boundsEnabledWrite := some true
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }
  | .disableBounds =>
      { boundsEnabledWrite := some false
        modeWrite := modeWrite
        movementDurationWrite := durationWrite
        movementTimerWrite := timerWrite
        movementTimerStateWrite := timerStateWrite }

def rawMovementPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawMovementOpShape)
    (operands : RawMovementOperands) : Except Fault RawMovementPrepared := do
  let expected := op.expectedFloatInputCount
  if op.floatInputs.length != expected then
    .error
      (malformedMovementShapeFault
        shape
        op
        ("profile declares " ++ toString op.floatInputs.length ++
          " float inputs, expected " ++ toString expected))
  else if operands.floatInputs.length != expected then
    .error
      (malformedMovementShapeFault
        shape
        op
        ("step supplied " ++ toString operands.floatInputs.length ++
          " float inputs, expected " ++ toString expected))
  else
    let resolutions <-
      (List.zip op.floatInputs operands.floatInputs).mapM
        (fun (inputShape, input) =>
          resolveMovementFloatInput shape rawPrefix inputShape input)
    let inputBits := resolutions.map RawMovementFloatResolution.bits
    let effect := movementEffect op inputBits operands.derivedAngleBits
    .ok
      { op := op
        inputResolutions := resolutions
        inputBits := inputBits
        effect := effect }

def rawMovementStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawMovementOperands) : Except Fault RawMovementOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawMovementCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findMovementOp? rawPrefix.opcode with
          | none => .ok (rawMovementCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawMovementPrepare shape rawPrefix op operands
              .ok
                (rawMovementCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  (some prepared))

end TouhouFormal.ECL
