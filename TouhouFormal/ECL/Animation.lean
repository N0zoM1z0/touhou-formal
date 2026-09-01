import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawAnimationIntInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawAnimationFloatInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawAnimationOperands where
  intInputs : List RawAnimationIntInput := []
  floatInputs : List RawAnimationFloatInput := []
  runtimeSpecialScript : Int := 0
  runtimeAlternateBank : Bool := false
deriving Repr, DecidableEq

inductive RawAnimationVmTarget where
  | primary
  | secondary (slot : Int)
deriving Repr, DecidableEq

inductive RawAnimationIntResolution where
  | intRValue : RawIntOperandResolution -> RawAnimationIntResolution
  | rawI32 : Int -> RawAnimationIntResolution
  | rawByte : Int -> RawAnimationIntResolution
  | rawU16ToI16 : Int -> RawAnimationIntResolution
  | rawI16 : Int -> RawAnimationIntResolution
deriving Repr, DecidableEq

def RawAnimationIntResolution.value : RawAnimationIntResolution -> Int
  | .intRValue value => value.value
  | .rawI32 value
  | .rawByte value
  | .rawU16ToI16 value
  | .rawI16 value => value

inductive RawAnimationFloatResolution where
  | floatRValue : RawFloatOperandResolution -> RawAnimationFloatResolution
  | rawBits : Int -> RawAnimationFloatResolution
deriving Repr, DecidableEq

def RawAnimationFloatResolution.bits : RawAnimationFloatResolution -> Int
  | .floatRValue value => value.value
  | .rawBits value => value

structure RawAnimationResolvedIntInput where
  shape : RawAnimationIntInputShape
  resolution : RawAnimationIntResolution
deriving Repr, DecidableEq

structure RawAnimationResolvedFloatInput where
  shape : RawAnimationFloatInputShape
  resolution : RawAnimationFloatResolution
deriving Repr, DecidableEq

structure RawAnimationHostCall where
  bank : RawAnimationBank
  target : RawAnimationVmTarget
  scriptId : Int
deriving Repr, DecidableEq

structure RawAnimationMovementScripts where
  defaultScript : Int
  farLeft : Int
  farRight : Int
  left : Int
  right : Int
  flags : Int
deriving Repr, DecidableEq

structure RawAnimationDeathScripts where
  first : Int
  second : Int
  third : Int
deriving Repr, DecidableEq

structure RawAnimationPrimaryScriptTable where
  idleInitial : Int
  moveLeft : Int
  moveRight : Int
  idleFromLeft : Int
  idleFromRight : Int
  special : Int
  anmDirection : Int
deriving Repr, DecidableEq

structure RawAnimationSecondarySlotDiagnostic where
  slot : Int
  bound : Nat
deriving Repr, DecidableEq

structure RawAnimationSecondaryScriptClear where
  slot : Int
  scriptIndex : Int
deriving Repr, DecidableEq

structure RawAnimationSecondaryInterruptWrite where
  slot : Int
  interruptId : Int
deriving Repr, DecidableEq

structure RawAnimationEffect where
  hostCall : Option RawAnimationHostCall := none
  movementScriptsWrite : Option RawAnimationMovementScripts := none
  deathScriptsWrite : Option RawAnimationDeathScripts := none
  primaryScriptTableWrite : Option RawAnimationPrimaryScriptTable := none
  alternateBankFlagWrite : Option Bool := none
  autoRotateWrite : Option Int := none
  primaryPendingInterruptWrite : Option Int := none
  secondarySlotDiagnostic : Option RawAnimationSecondarySlotDiagnostic := none
  secondaryScriptClear : Option RawAnimationSecondaryScriptClear := none
  secondaryPendingInterruptWrite :
    Option RawAnimationSecondaryInterruptWrite := none
  primaryRotationZWrite : Option Int := none
deriving Repr, DecidableEq

structure RawAnimationScriptResolution where
  source : RawAnimationScriptSource
  value : Int
  base : Int
  scriptId : Int
deriving Repr, DecidableEq

structure RawAnimationPrepared where
  op : RawAnimationOpShape
  intResolutions : List RawAnimationResolvedIntInput
  floatResolutions : List RawAnimationResolvedFloatInput
  bank : RawAnimationBank
  scriptResolution : Option RawAnimationScriptResolution
  effect : RawAnimationEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

inductive RawAnimationAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawAnimationOutcome where
  action : RawAnimationAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawAnimationEffect := none
  fault : Option Fault := none
  prepared : Option RawAnimationPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.animation"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedAnimationShapeFault
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.animation"
    detail := "animation opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def rawAnimationCursorOutcome
    (action : RawAnimationAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawAnimationEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawAnimationPrepared := none) : RawAnimationOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def missingAnimationOperandFault
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.animation"
    detail :=
      "animation opcode " ++ op.kind.name ++
        " did not receive source occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def missingSecondaryAccessFault
    (shape : HeaderShape)
    (op : RawAnimationOpShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.animation.secondaryVm"
    detail :=
      "animation opcode " ++ op.kind.name ++
        " requires a secondary VM access profile"
    index := some op.opcode }

private def secondarySlotWriteFault
    (shape : HeaderShape)
    (_op : RawAnimationOpShape)
    (access : RawAnimationSecondaryAccessShape)
    (slot : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.animation.secondaryVm"
    detail :=
      "source indexes a secondary ANM VM slot without a full bounds check"
    index := some slot
    bound := some access.slotCount }

private def secondarySlotInBounds
    (access : RawAnimationSecondaryAccessShape)
    (slot : Int) : Bool :=
  decide (0 <= slot ∧ slot < Int.ofNat access.slotCount)

private def secondarySlotDiagnostic?
    (access : RawAnimationSecondaryAccessShape)
    (slot : Int) : Option RawAnimationSecondarySlotDiagnostic :=
  if access.diagnoseHighOnly && decide (Int.ofNat access.slotCount <= slot) then
    some { slot := slot, bound := access.slotCount }
  else
    none

def rawAnimationU8FromWord (rawValue : Int) (byteIndex : Nat) : Int :=
  (TouhouFormal.toWord32Bits rawValue / (2 ^ (8 * byteIndex))) % 256

def rawAnimationU16FromWord (rawValue : Int) (halfIndex : Nat) : Int :=
  (TouhouFormal.toWord32Bits rawValue / (2 ^ (16 * halfIndex))) %
    TouhouFormal.word16Modulus

def rawAnimationI16FromWord (rawValue : Int) (halfIndex : Nat) : Int :=
  TouhouFormal.word16BitsToInt
    (rawAnimationU16FromWord rawValue halfIndex)

private def resolveAnimationIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawAnimationIntInputShape)
    (input : RawAnimationIntInput) :
    Except Fault RawAnimationResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .intRValue => do
        let value <-
          resolveIntRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawValue
            input.hostValue
        .ok (.intRValue value)
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .rawByte =>
        .ok
          (.rawByte
            (rawAnimationU8FromWord input.rawValue inputShape.byteIndex))
    | .rawU16ToI16 =>
        .ok
          (.rawU16ToI16
            (TouhouFormal.word16BitsToInt
              (rawAnimationU16FromWord input.rawValue inputShape.halfIndex)))
    | .rawI16 =>
        .ok
          (.rawI16
            (rawAnimationI16FromWord input.rawValue inputShape.halfIndex))
  .ok { shape := inputShape, resolution := resolution }

private def resolveAnimationIntOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawAnimationOpShape)
    (operands : RawAnimationOperands)
    (occurrence : Nat)
    (inputShape : RawAnimationIntInputShape) :
    Except Fault RawAnimationResolvedIntInput := do
  let input <-
    match operands.intInputs[occurrence]? with
    | none =>
        .error
          (missingAnimationOperandFault
            shape op occurrence inputShape.operandIndex)
    | some input => .ok input
  resolveAnimationIntInput shape rawPrefix inputShape input

private def resolveAnimationFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawAnimationFloatInputShape)
    (input : RawAnimationFloatInput) :
    Except Fault RawAnimationResolvedFloatInput := do
  let resolution <-
    match inputShape.policy with
    | .floatRValue => do
        let value <-
          resolveFloatRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawValue
            input.hostValue
        .ok (.floatRValue value)
    | .rawBits => .ok (.rawBits input.rawValue)
  .ok { shape := inputShape, resolution := resolution }

private def findResolvedInt?
    (inputs : List RawAnimationResolvedIntInput)
    (operandIndex : Nat) : Option RawAnimationIntResolution :=
  (inputs.find? (fun input => input.shape.operandIndex == operandIndex)).map
    (fun input => input.resolution)

private def findResolvedFloat?
    (inputs : List RawAnimationResolvedFloatInput)
    (operandIndex : Nat) : Option RawAnimationFloatResolution :=
  (inputs.find? (fun input => input.shape.operandIndex == operandIndex)).map
    (fun input => input.resolution)

private def resolveAnimationBank
    (policy : RawAnimationBankPolicy)
    (operands : RawAnimationOperands) : RawAnimationBank :=
  match policy with
  | .fixed bank => bank
  | .runtimeFlag =>
      if operands.runtimeAlternateBank then .alternate else .primary

private def resolveAnimationScript
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (intResolutions : List RawAnimationResolvedIntInput)
    (operands : RawAnimationOperands) :
    Except Fault (Option RawAnimationScriptResolution) :=
  match op.scriptSource with
  | none => .ok none
  | some source =>
      let value? :=
        match source with
        | .intRValue operandIndex =>
            (findResolvedInt? intResolutions operandIndex).map
              RawAnimationIntResolution.value
        | .rawI32 operandIndex =>
            (findResolvedInt? intResolutions operandIndex).map
              RawAnimationIntResolution.value
        | .runtimeSpecial => some operands.runtimeSpecialScript
      match value? with
      | none =>
          .error
            (malformedAnimationShapeFault
              shape op
              ("script source " ++ source.name ++
                " has no matching integer input"))
      | some value =>
          .ok
            (some
              { source := source
                value := value
                base := op.scriptBase
                scriptId := value + op.scriptBase })

private def signedI16 (value : Int) : Int :=
  TouhouFormal.word16BitsToInt (TouhouFormal.toWord16Bits value)

private def movementScriptsFromInputs
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (intResolutions : List RawAnimationResolvedIntInput) :
    Except Fault RawAnimationMovementScripts :=
  match intResolutions with
  | [defaultScript, farLeft, farRight, left, right] =>
    .ok
      { defaultScript := signedI16 defaultScript.resolution.value
        farLeft := signedI16 farLeft.resolution.value
        farRight := signedI16 farRight.resolution.value
        left := signedI16 left.resolution.value
        right := signedI16 right.resolution.value
        flags := 255 }
  | _ =>
    .error
      (malformedAnimationShapeFault
        shape op
        ("profile resolved " ++ toString intResolutions.length ++
          " movement scripts, expected 5"))

private def deathScriptsFromInputs
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (intResolutions : List RawAnimationResolvedIntInput) :
    Except Fault RawAnimationDeathScripts :=
  match intResolutions with
  | [first, second, third] =>
    .ok
      { first := first.resolution.value
        second := second.resolution.value
        third := third.resolution.value }
  | _ =>
    .error
      (malformedAnimationShapeFault
        shape op
        ("profile resolved " ++ toString intResolutions.length ++
          " death scripts, expected 3"))

private def primaryScriptTableFromValues
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (values : List Int) : Except Fault RawAnimationPrimaryScriptTable :=
  match values with
  | [idleInitial, moveLeft, moveRight, idleFromLeft, idleFromRight, special] =>
    .ok
      { idleInitial := signedI16 idleInitial
        moveLeft := signedI16 moveLeft
        moveRight := signedI16 moveRight
        idleFromLeft := signedI16 idleFromLeft
        idleFromRight := signedI16 idleFromRight
        special := signedI16 special
        anmDirection := 255 }
  | _ =>
    .error
      (malformedAnimationShapeFault
        shape op
        ("primary script table resolved " ++ toString values.length ++
          " scripts, expected 6"))

private def explicitPrimaryScriptTable
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (intResolutions : List RawAnimationResolvedIntInput) :
    Except Fault RawAnimationPrimaryScriptTable :=
  primaryScriptTableFromValues
    shape op (intResolutions.map (fun input => input.resolution.value))

private def sequentialPrimaryScriptTable
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (scriptResolution : Option RawAnimationScriptResolution) :
    Except Fault RawAnimationPrimaryScriptTable :=
  match scriptResolution with
  | none =>
      .error
        (malformedAnimationShapeFault
          shape op "sequential table opcode has no base script")
  | some script =>
      primaryScriptTableFromValues
        shape
        op
        [ script.value,
          script.value + 1,
          script.value + 2,
          script.value + 3,
          script.value + 4,
          script.value + 5 ]

private def autoRotateFromInputs
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (intResolutions : List RawAnimationResolvedIntInput) :
    Except Fault Int :=
  match intResolutions with
  | [input] =>
      .ok (TouhouFormal.truncateUnsignedBits input.resolution.value 1)
  | _ =>
      .error
        (malformedAnimationShapeFault
          shape op
          ("auto-rotate opcode resolved " ++
            toString intResolutions.length ++ " inputs, expected 1"))

private def primaryInterruptFromInputs
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (intResolutions : List RawAnimationResolvedIntInput) :
    Except Fault Int :=
  match intResolutions with
  | [input] => .ok (signedI16 input.resolution.value)
  | _ =>
      .error
        (malformedAnimationShapeFault
          shape op
          ("primary-interrupt opcode resolved " ++
            toString intResolutions.length ++ " inputs, expected 1"))

private def primaryRotationFromInputs
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (floatResolutions : List RawAnimationResolvedFloatInput) :
    Except Fault Int :=
  match floatResolutions with
  | [input] => .ok input.resolution.bits
  | _ =>
      .error
        (malformedAnimationShapeFault
          shape op
          ("primary-rotation opcode resolved " ++
            toString floatResolutions.length ++ " inputs, expected 1"))

private def secondaryFaultPrepared
    (op : RawAnimationOpShape)
    (intResolutions : List RawAnimationResolvedIntInput)
    (bank : RawAnimationBank)
    (scriptResolution : Option RawAnimationScriptResolution)
    (effect : RawAnimationEffect)
    (fault : Fault) : RawAnimationPrepared :=
  { op := op
    intResolutions := intResolutions
    floatResolutions := []
    bank := bank
    scriptResolution := scriptResolution
    effect := effect
    hostFault := some fault }

private def prepareSecondaryScriptDirect
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawAnimationOpShape)
    (access : RawAnimationSecondaryAccessShape)
    (operands : RawAnimationOperands)
    (bank : RawAnimationBank) : Except Fault RawAnimationPrepared := do
  let slotRead <-
    resolveAnimationIntOccurrence
      shape rawPrefix op operands 0 access.slotInput
  let scriptRead <-
    resolveAnimationIntOccurrence
      shape rawPrefix op operands 1 access.scriptInput
  let slot := slotRead.resolution.value
  let scriptResolution : RawAnimationScriptResolution :=
    { source := .rawI32 access.scriptInput.operandIndex
      value := scriptRead.resolution.value
      base := access.scriptBase
      scriptId := scriptRead.resolution.value + access.scriptBase }
  let diagnostic := secondarySlotDiagnostic? access slot
  let baseEffect : RawAnimationEffect :=
    { alternateBankFlagWrite := op.setAlternateBankFlag
      secondarySlotDiagnostic := diagnostic }
  let reads := [slotRead, scriptRead]
  if !secondarySlotInBounds access slot then
    let fault := secondarySlotWriteFault shape op access slot
    .ok
      (secondaryFaultPrepared
        op reads bank (some scriptResolution) baseEffect fault)
  else
    .ok
      { op := op
        intResolutions := reads
        floatResolutions := []
        bank := bank
        scriptResolution := some scriptResolution
        effect :=
          { baseEffect with
            hostCall :=
              some
                { bank := bank
                  target := .secondary slot
                  scriptId := scriptResolution.scriptId } } }

private def prepareSecondaryScriptBranched
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawAnimationOpShape)
    (access : RawAnimationSecondaryAccessShape)
    (operands : RawAnimationOperands)
    (bank : RawAnimationBank) : Except Fault RawAnimationPrepared := do
  let slotCheckRead <-
    resolveAnimationIntOccurrence
      shape rawPrefix op operands 0 access.slotInput
  let branchScriptRead <-
    resolveAnimationIntOccurrence
      shape rawPrefix op operands 1 access.scriptInput
  let branchScript := branchScriptRead.resolution.value
  let slotCheck := slotCheckRead.resolution.value
  let diagnostic := secondarySlotDiagnostic? access slotCheck
  if decide (0 <= branchScript) then
    let slotAccessRead <-
      resolveAnimationIntOccurrence
        shape rawPrefix op operands 2 access.slotInput
    let scriptRunRead <-
      resolveAnimationIntOccurrence
        shape rawPrefix op operands 3 access.scriptInput
    let slot := slotAccessRead.resolution.value
    let scriptResolution : RawAnimationScriptResolution :=
      { source := .intRValue access.scriptInput.operandIndex
        value := scriptRunRead.resolution.value
        base := access.scriptBase
        scriptId := scriptRunRead.resolution.value + access.scriptBase }
    let baseEffect : RawAnimationEffect :=
      { alternateBankFlagWrite := op.setAlternateBankFlag
        secondarySlotDiagnostic := diagnostic }
    let reads :=
      [slotCheckRead, branchScriptRead, slotAccessRead, scriptRunRead]
    if !secondarySlotInBounds access slot then
      let fault := secondarySlotWriteFault shape op access slot
      .ok
        (secondaryFaultPrepared
          op reads bank (some scriptResolution) baseEffect fault)
    else
      .ok
        { op := op
          intResolutions := reads
          floatResolutions := []
          bank := bank
          scriptResolution := some scriptResolution
          effect :=
            { baseEffect with
              hostCall :=
                some
                  { bank := bank
                    target := .secondary slot
                    scriptId := scriptResolution.scriptId } } }
  else
    let slotAccessRead <-
      resolveAnimationIntOccurrence
        shape rawPrefix op operands 2 access.slotInput
    let slot := slotAccessRead.resolution.value
    let baseEffect : RawAnimationEffect :=
      { alternateBankFlagWrite := op.setAlternateBankFlag
        secondarySlotDiagnostic := diagnostic }
    let reads := [slotCheckRead, branchScriptRead, slotAccessRead]
    if !secondarySlotInBounds access slot then
      let fault := secondarySlotWriteFault shape op access slot
      .ok (secondaryFaultPrepared op reads bank none baseEffect fault)
    else
      .ok
        { op := op
          intResolutions := reads
          floatResolutions := []
          bank := bank
          scriptResolution := none
          effect :=
            { baseEffect with
              secondaryScriptClear :=
                some
                  { slot := slot
                    scriptIndex := access.clearScriptIndexValue } } }

private def prepareSecondaryScript
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawAnimationOpShape)
    (operands : RawAnimationOperands) : Except Fault RawAnimationPrepared := do
  let access <-
    match op.secondaryAccess with
    | none => .error (missingSecondaryAccessFault shape op)
    | some access => .ok access
  let bank := resolveAnimationBank op.bankPolicy operands
  match access.scriptMode with
  | .alwaysRun =>
      prepareSecondaryScriptDirect shape rawPrefix op access operands bank
  | .runWhenNonnegativeElseClear =>
      prepareSecondaryScriptBranched shape rawPrefix op access operands bank

private def prepareSecondaryInterrupt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawAnimationOpShape)
    (operands : RawAnimationOperands) : Except Fault RawAnimationPrepared := do
  let access <-
    match op.secondaryAccess with
    | none => .error (missingSecondaryAccessFault shape op)
    | some access => .ok access
  let slotRead <-
    resolveAnimationIntOccurrence
      shape rawPrefix op operands 0 access.slotInput
  let interruptRead <-
    resolveAnimationIntOccurrence
      shape rawPrefix op operands 1 access.interruptInput
  let slot := slotRead.resolution.value
  let interruptId := interruptRead.resolution.value
  let bank := resolveAnimationBank op.bankPolicy operands
  let diagnostic := secondarySlotDiagnostic? access slot
  let baseEffect : RawAnimationEffect :=
    { alternateBankFlagWrite := op.setAlternateBankFlag
      secondarySlotDiagnostic := diagnostic }
  let reads := [slotRead, interruptRead]
  if !secondarySlotInBounds access slot then
    let fault := secondarySlotWriteFault shape op access slot
    .ok (secondaryFaultPrepared op reads bank none baseEffect fault)
  else
    .ok
      { op := op
        intResolutions := reads
        floatResolutions := []
        bank := bank
        scriptResolution := none
        effect :=
          { baseEffect with
            secondaryPendingInterruptWrite :=
              some { slot := slot, interruptId := interruptId } } }

private def animationEffect
    (shape : HeaderShape)
    (op : RawAnimationOpShape)
    (bank : RawAnimationBank)
    (scriptResolution : Option RawAnimationScriptResolution)
    (intResolutions : List RawAnimationResolvedIntInput)
    (floatResolutions : List RawAnimationResolvedFloatInput) :
    Except Fault RawAnimationEffect := do
  let baseEffect : RawAnimationEffect :=
    { alternateBankFlagWrite := op.setAlternateBankFlag }
  match op.kind with
  | .setPrimaryScript =>
      match scriptResolution with
      | none =>
          .error
            (malformedAnimationShapeFault
              shape op "primary script opcode has no script source")
      | some script =>
          .ok
            { baseEffect with
              hostCall :=
                some
                  { bank := bank
                    target := .primary
                    scriptId := script.scriptId } }
  | .setSecondaryScript =>
      .error
        (malformedAnimationShapeFault
          shape op "secondary script opcodes use ordered source reads")
  | .setPrimaryScriptTableSequential =>
      let table <- sequentialPrimaryScriptTable shape op scriptResolution
      .ok { baseEffect with primaryScriptTableWrite := some table }
  | .setPrimaryScriptTableExplicit =>
      let table <- explicitPrimaryScriptTable shape op intResolutions
      .ok { baseEffect with primaryScriptTableWrite := some table }
  | .playPrimarySpecialScript =>
      match scriptResolution with
      | none =>
          .error
            (malformedAnimationShapeFault
              shape op "special-script opcode has no runtime script source")
      | some script =>
          .ok
            { baseEffect with
              hostCall :=
                some
                  { bank := bank
                    target := .primary
                    scriptId := script.scriptId } }
  | .setMovementScripts =>
      let scripts <- movementScriptsFromInputs shape op intResolutions
      .ok { baseEffect with movementScriptsWrite := some scripts }
  | .setDeathScripts =>
      let scripts <- deathScriptsFromInputs shape op intResolutions
      .ok { baseEffect with deathScriptsWrite := some scripts }
  | .setAutoRotate =>
      let value <- autoRotateFromInputs shape op intResolutions
      .ok { baseEffect with autoRotateWrite := some value }
  | .setPrimaryInterrupt =>
      let value <- primaryInterruptFromInputs shape op intResolutions
      .ok { baseEffect with primaryPendingInterruptWrite := some value }
  | .setSecondaryInterrupt =>
      .error
        (malformedAnimationShapeFault
          shape op "secondary interrupt opcodes use ordered source reads")
  | .setPrimaryRotationZ =>
      let value <- primaryRotationFromInputs shape op floatResolutions
      .ok { baseEffect with primaryRotationZWrite := some value }

def rawAnimationPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawAnimationOpShape)
    (operands : RawAnimationOperands) :
    Except Fault RawAnimationPrepared := do
  match op.kind with
  | .setSecondaryScript =>
      prepareSecondaryScript shape rawPrefix op operands
  | .setSecondaryInterrupt =>
      prepareSecondaryInterrupt shape rawPrefix op operands
  | _ =>
      if operands.intInputs.length != op.intInputs.length then
        .error
          (malformedAnimationShapeFault
            shape op
            ("step supplied " ++ toString operands.intInputs.length ++
              " integer inputs, expected " ++ toString op.intInputs.length))
      else if operands.floatInputs.length != op.floatInputs.length then
        .error
          (malformedAnimationShapeFault
            shape op
            ("step supplied " ++ toString operands.floatInputs.length ++
              " float inputs, expected " ++ toString op.floatInputs.length))
      else
        let intResolutions <-
          (List.zip op.intInputs operands.intInputs).mapM
            (fun (inputShape, input) =>
              resolveAnimationIntInput shape rawPrefix inputShape input)
        let floatResolutions <-
          (List.zip op.floatInputs operands.floatInputs).mapM
            (fun (inputShape, input) =>
              resolveAnimationFloatInput shape rawPrefix inputShape input)
        let bank := resolveAnimationBank op.bankPolicy operands
        let scriptResolution <-
          resolveAnimationScript shape op intResolutions operands
        let effect <-
          animationEffect shape op bank scriptResolution intResolutions
            floatResolutions
        .ok
          { op := op
            intResolutions := intResolutions
            floatResolutions := floatResolutions
            bank := bank
            scriptResolution := scriptResolution
            effect := effect }

def rawAnimationStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawAnimationOperands) :
    Except Fault RawAnimationOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawAnimationCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawAnimationCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findAnimationOp? rawPrefix.opcode with
          | none =>
              .ok (rawAnimationCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawAnimationPrepare shape rawPrefix op operands
              let action :=
                match prepared.hostFault with
                | none => .advanced
                | some _ => .hostFault
              .ok
                (rawAnimationCursorOutcome
                  action
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  prepared.hostFault
                  (some prepared))

end TouhouFormal.ECL
