import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawBossIntReadOperands where
  outputRaw : Int
  outputHostBefore : Int
  valueRaw : Int
  valueHost : Int
  bossIndexRaw : Int
  bossIndexHost : Int
  bossPresent : Bool
deriving Repr, DecidableEq

structure RawBossIntReadPrepared where
  read : RawBossIntReadShape
  output : RawIntLValueResolution
  bossIndexResolution : Option RawIntOperandResolution := none
  valueResolution : Option RawIntOperandResolution := none
  bossIndexValue : Option Int := none
  value : Option Int := none
  bossPresent : Option Bool := none
deriving Repr, DecidableEq

inductive RawBossIntReadAction where
  | yielded
  | skipped
  | advanced
  | valueRawNoBossRead
  | nonIntOutput
  | vmError
deriving Repr, DecidableEq

structure RawBossIntReadOutcome where
  action : RawBossIntReadAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  result : Option Int := none
  prepared : Option RawBossIntReadPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossIntRead"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingIntResolverFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossIntRead"
    detail := "profile does not define integer operand resolver semantics" }

private def bossIndexOutOfBoundsFault
    (shape : HeaderShape)
    (read : RawBossIntReadShape)
    (bossIndex : Int) : Fault :=
  Fault.outOfBoundsRead
    shape.title
    "EclRun.bossIntRead.bosses"
    ("source boss-indexed integer read reaches g_EnemyManager.bosses[index] for opcode " ++
      toString read.opcode)
    bossIndex
    read.bossSlotCount

private def nullBossFault
    (shape : HeaderShape)
    (read : RawBossIntReadShape)
    (bossIndex : Int) : Fault :=
  { kind := .nullDereference
    title := shape.title
    component := "EclRun.bossIntRead.bosses"
    detail :=
      "source boss-indexed integer read dereferences a null boss pointer for opcode " ++
        toString read.opcode
    index := some bossIndex
    bound := some read.bossSlotCount }

private def rawBossIntReadCursorOutcome
    (action : RawBossIntReadAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (result : Option Int := none)
    (prepared : Option RawBossIntReadPrepared := none) : RawBossIntReadOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some (TouhouFormal.classifyCursorTransfer rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    result := result
    prepared := prepared }

def rawBossIntReadPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (read : RawBossIntReadShape)
    (operands : RawBossIntReadOperands) :
    Except Fault RawBossIntReadPrepared := do
  let output <-
    resolveIntLValue
      shape
      rawPrefix
      read.outputOperandIndex
      operands.outputRaw
      operands.outputHostBefore
  if output.kind == .nonIntOutput then
    .ok
      { read := read
        output := output }
  else
    match shape.rawInstrShape with
    | none => .error (missingRawInstrShapeFault shape)
    | some rawShape =>
        match rawShape.intRValueResolver with
        | none => .error (missingIntResolverFault shape)
        | some resolver => do
            let valueFlagEnabled <-
              rawIntOperandFlagEnabled
                shape
                rawPrefix
                read.valueOperandIndex
                resolver
            if !valueFlagEnabled then
              .ok
                { read := read
                  output := output
                  valueResolution :=
                    some
                      { kind := .rawImmediate
                        value := operands.valueRaw
                        rawValue := operands.valueRaw
                        hostValue := none
                        selectorKnown := resolver.knownRValueSelectors.contains operands.valueRaw
                        flagEnabled := false }
                  value := some operands.valueRaw }
            else
              let bossIndex <-
                resolveIntRValue
                  shape
                  rawPrefix
                  read.bossIndexOperandIndex
                  operands.bossIndexRaw
                  operands.bossIndexHost
              if bossIndex.value < 0 then
                .error (bossIndexOutOfBoundsFault shape read bossIndex.value)
              else if read.bossSlotCount <= bossIndex.value.toNat then
                .error (bossIndexOutOfBoundsFault shape read bossIndex.value)
              else if !operands.bossPresent &&
                  read.nullDerefValueSelectors.contains operands.valueRaw then
                .error (nullBossFault shape read bossIndex.value)
              else
                let value <-
                  resolveIntRValue
                    shape
                    rawPrefix
                    read.valueOperandIndex
                    operands.valueRaw
                    operands.valueHost
                .ok
                  { read := read
                    output := output
                    bossIndexResolution := some bossIndex
                    valueResolution := some value
                    bossIndexValue := some bossIndex.value
                    value := some value.value
                    bossPresent := some operands.bossPresent }

def rawBossIntReadStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawBossIntReadOperands) :
    Except Fault RawBossIntReadOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <- rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawBossIntReadCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findBossIntRead? rawPrefix.opcode with
          | none =>
              .ok (rawBossIntReadCursorOutcome .advanced rawPrefix bufferSize)
          | some read => do
              let prepared <- rawBossIntReadPrepare shape rawPrefix read operands
              if prepared.output.kind == .nonIntOutput then
                .ok
                  (rawBossIntReadCursorOutcome
                    .nonIntOutput
                    rawPrefix
                    bufferSize
                    none
                    (some prepared))
              else
                match prepared.value with
                | none =>
                    .error
                      { kind := .invalidInstruction
                        title := shape.title
                        component := "EclRun.bossIntRead"
                        detail := "boss integer read reached without a resolved value" }
                | some value =>
                    let action :=
                      match prepared.bossIndexValue with
                      | none => .valueRawNoBossRead
                      | some _ => .advanced
                    .ok
                      (rawBossIntReadCursorOutcome
                        action
                        rawPrefix
                        bufferSize
                        (some value)
                        (some prepared))

end TouhouFormal.ECL
