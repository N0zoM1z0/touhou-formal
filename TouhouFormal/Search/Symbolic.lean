import TouhouFormal.ECL.Body
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

inductive RawBodyPath where
  | decJumpTaken (cursor : CursorGoal)
  | decJumpNotTaken (cursor : CursorGoal)
  | intCondJumpTaken (cursor : CursorGoal)
  | intCondJumpNotTaken (cursor : CursorGoal)
  | intDivisorZero
deriving Repr, DecidableEq

def RawBodyPath.name : RawBodyPath -> String
  | .decJumpTaken cursor => "decjump-taken-" ++ cursor.name
  | .decJumpNotTaken cursor => "decjump-not-taken-" ++ cursor.name
  | .intCondJumpTaken cursor => "int-condjump-taken-" ++ cursor.name
  | .intCondJumpNotTaken cursor => "int-condjump-not-taken-" ++ cursor.name
  | .intDivisorZero => "int-divisor-zero"

def RawBodyPath.parse? : String -> Option RawBodyPath
  | "decjump-taken-before-buffer" => some (.decJumpTaken .beforeBuffer)
  | "decjump-taken-non-progress" => some (.decJumpTaken .nonProgress)
  | "decjump-taken-in-bounds" => some (.decJumpTaken .inBounds)
  | "decjump-taken-at-or-past-end" => some (.decJumpTaken .atOrPastEnd)
  | "decjump-not-taken-before-buffer" => some (.decJumpNotTaken .beforeBuffer)
  | "decjump-not-taken-non-progress" => some (.decJumpNotTaken .nonProgress)
  | "decjump-not-taken-in-bounds" => some (.decJumpNotTaken .inBounds)
  | "decjump-not-taken-at-or-past-end" => some (.decJumpNotTaken .atOrPastEnd)
  | "int-condjump-taken-before-buffer" => some (.intCondJumpTaken .beforeBuffer)
  | "int-condjump-taken-non-progress" => some (.intCondJumpTaken .nonProgress)
  | "int-condjump-taken-in-bounds" => some (.intCondJumpTaken .inBounds)
  | "int-condjump-taken-at-or-past-end" => some (.intCondJumpTaken .atOrPastEnd)
  | "int-condjump-not-taken-before-buffer" => some (.intCondJumpNotTaken .beforeBuffer)
  | "int-condjump-not-taken-non-progress" => some (.intCondJumpNotTaken .nonProgress)
  | "int-condjump-not-taken-in-bounds" => some (.intCondJumpNotTaken .inBounds)
  | "int-condjump-not-taken-at-or-past-end" => some (.intCondJumpNotTaken .atOrPastEnd)
  | "int-divisor-zero" => some .intDivisorZero
  | _ => none

def allRawBodyPaths : List RawBodyPath :=
  allCursorGoals.map RawBodyPath.decJumpTaken ++
    allCursorGoals.map RawBodyPath.decJumpNotTaken ++
    allCursorGoals.map RawBodyPath.intCondJumpTaken ++
    allCursorGoals.map RawBodyPath.intCondJumpNotTaken ++
    [ .intDivisorZero ]

inductive RawIntResolverPath where
  | rawImmediate
  | resolvedHost
  | resolvedDefaultRaw
deriving Repr, DecidableEq

def RawIntResolverPath.name : RawIntResolverPath -> String
  | .rawImmediate => "raw-immediate"
  | .resolvedHost => "resolved-host"
  | .resolvedDefaultRaw => "resolved-default-raw"

def RawIntResolverPath.parse? : String -> Option RawIntResolverPath
  | "raw-immediate" => some .rawImmediate
  | "resolved-host" => some .resolvedHost
  | "resolved-default-raw" => some .resolvedDefaultRaw
  | _ => none

def allRawIntResolverPaths : List RawIntResolverPath :=
  [ .rawImmediate, .resolvedHost, .resolvedDefaultRaw ]

private def joinLines : List String -> String
  | [] => ""
  | line :: rest => line ++ "\n" ++ joinLines rest

private def joinWith (sep : String) : List String -> String
  | [] => ""
  | value :: [] => value
  | value :: rest => value ++ sep ++ joinWith sep rest

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

private def maxDecJumpOperandIndex (decJumpShape : TouhouFormal.ECL.RawDecJumpShape) : Nat :=
  Nat.max
    (Nat.max decJumpShape.targetTimeOperandIndex decJumpShape.displacementOperandIndex)
    decJumpShape.counterOperandIndex

private def maxIntConditionJumpOperandIndex
    (condShape : TouhouFormal.ECL.RawIntConditionJumpShape) : Nat :=
  Nat.max
    (Nat.max condShape.lhsOperandIndex condShape.rhsOperandIndex)
    (Nat.max condShape.targetTimeOperandIndex condShape.displacementOperandIndex)

private def maxNatList (values : List Nat) : Nat :=
  values.foldl (fun acc value => Nat.max acc value) 0

private def intSelectorRangePredicate
    (valueName : String)
    (range : TouhouFormal.ECL.IntSelectorRange) : String :=
  "(and (<= " ++ toString range.first ++ " " ++ valueName ++ ") (<= " ++
    valueName ++ " " ++ toString range.last ++ "))"

private def intSelectorSetPredicate
    (valueName : String)
    (set : TouhouFormal.ECL.IntSelectorSet) : String :=
  let rangePredicate :=
    match set.ranges with
    | [] => "false"
    | [range] => intSelectorRangePredicate valueName range
    | _ =>
        "(or " ++
          joinWith " " (set.ranges.map (intSelectorRangePredicate valueName)) ++
          ")"
  let exclusionPredicate :=
    match set.exclusions with
    | [] => "true"
    | exclusions =>
        "(and " ++
          joinWith " " (exclusions.map fun value =>
            "(not (= " ++ valueName ++ " " ++ toString value ++ "))") ++
          ")"
  "(and " ++ rangePredicate ++ " " ++ exclusionPredicate ++ ")"

private def intMaskBitSetPredicate (maskName : String) (slot : Nat) : String :=
  "(= (mod (div " ++ maskName ++ " " ++ toString (2 ^ slot) ++ ") 2) 1)"

private def intResolverSwitchPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (maskName : String) : String :=
  match resolver.maskPolicy with
  | .noMaskAlwaysResolve => "true"
  | .bitSetMeansResolve => intMaskBitSetPredicate maskName slot

private def rawIntResolvedValueAssertions
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (rawName hostName resolvedName : String) : List String :=
  let switchPredicate := intResolverSwitchPredicate resolver slot "operandMask"
  let knownPredicate := intSelectorSetPredicate rawName resolver.knownRValueSelectors
  [ "(define-fun " ++ resolvedName ++ " () Int (ite (and " ++ switchPredicate ++
      " " ++ knownPredicate ++ ") " ++ hostName ++ " " ++ rawName ++ "))" ]

private def rawIntComparePredicate
    (op : TouhouFormal.ECL.RawIntCompareOp)
    (lhs rhs : String) : String :=
  match op with
  | .eq => "(= " ++ lhs ++ " " ++ rhs ++ ")"
  | .neq => "(not (= " ++ lhs ++ " " ++ rhs ++ "))"
  | .lt => "(< " ++ lhs ++ " " ++ rhs ++ ")"
  | .le => "(<= " ++ lhs ++ " " ++ rhs ++ ")"
  | .gt => "(> " ++ lhs ++ " " ++ rhs ++ ")"
  | .ge => "(>= " ++ lhs ++ " " ++ rhs ++ ")"

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

private def requiredBodyInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawBodyPath) : Nat :=
  match path with
  | .decJumpTaken _ | .decJumpNotTaken _ =>
      match rawShape.fixedDecJumpShape, rawShape.fixedI32OperandBaseOffset with
      | some decJumpShape, some baseOffset =>
          baseOffset + rawShape.fixedI32OperandStride * (maxDecJumpOperandIndex decJumpShape + 1)
      | _, _ => rawShape.fixedPrefixBytes
  | .intCondJumpTaken _ | .intCondJumpNotTaken _ =>
      match rawShape.fixedI32OperandBaseOffset with
      | some baseOffset =>
          let maxOperand :=
            maxNatList (rawShape.intConditionJumps.map maxIntConditionJumpOperandIndex)
          if rawShape.intConditionJumps.isEmpty then
            rawShape.fixedPrefixBytes
          else
            baseOffset + rawShape.fixedI32OperandStride * (maxOperand + 1)
      | none => rawShape.fixedPrefixBytes
  | .intDivisorZero =>
      match rawShape.fixedI32OperandBaseOffset with
      | some baseOffset =>
          let maxOperand :=
            maxNatList (rawShape.intDivisorHazards.map (fun hazard => hazard.divisorOperandIndex))
          if rawShape.intDivisorHazards.isEmpty then
            rawShape.fixedPrefixBytes
          else
            baseOffset + rawShape.fixedI32OperandStride * (maxOperand + 1)
      | none => rawShape.fixedPrefixBytes

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

private def opcodeSetAssertion (opcodes : List Int) : String :=
  match opcodes with
  | [] => "(assert false) ; no source-backed opcode for this body path"
  | [opcode] => "(assert (= opcode " ++ toString opcode ++ "))"
  | _ =>
      "(assert (or " ++
        joinWith " " (opcodes.map fun opcode => "(= opcode " ++ toString opcode ++ ")") ++
        "))"

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

private def intConditionJumpCasePredicate
    (condShape : TouhouFormal.ECL.RawIntConditionJumpShape)
    (taken : Bool) : String :=
  let condition :=
    match condShape.source with
    | .compareRegister => rawIntComparePredicate condShape.op "compareRegister" "0"
    | .resolvedOperands => rawIntComparePredicate condShape.op "lhsResolvedValue" "rhsResolvedValue"
  "(and (= opcode " ++ toString condShape.opcode ++ ") " ++
    (if taken then condition else "(not " ++ condition ++ ")") ++
    ")"

private def intConditionJumpPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (taken : Bool)
    (cursor : CursorGoal) : List String :=
  let opcodeCondition :=
    match rawShape.intConditionJumps with
    | [] => "(assert false) ; profile has no integer conditional-jump opcodes"
    | [condShape] => "(assert " ++ intConditionJumpCasePredicate condShape taken ++ ")"
    | condShapes =>
        "(assert (or " ++
          joinWith " " (condShapes.map fun condShape =>
            intConditionJumpCasePredicate condShape taken) ++
          "))"
  let resolverLines :=
    match rawShape.intRValueResolver with
    | none => []
    | some resolver =>
        rawIntResolvedValueAssertions resolver 0 "lhsRaw" "lhsHost" "lhsResolvedValue" ++
          rawIntResolvedValueAssertions resolver 1 "rhsRaw" "rhsHost" "rhsResolvedValue"
  resolverLines ++
    [ opcodeCondition
    , "(define-fun targetCursor () Int (+ fileOffset " ++
        (if taken then "jumpDisplacement" else "nextOffset") ++ "))"
    , cursorGoalAssertion "targetCursor" cursor ]

private def rawBodyPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawBodyPath) : List String :=
  let decJumpOpcodeConstraints :=
    match rawShape.fixedDecJumpShape with
    | none => ["(assert false) ; profile has no JUMPDEC opcode"]
    | some decJumpShape => ["(assert (= opcode " ++ toString decJumpShape.opcode ++ "))"]
  let divisorHazardOpcodes :=
    rawShape.intDivisorHazards.map (fun hazard => hazard.opcode)
  let dispatchPrefix :=
    [ "(assert (= currentTime instrTime))"
    , "(assert difficultyPass)" ]
  let immediateDispatchPrefix :=
    [ "(assert (= currentTime instrTime))"
    , "(assert difficultyPass)"
    , "(assert (= operandMask 0)) ; immediate/raw operand branch" ]
  match path with
  | .decJumpTaken cursor =>
      immediateDispatchPrefix ++
      decJumpOpcodeConstraints ++
      [ "(assert (> (- counterBefore 1) 0))"
      , "(define-fun targetCursor () Int (+ fileOffset jumpDisplacement))"
      , cursorGoalAssertion "targetCursor" cursor ]
  | .decJumpNotTaken cursor =>
      immediateDispatchPrefix ++
      decJumpOpcodeConstraints ++
      [ "(assert (<= (- counterBefore 1) 0))"
      , "(define-fun targetCursor () Int (+ fileOffset nextOffset))"
      , cursorGoalAssertion "targetCursor" cursor ]
  | .intCondJumpTaken cursor =>
      dispatchPrefix ++
        intConditionJumpPathConstraints rawShape true cursor
  | .intCondJumpNotTaken cursor =>
      dispatchPrefix ++
        intConditionJumpPathConstraints rawShape false cursor
  | .intDivisorZero =>
      immediateDispatchPrefix ++
      [ opcodeSetAssertion divisorHazardOpcodes
      , "(assert (= divisorValue 0))" ]

private def rawIntResolverPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawIntResolverPath)
    (slot : Nat) : List String :=
  match rawShape.intRValueResolver with
  | none => ["(assert false) ; profile has no integer rvalue resolver"]
  | some resolver =>
      let switchPredicate := intResolverSwitchPredicate resolver slot "operandMask"
      let knownPredicate := intSelectorSetPredicate "rawValue" resolver.knownRValueSelectors
      match path with
      | .rawImmediate =>
          match resolver.maskPolicy with
          | .noMaskAlwaysResolve =>
              ["(assert false) ; this title has no mask-clear immediate branch"]
          | .bitSetMeansResolve =>
              [ "(assert (not " ++ switchPredicate ++ "))" ]
      | .resolvedHost =>
          [ "(assert " ++ switchPredicate ++ ")"
          , "(assert " ++ knownPredicate ++ ")" ]
      | .resolvedDefaultRaw =>
          [ "(assert " ++ switchPredicate ++ ")"
          , "(assert (not " ++ knownPredicate ++ "))" ]

private def rawStepValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask jumpTargetTime jumpDisplacement bufferSize difficultyPass)"

private def rawBodyValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask jumpTargetTime jumpDisplacement counterBefore divisorValue lhsRaw rhsRaw lhsHost rhsHost compareRegister bufferSize difficultyPass)"

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

private def rawBodyQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawBodyPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL body query"
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
         , "; Symbolic execution query generated from shared raw ECL body semantics."
         , "; Title: " ++ shape.title
         , "; Body path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const jumpTargetTime Int)"
         , "(declare-const jumpDisplacement Int)"
         , "(declare-const counterBefore Int)"
         , "(declare-const divisorValue Int)"
         , "(declare-const lhsRaw Int)"
         , "(declare-const rhsRaw Int)"
         , "(declare-const lhsHost Int)"
         , "(declare-const rhsHost Int)"
         , "(declare-const compareRegister Int)"
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
         , signedI32Range "counterBefore"
         , signedI32Range "divisorValue"
         , signedI32Range "lhsRaw"
         , signedI32Range "rhsRaw"
         , signedI32Range "lhsHost"
         , signedI32Range "rhsHost"
         , signedI32Range "compareRegister"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (and (<= " ++ toString (requiredBodyInstructionBytes rawShape path) ++
             " bufferSize) (<= bufferSize 1048576)))" ] ++
         operandMaskSmtLines rawShape ++
         rawBodyPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawBodyValueTerms ++ ")"] else []))

def rawBodyQuery
    (title : Title)
    (path : RawBodyPath)
    (activeMask overrideMask : Nat) : String :=
  rawBodyQueryWith true false title path activeMask overrideMask

def rawBodyValuesQuery
    (title : Title)
    (path : RawBodyPath)
    (activeMask overrideMask : Nat) : String :=
  rawBodyQueryWith false true title path activeMask overrideMask

def listRawBodyPathsText : String :=
  joinLines (allRawBodyPaths.map RawBodyPath.name)

private def rawIntResolverValueTerms : String :=
  "(slot rawValue hostValue operandMask)"

private def rawIntResolverQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawIntResolverPath)
    (slot : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL integer resolver query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared integer operand resolver semantics."
         , "; Title: " ++ shape.title
         , "; Resolver path: " ++ path.name
         , "(define-fun slot () Int " ++ toString slot ++ ")"
         , "(declare-const rawValue Int)"
         , "(declare-const hostValue Int)"
         , signedI32Range "rawValue"
         , signedI32Range "hostValue" ] ++
         operandMaskSmtLines rawShape ++
         rawIntResolverPathConstraints rawShape path slot ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawIntResolverValueTerms ++ ")"] else []))

def rawIntResolverQuery
    (title : Title)
    (path : RawIntResolverPath)
    (slot : Nat) : String :=
  rawIntResolverQueryWith false false title path slot

def rawIntResolverValuesQuery
    (title : Title)
    (path : RawIntResolverPath)
    (slot : Nat) : String :=
  rawIntResolverQueryWith false true title path slot

def listRawIntResolverPathsText : String :=
  joinLines (allRawIntResolverPaths.map RawIntResolverPath.name)

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

structure RawBodyWitness extends RawStepWitness where
  counterBefore : Int
  divisorValue : Int
  lhsRaw : Int
  rhsRaw : Int
  lhsHost : Int
  rhsHost : Int
  compareRegister : Int
deriving Repr, DecidableEq

structure RawStepMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  jump : Option TouhouFormal.ECL.RawJumpOperands
  outcome : TouhouFormal.ECL.RawStepOutcome
  matchesPath : Bool
deriving Repr, DecidableEq

structure RawBodyMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome
  matchesPath : Bool
deriving Repr

structure RawIntResolverWitness where
  slot : Nat
  rawValue : Int
  hostValue : Int
  operandMask : Int
deriving Repr, DecidableEq

structure RawIntResolverMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  rawValue : Int
  resolution : TouhouFormal.ECL.RawIntOperandResolution
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

private def writeFixedI32OperandValue
    (bytes : TouhouFormal.Bytes)
    (shape : TouhouFormal.ECL.HeaderShape)
    (operandIndex : Nat)
    (value : Int)
    (fieldName : String) : Except String TouhouFormal.Bytes :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.fixedI32OperandBaseOffset with
      | none => .error ("profile has no fixed-width i32 raw operand shape for " ++ shape.title)
      | some baseOffset =>
          writeScalar
            bytes
            (baseOffset + rawShape.fixedI32OperandStride * operandIndex)
            .i32
            value
            fieldName

private def requiredResolverInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (slot : Nat) : Nat :=
  match rawShape.fixedI32OperandBaseOffset with
  | none => rawShape.fixedPrefixBytes
  | some baseOffset =>
      baseOffset + rawShape.fixedI32OperandStride * (slot + 1)

private def RawIntResolverPath.matchesResolution
    (path : RawIntResolverPath)
    (resolution : TouhouFormal.ECL.RawIntOperandResolution) : Bool :=
  match path, resolution.kind with
  | .rawImmediate, .rawImmediate => true
  | .resolvedHost, .resolvedHost => true
  | .resolvedDefaultRaw, .resolvedDefaultRaw => true
  | _, _ => false

def rawIntResolverMaterialize
    (title : Title)
    (path : RawIntResolverPath)
    (witness : RawIntResolverWitness) : Except String RawIntResolverMaterialization := do
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredResolverInstructionBytes rawShape witness.slot
      let baseBytes <-
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := 0
            instrTime := 0
            opcode := 0
            nextOffset := Int.ofNat rawShape.fixedPrefixBytes
            instructionMask := 1
            operandMask := witness.operandMask
            activeMask := 1
            overrideMask := 0
            jumpTargetTime := 0
            jumpDisplacement := 0
            bufferSize := requiredBytes }
      let bytes <-
        writeFixedI32OperandValue
          baseBytes
          shape
          witness.slot
          witness.rawValue
          "resolverRawValue"
      let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix shape bytes 0)
      let rawValue <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            witness.slot)
      let resolution <-
        liftFaultToString
          (TouhouFormal.ECL.resolveIntRValue
            shape
            rawPrefix
            witness.slot
            rawValue
            witness.hostValue)
      .ok
        { bytes := bytes
          rawPrefix := rawPrefix
          rawValue := rawValue
          resolution := resolution
          matchesPath := path.matchesResolution resolution }

private def rawBodyWitnessBaseBytes
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredBodyInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required raw body bytes=" ++ toString requiredBytes)
      else
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := witness.currentTime
            instrTime := witness.instrTime
            opcode := witness.opcode
            nextOffset := witness.nextOffset
            instructionMask := witness.instructionMask
            operandMask := witness.operandMask
            activeMask := witness.activeMask
            overrideMask := witness.overrideMask
            jumpTargetTime := witness.jumpTargetTime
            jumpDisplacement := witness.jumpDisplacement
            bufferSize := witness.bufferSize }

private def findBodyDivisorHazard
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawIntDivisorHazard :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findIntDivisorHazard? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed integer divisor hazard for " ++ shape.title)
      | some hazard => .ok hazard

private def findIntConditionJump
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawIntConditionJumpShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findIntConditionJump? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed integer conditional jump for " ++ shape.title)
      | some condShape => .ok condShape

private def rawBodyWitnessBytes
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness) : Except String TouhouFormal.Bytes := do
  let shape := title.headerShape
  let bytes <- rawBodyWitnessBaseBytes title path witness
  match path with
  | .decJumpTaken _ | .decJumpNotTaken _ =>
      match shape.rawInstrShape with
      | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
      | some rawShape =>
          match rawShape.fixedDecJumpShape with
          | none => .error ("profile has no JUMPDEC shape for " ++ shape.title)
          | some decJumpShape => do
              let bytes <-
                writeFixedI32OperandValue
                  bytes
                  shape
                  decJumpShape.targetTimeOperandIndex
                  witness.jumpTargetTime
                  "decJumpTargetTime"
              let bytes <-
                writeFixedI32OperandValue
                  bytes
                  shape
                  decJumpShape.displacementOperandIndex
                  witness.jumpDisplacement
                  "decJumpDisplacement"
              writeFixedI32OperandValue
                bytes
                shape
                decJumpShape.counterOperandIndex
                witness.counterBefore
                "decJumpCounterBefore"
  | .intCondJumpTaken _ | .intCondJumpNotTaken _ =>
      let condShape <- findIntConditionJump shape witness.opcode
      let bytes <-
        match condShape.source with
        | .compareRegister => .ok bytes
        | .resolvedOperands => do
            let bytes <-
              writeFixedI32OperandValue
                bytes
                shape
                condShape.lhsOperandIndex
                witness.lhsRaw
                "intCondJumpLhsRaw"
            writeFixedI32OperandValue
              bytes
              shape
              condShape.rhsOperandIndex
              witness.rhsRaw
              "intCondJumpRhsRaw"
      let bytes <-
        writeFixedI32OperandValue
          bytes
          shape
          condShape.targetTimeOperandIndex
          witness.jumpTargetTime
          "intCondJumpTargetTime"
      writeFixedI32OperandValue
        bytes
        shape
        condShape.displacementOperandIndex
        witness.jumpDisplacement
        "intCondJumpDisplacement"
  | .intDivisorZero =>
      let hazard <- findBodyDivisorHazard shape witness.opcode
      writeFixedI32OperandValue
        bytes
        shape
        hazard.divisorOperandIndex
        witness.divisorValue
        "intDivisor"

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

private def RawBodyPath.matchesResult
    (path : RawBodyPath)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : Bool :=
  match path, result with
  | .intDivisorZero, .error faultValue => faultValue.kind == .divideByZero
  | .decJumpTaken cursor, .ok outcome =>
      outcome.action == .jumped &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | .decJumpNotTaken cursor, .ok outcome =>
      outcome.action == .advanced &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | .intCondJumpTaken cursor, .ok outcome =>
      outcome.action == .jumped &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | .intCondJumpNotTaken cursor, .ok outcome =>
      outcome.action == .advanced &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | _, _ => false

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

private def runRawBodyResult
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String (Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) :=
  let shape := title.headerShape
  match path with
  | .decJumpTaken _ | .decJumpNotTaken _ =>
      match shape.rawInstrShape with
      | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
      | some rawShape =>
          match rawShape.fixedDecJumpShape with
          | none => .error ("profile has no JUMPDEC shape for " ++ shape.title)
          | some decJumpShape => do
              let targetTime <-
                liftFaultToString
                  (TouhouFormal.ECL.readFixedI32Operand
                    shape
                    bytes
                    rawPrefix
                    decJumpShape.targetTimeOperandIndex)
              let displacement <-
                liftFaultToString
                  (TouhouFormal.ECL.readFixedI32Operand
                    shape
                    bytes
                    rawPrefix
                    decJumpShape.displacementOperandIndex)
              let counterBefore <-
                liftFaultToString
                  (TouhouFormal.ECL.readFixedI32Operand
                    shape
                    bytes
                    rawPrefix
                    decJumpShape.counterOperandIndex)
              .ok
                (TouhouFormal.ECL.rawDecJumpStep
                  shape
                  witness.currentTime
                  witness.activeMask
                  witness.overrideMask
                  8
                  witness.bufferSize
                  rawPrefix
                  { targetTime := targetTime
                    displacement := displacement
                    counterBefore := counterBefore })
  | .intCondJumpTaken _ | .intCondJumpNotTaken _ => do
      let condShape <- findIntConditionJump shape rawPrefix.opcode
      let targetTime <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            condShape.targetTimeOperandIndex)
      let displacement <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            condShape.displacementOperandIndex)
      let lhsRaw <-
        match condShape.source with
        | .compareRegister => .ok witness.lhsRaw
        | .resolvedOperands =>
            liftFaultToString
              (TouhouFormal.ECL.readFixedI32Operand
                shape
                bytes
                rawPrefix
                condShape.lhsOperandIndex)
      let rhsRaw <-
        match condShape.source with
        | .compareRegister => .ok witness.rhsRaw
        | .resolvedOperands =>
            liftFaultToString
              (TouhouFormal.ECL.readFixedI32Operand
                shape
                bytes
                rawPrefix
                condShape.rhsOperandIndex)
      .ok
        (TouhouFormal.ECL.rawIntConditionJumpStep
          shape
          witness.currentTime
          witness.activeMask
          witness.overrideMask
          8
          witness.bufferSize
          rawPrefix
          { lhsRaw := lhsRaw
            rhsRaw := rhsRaw
            lhsHost := witness.lhsHost
            rhsHost := witness.rhsHost
            compareRegister := witness.compareRegister
            targetTime := targetTime
            displacement := displacement })
  | .intDivisorZero => do
      let hazard <- findBodyDivisorHazard shape rawPrefix.opcode
      let divisor <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            hazard.divisorOperandIndex)
      .ok
        (TouhouFormal.ECL.rawIntDivisorStep
          shape
          witness.currentTime
          witness.activeMask
          witness.overrideMask
          8
          witness.bufferSize
          rawPrefix
          { divisor := divisor })

def rawBodyMaterialize
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness) : Except String RawBodyMaterialization := do
  let bytes <- rawBodyWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let result <- runRawBodyResult title path witness bytes rawPrefix
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      result := result
      matchesPath := path.matchesResult result }

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

private def bodyResultActionText
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : String :=
  match result with
  | .ok outcome => rawStepActionName outcome.action
  | .error faultValue => "fault:" ++ faultValue.kind.name

private def bodyResultTargetCursor
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.targetCursor
  | .error _ => none

private def bodyResultCursorClass
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) :
    Option TouhouFormal.CursorClass :=
  match result with
  | .ok outcome => outcome.cursorClass
  | .error _ => none

private def bodyResultTargetTime
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.targetTime
  | .error _ => none

private def bodyResultFaultKind
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.kind.name

private def bodyResultFaultDetail
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.detail

def RawBodyMaterialization.report (materialization : RawBodyMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "action=" ++ bodyResultActionText materialization.result
    , "targetCursor=" ++ optionIntText (bodyResultTargetCursor materialization.result)
    , "cursorClass=" ++ optionCursorClassText (bodyResultCursorClass materialization.result)
    , "targetTime=" ++ optionIntText (bodyResultTargetTime materialization.result)
    , "faultKind=" ++ bodyResultFaultKind materialization.result
    , "faultDetail=" ++ bodyResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

def RawIntResolverMaterialization.report
    (materialization : RawIntResolverMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "rawValue=" ++ toString materialization.rawValue
    , "resolvedKind=" ++ materialization.resolution.kind.name
    , "resolvedValue=" ++ toString materialization.resolution.value
    , "selectorKnown=" ++ toString materialization.resolution.selectorKnown
    , "flagEnabled=" ++ toString materialization.resolution.flagEnabled
    , "hostValue=" ++ optionIntText materialization.resolution.hostValue
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
