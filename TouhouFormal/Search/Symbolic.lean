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

def rawStepQuery
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
         rawStepPathConstraints rawShape path ++
         [ "(check-sat)", "(get-model)" ])

def listRawStepPathsText : String :=
  joinLines (allRawStepPaths.map RawStepPath.name)

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
