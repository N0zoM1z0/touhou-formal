import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

inductive RawCallRetAction where
  | yielded
  | skipped
  | callEntered
  | callNoOp
  | callConditionFalse
  | retRestored
  | retExitedChild
deriving Repr, DecidableEq

structure RawCallOperands where
  subId : Int
  stackDepth : Int
  stackDisabled : Bool
  subOffsets : Array Nat
deriving Repr, DecidableEq

structure RawRetOperands where
  stackDepth : Int
  stackDisabled : Bool
  childContextSlot : Int := 0
deriving Repr, DecidableEq

structure RawConditionalCallOperands extends RawCallOperands where
  lhsRaw : Int
  lhsHost : Int
  rhsRaw : Int
deriving Repr, DecidableEq

structure RawCallRetOutcome where
  action : RawCallRetAction
  stackDepthAfter : Option Int := none
  returnCursor : Option Int := none
  returnCursorClass : Option TouhouFormal.CursorClass := none
  targetSubOffset : Option Nat := none
  childContextIndex : Option Int := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.stack"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingCallRetShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.stack"
    detail := "profile does not define source-backed CALL/RET stack semantics" }

private def unexpectedOpcodeFault (shape : HeaderShape) (opcode expected : Int) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.stack"
    detail := "CALL/RET body reached with an unexpected opcode; raw dispatch should have selected the profile opcode first"
    index := some opcode
    bound := some expected.toNat }

private def callStackWriteFault
    (shape : HeaderShape)
    (callRet : RawCallRetShape)
    (stackDepth : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.stack.call"
    detail := "CALL saves current context to saved/active ECL call stack before checking the increment guard"
    index := some stackDepth
    bound := some callRet.stackEntryCount }

private def retStackReadFault
    (shape : HeaderShape)
    (callRet : RawCallRetShape)
    (stackDepthAfterDecrement : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.stack.ret"
    detail := "RET decrements the call-stack depth before reading saved/active ECL call stack"
    index := some stackDepthAfterDecrement
    bound := some callRet.stackEntryCount }

private def retChildContextIndexFault
    (shape : HeaderShape)
    (callRet : RawCallRetShape)
    (childContextIndex : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.stack.retChild"
    detail := "TH08 RET underflow indexes childEclBlocks[childContextSlot - 1]"
    index := some childContextIndex
    bound := some callRet.childContextSlotCount }

private def stackIndexInBounds (entryCount : Nat) (index : Int) : Bool :=
  decide (0 <= index ∧ index < Int.ofNat entryCount)

private def callReturnCursorOutcome
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (action : RawCallRetAction)
    (stackDepthAfter : Int)
    (targetSubOffset : Option Nat := none) : RawCallRetOutcome :=
  { action := action
    stackDepthAfter := some stackDepthAfter
    returnCursor := some rawPrefix.nextCursor
    returnCursorClass :=
      some
        (TouhouFormal.classifyCursorTransfer
          rawPrefix.fileOffset
          rawPrefix.nextCursor
          bufferSize)
    targetSubOffset := targetSubOffset }

private def rawCallRetEnvelope
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (body : RawInstrShape -> RawCallRetShape -> Except Fault RawCallRetOutcome) :
    Except Fault RawCallRetOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      match rawShape.callRetShape with
      | none => .error (missingCallRetShapeFault shape)
      | some callRet =>
          if currentTime != rawPrefix.time then
            .ok { action := .yielded }
          else do
            let difficultyPass <- rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
            if !difficultyPass then
              .ok
                { action := .skipped
                  returnCursor := some rawPrefix.nextCursor
                  returnCursorClass :=
                    some
                      (TouhouFormal.classifyCursorTransfer
                        rawPrefix.fileOffset
                        rawPrefix.nextCursor
                        bufferSize) }
            else
              body rawShape callRet

private def rawCallRetGate
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (expectedOpcode : RawCallRetShape -> Int)
    (body : RawInstrShape -> RawCallRetShape -> Except Fault RawCallRetOutcome) :
    Except Fault RawCallRetOutcome :=
  rawCallRetEnvelope
    shape
    currentTime
    activeMask
    overrideMask
    maxBits
    bufferSize
    rawPrefix
    (fun rawShape callRet =>
      if rawPrefix.opcode != expectedOpcode callRet then
        .error (unexpectedOpcodeFault shape rawPrefix.opcode (expectedOpcode callRet))
      else
        body rawShape callRet)

private def missingConditionalCallShapeFault (shape : HeaderShape) (opcode : Int) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.stack.conditionalCall"
    detail := "profile does not define source-backed conditional CALL semantics for opcode"
    index := some opcode }

private def rawCallBody
    (shape : HeaderShape)
    (bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (callRet : RawCallRetShape)
    (operands : RawCallOperands) : Except Fault RawCallRetOutcome := do
  if !operands.stackDisabled &&
      !stackIndexInBounds callRet.stackEntryCount operands.stackDepth then
    .error (callStackWriteFault shape callRet operands.stackDepth)
  else
    let lookup <- lookupSubOffset shape operands.subOffsets operands.subId
    let stackDepthAfter :=
      if !operands.stackDisabled &&
          operands.stackDepth < Int.ofNat callRet.stackIncrementGuardExclusive then
        operands.stackDepth + 1
      else
        operands.stackDepth
    match lookup with
    | some subOffset =>
        .ok
          (callReturnCursorOutcome
            rawPrefix
            bufferSize
            .callEntered
            stackDepthAfter
            (some subOffset))
    | none =>
        .ok
          (callReturnCursorOutcome
            rawPrefix
            bufferSize
            .callNoOp
            stackDepthAfter
            none)

def rawCallStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawCallOperands) : Except Fault RawCallRetOutcome :=
  rawCallRetGate
    shape
    currentTime
    activeMask
    overrideMask
    maxBits
    bufferSize
    rawPrefix
    (fun callRet => callRet.callOpcode)
    (fun _rawShape callRet =>
      rawCallBody shape bufferSize rawPrefix callRet operands)

def rawConditionalCallStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawConditionalCallOperands) : Except Fault RawCallRetOutcome :=
  rawCallRetEnvelope
    shape
    currentTime
    activeMask
    overrideMask
    maxBits
    bufferSize
    rawPrefix
    (fun rawShape callRet => do
      match rawShape.findConditionalCall? rawPrefix.opcode with
      | none => .error (missingConditionalCallShapeFault shape rawPrefix.opcode)
      | some condCall =>
          let lhs <-
            resolveIntRValue
              shape
              rawPrefix
              condCall.lhsOperandIndex
              operands.lhsRaw
              operands.lhsHost
          if condCall.op.holds lhs.value operands.rhsRaw then
            rawCallBody
              shape
              bufferSize
              rawPrefix
              callRet
              { subId := operands.subId
                stackDepth := operands.stackDepth
                stackDisabled := operands.stackDisabled
                subOffsets := operands.subOffsets }
          else
            .ok
              (callReturnCursorOutcome
                rawPrefix
                bufferSize
                .callConditionFalse
                operands.stackDepth))

def rawRetStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawRetOperands) : Except Fault RawCallRetOutcome :=
  rawCallRetGate
    shape
    currentTime
    activeMask
    overrideMask
    maxBits
    bufferSize
    rawPrefix
    (fun callRet => callRet.retOpcode)
    (fun _rawShape callRet => do
      let stackDepthAfter := operands.stackDepth - 1
      match callRet.retUnderflowPolicy with
      | .uncheckedSavedContextRead =>
          if !stackIndexInBounds callRet.stackEntryCount stackDepthAfter then
            .error (retStackReadFault shape callRet stackDepthAfter)
          else
            .ok
              { action := .retRestored
                stackDepthAfter := some stackDepthAfter }
      | .th08ChildContextExit =>
          if stackDepthAfter < 0 then
            let childContextIndex := operands.childContextSlot - 1
            if !stackIndexInBounds callRet.childContextSlotCount childContextIndex then
              .error (retChildContextIndexFault shape callRet childContextIndex)
            else
              .ok
                { action := .retExitedChild
                  stackDepthAfter := some stackDepthAfter
                  childContextIndex := some childContextIndex }
          else if !stackIndexInBounds callRet.stackEntryCount stackDepthAfter then
            .error (retStackReadFault shape callRet stackDepthAfter)
          else
            .ok
              { action := .retRestored
                stackDepthAfter := some stackDepthAfter })

end TouhouFormal.ECL
