import TouhouFormal.Core.Float32
import TouhouFormal.ECL.Movement

namespace TouhouFormal.ECL

structure RawTimedMovementOperandSlot where
  rawValue : Int
  /-- One value per source read; a singleton models stable host state. -/
  hostValues : List Int := [0]
deriving Repr, DecidableEq

structure RawTimedMovementFloatResults where
  /-- Angle after any source-side normalization, but before trig calls. -/
  effectiveDirectionAngleBits : Int
  /-- Player-relative angle used only by an immediate player-directed branch. -/
  playerRelativeAngleBits : Int
  /-- Result of source binary32 subtraction/trig/multiplication. -/
  interpolationDelta : RawVec3Bits
deriving Repr, DecidableEq

structure RawTimedMovementRuntime where
  positionBefore : RawVec3Bits := { x := 0, y := 0, z := 0 }
  worldPositionBefore : RawVec3Bits := { x := 0, y := 0, z := 0 }
  currentAngle : RawTimedMovementOperandSlot := { rawValue := 0 }
  currentSpeedBits : Int := 0
  mirrorX : Bool := false
deriving Repr, DecidableEq

structure RawTimedMovementOperands where
  slots : List RawTimedMovementOperandSlot := []
  floatResults : RawTimedMovementFloatResults
  runtime : RawTimedMovementRuntime := {}
deriving Repr, DecidableEq

inductive RawTimedMovementReadSource where
  | operand (operandIndex : Nat)
  | currentAngle
  | currentSpeed
deriving Repr, DecidableEq

inductive RawTimedMovementResolution where
  | rawI32 (value : Int)
  | rawFloatBits (value : Int)
  | intRValue (value : RawIntOperandResolution)
  | floatRValue (value : RawFloatOperandResolution)
  | currentSpeedBits (value : Int)
deriving Repr, DecidableEq

def RawTimedMovementResolution.value : RawTimedMovementResolution -> Int
  | .rawI32 value | .rawFloatBits value | .currentSpeedBits value => value
  | .intRValue value => value.value
  | .floatRValue value => value.value

structure RawTimedMovementRead where
  source : RawTimedMovementReadSource
  occurrence : Nat
  resolution : RawTimedMovementResolution
deriving Repr, DecidableEq

inductive RawTimedMovementBranch where
  | interpolated
  | immediatePolar
deriving Repr, DecidableEq

structure RawTimedMovementPrepared where
  familyMatch : RawTimedMovementFamilyMatch
  branch : RawTimedMovementBranch
  reads : List RawTimedMovementRead
  effectiveAngleBits : Option Int := none
  effect : RawMovementEffect
deriving Repr, DecidableEq

inductive RawTimedMovementAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawTimedMovementOutcome where
  action : RawTimedMovementAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawMovementEffect := none
  prepared : Option RawTimedMovementPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.timedMovement"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedTimedMovementShapeFault
    (shape : HeaderShape)
    (family : RawTimedMovementFamilyShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.timedMovement"
    detail := "timed movement " ++ family.kind.name ++ ": " ++ detail
    index := some family.firstOpcode }

private def missingTimedMovementOperandFault
    (shape : HeaderShape)
    (family : RawTimedMovementFamilyShape)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.timedMovement"
    detail :=
      "timed movement " ++ family.kind.name ++
        " did not receive operand slot " ++ toString operandIndex
    index := some family.firstOpcode }

private def rawTimedMovementCursorOutcome
    (action : RawTimedMovementAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawMovementEffect := none)
    (prepared : Option RawTimedMovementPrepared := none) :
    RawTimedMovementOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def timedMovementHostValue
    (slot : RawTimedMovementOperandSlot)
    (occurrence : Nat) : Int :=
  slot.hostValues[occurrence]?.getD (slot.hostValues.head?.getD 0)

private def timedMovementSlot
    (shape : HeaderShape)
    (family : RawTimedMovementFamilyShape)
    (operands : RawTimedMovementOperands)
    (operandIndex : Nat) : Except Fault RawTimedMovementOperandSlot :=
  match operands.slots[operandIndex]? with
  | some slot => .ok slot
  | none => .error (missingTimedMovementOperandFault shape family operandIndex)

private def expectedTimedMovementRoles
    (family : RawTimedMovementFamilyShape) : List RawTimedMovementFloatRole :=
  match family.kind with
  | .direction | .playerDirection => [.angle, .speed]
  | .hostDirection => [.speed]
  | .position =>
      if family.zeroTargetZ then
        [.targetX, .targetY]
      else
        [.targetX, .targetY, .targetZ]
  | .currentDirection => []

private def validateTimedMovementFamily
    (shape : HeaderShape)
    (family : RawTimedMovementFamilyShape) : Except Fault Unit := do
  if family.lastOpcode < family.firstOpcode then
    .error
      (malformedTimedMovementShapeFault shape family
        "last opcode precedes first opcode")
  else if family.floatInputs.map (fun input => input.role) !=
      expectedTimedMovementRoles family then
    .error
      (malformedTimedMovementShapeFault shape family
        "float roles do not match the source handler shape")
  else
    match family.easingPolicy with
    | .opcodeOffset _ => .ok ()
    | .intRValue _ =>
        if family.firstOpcode != family.lastOpcode then
          .error
            (malformedTimedMovementShapeFault shape family
              "operand-driven easing must use a singleton opcode family")
        else
          .ok ()

private def timedMovementFloatInput?
    (family : RawTimedMovementFamilyShape)
    (role : RawTimedMovementFloatRole) : Option RawTimedMovementFloatInputShape :=
  family.floatInputs.find? (fun input => input.role == role)

private def resolveTimedMovementDuration
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (family : RawTimedMovementFamilyShape)
    (operands : RawTimedMovementOperands)
    (occurrence : Nat) : Except Fault RawTimedMovementRead := do
  let operandIndex := family.durationOperandIndex
  let slot <- timedMovementSlot shape family operands operandIndex
  let resolution <-
    match family.durationPolicy with
    | .rawI32 => .ok (.rawI32 slot.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix operandIndex slot.rawValue
            (timedMovementHostValue slot occurrence)
        .ok (.intRValue value)
  .ok
    { source := .operand operandIndex
      occurrence := occurrence
      resolution := resolution }

private def resolveTimedMovementFloat
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (family : RawTimedMovementFamilyShape)
    (operands : RawTimedMovementOperands)
    (role : RawTimedMovementFloatRole)
    (occurrence : Nat) : Except Fault RawTimedMovementRead := do
  let input <-
    match timedMovementFloatInput? family role with
    | some input => .ok input
    | none =>
        .error
          (malformedTimedMovementShapeFault shape family
            ("missing float role " ++ role.name))
  let slot <- timedMovementSlot shape family operands input.operandIndex
  let resolution <-
    match input.policy with
    | .rawBits => .ok (.rawFloatBits slot.rawValue)
    | .rValue => do
        let value <-
          resolveFloatRValue shape rawPrefix input.operandIndex slot.rawValue
            (timedMovementHostValue slot occurrence)
        .ok (.floatRValue value)
  .ok
    { source := .operand input.operandIndex
      occurrence := occurrence
      resolution := resolution }

private def resolveTimedMovementCurrentAngle
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (operands : RawTimedMovementOperands) :
    Except Fault RawTimedMovementRead := do
  let slot := operands.runtime.currentAngle
  let value <-
    resolveFloatRValue shape rawPrefix 0 slot.rawValue
      (timedMovementHostValue slot 0)
  .ok
    { source := .currentAngle
      occurrence := 0
      resolution := .floatRValue value }

private def timedMovementCurrentSpeedRead
    (operands : RawTimedMovementOperands)
    (occurrence : Nat) : RawTimedMovementRead :=
  { source := .currentSpeed
    occurrence := occurrence
    resolution := .currentSpeedBits operands.runtime.currentSpeedBits }

private def resolveTimedMovementEasing
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (familyMatch : RawTimedMovementFamilyMatch)
    (operands : RawTimedMovementOperands) :
    Except Fault (Int × List RawTimedMovementRead) :=
  match familyMatch.family.easingPolicy with
  | .opcodeOffset _ =>
      match familyMatch.easingFromOpcode with
      | some value => .ok (TouhouFormal.truncateUnsignedBits value 3, [])
      | none =>
          .error
            (malformedTimedMovementShapeFault shape familyMatch.family
              "opcode-derived easing is unavailable")
  | .intRValue operandIndex => do
      let slot <- timedMovementSlot shape familyMatch.family operands operandIndex
      let value <-
        resolveIntRValue shape rawPrefix operandIndex slot.rawValue
          (timedMovementHostValue slot 0)
      let read : RawTimedMovementRead :=
        { source := .operand operandIndex
          occurrence := 0
          resolution := .intRValue value }
      .ok (TouhouFormal.truncateUnsignedBits value.value 3, [read])

private def timedMovementOrigin
    (family : RawTimedMovementFamilyShape)
    (operands : RawTimedMovementOperands) : RawVec3Bits :=
  match family.originSource with
  | .position => operands.runtime.positionBefore
  | .worldPosition => operands.runtime.worldPositionBefore

private def timedMovementDelta
    (family : RawTimedMovementFamilyShape)
    (operands : RawTimedMovementOperands) : RawVec3Bits :=
  let raw := operands.floatResults.interpolationDelta
  let withSourceZ :=
    if family.kind != .position && family.zeroDirectionDeltaZ then
      { raw with z := 0 }
    else
      raw
  if family.mirrorDeltaX && operands.runtime.mirrorX then
    { withSourceZ with x := TouhouFormal.f32NegBits withSourceZ.x }
  else
    withSourceZ

private def timedMovementTimerState (value : Int) : RawMovementTimerWrite :=
  { current := value, subFrameBits := 0, previous := -999 }

private def prepareTimedMovementPosition
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (familyMatch : RawTimedMovementFamilyMatch)
    (operands : RawTimedMovementOperands) :
    Except Fault RawTimedMovementPrepared := do
  let family := familyMatch.family
  let xRead <- resolveTimedMovementFloat shape rawPrefix family operands .targetX 0
  let yRead <- resolveTimedMovementFloat shape rawPrefix family operands .targetY 0
  let targetReads <-
    if family.zeroTargetZ then
      .ok [xRead, yRead]
    else do
      let zRead <- resolveTimedMovementFloat shape rawPrefix family operands .targetZ 0
      .ok [xRead, yRead, zRead]
  let durationRead <-
    resolveTimedMovementDuration shape rawPrefix family operands 0
  let (easing, easingReads) <-
    resolveTimedMovementEasing shape rawPrefix familyMatch operands
  let zeroVelocity : Option RawVec3Bits :=
    if family.zeroVelocity then some { x := 0, y := 0, z := 0 } else none
  let effect : RawMovementEffect :=
    { velocityWrite := zeroVelocity
      interpolationDeltaWrite := some (timedMovementDelta family operands)
      interpolationOriginWrite := some (timedMovementOrigin family operands)
      easingWrite := some easing
      modeWrite := some .interpolation
      movementDurationWrite := some durationRead.resolution.value
      movementTimerWrite := some durationRead.resolution.value
      movementTimerStateWrite :=
        some (timedMovementTimerState durationRead.resolution.value) }
  .ok
    { familyMatch := familyMatch
      branch := .interpolated
      reads := targetReads ++ [durationRead] ++ easingReads
      effect := effect }

private def prepareTimedMovementInterpolatedDirection
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (familyMatch : RawTimedMovementFamilyMatch)
    (operands : RawTimedMovementOperands)
    (durationOccurrence : Nat) :
    Except Fault RawTimedMovementPrepared := do
  let family := familyMatch.family
  let angleReads <-
    match family.kind with
    | .currentDirection =>
        let read <- resolveTimedMovementCurrentAngle shape rawPrefix operands
        .ok [read]
    | .direction | .playerDirection =>
        let read <-
          resolveTimedMovementFloat shape rawPrefix family operands .angle 0
        .ok [read]
    | .hostDirection => .ok []
    | .position =>
        .error
          (malformedTimedMovementShapeFault shape family
            "position handler entered direction preparation")
  let speedRead0 <-
    match family.kind with
    | .currentDirection => .ok (timedMovementCurrentSpeedRead operands 0)
    | .direction | .hostDirection | .playerDirection =>
        resolveTimedMovementFloat shape rawPrefix family operands .speed 0
    | .position =>
        .error
          (malformedTimedMovementShapeFault shape family
            "position handler entered direction preparation")
  let durationRead0 <-
    resolveTimedMovementDuration shape rawPrefix family operands durationOccurrence
  let speedRead1 <-
    match family.kind with
    | .currentDirection => .ok (timedMovementCurrentSpeedRead operands 1)
    | .direction | .hostDirection | .playerDirection =>
        resolveTimedMovementFloat shape rawPrefix family operands .speed 1
    | .position =>
        .error
          (malformedTimedMovementShapeFault shape family
            "position handler entered direction preparation")
  let durationRead1 <-
    resolveTimedMovementDuration shape rawPrefix family operands (durationOccurrence + 1)
  let durationWriteRead <-
    resolveTimedMovementDuration shape rawPrefix family operands (durationOccurrence + 2)
  let (easing, easingReads) <-
    resolveTimedMovementEasing shape rawPrefix familyMatch operands
  let effectiveAngle := operands.floatResults.effectiveDirectionAngleBits
  let effect : RawMovementEffect :=
    { interpolationDeltaWrite := some (timedMovementDelta family operands)
      interpolationOriginWrite := some (timedMovementOrigin family operands)
      easingWrite := some easing
      modeWrite := some .interpolation
      movementDurationWrite := some durationWriteRead.resolution.value
      movementTimerWrite := some durationWriteRead.resolution.value
      movementTimerStateWrite :=
        some (timedMovementTimerState durationWriteRead.resolution.value) }
  .ok
    { familyMatch := familyMatch
      branch := .interpolated
      reads := angleReads ++
        [speedRead0, durationRead0, speedRead1,
          durationRead1, durationWriteRead] ++ easingReads
      effectiveAngleBits := some effectiveAngle
      effect := effect }

private def prepareTimedMovementImmediate
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (familyMatch : RawTimedMovementFamilyMatch)
    (operands : RawTimedMovementOperands)
    (testRead : RawTimedMovementRead) :
    Except Fault RawTimedMovementPrepared := do
  let family := familyMatch.family
  let angleReads <-
    match family.kind with
    | .hostDirection => .ok []
    | .direction | .playerDirection =>
        let read <-
          resolveTimedMovementFloat shape rawPrefix family operands .angle 0
        .ok [read]
    | .currentDirection | .position =>
        .error
          (malformedTimedMovementShapeFault shape family
            "handler without an angle operand entered immediate preparation")
  let speedRead <-
    resolveTimedMovementFloat shape rawPrefix family operands .speed 0
  let (timerValue, timerReads) <-
    match family.nonpositivePolicy with
    | .immediatePolarZeroTimers => .ok (0, [])
    | .immediatePolarResolvedTimers => do
        let durationRead <-
          resolveTimedMovementDuration shape rawPrefix family operands 1
        .ok (durationRead.resolution.value, [durationRead])
    | .alwaysInterpolate =>
        .error
          (malformedTimedMovementShapeFault shape family
            "always-interpolate family entered immediate preparation")
  let angleBits :=
    match family.kind with
    | .playerDirection => operands.floatResults.playerRelativeAngleBits
    | _ => operands.floatResults.effectiveDirectionAngleBits
  let effect : RawMovementEffect :=
    { angleWrite := some angleBits
      speedWrite := some speedRead.resolution.value
      modeWrite := some .polar
      movementDurationWrite := some timerValue
      movementTimerWrite := some timerValue
      movementTimerStateWrite := some (timedMovementTimerState timerValue) }
  .ok
    { familyMatch := familyMatch
      branch := .immediatePolar
      reads := [testRead] ++ angleReads ++ [speedRead] ++ timerReads
      effectiveAngleBits := some angleBits
      effect := effect }

def rawTimedMovementPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (familyMatch : RawTimedMovementFamilyMatch)
    (operands : RawTimedMovementOperands) :
    Except Fault RawTimedMovementPrepared := do
  let family := familyMatch.family
  validateTimedMovementFamily shape family
  match family.kind with
  | .position =>
      prepareTimedMovementPosition shape rawPrefix familyMatch operands
  | .direction | .hostDirection | .currentDirection | .playerDirection =>
      match family.nonpositivePolicy with
      | .alwaysInterpolate =>
          prepareTimedMovementInterpolatedDirection
            shape rawPrefix familyMatch operands 0
      | .immediatePolarZeroTimers | .immediatePolarResolvedTimers => do
          let testRead <-
            resolveTimedMovementDuration shape rawPrefix family operands 0
          if testRead.resolution.value <= 0 then
            prepareTimedMovementImmediate
              shape rawPrefix familyMatch operands testRead
          else
            let prepared <-
              prepareTimedMovementInterpolatedDirection
                shape rawPrefix familyMatch operands 1
            .ok { prepared with reads := testRead :: prepared.reads }

def rawTimedMovementStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawTimedMovementOperands) :
    Except Fault RawTimedMovementOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawTimedMovementCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findTimedMovementFamily? rawPrefix.opcode with
          | none =>
              .ok (rawTimedMovementCursorOutcome .advanced rawPrefix bufferSize)
          | some familyMatch => do
              let prepared <-
                rawTimedMovementPrepare shape rawPrefix familyMatch operands
              .ok
                (rawTimedMovementCursorOutcome
                  .advanced rawPrefix bufferSize
                  (some prepared.effect) (some prepared))

end TouhouFormal.ECL
