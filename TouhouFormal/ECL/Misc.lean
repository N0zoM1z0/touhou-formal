import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawMiscIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawMiscFloatInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawMiscOperands where
  intInputs : List RawMiscIntInput := []
  floatInputs : List RawMiscFloatInput := []
  minimumDistanceSquaredBits : Int := 0
  gameFlagsBefore : Int := 0
  currentStage : Int := 0
  currentSpellCardNumber : Int := 0
  clockBits : Int := 0
deriving Repr, DecidableEq

inductive RawMiscIntResolution where
  | rawI32 (value : Int)
  | rawByte (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawMiscIntResolution.value : RawMiscIntResolution -> Int
  | .rawI32 value | .rawByte value => value
  | .intRValue resolution => resolution.value

inductive RawMiscFloatResolution where
  | rawBits (value : Int)
  | floatRValue (value : RawFloatOperandResolution)
deriving Repr, DecidableEq

def RawMiscFloatResolution.bits : RawMiscFloatResolution -> Int
  | .rawBits value => TouhouFormal.toWord32Bits value
  | .floatRValue resolution => TouhouFormal.toWord32Bits resolution.value

structure RawMiscResolvedIntInput where
  shape : RawMiscIntInputShape
  resolution : RawMiscIntResolution
deriving Repr, DecidableEq

structure RawMiscResolvedFloatInput where
  shape : RawMiscFloatInputShape
  resolution : RawMiscFloatResolution
deriving Repr, DecidableEq

structure RawMiscIntWrite where
  target : RawMiscIntTarget
  value : Int
deriving Repr, DecidableEq

structure RawMiscTimerWrite where
  target : RawMiscTimerTarget
  current : Int
  subFrameBits : Int
  previous : Int
deriving Repr, DecidableEq

structure RawMiscTrailEffect where
  flags : Int
  historyLength : Int
  collisionLength : Int
  sampleStride : Int
  stripInitializationRequested : Bool
  stripVertexCount : Option Int := none
deriving Repr, DecidableEq

structure RawMiscPauseEffect where
  gameFlagsBefore : Int
  gameFlagsAfter : Int
  stageSelectedPauseMode : Bool
  spellSelectedPauseMode : Bool
  enemyPauseTimerFlagSet : Bool
deriving Repr, DecidableEq

structure RawMiscMinimumDistanceEffect where
  resolvedDistanceBits : Int
  squaredDistanceBits : Int
deriving Repr, DecidableEq

structure RawMiscClockEffect where
  clockBeforeBits : Int
  clockBeforeSigned : Int
  advanced : Bool
  soundId : Option Int := none
  clockAfterBits : Int
  fastFlash : Bool
  slowFlash : Bool
deriving Repr, DecidableEq

structure RawMiscEffect where
  intWrites : List RawMiscIntWrite := []
  timerWrites : List RawMiscTimerWrite := []
  trail : Option RawMiscTrailEffect := none
  cherryDelta : Option Int := none
  stageUnpauseWrite : Option Int := none
  guiAction : Option RawMiscGuiAction := none
  pause : Option RawMiscPauseEffect := none
  minimumDistance : Option RawMiscMinimumDistanceEffect := none
  clock : Option RawMiscClockEffect := none
deriving Repr, DecidableEq

inductive RawMiscAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawMiscPrepared where
  op : RawMiscOpShape
  intResolutions : List RawMiscResolvedIntInput := []
  floatResolutions : List RawMiscResolvedFloatInput := []
  effect : RawMiscEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawMiscOutcome where
  action : RawMiscAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawMiscEffect := none
  fault : Option Fault := none
  prepared : Option RawMiscPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.misc"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedMiscFault
    (shape : HeaderShape)
    (op : RawMiscOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.misc"
    detail := op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def trailDivideByZeroFault
    (shape : HeaderShape)
    (op : RawMiscOpShape) : Fault :=
  { kind := .divideByZero
    title := shape.title
    component := "EclRun.misc.trail"
    detail :=
      "source initializes a trail strip after storing a zero signed-i16 sample stride"
    index := some op.opcode }

private def rawMiscCursorOutcome
    (action : RawMiscAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawMiscEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawMiscPrepared := none) : RawMiscOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def expectedIntCount : RawMiscOpKind -> Nat
  | .noOp | .stageUnpause | .configurePause | .setMinimumPlayerDistance |
      .gui _ | .advanceClock => 0
  | .writeInt _ _ | .writeTimer _ | .setProjectile |
      .setSpecialInteraction | .addCherry => 1
  | .configureTrail => 4

private def expectedFloatCount : RawMiscOpKind -> Nat
  | .setMinimumPlayerDistance => 1
  | _ => 0

private def resolveIntAt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawMiscOpShape)
    (operands : RawMiscOperands)
    (occurrence : Nat)
    (inputShape : RawMiscIntInputShape) :
    Except Fault RawMiscResolvedIntInput := do
  let input <-
    match operands.intInputs[occurrence]? with
    | some input => .ok input
    | none =>
        .error
          (malformedMiscFault shape op
            ("missing integer occurrence " ++ toString occurrence))
  let resolution <-
    match inputShape.policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .rawByte =>
        .ok (.rawByte (TouhouFormal.truncateUnsignedBits input.rawValue 8))
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix inputShape.operandIndex
            input.rawValue input.hostValue
        .ok (.intRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveFloatAt
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawMiscOpShape)
    (operands : RawMiscOperands)
    (occurrence : Nat)
    (inputShape : RawMiscFloatInputShape) :
    Except Fault RawMiscResolvedFloatInput := do
  let input <-
    match operands.floatInputs[occurrence]? with
    | some input => .ok input
    | none =>
        .error
          (malformedMiscFault shape op
            ("missing float occurrence " ++ toString occurrence))
  let resolution <-
    match inputShape.policy with
    | .rawBits => .ok (.rawBits input.rawValue)
    | .floatRValue => do
        let value <-
          resolveFloatRValue shape rawPrefix inputShape.operandIndex
            input.rawValue input.hostValue
        .ok (.floatRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def resolveIntsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawMiscOpShape)
    (operands : RawMiscOperands) :
    Nat -> List RawMiscIntInputShape ->
      Except Fault (List RawMiscResolvedIntInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let head <- resolveIntAt shape rawPrefix op operands occurrence inputShape
      let tail <-
        resolveIntsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def resolveFloatsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawMiscOpShape)
    (operands : RawMiscOperands) :
    Nat -> List RawMiscFloatInputShape ->
      Except Fault (List RawMiscResolvedFloatInput)
  | _, [] => .ok []
  | occurrence, inputShape :: rest => do
      let head <-
        resolveFloatAt shape rawPrefix op operands occurrence inputShape
      let tail <-
        resolveFloatsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok (head :: tail)

private def applyStorePolicy
    (policy : RawMiscStorePolicy)
    (value : Int) : Int :=
  match policy with
  | .identityI32 => value
  | .unsignedBits width => TouhouFormal.truncateUnsignedBits value width
  | .signedI16 => TouhouFormal.word16BitsToInt value

private def wordMaskSet (value : Int) (mask : Nat) : Bool :=
  if mask == 0 then
    false
  else
    (TouhouFormal.toWord32Bits value / mask) % 2 == 1

private def setWord32Bit (value : Int) (bit : Nat) (enabled : Bool) : Int :=
  let bits := TouhouFormal.toWord32Bits value
  let place : Int := 2 ^ bit
  let wasSet := TouhouFormal.word32BitSet bits bit
  if enabled then
    if wasSet then bits else TouhouFormal.toWord32Bits (bits + place)
  else if wasSet then
    TouhouFormal.toWord32Bits (bits - place)
  else
    bits

private def configurePauseEffect
    (operands : RawMiscOperands) : RawMiscPauseEffect :=
  let before := TouhouFormal.toWord32Bits operands.gameFlagsBefore
  let cleared7 := setWord32Bit before 7 false
  let cleared8 := setWord32Bit cleared7 8 false
  let selected := setWord32Bit cleared8 7 true
  let withoutPauseMode := setWord32Bit selected 13 false
  let bit14 := TouhouFormal.word32BitSet selected 14
  let stageSelected :=
    !bit14 && (operands.currentStage == 6 || operands.currentStage == 7)
  let spellSelected :=
    bit14 &&
      ((decide (0x8f <= operands.currentSpellCardNumber &&
          operands.currentSpellCardNumber <= 0x92)) ||
       (decide (0xab <= operands.currentSpellCardNumber &&
          operands.currentSpellCardNumber <= 0xbe)))
  { gameFlagsBefore := before
    gameFlagsAfter :=
      setWord32Bit withoutPauseMode 13 (stageSelected || spellSelected)
    stageSelectedPauseMode := stageSelected
    spellSelectedPauseMode := spellSelected
    enemyPauseTimerFlagSet := true }

private def signedI8 (value : Int) : Int :=
  let bits := TouhouFormal.truncateUnsignedBits value 8
  if bits < 128 then bits else bits - 256

private def advanceClockEffect (clock : Int) : RawMiscClockEffect :=
  let before := TouhouFormal.truncateUnsignedBits clock 8
  let beforeSigned := signedI8 before
  if beforeSigned < 12 then
    let after := TouhouFormal.truncateUnsignedBits (before + 1) 8
    let fast := signedI8 after == 12
    { clockBeforeBits := before
      clockBeforeSigned := beforeSigned
      advanced := true
      soundId := some 0x2d
      clockAfterBits := after
      fastFlash := fast
      slowFlash := !fast }
  else
    { clockBeforeBits := before
      clockBeforeSigned := beforeSigned
      advanced := false
      clockAfterBits := before
      fastFlash := false
      slowFlash := false }

private def intValueAt
    (values : List RawMiscResolvedIntInput)
    (index : Nat) : Int :=
  (values[index]?).map (fun value => value.resolution.value) |>.getD 0

private def floatBitsAt
    (values : List RawMiscResolvedFloatInput)
    (index : Nat) : Int :=
  (values[index]?).map (fun value => value.resolution.bits) |>.getD 0

def rawMiscPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawMiscOpShape)
    (operands : RawMiscOperands) :
    Except Fault RawMiscPrepared := do
  if op.intInputs.length != expectedIntCount op.kind then
    .error
      (malformedMiscFault shape op
        ("profile declares " ++ toString op.intInputs.length ++
          " integer inputs; expected " ++ toString (expectedIntCount op.kind)))
  else if op.floatInputs.length != expectedFloatCount op.kind then
    .error
      (malformedMiscFault shape op
        ("profile declares " ++ toString op.floatInputs.length ++
          " float inputs; expected " ++ toString (expectedFloatCount op.kind)))
  else
    let ints <- resolveIntsAux shape rawPrefix op operands 0 op.intInputs
    let floats <-
      resolveFloatsAux shape rawPrefix op operands 0 op.floatInputs
    let value0 := intValueAt ints 0
    let base : RawMiscPrepared :=
      { op := op, intResolutions := ints, floatResolutions := floats,
        effect := {} }
    match op.kind with
    | .noOp => .ok base
    | .writeInt target store =>
        .ok
          { base with effect.intWrites :=
              [ { target := target, value := applyStorePolicy store value0 } ] }
    | .writeTimer target =>
        .ok
          { base with effect.timerWrites :=
              [ { target := target
                  current := value0
                  subFrameBits := 0
                  previous := -999 } ] }
    | .setProjectile =>
        .ok
          { base with effect.intWrites :=
              [ { target := .enemyIsProjectile
                  value := TouhouFormal.truncateUnsignedBits value0 1 },
                { target := .enemyZLayer, value := 2 } ] }
    | .setSpecialInteraction =>
        .ok
          { base with effect.intWrites :=
              [ { target := .enemySpecialInteraction
                  value := TouhouFormal.truncateUnsignedBits value0 1 },
                { target := .enemyDrawGroup, value := 2 } ] }
    | .configureTrail =>
        let flags := TouhouFormal.truncateUnsignedBits value0 8
        let history := TouhouFormal.word16BitsToInt (intValueAt ints 1)
        let collision := TouhouFormal.word16BitsToInt (intValueAt ints 2)
        let stride := TouhouFormal.word16BitsToInt (intValueAt ints 3)
        let shouldInitialize :=
          wordMaskSet flags op.trailRenderMask
        let trailBase : RawMiscTrailEffect :=
          { flags := flags
            historyLength := history
            collisionLength := collision
            sampleStride := stride
            stripInitializationRequested := shouldInitialize }
        if shouldInitialize && stride == 0 then
          let fault := trailDivideByZeroFault shape op
          .ok
            { base with
              effect.trail := some trailBase
              hostFault := some fault }
        else
          let trailEffect : RawMiscTrailEffect :=
            { trailBase with stripVertexCount :=
                (if shouldInitialize then
                  some (Int.tdiv history stride * 2)
                else
                  none) }
          .ok { base with effect.trail := some trailEffect }
    | .addCherry =>
        .ok { base with effect.cherryDelta := some value0 }
    | .stageUnpause =>
        .ok { base with effect.stageUnpauseWrite := some 1 }
    | .configurePause =>
        .ok { base with effect.pause := some (configurePauseEffect operands) }
    | .setMinimumPlayerDistance =>
        let distanceEffect : RawMiscMinimumDistanceEffect :=
          { resolvedDistanceBits := floatBitsAt floats 0
            squaredDistanceBits :=
              TouhouFormal.toWord32Bits operands.minimumDistanceSquaredBits }
        .ok { base with effect.minimumDistance := some distanceEffect }
    | .gui action =>
        .ok { base with effect.guiAction := some action }
    | .advanceClock =>
        .ok { base with effect.clock := some (advanceClockEffect operands.clockBits) }

def rawMiscStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawMiscOperands) :
    Except Fault RawMiscOutcome :=
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
          .ok (rawMiscCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawMiscCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findMiscOp? rawPrefix.opcode with
          | none => .ok (rawMiscCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawMiscPrepare shape rawPrefix op operands
              let action :=
                if prepared.hostFault.isSome then
                  RawMiscAction.hostFault
                else
                  RawMiscAction.advanced
              .ok
                (rawMiscCursorOutcome action rawPrefix bufferSize
                  (some prepared.effect) prepared.hostFault (some prepared))

end TouhouFormal.ECL
