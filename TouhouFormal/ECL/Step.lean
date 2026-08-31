import TouhouFormal.Core.Cursor
import TouhouFormal.ECL.Difficulty
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

inductive RawStepAction where
  | yielded
  | skipped
  | advanced
  | jumped
  | vmError
deriving Repr, DecidableEq

structure RawStepOutcome where
  action : RawStepAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  targetTime : Option Int := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.step"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingDifficultyMaskFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.step.difficulty"
    detail := "profile defines raw difficulty-mask policy but decoded prefix has no mask" }

private def negativeDifficultyMaskFault (shape : HeaderShape) (mask : Int) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.step.difficulty"
    detail := "decoded raw difficulty mask is negative"
    index := some mask }

private def missingJumpOperandsFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.step.jump"
    detail := "profile fixed-jump opcode reached but jump operands are unavailable" }

private def cursorOutcome
    (action : RawStepAction)
    (sourceOffset : Nat)
    (targetCursor : Int)
    (bufferSize : Nat)
    (targetTime : Option Int := none) : RawStepOutcome :=
  { action := action
    targetCursor := some targetCursor
    cursorClass := some (TouhouFormal.classifyCursorTransfer sourceOffset targetCursor bufferSize)
    targetTime := targetTime }

private def rawDifficultyPass
    (shape : HeaderShape)
    (rawShape : RawInstrShape)
    (rawPrefix : RawInstrPrefix)
    (activeMask overrideMask maxBits : Nat) : Except Fault Bool :=
  match rawShape.difficultyMaskPolicy with
  | none => .ok true
  | some policy =>
      match rawPrefix.difficultyMask with
      | none => .error (missingDifficultyMaskFault shape)
      | some mask =>
          if mask < 0 then
            .error (negativeDifficultyMaskFault shape mask)
          else
            .ok (policy.shouldExecute mask.toNat activeMask overrideMask maxBits)

def rawStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (jump : Option RawJumpOperands := none) : Except Fault RawStepOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <- rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok
            (cursorOutcome
              .skipped
              rawPrefix.fileOffset
              rawPrefix.nextCursor
              bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.fixedJumpShape with
          | some jumpShape =>
              if rawPrefix.opcode == jumpShape.opcode then
                match jump with
                | none => .error (missingJumpOperandsFault shape)
                | some jumpOperands =>
                    .ok
                      (cursorOutcome
                        .jumped
                        rawPrefix.fileOffset
                        (Int.ofNat rawPrefix.fileOffset + jumpOperands.displacement)
                        bufferSize
                        (some jumpOperands.targetTime))
              else
                .ok
                  (cursorOutcome
                    .advanced
                    rawPrefix.fileOffset
                    rawPrefix.nextCursor
                    bufferSize)
          | none =>
              .ok
                (cursorOutcome
                  .advanced
                  rawPrefix.fileOffset
                  rawPrefix.nextCursor
                  bufferSize)

end TouhouFormal.ECL
