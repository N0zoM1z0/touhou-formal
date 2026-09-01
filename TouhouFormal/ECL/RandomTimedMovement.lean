import TouhouFormal.ECL.RandomDirection
import TouhouFormal.ECL.TimedMovement

namespace TouhouFormal.ECL

structure RawRandomTimedMovementOperands where
  direction : RawRandomDirectionOperands
  movement : RawTimedMovementOperands
deriving Repr, DecidableEq

structure RawRandomTimedMovementPrepared where
  direction : RawRandomDirectionPrepared
  movement : RawTimedMovementPrepared
deriving Repr, DecidableEq

inductive RawRandomTimedMovementAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawRandomTimedMovementOutcome where
  action : RawRandomTimedMovementAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  directionEffect : Option RawRandomDirectionEffect := none
  movementEffect : Option RawMovementEffect := none
  prepared : Option RawRandomTimedMovementPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.randomTimedMovement"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def inconsistentRandomTimedMovementProfileFault
    (shape : HeaderShape)
    (opcode : Int)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.randomTimedMovement"
    detail := "random/timed movement profile drift: " ++ detail
    index := some opcode }

private def rawRandomTimedMovementCursorOutcome
    (action : RawRandomTimedMovementAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (directionEffect : Option RawRandomDirectionEffect := none)
    (movementEffect : Option RawMovementEffect := none)
    (prepared : Option RawRandomTimedMovementPrepared := none) :
    RawRandomTimedMovementOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    directionEffect := directionEffect
    movementEffect := movementEffect
    prepared := prepared }

def rawRandomTimedMovementPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (directionOp : RawRandomDirectionOpShape)
    (familyMatch : RawTimedMovementFamilyMatch)
    (operands : RawRandomTimedMovementOperands) :
    Except Fault RawRandomTimedMovementPrepared := do
  if directionOp.outputPolicy != .hostAngle then
    .error
      (inconsistentRandomTimedMovementProfileFault shape rawPrefix.opcode
        "the direction stage does not expose a host angle")
  else if familyMatch.family.kind != .hostDirection then
    .error
      (inconsistentRandomTimedMovementProfileFault shape rawPrefix.opcode
        "the timed stage is not a host-direction handler")
  else
    let direction <-
      rawRandomDirectionPrepare shape rawPrefix directionOp operands.direction
    let angle <-
      match direction.effect.hostAngleResult with
      | some angle => .ok angle
      | none =>
          .error
            (inconsistentRandomTimedMovementProfileFault shape rawPrefix.opcode
              "the prepared direction stage did not produce an angle")
    let movementOperands : RawTimedMovementOperands :=
      { operands.movement with
        floatResults :=
          { operands.movement.floatResults with
            effectiveDirectionAngleBits := angle } }
    let movement <-
      rawTimedMovementPrepare shape rawPrefix familyMatch movementOperands
    .ok { direction := direction, movement := movement }

def rawRandomTimedMovementStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawRandomTimedMovementOperands) :
    Except Fault RawRandomTimedMovementOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok
            (rawRandomTimedMovementCursorOutcome
              .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findRandomDirectionOp? rawPrefix.opcode with
          | none =>
              .ok
                (rawRandomTimedMovementCursorOutcome
                  .advanced rawPrefix bufferSize)
          | some directionOp =>
              match directionOp.outputPolicy with
              | .enemyAngle | .floatLValue _ =>
                  .ok
                    (rawRandomTimedMovementCursorOutcome
                      .advanced rawPrefix bufferSize)
              | .hostAngle =>
                  match rawShape.findTimedMovementFamily? rawPrefix.opcode with
                  | none =>
                      .error
                        (inconsistentRandomTimedMovementProfileFault
                          shape rawPrefix.opcode
                          "host-angle opcode has no timed movement family")
                  | some familyMatch => do
                      let prepared <-
                        rawRandomTimedMovementPrepare
                          shape rawPrefix directionOp familyMatch operands
                      .ok
                        (rawRandomTimedMovementCursorOutcome
                          .advanced rawPrefix bufferSize
                          (some prepared.direction.effect)
                          (some prepared.movement.effect)
                          (some prepared))

end TouhouFormal.ECL
