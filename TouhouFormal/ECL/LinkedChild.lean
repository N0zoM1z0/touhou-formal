import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawLinkedChildIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawLinkedChildFloatInput where
  rawBits : Int := 0
  hostBits : Int := 0
deriving Repr, DecidableEq

structure RawLinkedChildVector3Bits where
  x : Int := 0
  y : Int := 0
  z : Int := 0
deriving Repr, DecidableEq

structure RawLinkedChildRuntime where
  parentLife : Int := 1
  parentSuppressDeathEffects : Bool := false
  parentHasChain : Bool := false
  attachmentChainTerminates : Bool := true
  attachmentTailHops : Nat := 0
  spawnSucceeds : Bool := true
  childAlignmentEffectPresent : Bool := false
  alignmentEffectSpawnSucceeds : Bool := true
  playerYoukaiReads : List Bool := []
  childEnemyIndex : Int := 0
  parentPositionBits : RawLinkedChildVector3Bits := {}
  parentWorldPositionBits : RawLinkedChildVector3Bits := {}
  parentOffsetResultBits : RawLinkedChildVector3Bits := {}
  inheritedWorldPositionResultBits : RawLinkedChildVector3Bits := {}
deriving Repr, DecidableEq

structure RawLinkedChildOperands where
  intInputs : List RawLinkedChildIntInput := []
  floatInputs : List RawLinkedChildFloatInput := []
  runtime : RawLinkedChildRuntime := {}
deriving Repr, DecidableEq

inductive RawLinkedChildIntResolution where
  | rawI32 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawLinkedChildIntResolution.value :
    RawLinkedChildIntResolution -> Int
  | .rawI32 value => value
  | .intRValue resolution => resolution.value

structure RawLinkedChildResolvedIntInput where
  shape : RawLinkedChildIntInputShape
  resolution : RawLinkedChildIntResolution
deriving Repr, DecidableEq

structure RawLinkedChildResolvedFloatInput where
  shape : RawLinkedChildFloatInputShape
  resolution : RawFloatOperandResolution
deriving Repr, DecidableEq

inductive RawLinkedChildReadRole where
  | int (role : RawLinkedChildIntRole)
  | float (role : RawLinkedChildFloatRole)
  | playerYoukai (occurrence : Nat)
deriving Repr, DecidableEq

structure RawLinkedChildTailTraversal where
  parentHasChain : Bool
  terminates : Bool
  tailHops : Nat
deriving Repr, DecidableEq

structure RawLinkedChildSpawnPosition where
  mode : RawLinkedChildPositionMode
  resolvedScriptBits : RawLinkedChildVector3Bits
  parentWorldPositionBits : RawLinkedChildVector3Bits
  finalSpawnPositionBits : RawLinkedChildVector3Bits
deriving Repr, DecidableEq

structure RawLinkedChildSpawnRequest where
  rawSubId : Int
  hostSubId : Int
  position : RawLinkedChildSpawnPosition
  life : Int
  itemDrop : Int
  hostItemDrop : Int
  score : Int
  poolSearchSlots : Nat
  contextCopyBytes : Nat
  runSpawnedEclImmediately : Bool := true
deriving Repr, DecidableEq

structure RawLinkedChildAlignmentRequest where
  effectId : Int
  positionSource : RawLinkedChildEffectPositionSource
  positionBits : RawLinkedChildVector3Bits
  interrupt : Int
  flag17CollisionValue : Bool
  negatesAngularVelocityZ : Bool
deriving Repr, DecidableEq

structure RawLinkedChildInitialization where
  linkedChildFlagSet : Bool
  playerYoukaiReads : List Bool
  youkaiAligned : Bool
  drawGroup : Int
  collisionCleared : Bool
  positionOffsetWrite : Option RawLinkedChildVector3Bits := none
  worldPositionWrite : Option RawLinkedChildVector3Bits := none
  alignmentEffectAlreadyPresent : Bool
  alignmentRequest : Option RawLinkedChildAlignmentRequest := none
  inheritParentPositionFlagSet : Bool
  parentLinkWritten : Bool
  tailLinkHops : Option Nat := none
  parentLinkedChildCountDelta : Int
deriving Repr, DecidableEq

structure RawLinkedChildSoundRequest where
  soundId : Int
  positionedByParentX : Bool
deriving Repr, DecidableEq

structure RawLinkedChildEffect where
  tailTraversal : RawLinkedChildTailTraversal
  spawnSuppressedByParentState : Bool := false
  lastSpawnFailed : Bool := false
  spawnRequest : Option RawLinkedChildSpawnRequest := none
  spawnSucceeded : Bool := false
  initialization : Option RawLinkedChildInitialization := none
  soundRequest : Option RawLinkedChildSoundRequest := none
deriving Repr, DecidableEq

inductive RawLinkedChildAction where
  | yielded
  | skipped
  | advanced
  | diverged
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawLinkedChildPrepared where
  op : RawLinkedChildOpShape
  intResolutions : List RawLinkedChildResolvedIntInput := []
  floatResolutions : List RawLinkedChildResolvedFloatInput := []
  readOrder : List RawLinkedChildReadRole := []
  effect : RawLinkedChildEffect
  terminalAction : RawLinkedChildAction := .advanced
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawLinkedChildOutcome where
  action : RawLinkedChildAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawLinkedChildEffect := none
  fault : Option Fault := none
  prepared : Option RawLinkedChildPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.linkedChild"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedLinkedChildFault
    (shape : HeaderShape)
    (op : RawLinkedChildOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.linkedChild"
    detail := op.positionMode.name ++ ": " ++ detail
    index := some op.opcode }

private def alignmentEffectNullFault
    (shape : HeaderShape)
    (op : RawLinkedChildOpShape) : Fault :=
  { kind := .nullDereference
    title := shape.title
    component := "EclRun.linkedChild.alignmentEffect"
    detail :=
      "source stores the effect-manager result and immediately dereferences it without a null guard"
    index := some op.opcode }

private def rawLinkedChildCursorOutcome
    (action : RawLinkedChildAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawLinkedChildEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawLinkedChildPrepared := none) :
    RawLinkedChildOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def expectedIntRoles : List RawLinkedChildIntRole :=
  [.subId, .life, .itemDrop, .score]

private def expectedFloatRoles : List RawLinkedChildFloatRole :=
  [.positionX, .positionY]

private def validateShape
    (shape : HeaderShape)
    (op : RawLinkedChildOpShape) : Except Fault Unit := do
  if op.intInputs.map (fun input => input.role) != expectedIntRoles then
    .error
      (malformedLinkedChildFault shape op
        "integer roles do not match the child spawn packet")
  else if op.floatInputs.map (fun input => input.role) != expectedFloatRoles then
    .error
      (malformedLinkedChildFault shape op
        "float roles do not match the child spawn packet")
  else
    .ok ()

private def intInputAt
    (shape : HeaderShape)
    (op : RawLinkedChildOpShape)
    (operands : RawLinkedChildOperands)
    (occurrence : Nat)
    (inputShape : RawLinkedChildIntInputShape) :
    Except Fault RawLinkedChildIntInput :=
  match operands.intInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (malformedLinkedChildFault shape op
          ("missing integer occurrence " ++ toString occurrence ++
            " for role " ++ inputShape.role.name))

private def floatInputAt
    (shape : HeaderShape)
    (op : RawLinkedChildOpShape)
    (operands : RawLinkedChildOperands)
    (occurrence : Nat)
    (inputShape : RawLinkedChildFloatInputShape) :
    Except Fault RawLinkedChildFloatInput :=
  match operands.floatInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (malformedLinkedChildFault shape op
          ("missing float occurrence " ++ toString occurrence ++
            " for role " ++ inputShape.role.name))

private def resolveIntAt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLinkedChildOpShape)
    (operands : RawLinkedChildOperands)
    (occurrence : Nat)
    (inputShape : RawLinkedChildIntInputShape) :
    Except Fault RawLinkedChildResolvedIntInput := do
  let input <- intInputAt shape op operands occurrence inputShape
  let resolution <-
    match inputShape.policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix inputShape.operandIndex
            input.rawValue input.hostValue
        .ok (.intRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveFloatAt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLinkedChildOpShape)
    (operands : RawLinkedChildOperands)
    (occurrence : Nat)
    (inputShape : RawLinkedChildFloatInputShape) :
    Except Fault RawLinkedChildResolvedFloatInput := do
  let input <- floatInputAt shape op operands occurrence inputShape
  let resolution <-
    resolveFloatRValue shape rawPrefix inputShape.operandIndex
      input.rawBits input.hostBits
  .ok { shape := inputShape, resolution := resolution }

private def resolveIntsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLinkedChildOpShape)
    (operands : RawLinkedChildOperands) :
    Nat -> List RawLinkedChildIntInputShape ->
      Except Fault (List RawLinkedChildResolvedIntInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let head <- resolveIntAt shape rawPrefix op operands occurrence inputShape
      let tail <-
        resolveIntsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def resolveFloatsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLinkedChildOpShape)
    (operands : RawLinkedChildOperands) :
    Nat -> List RawLinkedChildFloatInputShape ->
      Except Fault (List RawLinkedChildResolvedFloatInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let head <-
        resolveFloatAt shape rawPrefix op operands occurrence inputShape
      let tail <-
        resolveFloatsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def intByRole?
    (inputs : List RawLinkedChildResolvedIntInput)
    (role : RawLinkedChildIntRole) : Option Int :=
  (inputs.find? (fun input => input.shape.role == role)).map
    (fun input => input.resolution.value)

private def floatByRole?
    (inputs : List RawLinkedChildResolvedFloatInput)
    (role : RawLinkedChildFloatRole) : Option Int :=
  (inputs.find? (fun input => input.shape.role == role)).map
    (fun input => TouhouFormal.toWord32Bits input.resolution.value)

private def signedI8 (value : Int) : Int :=
  let bits := TouhouFormal.truncateUnsignedBits value 8
  if bits < 128 then bits else bits - 256

private def playerReadAt
    (shape : HeaderShape)
    (op : RawLinkedChildOpShape)
    (runtime : RawLinkedChildRuntime)
    (occurrence : Nat) : Except Fault Bool :=
  match runtime.playerYoukaiReads[occurrence]? with
  | some value => .ok value
  | none =>
      .error
        (malformedLinkedChildFault shape op
          ("missing player-alignment observation " ++ toString occurrence))

private def tailTraversal
    (runtime : RawLinkedChildRuntime) : RawLinkedChildTailTraversal :=
  if runtime.parentHasChain then
    { parentHasChain := true
      terminates := runtime.attachmentChainTerminates
      tailHops := runtime.attachmentTailHops }
  else
    { parentHasChain := false, terminates := true, tailHops := 0 }

private def soundRequest
    (op : RawLinkedChildOpShape) : RawLinkedChildSoundRequest :=
  { soundId := op.spawnSoundId, positionedByParentX := true }

private def completedInitialization
    (base : RawLinkedChildInitialization)
    (tailHops : Nat) : RawLinkedChildInitialization :=
  { base with
    parentLinkWritten := true
    tailLinkHops := some tailHops
    parentLinkedChildCountDelta := 1 }

def rawLinkedChildPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawLinkedChildOpShape)
    (operands : RawLinkedChildOperands) :
    Except Fault RawLinkedChildPrepared := do
  let traversal := tailTraversal operands.runtime
  let baseEffect : RawLinkedChildEffect := { tailTraversal := traversal }
  if traversal.parentHasChain && !traversal.terminates then
    .ok
      { op := op
        effect := baseEffect
        terminalAction := .diverged }
  else if !(decide (0 < operands.runtime.parentLife)) ||
      operands.runtime.parentSuppressDeathEffects then
    .ok
      { op := op
        effect :=
          { baseEffect with
            spawnSuppressedByParentState := true
            lastSpawnFailed := true
            soundRequest := some (soundRequest op) } }
  else do
    validateShape shape op
    let floats <- resolveFloatsAux shape rawPrefix op operands 0 op.floatInputs
    let ints <- resolveIntsAux shape rawPrefix op operands 0 op.intInputs
    let scriptPosition : RawLinkedChildVector3Bits :=
      { x := (floatByRole? floats .positionX).getD 0
        y := (floatByRole? floats .positionY).getD 0
        z := 0 }
    let finalSpawnPosition :=
      match op.positionMode with
      | .scriptPosition => scriptPosition
      | .parentWorldOffset => operands.runtime.parentOffsetResultBits
    let rawSubId := (intByRole? ints .subId).getD 0
    let itemDrop := (intByRole? ints .itemDrop).getD 0
    let request : RawLinkedChildSpawnRequest :=
      { rawSubId := rawSubId
        hostSubId :=
          if op.hostSubIdTruncatesToI16 then
            TouhouFormal.word16BitsToInt rawSubId
          else
            rawSubId
        position :=
          { mode := op.positionMode
            resolvedScriptBits := scriptPosition
            parentWorldPositionBits := operands.runtime.parentWorldPositionBits
            finalSpawnPositionBits := finalSpawnPosition }
        life := (intByRole? ints .life).getD 0
        itemDrop := itemDrop
        hostItemDrop :=
          if op.hostItemDropTruncatesToI8 then signedI8 itemDrop else itemDrop
        score := (intByRole? ints .score).getD 0
        poolSearchSlots := op.poolSearchSlots
        contextCopyBytes := op.contextCopyBytes }
    let sourceReadOrder :=
      op.floatInputs.map (fun input => RawLinkedChildReadRole.float input.role) ++
      op.intInputs.map (fun input => RawLinkedChildReadRole.int input.role)
    let spawnedEffect : RawLinkedChildEffect :=
      { baseEffect with
        spawnRequest := some request
        spawnSucceeded := operands.runtime.spawnSucceeds
        lastSpawnFailed := !operands.runtime.spawnSucceeds }
    if !operands.runtime.spawnSucceeds then
      .ok
        { op := op
          intResolutions := ints
          floatResolutions := floats
          readOrder := sourceReadOrder
          effect :=
            { spawnedEffect with soundRequest := some (soundRequest op) } }
    else
      let alignment0 <- playerReadAt shape op operands.runtime 0
      let alignment1 <- playerReadAt shape op operands.runtime 1
      let drawGroup := if alignment1 then 0 else 2
      let positionOffsetWrite :=
        if op.setParentPositionOffset then
          some operands.runtime.parentPositionBits
        else
          none
      let worldPositionWrite :=
        if op.setParentPositionOffset then
          some operands.runtime.inheritedWorldPositionResultBits
        else
          none
      let initializationBase : RawLinkedChildInitialization :=
        { linkedChildFlagSet := true
          playerYoukaiReads := [alignment0, alignment1]
          youkaiAligned := alignment0
          drawGroup := drawGroup
          collisionCleared := true
          positionOffsetWrite := positionOffsetWrite
          worldPositionWrite := worldPositionWrite
          alignmentEffectAlreadyPresent :=
            operands.runtime.childAlignmentEffectPresent
          inheritParentPositionFlagSet := op.inheritParentPosition
          parentLinkWritten := false
          parentLinkedChildCountDelta := 0 }
      let alignmentReads :=
        sourceReadOrder ++
          [.playerYoukai 0, .playerYoukai 1]
      if operands.runtime.childAlignmentEffectPresent then
        let initialized :=
          completedInitialization initializationBase traversal.tailHops
        .ok
          { op := op
            intResolutions := ints
            floatResolutions := floats
            readOrder := alignmentReads
            effect :=
              { spawnedEffect with
                initialization := some initialized
                soundRequest := some (soundRequest op) } }
      else
        let alignment2 <- playerReadAt shape op operands.runtime 2
        let effectPositionBits :=
          match op.effectPositionSource with
          | .childPosition => finalSpawnPosition
          | .childWorldPosition =>
              operands.runtime.inheritedWorldPositionResultBits
        let alignmentRequest : RawLinkedChildAlignmentRequest :=
          { effectId := op.alignmentEffectId
            positionSource := op.effectPositionSource
            positionBits := effectPositionBits
            interrupt := if alignment2 then 2 else 1
            flag17CollisionValue := false
            negatesAngularVelocityZ :=
              TouhouFormal.word32BitSet operands.runtime.childEnemyIndex 0 }
        let withAlignment : RawLinkedChildInitialization :=
          { initializationBase with
            playerYoukaiReads := [alignment0, alignment1, alignment2]
            alignmentRequest := some alignmentRequest }
        let allReads := alignmentReads ++ [.playerYoukai 2]
        if !operands.runtime.alignmentEffectSpawnSucceeds then
          let fault := alignmentEffectNullFault shape op
          .ok
            { op := op
              intResolutions := ints
              floatResolutions := floats
              readOrder := allReads
              effect :=
                { spawnedEffect with initialization := some withAlignment }
              terminalAction := .hostFault
              hostFault := some fault }
        else
          let initialized :=
            completedInitialization withAlignment traversal.tailHops
          .ok
            { op := op
              intResolutions := ints
              floatResolutions := floats
              readOrder := allReads
              effect :=
                { spawnedEffect with
                  initialization := some initialized
                  soundRequest := some (soundRequest op) } }

def rawLinkedChildStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawLinkedChildOperands) :
    Except Fault RawLinkedChildOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix
            activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawLinkedChildCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawLinkedChildCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findLinkedChildOp? rawPrefix.opcode with
          | none =>
              .ok (rawLinkedChildCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawLinkedChildPrepare shape rawPrefix op operands
              if prepared.terminalAction == .diverged then
                .ok
                  { action := .diverged
                    effect := some prepared.effect
                    prepared := some prepared }
              else
                .ok
                  (rawLinkedChildCursorOutcome prepared.terminalAction
                    rawPrefix bufferSize (some prepared.effect)
                    prepared.hostFault (some prepared))

end TouhouFormal.ECL
