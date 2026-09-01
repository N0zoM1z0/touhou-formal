import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawEnemyStateFloatInput where
  rawValue : Int
  hostValue : Int
deriving Repr, DecidableEq

structure RawEnemyStateOperands where
  floatInputs : List RawEnemyStateFloatInput := []
  intRaw : Int := 0
  intHost : Int := 0
  alignmentEffectPresent : Bool := false
  presentationWritesAllowed : Bool := true
deriving Repr, DecidableEq

inductive RawEnemyStateFloatResolution where
  | floatRValue : RawFloatOperandResolution -> RawEnemyStateFloatResolution
  | rawBits : Int -> RawEnemyStateFloatResolution
deriving Repr, DecidableEq

def RawEnemyStateFloatResolution.bits : RawEnemyStateFloatResolution -> Int
  | .floatRValue value => value.value
  | .rawBits value => value

inductive RawEnemyStateIntResolution where
  | rawI32 (value : Int)
  | rawByte (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawEnemyStateIntResolution.value : RawEnemyStateIntResolution -> Int
  | .rawI32 value | .rawByte value => value
  | .intRValue value => value.value

structure RawEnemyHitboxBits where
  x : Int
  y : Int
  z : Option Int := none
deriving Repr, DecidableEq

structure RawEnemyStateFieldWrite where
  field : RawEnemyStateField
  value : Int
deriving Repr, DecidableEq

structure RawEnemyStateEffect where
  primaryHitboxWrite : Option RawEnemyHitboxBits := none
  secondaryHitboxWrite : Option RawEnemyHitboxBits := none
  fieldWrites : List RawEnemyStateFieldWrite := []
  alignmentEffectCollisionWrite : Option Bool := none
  suppressedByPresentationPolicy : Bool := false
deriving Repr, DecidableEq

structure RawEnemyStatePrepared where
  op : RawEnemyStateOpShape
  floatResolutions : List RawEnemyStateFloatResolution
  floatBits : List Int
  intResolution : Option RawEnemyStateIntResolution
  intValue : Option Int
  effect : RawEnemyStateEffect
deriving Repr, DecidableEq

inductive RawEnemyStateAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawEnemyStateOutcome where
  action : RawEnemyStateAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawEnemyStateEffect := none
  prepared : Option RawEnemyStatePrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.enemyState"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedEnemyStateShapeFault
    (shape : HeaderShape)
    (op : RawEnemyStateOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.enemyState"
    detail := "enemy-state opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def rawEnemyStateCursorOutcome
    (action : RawEnemyStateAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawEnemyStateEffect := none)
    (prepared : Option RawEnemyStatePrepared := none) : RawEnemyStateOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset
        rawPrefix.nextCursor
        bufferSize)
    effect := effect
    prepared := prepared }

private def resolveEnemyStateFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawEnemyStateFloatInputShape)
    (input : RawEnemyStateFloatInput) :
    Except Fault RawEnemyStateFloatResolution :=
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

private def resolveEnemyStateIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawEnemyStateOpShape)
    (operands : RawEnemyStateOperands) :
    Except Fault (Option RawEnemyStateIntResolution) :=
  match op.intInputPolicy with
  | none => .ok none
  | some .rawI32 => .ok (some (.rawI32 operands.intRaw))
  | some .rawByte =>
      .ok
        (some
          (.rawByte (TouhouFormal.truncateUnsignedBits operands.intRaw 8)))
  | some .intRValue => do
      let value <-
        resolveIntRValue
          shape
          rawPrefix
          op.intOperandIndex
          operands.intRaw
          operands.intHost
      .ok (some (.intRValue value))

private def enemyStateFieldWrite
    (field : RawEnemyStateField)
    (value : Int) : RawEnemyStateFieldWrite :=
  { field := field
    value := TouhouFormal.truncateUnsignedBits value field.bitWidth }

private def enemyStateBoolFieldWrite
    (field : RawEnemyStateField)
    (value : Bool) : RawEnemyStateFieldWrite :=
  enemyStateFieldWrite field (if value then 1 else 0)

private def optionalEnemyStateBoolFieldWrite
    (enabled : Bool)
    (field : RawEnemyStateField)
    (value : Bool) : List RawEnemyStateFieldWrite :=
  if enabled then [enemyStateBoolFieldWrite field value] else []

private def th08MaskFieldWrites
    (kind : RawEnemyStateOpKind)
    (value : Int) : List RawEnemyStateFieldWrite :=
  let bit0 := TouhouFormal.word32BitSet value 0
  let bit1 := TouhouFormal.word32BitSet value 1
  let bit2 := TouhouFormal.word32BitSet value 2
  let bit3 := TouhouFormal.word32BitSet value 3
  let bit4 := TouhouFormal.word32BitSet value 4
  let bit5 := TouhouFormal.word32BitSet value 5
  match kind with
  | .replaceFlagMask =>
      [ enemyStateBoolFieldWrite .acceptsDamage (!bit0),
        enemyStateBoolFieldWrite .collision (!bit1),
        enemyStateBoolFieldWrite .damageable (!bit2),
        enemyStateBoolFieldWrite .noSprite bit3,
        enemyStateBoolFieldWrite .allowOffscreen bit4,
        enemyStateBoolFieldWrite .noDeath bit5 ]
  | .disableFlagMask =>
      optionalEnemyStateBoolFieldWrite bit0 .acceptsDamage false ++
      optionalEnemyStateBoolFieldWrite bit1 .collision false ++
      optionalEnemyStateBoolFieldWrite bit2 .damageable false ++
      optionalEnemyStateBoolFieldWrite bit3 .noSprite true ++
      optionalEnemyStateBoolFieldWrite bit4 .allowOffscreen true ++
      optionalEnemyStateBoolFieldWrite bit5 .noDeath true
  | .enableFlagMask =>
      optionalEnemyStateBoolFieldWrite bit0 .acceptsDamage true ++
      optionalEnemyStateBoolFieldWrite bit1 .collision true ++
      optionalEnemyStateBoolFieldWrite bit2 .damageable true ++
      optionalEnemyStateBoolFieldWrite bit3 .noSprite false ++
      optionalEnemyStateBoolFieldWrite bit4 .allowOffscreen false ++
      optionalEnemyStateBoolFieldWrite bit5 .noDeath false
  | _ => []

private def enemyHitboxBits
    (dimensions : Nat)
    (floatBits : List Int) : RawEnemyHitboxBits :=
  { x := floatBits[0]!
    y := floatBits[1]!
    z := if dimensions == 3 then floatBits[2]? else none }

private def enemyStateEffect
    (op : RawEnemyStateOpShape)
    (floatBits : List Int)
    (intValue : Option Int)
    (operands : RawEnemyStateOperands) : RawEnemyStateEffect :=
  let value := intValue.getD 0
  let suppressed := op.presentationGuard && !operands.presentationWritesAllowed
  match op.kind with
  | .setPrimaryHitbox dimensions =>
      { primaryHitboxWrite := some (enemyHitboxBits dimensions floatBits) }
  | .setSecondaryHitbox dimensions =>
      { secondaryHitboxWrite := some (enemyHitboxBits dimensions floatBits) }
  | .setField field =>
      if suppressed then
        { suppressedByPresentationPolicy := true }
      else
        { fieldWrites := [enemyStateFieldWrite field value] }
  | .replaceFlagMask =>
      { fieldWrites := th08MaskFieldWrites op.kind value }
  | .disableFlagMask =>
      { fieldWrites := th08MaskFieldWrites op.kind value
        alignmentEffectCollisionWrite :=
          if operands.alignmentEffectPresent &&
              TouhouFormal.word32BitSet value 1 then
            some false
          else
            none }
  | .enableFlagMask =>
      { fieldWrites := th08MaskFieldWrites op.kind value
        alignmentEffectCollisionWrite :=
          if operands.alignmentEffectPresent &&
              TouhouFormal.word32BitSet value 1 then
            some true
          else
            none }

def rawEnemyStatePrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawEnemyStateOpShape)
    (operands : RawEnemyStateOperands) :
    Except Fault RawEnemyStatePrepared := do
  let expectedFloatCount := op.kind.hitboxDimensions?.getD 0
  if expectedFloatCount != 0 && expectedFloatCount != 2 && expectedFloatCount != 3 then
    .error
      (malformedEnemyStateShapeFault
        shape op "hitbox dimension count must be two or three")
  else if op.floatInputs.length != expectedFloatCount then
    .error
      (malformedEnemyStateShapeFault
        shape op
        ("profile declares " ++ toString op.floatInputs.length ++
          " float inputs, expected " ++ toString expectedFloatCount))
  else if operands.floatInputs.length != expectedFloatCount then
    .error
      (malformedEnemyStateShapeFault
        shape op
        ("step supplied " ++ toString operands.floatInputs.length ++
          " float inputs, expected " ++ toString expectedFloatCount))
  else if op.kind.requiresIntInput != op.intInputPolicy.isSome then
    .error
      (malformedEnemyStateShapeFault
        shape op "integer input policy does not match opcode kind")
  else
    let floatResolutions <-
      (List.zip op.floatInputs operands.floatInputs).mapM
        (fun (inputShape, input) =>
          resolveEnemyStateFloatInput shape rawPrefix inputShape input)
    let floatBits := floatResolutions.map RawEnemyStateFloatResolution.bits
    let intResolution <-
      resolveEnemyStateIntInput shape rawPrefix op operands
    let intValue := intResolution.map RawEnemyStateIntResolution.value
    let effect := enemyStateEffect op floatBits intValue operands
    .ok
      { op := op
        floatResolutions := floatResolutions
        floatBits := floatBits
        intResolution := intResolution
        intValue := intValue
        effect := effect }

def rawEnemyStateStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawEnemyStateOperands) :
    Except Fault RawEnemyStateOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawEnemyStateCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawEnemyStateCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findEnemyStateOp? rawPrefix.opcode with
          | none =>
              .ok (rawEnemyStateCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawEnemyStatePrepare shape rawPrefix op operands
              .ok
                (rawEnemyStateCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  (some prepared))

end TouhouFormal.ECL
