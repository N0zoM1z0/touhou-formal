import TouhouFormal.ECL.Step
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Symbolic

inductive Title where
  | th06
  | th07
  | th08
deriving Repr, DecidableEq

def Title.name : Title -> String
  | .th06 => "th06"
  | .th07 => "th07"
  | .th08 => "th08"

def Title.headerShape : Title -> TouhouFormal.ECL.HeaderShape
  | .th06 => TouhouFormal.TH06.headerShape
  | .th07 => TouhouFormal.TH07.headerShape
  | .th08 => TouhouFormal.TH08.headerShape

def Title.parse? : String -> Option Title
  | "th06" => some .th06
  | "th07" => some .th07
  | "th08" => some .th08
  | _ => none

inductive CursorGoal where
  | beforeBuffer
  | nonProgress
  | inBounds
  | atOrPastEnd
deriving Repr, DecidableEq

def CursorGoal.name : CursorGoal -> String
  | .beforeBuffer => "before-buffer"
  | .nonProgress => "non-progress"
  | .inBounds => "in-bounds"
  | .atOrPastEnd => "at-or-past-end"

inductive RawStepPath where
  | yielded
  | skipped (cursor : CursorGoal)
  | advanced (cursor : CursorGoal)
  | jumped (cursor : CursorGoal)
  | vmError
deriving Repr, DecidableEq

def RawStepPath.name : RawStepPath -> String
  | .yielded => "yielded"
  | .skipped cursor => "skipped-" ++ cursor.name
  | .advanced cursor => "advanced-" ++ cursor.name
  | .jumped cursor => "jumped-" ++ cursor.name
  | .vmError => "vm-error"

def RawStepPath.parse? : String -> Option RawStepPath
  | "yielded" => some .yielded
  | "skipped-before-buffer" => some (.skipped .beforeBuffer)
  | "skipped-non-progress" => some (.skipped .nonProgress)
  | "skipped-in-bounds" => some (.skipped .inBounds)
  | "skipped-at-or-past-end" => some (.skipped .atOrPastEnd)
  | "advanced-before-buffer" => some (.advanced .beforeBuffer)
  | "advanced-non-progress" => some (.advanced .nonProgress)
  | "advanced-in-bounds" => some (.advanced .inBounds)
  | "advanced-at-or-past-end" => some (.advanced .atOrPastEnd)
  | "jumped-before-buffer" => some (.jumped .beforeBuffer)
  | "jumped-non-progress" => some (.jumped .nonProgress)
  | "jumped-in-bounds" => some (.jumped .inBounds)
  | "jumped-at-or-past-end" => some (.jumped .atOrPastEnd)
  | "vm-error" => some .vmError
  | _ => none

def allCursorGoals : List CursorGoal :=
  [ .beforeBuffer, .nonProgress, .inBounds, .atOrPastEnd ]

def allRawStepPaths : List RawStepPath :=
  [ .yielded ] ++
    allCursorGoals.map RawStepPath.skipped ++
    allCursorGoals.map RawStepPath.advanced ++
    allCursorGoals.map RawStepPath.jumped ++
    [ .vmError ]

private def joinLines : List String -> String
  | [] => ""
  | line :: rest => line ++ "\n" ++ joinLines rest

private def signedI16Range (name : String) : String :=
  "(assert (and (<= (- 32768) " ++ name ++ ") (<= " ++ name ++ " 32767)))"

private def signedI32Range (name : String) : String :=
  "(assert (and (<= (- 2147483648) " ++ name ++ ") (<= " ++ name ++ " 2147483647)))"

private def scalarRange (name : String) : TouhouFormal.ScalarWidth -> String
  | .u8 => "(assert (and (<= 0 " ++ name ++ ") (<= " ++ name ++ " 255)))"
  | .u16 => "(assert (and (<= 0 " ++ name ++ ") (<= " ++ name ++ " 65535)))"
  | .u32 => "(assert (and (<= 0 " ++ name ++ ") (<= " ++ name ++ " 4294967295)))"
  | .i16 => signedI16Range name
  | .i32 => signedI32Range name

private def operandMaskSmtLines (rawShape : TouhouFormal.ECL.RawInstrShape) : List String :=
  match rawShape.operandMaskWidth with
  | none => ["(define-fun operandMask () Int 0)"]
  | some width =>
      [ "(declare-const operandMask Int)"
      , scalarRange "operandMask" width ]

private def hexDigit : Nat -> String
  | 0 => "0"
  | 1 => "1"
  | 2 => "2"
  | 3 => "3"
  | 4 => "4"
  | 5 => "5"
  | 6 => "6"
  | 7 => "7"
  | 8 => "8"
  | 9 => "9"
  | 10 => "a"
  | 11 => "b"
  | 12 => "c"
  | 13 => "d"
  | 14 => "e"
  | _ => "f"

private def bv8 (value : Nat) : String :=
  "#x" ++ hexDigit ((value / 16) % 16) ++ hexDigit (value % 16)

private def difficultyPassExpr : TouhouFormal.ECL.DifficultyMaskPolicy -> String
  | .intersectsActive =>
      "(not (= (bvand instructionMask activeMask) #x00))"
  | .containsActiveAndOverride =>
      "(= (bvand instructionMask requiredDifficultyMask) requiredDifficultyMask)"

private def cursorGoalAssertion (targetName : String) : CursorGoal -> String
  | .beforeBuffer => "(assert (< " ++ targetName ++ " 0))"
  | .nonProgress => "(assert (= " ++ targetName ++ " fileOffset))"
  | .inBounds =>
      "(assert (and (<= 0 " ++ targetName ++ ") (< " ++ targetName ++ " bufferSize) (not (= " ++
        targetName ++ " fileOffset))))"
  | .atOrPastEnd => "(assert (<= bufferSize " ++ targetName ++ "))"

private def maxJumpOperandIndex (jumpShape : TouhouFormal.ECL.RawFixedJumpShape) : Nat :=
  Nat.max jumpShape.targetTimeOperandIndex jumpShape.displacementOperandIndex

private def requiredInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawStepPath) : Nat :=
  match path with
  | .jumped _ =>
      match rawShape.fixedJumpShape, rawShape.fixedI32OperandBaseOffset with
      | some jumpShape, some baseOffset =>
          baseOffset + rawShape.fixedI32OperandStride * (maxJumpOperandIndex jumpShape + 1)
      | _, _ => rawShape.fixedPrefixBytes
  | _ => rawShape.fixedPrefixBytes

private def opcodeExclusions (rawShape : TouhouFormal.ECL.RawInstrShape) : List Int :=
  let excludeJump :=
    match rawShape.fixedJumpShape with
    | none => []
    | some jumpShape => [jumpShape.opcode]
  let excludeUnimp :=
    match rawShape.unimplementedOpcode with
    | none => []
    | some opcode => [opcode]
  excludeJump ++ excludeUnimp

private def notOpcodeAssertions (opcodes : List Int) : List String :=
  opcodes.map fun opcode => "(assert (not (= opcode " ++ toString opcode ++ ")))"

private def rawStepPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawStepPath) : List String :=
  let jumpOpcodeConstraints :=
    match rawShape.fixedJumpShape with
    | none => ["(assert false) ; profile has no fixed-jump opcode"]
    | some jumpShape => ["(assert (= opcode " ++ toString jumpShape.opcode ++ "))"]
  let unimpConstraints :=
    match rawShape.unimplementedOpcode with
    | none => ["(assert false) ; profile has no modeled VM-error opcode"]
    | some opcode => ["(assert (= opcode " ++ toString opcode ++ "))"]
  match path with
  | .yielded =>
      ["(assert (not (= currentTime instrTime)))"]
  | .skipped cursor =>
      [ "(assert (= currentTime instrTime))"
      , "(assert (not difficultyPass))"
      , "(define-fun targetCursor () Int (+ fileOffset nextOffset))"
      , cursorGoalAssertion "targetCursor" cursor ]
  | .advanced cursor =>
      [ "(assert (= currentTime instrTime))"
      , "(assert difficultyPass)"
      , "(define-fun targetCursor () Int (+ fileOffset nextOffset))"
      , cursorGoalAssertion "targetCursor" cursor ] ++
      notOpcodeAssertions (opcodeExclusions rawShape)
  | .jumped cursor =>
      [ "(assert (= currentTime instrTime))"
      , "(assert difficultyPass)"
      , "(define-fun targetCursor () Int (+ fileOffset jumpDisplacement))"
      , cursorGoalAssertion "targetCursor" cursor ] ++
      jumpOpcodeConstraints
  | .vmError =>
      [ "(assert (= currentTime instrTime))"
      , "(assert difficultyPass)" ] ++
      unimpConstraints

private def rawStepValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask jumpTargetTime jumpDisplacement bufferSize difficultyPass)"

private def rawStepQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawStepPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL step query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared raw ECL single-step semantics."
         , "; Title: " ++ shape.title
         , "; Path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const jumpTargetTime Int)"
         , "(declare-const jumpDisplacement Int)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI32Range "jumpTargetTime"
         , signedI32Range "jumpDisplacement"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (and (<= " ++ toString (requiredInstructionBytes rawShape path) ++
             " bufferSize) (<= bufferSize 1048576)))" ] ++
         operandMaskSmtLines rawShape ++
         rawStepPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawStepValueTerms ++ ")"] else []))

def rawStepQuery
    (title : Title)
    (path : RawStepPath)
    (activeMask overrideMask : Nat) : String :=
  rawStepQueryWith true false title path activeMask overrideMask

def rawStepValuesQuery
    (title : Title)
    (path : RawStepPath)
    (activeMask overrideMask : Nat) : String :=
  rawStepQueryWith false true title path activeMask overrideMask

def listRawStepPathsText : String :=
  joinLines (allRawStepPaths.map RawStepPath.name)

structure RawStepWitness where
  currentTime : Int
  instrTime : Int
  opcode : Int
  nextOffset : Int
  instructionMask : Nat
  operandMask : Int
  activeMask : Nat
  overrideMask : Nat
  jumpTargetTime : Int
  jumpDisplacement : Int
  bufferSize : Nat
deriving Repr, DecidableEq

structure RawStepMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  jump : Option TouhouFormal.ECL.RawJumpOperands
  outcome : TouhouFormal.ECL.RawStepOutcome
  matchesPath : Bool
deriving Repr, DecidableEq

structure RawStepEclFileMaterialization where
  rawStep : RawStepMaterialization
  eclFile : TouhouFormal.Bytes
  subOffset : Nat
deriving Repr, DecidableEq

private partial def writeAt
    (bytes : TouhouFormal.Bytes)
    (offset : Nat) :
    List UInt8 -> Option TouhouFormal.Bytes
  | [] => some bytes
  | byte :: rest =>
      if offset < bytes.size then
        writeAt (bytes.set! offset byte) (offset + 1) rest
      else
        none

private def writeScalar
    (bytes : TouhouFormal.Bytes)
    (offset : Nat)
    (width : TouhouFormal.ScalarWidth)
    (value : Int)
    (fieldName : String) : Except String TouhouFormal.Bytes :=
  match width.encodeLE? value with
  | none =>
      .error
        ("cannot encode " ++ fieldName ++ "=" ++ toString value ++
          " as " ++ reprStr width)
  | some encoded =>
      match writeAt bytes offset encoded with
      | none =>
          .error
            ("field " ++ fieldName ++ " at offset " ++ toString offset ++
              " does not fit in buffer")
      | some updated => .ok updated

private def writeOptionalScalar
    (bytes : TouhouFormal.Bytes)
    (fieldName : String)
    (offset? : Option Nat)
    (width? : Option TouhouFormal.ScalarWidth)
    (value : Int) : Except String TouhouFormal.Bytes :=
  match offset?, width? with
  | some offset, some width => writeScalar bytes offset width value fieldName
  | none, none => .ok bytes
  | _, _ => .error ("profile has partial optional field shape for " ++ fieldName)

private def liftFaultToString {α : Type} : Except TouhouFormal.Fault α -> Except String α
  | .ok value => .ok value
  | .error faultValue => .error faultValue.describe

def rawStepWitnessBytes
    (title : Title)
    (path : RawStepPath)
    (witness : RawStepWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required raw instruction bytes=" ++ toString requiredBytes)
      else if 255 < witness.instructionMask then
        .error "instructionMask must fit in an unsigned byte"
      else if 255 < witness.activeMask || 255 < witness.overrideMask then
        .error "activeMask and overrideMask must fit in an unsigned byte"
      else
        let initial : TouhouFormal.Bytes := (TouhouFormal.zeroBytes witness.bufferSize).toArray
        let bytes <- writeScalar initial rawShape.timeOffset rawShape.timeWidth witness.instrTime "time"
        let bytes <- writeScalar bytes rawShape.opcodeOffset rawShape.opcodeWidth witness.opcode "opcode"
        let bytes <-
          writeScalar
            bytes
            rawShape.nextOffsetOffset
            rawShape.nextOffsetWidth
            witness.nextOffset
            "nextOffset"
        let bytes <-
          writeOptionalScalar
            bytes
            "difficultyMask"
            rawShape.difficultyMaskOffset
            rawShape.difficultyMaskWidth
            (Int.ofNat witness.instructionMask)
        let bytes <-
          writeOptionalScalar
            bytes
            "operandMask"
            rawShape.operandMaskOffset
            rawShape.operandMaskWidth
            witness.operandMask
        match path, rawShape.fixedJumpShape, rawShape.fixedI32OperandBaseOffset with
        | .jumped _, some jumpShape, some baseOffset =>
            let bytes <-
              writeScalar
                bytes
                (baseOffset + rawShape.fixedI32OperandStride * jumpShape.targetTimeOperandIndex)
                .i32
                witness.jumpTargetTime
                "jumpTargetTime"
            writeScalar
              bytes
              (baseOffset + rawShape.fixedI32OperandStride * jumpShape.displacementOperandIndex)
              .i32
              witness.jumpDisplacement
              "jumpDisplacement"
        | .jumped _, _, _ =>
            .error ("profile has no fixed jump operand shape for " ++ shape.title)
        | _, _, _ => .ok bytes

private def decodeJumpForWitness
    (title : Title)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String (Option TouhouFormal.ECL.RawJumpOperands) :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.fixedJumpShape with
      | some jumpShape =>
          if rawPrefix.opcode == jumpShape.opcode then
            match liftFaultToString (TouhouFormal.ECL.decodeProfileFixedJumpOperands shape bytes rawPrefix) with
            | .ok jump => .ok (some jump)
            | .error message => .error message
          else
            .ok none
      | none => .ok none

private def CursorGoal.toCursorClass : CursorGoal -> TouhouFormal.CursorClass
  | .beforeBuffer => .beforeBuffer
  | .nonProgress => .nonProgress
  | .inBounds => .inBounds
  | .atOrPastEnd => .atOrPastEnd

private def RawStepPath.matchesOutcome
    (path : RawStepPath)
    (outcome : TouhouFormal.ECL.RawStepOutcome) : Bool :=
  match path, outcome.action, outcome.cursorClass with
  | .yielded, .yielded, _ => true
  | .skipped cursor, .skipped, some actual => actual == cursor.toCursorClass
  | .advanced cursor, .advanced, some actual => actual == cursor.toCursorClass
  | .jumped cursor, .jumped, some actual => actual == cursor.toCursorClass
  | .vmError, .vmError, _ => true
  | _, _, _ => false

def rawStepMaterialize
    (title : Title)
    (path : RawStepPath)
    (witness : RawStepWitness) : Except String RawStepMaterialization := do
  let shape := title.headerShape
  let bytes <- rawStepWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix shape bytes 0)
  let jump <- decodeJumpForWitness title bytes rawPrefix
  let outcome <-
    liftFaultToString
      (TouhouFormal.ECL.rawStep
        shape
        witness.currentTime
        witness.activeMask
        witness.overrideMask
        8
        witness.bufferSize
        rawPrefix
        jump)
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      jump := jump
      outcome := outcome
      matchesPath := path.matchesOutcome outcome }

private def rawStepActionName : TouhouFormal.ECL.RawStepAction -> String
  | .yielded => "yielded"
  | .skipped => "skipped"
  | .advanced => "advanced"
  | .jumped => "jumped"
  | .vmError => "vm-error"

private def optionIntText : Option Int -> String
  | none => "-"
  | some value => toString value

private def optionCursorClassText : Option TouhouFormal.CursorClass -> String
  | none => "-"
  | some cursorClass => cursorClass.name

private def byteHex (byte : UInt8) : String :=
  hexDigit ((byte.toNat / 16) % 16) ++ hexDigit (byte.toNat % 16)

private def concatStrings : List String -> String
  | [] => ""
  | value :: rest => value ++ concatStrings rest

def bytesHex (bytes : TouhouFormal.Bytes) : String :=
  concatStrings (bytes.toList.map byteHex)

def RawStepMaterialization.report (materialization : RawStepMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "action=" ++ rawStepActionName materialization.outcome.action
    , "targetCursor=" ++ optionIntText materialization.outcome.targetCursor
    , "cursorClass=" ++ optionCursorClassText materialization.outcome.cursorClass
    , "targetTime=" ++ optionIntText materialization.outcome.targetTime
    , "matchesPath=" ++ toString materialization.matchesPath ]

private def writeOptionalVersion
    (bytes : TouhouFormal.Bytes)
    (shape : TouhouFormal.ECL.HeaderShape) : Except String TouhouFormal.Bytes :=
  match shape.expectedVersion, shape.versionOffset with
  | some version, some offset => writeScalar bytes offset .u32 (Int.ofNat version) "version"
  | none, none => .ok bytes
  | _, _ => .error ("profile has partial version field shape for " ++ shape.title)

def rawStepEclFileMaterialize
    (title : Title)
    (path : RawStepPath)
    (witness : RawStepWitness) : Except String RawStepEclFileMaterialization := do
  let materialization <- rawStepMaterialize title path witness
  let shape := title.headerShape
  let subOffset := shape.fixedHeaderBytes + 4
  let totalSize := subOffset + materialization.bytes.size
  let initial : TouhouFormal.Bytes := (TouhouFormal.zeroBytes totalSize).toArray
  let bytes <- writeOptionalVersion initial shape
  let bytes <- writeScalar bytes shape.subCountOffset .i16 1 "subCount"
  let bytes <- writeScalar bytes shape.timelineCountOffset .i16 0 "timelineCount"
  let bytes <- writeScalar bytes shape.fixedHeaderBytes .u32 (Int.ofNat subOffset) "subOffset[0]"
  let bytes <-
    match writeAt bytes subOffset materialization.bytes.toList with
    | some updated => .ok updated
    | none => .error "raw instruction bytes did not fit in generated ECL file"
  .ok
    { rawStep := materialization
      eclFile := bytes
      subOffset := subOffset }

def RawStepEclFileMaterialization.report
    (materialization : RawStepEclFileMaterialization) : String :=
  joinLines
    [ "rawInstructionSize=" ++ toString materialization.rawStep.bytes.size
    , "rawInstructionHex=" ++ bytesHex materialization.rawStep.bytes
    , "eclFileSize=" ++ toString materialization.eclFile.size
    , "eclFileHex=" ++ bytesHex materialization.eclFile
    , "subOffset=" ++ toString materialization.subOffset
    , "action=" ++ rawStepActionName materialization.rawStep.outcome.action
    , "targetCursor=" ++ optionIntText materialization.rawStep.outcome.targetCursor
    , "cursorClass=" ++ optionCursorClassText materialization.rawStep.outcome.cursorClass
    , "targetTime=" ++ optionIntText materialization.rawStep.outcome.targetTime
    , "matchesPath=" ++ toString materialization.rawStep.matchesPath ]

def th08ConcreteJumpBeforeBufferStep : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome :=
  TouhouFormal.ECL.rawStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    20
    { fileOffset := 0
      time := 0
      opcode := TouhouFormal.TH08.eclOpcodeJump
      nextOffset := 12
      difficultyMask := some 1
      operandMask := some 0 }
    (some { targetTime := 0, displacement := -1 })

def th08ConcreteOverrideSkipStep : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome :=
  TouhouFormal.ECL.rawStep
    TouhouFormal.TH08.headerShape
    0
    1
    2
    8
    64
    { fileOffset := 0
      time := 0
      opcode := TouhouFormal.TH08.eclOpcodeJump
      nextOffset := 12
      difficultyMask := some 1
      operandMask := some 0 }
    (some { targetTime := 0, displacement := -1 })

theorem th08_concrete_jump_before_buffer_step :
    th08ConcreteJumpBeforeBufferStep =
      .ok
        { action := .jumped
          targetCursor := some (-1)
          cursorClass := some .beforeBuffer
          targetTime := some 0 } := by
  rfl

theorem th08_concrete_override_skip_precedes_jump_effect :
    th08ConcreteOverrideSkipStep =
      .ok
        { action := .skipped
          targetCursor := some 12
          cursorClass := some .inBounds
          targetTime := none } := by
  rfl

end TouhouFormal.Search.Symbolic
