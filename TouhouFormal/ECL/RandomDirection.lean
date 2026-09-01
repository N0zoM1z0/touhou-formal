import TouhouFormal.Core.Float32
import TouhouFormal.ECL.Movement

namespace TouhouFormal.ECL

def randomDirectionZeroBits : Int := 0
def randomDirectionHalfPiBits : Int := 1070141403
def randomDirectionNegativeHalfPiBits : Int := 3217625051
def randomDirectionArenaInnerLeftBits : Int := 1119879168
def randomDirectionArenaInnerRightBits : Int := 1133510656

structure RawRandomDirectionOperandSlot where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawRandomDirectionRuntime where
  playerXBits : Int := 0
  enemyXBits : Int := 0
  enemyYBits : Int := 0
  currentEnemyAngleBits : Int := 0
deriving Repr, DecidableEq

/--
Binary32 arithmetic performed by the retail host remains explicit here.  The
Lean transition chooses the same source branches and records which arithmetic
result is consumed; an SMT backend can later constrain these result bits with
IEEE-754 operations without changing the VM transition.
-/
structure RawRandomDirectionHostResults where
  candidateAngleBits : Int := 0
  leftCandidateAngleBits : Int := 0
  rightCandidateAngleBits : Int := 0
  lowerXPlusMarginBits : Int := 0
  upperXMinusMarginBits : Int := 0
  lowerYPlusMarginBits : Int := 0
  upperYMinusMarginBits : Int := 0
  leftPositiveResultBits : Int := 0
  leftNegativeResultBits : Int := 0
  rightPositiveCandidateResultBits : Int := 0
  rightPositiveCurrentResultBits : Int := 0
  rightNegativeResultBits : Int := 0
deriving Repr, DecidableEq

structure RawRandomDirectionOperands where
  slots : List RawRandomDirectionOperandSlot := []
  runtime : RawRandomDirectionRuntime := {}
  hostResults : RawRandomDirectionHostResults := {}
deriving Repr, DecidableEq

inductive RawRandomDirectionResolution where
  | rawBits (value : Int)
  | floatRValue (value : RawFloatOperandResolution)
deriving Repr, DecidableEq

def RawRandomDirectionResolution.bits : RawRandomDirectionResolution -> Int
  | .rawBits value => value
  | .floatRValue value => value.value

structure RawRandomDirectionRead where
  operandIndex : Nat
  resolution : RawRandomDirectionResolution
deriving Repr, DecidableEq

inductive RawRandomDirectionCandidateBranch where
  | operandRange
  | playerLeft
  | playerRight
  | arenaLeft
  | arenaRight
  | hostCandidate
deriving Repr, DecidableEq

inductive RawRandomDirectionReflectionKind where
  | leftPositive
  | leftNegative
  | rightPositiveCandidate
  | rightPositiveCurrent
  | rightNegative
  | lowerVertical
  | upperVertical
deriving Repr, DecidableEq

structure RawRandomDirectionReflection where
  kind : RawRandomDirectionReflectionKind
  angleBefore : Int
  formulaSourceBits : Int
  angleAfter : Int
deriving Repr, DecidableEq

inductive RawRandomDirectionOutput where
  | enemyAngle
  | floatLValue (resolution : RawFloatLValueResolution)
  | hostAngle
  | noWritableOutput
deriving Repr, DecidableEq

structure RawRandomDirectionEffect where
  enemyAngleWrite : Option Int := none
  floatLValueWrite : Option Int := none
  hostAngleResult : Option Int := none
deriving Repr, DecidableEq

structure RawRandomDirectionPrepared where
  op : RawRandomDirectionOpShape
  reads : List RawRandomDirectionRead
  candidateBranch : RawRandomDirectionCandidateBranch
  candidateAngleBits : Int
  reflections : List RawRandomDirectionReflection
  finalAngleBits : Int
  output : RawRandomDirectionOutput
  effect : RawRandomDirectionEffect
deriving Repr, DecidableEq

inductive RawRandomDirectionAction where
  | yielded
  | skipped
  | advanced
  | noWritableOutput
  | vmError
deriving Repr, DecidableEq

structure RawRandomDirectionOutcome where
  action : RawRandomDirectionAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawRandomDirectionEffect := none
  prepared : Option RawRandomDirectionPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.randomDirection"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedRandomDirectionShapeFault
    (shape : HeaderShape)
    (op : RawRandomDirectionOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.randomDirection"
    detail := "random direction " ++ op.generator.name ++ ": " ++ detail
    index := some op.opcode }

private def missingRandomDirectionOperandFault
    (shape : HeaderShape)
    (op : RawRandomDirectionOpShape)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.randomDirection"
    detail :=
      "random direction " ++ op.generator.name ++
        " did not receive operand slot " ++ toString operandIndex
    index := some op.opcode }

private def rawRandomDirectionCursorOutcome
    (action : RawRandomDirectionAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawRandomDirectionEffect := none)
    (prepared : Option RawRandomDirectionPrepared := none) :
    RawRandomDirectionOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def randomDirectionSlot
    (shape : HeaderShape)
    (op : RawRandomDirectionOpShape)
    (operands : RawRandomDirectionOperands)
    (operandIndex : Nat) : Except Fault RawRandomDirectionOperandSlot :=
  match operands.slots[operandIndex]? with
  | some slot => .ok slot
  | none => .error (missingRandomDirectionOperandFault shape op operandIndex)

private def expectedRandomDirectionInputCount
    (generator : RawRandomDirectionGeneratorKind) : Nat :=
  match generator with
  | .operandRange => 2
  | .playerSide | .arenaExit | .hostCandidate => 0

private def validateRandomDirectionOp
    (shape : HeaderShape)
    (op : RawRandomDirectionOpShape) : Except Fault Unit :=
  if op.floatInputs.length != expectedRandomDirectionInputCount op.generator then
    .error
      (malformedRandomDirectionShapeFault shape op
        "float operand count does not match the generator")
  else
    .ok ()

private def resolveRandomDirectionInputs
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawRandomDirectionOpShape)
    (operands : RawRandomDirectionOperands) :
    Except Fault (List RawRandomDirectionRead) :=
  op.floatInputs.mapM (fun input =>
    let slotResult := randomDirectionSlot shape op operands input.operandIndex
    match slotResult with
    | .error fault => .error fault
    | .ok slot =>
        match input.policy with
        | .rawBits =>
            .ok
              { operandIndex := input.operandIndex
                resolution := .rawBits slot.rawValue }
        | .floatRValue => do
            let value <-
              resolveFloatRValue shape rawPrefix input.operandIndex
                slot.rawValue slot.hostValue
            .ok
              { operandIndex := input.operandIndex
                resolution := .floatRValue value })

private def selectRandomDirectionCandidate
    (op : RawRandomDirectionOpShape)
    (operands : RawRandomDirectionOperands) :
    RawRandomDirectionCandidateBranch × Int :=
  let runtime := operands.runtime
  let host := operands.hostResults
  match op.generator with
  | .operandRange => (.operandRange, host.candidateAngleBits)
  | .playerSide =>
      if TouhouFormal.f32LessThanBits runtime.playerXBits runtime.enemyXBits then
        (.playerLeft, host.leftCandidateAngleBits)
      else
        (.playerRight, host.rightCandidateAngleBits)
  | .arenaExit =>
      let playerIsLeft :=
        TouhouFormal.f32LessThanBits runtime.playerXBits runtime.enemyXBits
      let pastInnerLeft :=
        TouhouFormal.f32LessThanBits
          randomDirectionArenaInnerLeftBits runtime.enemyXBits
      let pastInnerRight :=
        TouhouFormal.f32LessThanBits
          randomDirectionArenaInnerRightBits runtime.enemyXBits
      if (playerIsLeft && pastInnerLeft) || pastInnerRight then
        (.arenaLeft, host.leftCandidateAngleBits)
      else
        (.arenaRight, host.rightCandidateAngleBits)
  | .hostCandidate => (.hostCandidate, host.candidateAngleBits)

private def applyRandomDirectionLeftBoundary
    (runtime : RawRandomDirectionRuntime)
    (host : RawRandomDirectionHostResults)
    (angle : Int) : Int × List RawRandomDirectionReflection :=
  if TouhouFormal.f32LessThanBits runtime.enemyXBits host.lowerXPlusMarginBits then
    if TouhouFormal.f32GreaterThanBits angle randomDirectionHalfPiBits then
      (host.leftPositiveResultBits,
        [ { kind := .leftPositive
            angleBefore := angle
            formulaSourceBits := angle
            angleAfter := host.leftPositiveResultBits } ])
    else if TouhouFormal.f32LessThanBits angle randomDirectionNegativeHalfPiBits then
      (host.leftNegativeResultBits,
        [ { kind := .leftNegative
            angleBefore := angle
            formulaSourceBits := angle
            angleAfter := host.leftNegativeResultBits } ])
    else
      (angle, [])
  else
    (angle, [])

private def applyRandomDirectionRightBoundary
    (source : RawRandomDirectionRightPositiveSource)
    (runtime : RawRandomDirectionRuntime)
    (host : RawRandomDirectionHostResults)
    (angle : Int) : Int × List RawRandomDirectionReflection :=
  if TouhouFormal.f32GreaterThanBits runtime.enemyXBits host.upperXMinusMarginBits then
    if TouhouFormal.f32LessThanBits angle randomDirectionHalfPiBits &&
        TouhouFormal.f32GreaterOrEqualBits angle randomDirectionZeroBits then
      match source with
      | .candidateAngle =>
          (host.rightPositiveCandidateResultBits,
            [ { kind := .rightPositiveCandidate
                angleBefore := angle
                formulaSourceBits := angle
                angleAfter := host.rightPositiveCandidateResultBits } ])
      | .currentEnemyAngle =>
          (host.rightPositiveCurrentResultBits,
            [ { kind := .rightPositiveCurrent
                angleBefore := angle
                formulaSourceBits := runtime.currentEnemyAngleBits
                angleAfter := host.rightPositiveCurrentResultBits } ])
    else if
        TouhouFormal.f32GreaterThanBits angle randomDirectionNegativeHalfPiBits &&
          TouhouFormal.f32LessOrEqualBits angle randomDirectionZeroBits then
      (host.rightNegativeResultBits,
        [ { kind := .rightNegative
            angleBefore := angle
            formulaSourceBits := angle
            angleAfter := host.rightNegativeResultBits } ])
    else
      (angle, [])
  else
    (angle, [])

private def applyRandomDirectionVerticalBounds
    (runtime : RawRandomDirectionRuntime)
    (host : RawRandomDirectionHostResults)
    (angle : Int) : Int × List RawRandomDirectionReflection :=
  let (afterLower, lowerTrace) :=
    if TouhouFormal.f32LessThanBits runtime.enemyYBits host.lowerYPlusMarginBits &&
        TouhouFormal.f32LessThanBits angle randomDirectionZeroBits then
      let reflected := TouhouFormal.f32NegBits angle
      (reflected,
        [ { kind := .lowerVertical
            angleBefore := angle
            formulaSourceBits := angle
            angleAfter := reflected } ])
    else
      (angle, [])
  let (afterUpper, upperTrace) :=
    if TouhouFormal.f32GreaterThanBits runtime.enemyYBits host.upperYMinusMarginBits &&
        TouhouFormal.f32GreaterThanBits afterLower randomDirectionZeroBits then
      let reflected := TouhouFormal.f32NegBits afterLower
      (reflected,
        [ { kind := .upperVertical
            angleBefore := afterLower
            formulaSourceBits := afterLower
            angleAfter := reflected } ])
    else
      (afterLower, [])
  (afterUpper, lowerTrace ++ upperTrace)

private def applyRandomDirectionBounds
    (op : RawRandomDirectionOpShape)
    (operands : RawRandomDirectionOperands)
    (candidate : Int) : Int × List RawRandomDirectionReflection :=
  match op.boundaryPolicy with
  | .none => (candidate, [])
  | .vertical =>
      applyRandomDirectionVerticalBounds
        operands.runtime operands.hostResults candidate
  | .rectangle source =>
      let (afterLeft, leftTrace) :=
        applyRandomDirectionLeftBoundary
          operands.runtime operands.hostResults candidate
      let (afterRight, rightTrace) :=
        applyRandomDirectionRightBoundary
          source operands.runtime operands.hostResults afterLeft
      let (finalAngle, verticalTrace) :=
        applyRandomDirectionVerticalBounds
          operands.runtime operands.hostResults afterRight
      (finalAngle, leftTrace ++ rightTrace ++ verticalTrace)

private def resolveRandomDirectionOutput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawRandomDirectionOpShape)
    (operands : RawRandomDirectionOperands) :
    Except Fault RawRandomDirectionOutput :=
  match op.outputPolicy with
  | .enemyAngle => .ok .enemyAngle
  | .hostAngle => .ok .hostAngle
  | .floatLValue operandIndex => do
      let slot <- randomDirectionSlot shape op operands operandIndex
      let resolution <-
        resolveFloatLValue shape rawPrefix operandIndex
          slot.rawValue slot.hostValue
      if resolution.kind == .nonFloatOutput then
        .ok .noWritableOutput
      else
        .ok (.floatLValue resolution)

private def randomDirectionEffect
    (output : RawRandomDirectionOutput)
    (finalAngle : Int) : RawRandomDirectionEffect :=
  match output with
  | .enemyAngle => { enemyAngleWrite := some finalAngle }
  | .floatLValue _ => { floatLValueWrite := some finalAngle }
  | .hostAngle => { hostAngleResult := some finalAngle }
  | .noWritableOutput => {}

def rawRandomDirectionPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawRandomDirectionOpShape)
    (operands : RawRandomDirectionOperands) :
    Except Fault RawRandomDirectionPrepared := do
  validateRandomDirectionOp shape op
  let reads <- resolveRandomDirectionInputs shape rawPrefix op operands
  let (candidateBranch, candidateAngleBits) :=
    selectRandomDirectionCandidate op operands
  let (finalAngleBits, reflections) :=
    applyRandomDirectionBounds op operands candidateAngleBits
  let output <- resolveRandomDirectionOutput shape rawPrefix op operands
  let effect := randomDirectionEffect output finalAngleBits
  .ok
    { op := op
      reads := reads
      candidateBranch := candidateBranch
      candidateAngleBits := candidateAngleBits
      reflections := reflections
      finalAngleBits := finalAngleBits
      output := output
      effect := effect }

def rawRandomDirectionStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawRandomDirectionOperands) :
    Except Fault RawRandomDirectionOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawRandomDirectionCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findRandomDirectionOp? rawPrefix.opcode with
          | none =>
              .ok
                (rawRandomDirectionCursorOutcome
                  .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawRandomDirectionPrepare shape rawPrefix op operands
              let action :=
                match prepared.output with
                | .noWritableOutput => RawRandomDirectionAction.noWritableOutput
                | _ => .advanced
              .ok
                (rawRandomDirectionCursorOutcome action rawPrefix bufferSize
                  (some prepared.effect) (some prepared))

end TouhouFormal.ECL
