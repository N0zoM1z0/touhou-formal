import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawDecJumpOperands where
  targetTime : Int
  displacement : Int
  counterBefore : Int
deriving Repr, DecidableEq

structure RawIntDivisorOperands where
  divisor : Int
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.body"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingDecJumpShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.body.decJump"
    detail := "profile does not define source-backed JUMPDEC semantics" }

private def divideByZeroFault
    (shape : HeaderShape)
    (hazard : RawIntDivisorHazard) : Fault :=
  { kind := .divideByZero
    title := shape.title
    component := "EclRun.body.intDivisor"
    detail :=
      "source integer " ++ hazard.kind.name ++
        " opcode reads a zero divisor from operand index " ++
        toString hazard.divisorOperandIndex
    index := some hazard.opcode }

def rawDecJumpStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawDecJumpOperands) : Except Fault RawStepOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      match rawShape.fixedDecJumpShape with
      | none => .error (missingDecJumpShapeFault shape)
      | some decJumpShape =>
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
            else if rawPrefix.opcode != decJumpShape.opcode then
              .ok
                (cursorOutcome
                  .advanced
                  rawPrefix.fileOffset
                  rawPrefix.nextCursor
                  bufferSize)
            else
              let counterAfter := operands.counterBefore - 1
              if counterAfter <= 0 then
                .ok
                  (cursorOutcome
                    .advanced
                    rawPrefix.fileOffset
                    rawPrefix.nextCursor
                    bufferSize)
              else
                .ok
                  (cursorOutcome
                    .jumped
                    rawPrefix.fileOffset
                    (Int.ofNat rawPrefix.fileOffset + operands.displacement)
                    bufferSize
                    (some operands.targetTime))

def rawIntDivisorStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawIntDivisorOperands) : Except Fault RawStepOutcome :=
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
          match rawShape.findIntDivisorHazard? rawPrefix.opcode with
          | none =>
              .ok
                (cursorOutcome
                  .advanced
                  rawPrefix.fileOffset
                  rawPrefix.nextCursor
                  bufferSize)
          | some hazard =>
              if operands.divisor == 0 then
                .error (divideByZeroFault shape hazard)
              else
                .ok
                  (cursorOutcome
                    .advanced
                    rawPrefix.fileOffset
                    rawPrefix.nextCursor
                    bufferSize)

end TouhouFormal.ECL
