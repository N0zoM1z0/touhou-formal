import TouhouFormal.ECL.TimedMovement

namespace TouhouFormal.ECL

structure RawOrbitMovementOperandSlot where
  rawValue : Int
  hostValues : List Int := [0]
deriving Repr, DecidableEq

structure RawOrbitMovementOperands where
  slots : List RawOrbitMovementOperandSlot := []
  positionBefore : RawVec3Bits := { x := 0, y := 0, z := 0 }
deriving Repr, DecidableEq

inductive RawOrbitMovementResolution where
  | rawI32 (value : Int)
  | rawFloatBits (value : Int)
  | intRValue (value : RawIntOperandResolution)
  | floatRValue (value : RawFloatOperandResolution)
deriving Repr, DecidableEq

def RawOrbitMovementResolution.value : RawOrbitMovementResolution -> Int
  | .rawI32 value | .rawFloatBits value => value
  | .intRValue value => value.value
  | .floatRValue value => value.value

structure RawOrbitMovementRead where
  operandIndex : Nat
  occurrence : Nat
  resolution : RawOrbitMovementResolution
deriving Repr, DecidableEq

structure RawOrbitMovementPrepared where
  op : RawOrbitMovementOpShape
  reads : List RawOrbitMovementRead
  effect : RawMovementEffect
deriving Repr, DecidableEq

inductive RawOrbitMovementAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawOrbitMovementOutcome where
  action : RawOrbitMovementAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawMovementEffect := none
  prepared : Option RawOrbitMovementPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.orbitMovement"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedOrbitMovementShapeFault
    (shape : HeaderShape)
    (op : RawOrbitMovementOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.orbitMovement"
    detail := "orbit movement " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingOrbitMovementOperandFault
    (shape : HeaderShape)
    (op : RawOrbitMovementOpShape)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.orbitMovement"
    detail :=
      "orbit movement " ++ op.kind.name ++
        " did not receive operand slot " ++ toString operandIndex
    index := some op.opcode }

private def rawOrbitMovementCursorOutcome
    (action : RawOrbitMovementAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawMovementEffect := none)
    (prepared : Option RawOrbitMovementPrepared := none) :
    RawOrbitMovementOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def orbitMovementHostValue
    (slot : RawOrbitMovementOperandSlot)
    (occurrence : Nat) : Int :=
  slot.hostValues[occurrence]?.getD (slot.hostValues.head?.getD 0)

private def orbitMovementSlot
    (shape : HeaderShape)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands)
    (operandIndex : Nat) : Except Fault RawOrbitMovementOperandSlot :=
  match operands.slots[operandIndex]? with
  | some slot => .ok slot
  | none => .error (missingOrbitMovementOperandFault shape op operandIndex)

private def orbitMovementFloatInput?
    (op : RawOrbitMovementOpShape)
    (role : RawOrbitMovementFloatRole) : Option RawOrbitMovementFloatInputShape :=
  op.floatInputs.find? (fun input => input.role == role)

private def expectedOrbitMovementRoles
    (op : RawOrbitMovementOpShape) : List RawOrbitMovementFloatRole :=
  match op.kind with
  | .startFull =>
      let originRoles :=
        if op.originZFromOperand then
          [.originX, .originY, .originZ]
        else
          [.originX, .originY]
      originRoles ++
        [.angle, .angularVelocity, .radius, .radialVelocity]
  | .startFromCurrentPosition =>
      [.angle, .angularVelocity, .radialVelocity]
  | .setRadius => [.radius, .radialVelocity]
  | .setAngle => [.angle, .angularVelocity]
  | .setModeTimer _ => []
  | .setVelocities => [.angularVelocity, .radialVelocity]

private def orbitMovementRequiresDuration
    (kind : RawOrbitMovementKind) : Bool :=
  match kind with
  | .startFull | .startFromCurrentPosition | .setModeTimer _ | .setVelocities => true
  | .setRadius | .setAngle => false

private def validateOrbitMovementOp
    (shape : HeaderShape)
    (op : RawOrbitMovementOpShape) : Except Fault Unit := do
  if op.floatInputs.map (fun input => input.role) != expectedOrbitMovementRoles op then
    .error
      (malformedOrbitMovementShapeFault shape op
        "float roles do not match the source handler shape")
  else if op.durationOperandIndex.isSome != orbitMovementRequiresDuration op.kind then
    .error
      (malformedOrbitMovementShapeFault shape op
        "duration operand does not match the source handler shape")
  else
    .ok ()

private def resolveOrbitMovementFloat
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands)
    (role : RawOrbitMovementFloatRole)
    (occurrence : Nat := 0) : Except Fault RawOrbitMovementRead := do
  let input <-
    match orbitMovementFloatInput? op role with
    | some input => .ok input
    | none =>
        .error
          (malformedOrbitMovementShapeFault shape op
            ("missing float role " ++ role.name))
  let slot <- orbitMovementSlot shape op operands input.operandIndex
  let resolution <-
    match input.policy with
    | .rawBits => .ok (.rawFloatBits slot.rawValue)
    | .rValue => do
        let value <-
          resolveFloatRValue shape rawPrefix input.operandIndex slot.rawValue
            (orbitMovementHostValue slot occurrence)
        .ok (.floatRValue value)
  .ok
    { operandIndex := input.operandIndex
      occurrence := occurrence
      resolution := resolution }

private def resolveOrbitMovementDuration
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands) : Except Fault RawOrbitMovementRead := do
  let operandIndex <-
    match op.durationOperandIndex with
    | some operandIndex => .ok operandIndex
    | none =>
        .error
          (malformedOrbitMovementShapeFault shape op
            "missing duration operand")
  let slot <- orbitMovementSlot shape op operands operandIndex
  let resolution <-
    match op.durationPolicy with
    | .rawI32 => .ok (.rawI32 slot.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix operandIndex slot.rawValue
            (orbitMovementHostValue slot 0)
        .ok (.intRValue value)
  .ok
    { operandIndex := operandIndex
      occurrence := 0
      resolution := resolution }

private def orbitMovementTimerState (value : Int) : RawMovementTimerWrite :=
  { current := value, subFrameBits := 0, previous := -999 }

private def orbitTimerEffect
    (duration : Int)
    (mode : RawMovementMode) : RawMovementEffect :=
  { modeWrite := some mode
    movementDurationWrite := some duration
    movementTimerWrite := some duration
    movementTimerStateWrite := some (orbitMovementTimerState duration) }

private def prepareOrbitStartFull
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands) :
    Except Fault RawOrbitMovementPrepared := do
  let durationRead <- resolveOrbitMovementDuration shape rawPrefix op operands
  let originX <- resolveOrbitMovementFloat shape rawPrefix op operands .originX
  let originY <- resolveOrbitMovementFloat shape rawPrefix op operands .originY
  let (originReads, fullOrigin, partialOrigin) <-
    if op.originZFromOperand then do
      let originZ <- resolveOrbitMovementFloat shape rawPrefix op operands .originZ
      .ok
        ([originX, originY, originZ],
          some
            { x := originX.resolution.value
              y := originY.resolution.value
              z := originZ.resolution.value },
          none)
    else
      .ok
        ([originX, originY], none,
          some { x := originX.resolution.value, y := originY.resolution.value })
  let angle <- resolveOrbitMovementFloat shape rawPrefix op operands .angle
  let angular <-
    resolveOrbitMovementFloat shape rawPrefix op operands .angularVelocity
  let radius <- resolveOrbitMovementFloat shape rawPrefix op operands .radius
  let radial <-
    resolveOrbitMovementFloat shape rawPrefix op operands .radialVelocity
  let timerEffect := orbitTimerEffect durationRead.resolution.value .orbit
  let effect : RawMovementEffect :=
    { timerEffect with
      interpolationOriginWrite := fullOrigin
      interpolationOriginXYWrite := partialOrigin
      orbitAngleWrite := some angle.resolution.value
      orbitAngularVelocityWrite := some angular.resolution.value
      orbitRadiusWrite := some radius.resolution.value
      radialVelocityWrite := some radial.resolution.value }
  .ok
    { op := op
      reads :=
        [durationRead] ++ originReads ++ [angle, angular, radius, radial]
      effect := effect }

private def prepareOrbitStartFromPosition
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands) :
    Except Fault RawOrbitMovementPrepared := do
  let durationRead <- resolveOrbitMovementDuration shape rawPrefix op operands
  let angle <- resolveOrbitMovementFloat shape rawPrefix op operands .angle
  let angular <-
    resolveOrbitMovementFloat shape rawPrefix op operands .angularVelocity
  let radial <-
    resolveOrbitMovementFloat shape rawPrefix op operands .radialVelocity
  let timerEffect := orbitTimerEffect durationRead.resolution.value .orbit
  let effect : RawMovementEffect :=
    { timerEffect with
      interpolationOriginWrite := some operands.positionBefore
      orbitAngleWrite := some angle.resolution.value
      orbitAngularVelocityWrite := some angular.resolution.value
      orbitRadiusWrite := some 0
      radialVelocityWrite := some radial.resolution.value }
  .ok
    { op := op
      reads := [durationRead, angle, angular, radial]
      effect := effect }

private def prepareOrbitScalarPair
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands)
    (firstRole secondRole : RawOrbitMovementFloatRole)
    (effectOf : Int -> Int -> RawMovementEffect) :
    Except Fault RawOrbitMovementPrepared := do
  let first <- resolveOrbitMovementFloat shape rawPrefix op operands firstRole
  let second <- resolveOrbitMovementFloat shape rawPrefix op operands secondRole
  .ok
    { op := op
      reads := [first, second]
      effect := effectOf first.resolution.value second.resolution.value }

private def prepareOrbitVelocities
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands) :
    Except Fault RawOrbitMovementPrepared := do
  let durationRead <- resolveOrbitMovementDuration shape rawPrefix op operands
  let angular <-
    resolveOrbitMovementFloat shape rawPrefix op operands .angularVelocity
  let radial <-
    resolveOrbitMovementFloat shape rawPrefix op operands .radialVelocity
  let timerEffect := orbitTimerEffect durationRead.resolution.value .orbit
  let effect : RawMovementEffect :=
    { timerEffect with
      orbitAngularVelocityWrite := some angular.resolution.value
      radialVelocityWrite := some radial.resolution.value }
  .ok
    { op := op
      reads := [durationRead, angular, radial]
      effect := effect }

def rawOrbitMovementPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawOrbitMovementOpShape)
    (operands : RawOrbitMovementOperands) :
    Except Fault RawOrbitMovementPrepared := do
  validateOrbitMovementOp shape op
  match op.kind with
  | .startFull => prepareOrbitStartFull shape rawPrefix op operands
  | .startFromCurrentPosition =>
      prepareOrbitStartFromPosition shape rawPrefix op operands
  | .setRadius =>
      prepareOrbitScalarPair shape rawPrefix op operands .radius .radialVelocity
        (fun radius radial =>
          { orbitRadiusWrite := some radius
            radialVelocityWrite := some radial })
  | .setAngle =>
      prepareOrbitScalarPair shape rawPrefix op operands .angle .angularVelocity
        (fun angle angular =>
          { orbitAngleWrite := some angle
            orbitAngularVelocityWrite := some angular })
  | .setModeTimer mode => do
      let durationRead <- resolveOrbitMovementDuration shape rawPrefix op operands
      .ok
        { op := op
          reads := [durationRead]
          effect := orbitTimerEffect durationRead.resolution.value mode }
  | .setVelocities => prepareOrbitVelocities shape rawPrefix op operands

def rawOrbitMovementStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawOrbitMovementOperands) :
    Except Fault RawOrbitMovementOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawOrbitMovementCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findOrbitMovementOp? rawPrefix.opcode with
          | none =>
              .ok (rawOrbitMovementCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawOrbitMovementPrepare shape rawPrefix op operands
              .ok
                (rawOrbitMovementCursorOutcome
                  .advanced rawPrefix bufferSize
                  (some prepared.effect) (some prepared))

end TouhouFormal.ECL
