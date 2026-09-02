import TouhouFormal.ECL.Body
import TouhouFormal.ECL.Arithmetic
import TouhouFormal.ECL.Boss
import TouhouFormal.ECL.Stack
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

inductive RawCallRetPath where
  | callStackWriteBeforeStack
  | callStackWriteAtOrPastStack
  | callLookupFault
  | callEntered
  | callNoOp
  | retStackReadBeforeStack
  | retStackReadAtOrPastStack
  | retRestored
  | retExitChild
  | retChildIndexBeforeArray
  | retChildIndexAtOrPastArray
deriving Repr, DecidableEq

def RawCallRetPath.name : RawCallRetPath -> String
  | .callStackWriteBeforeStack => "call-stack-write-before-stack"
  | .callStackWriteAtOrPastStack => "call-stack-write-at-or-past-stack"
  | .callLookupFault => "call-lookup-fault"
  | .callEntered => "call-entered"
  | .callNoOp => "call-no-op"
  | .retStackReadBeforeStack => "ret-stack-read-before-stack"
  | .retStackReadAtOrPastStack => "ret-stack-read-at-or-past-stack"
  | .retRestored => "ret-restored"
  | .retExitChild => "ret-exit-child"
  | .retChildIndexBeforeArray => "ret-child-index-before-array"
  | .retChildIndexAtOrPastArray => "ret-child-index-at-or-past-array"

def RawCallRetPath.parse? : String -> Option RawCallRetPath
  | "call-stack-write-before-stack" => some .callStackWriteBeforeStack
  | "call-stack-write-at-or-past-stack" => some .callStackWriteAtOrPastStack
  | "call-lookup-fault" => some .callLookupFault
  | "call-entered" => some .callEntered
  | "call-no-op" => some .callNoOp
  | "ret-stack-read-before-stack" => some .retStackReadBeforeStack
  | "ret-stack-read-at-or-past-stack" => some .retStackReadAtOrPastStack
  | "ret-restored" => some .retRestored
  | "ret-exit-child" => some .retExitChild
  | "ret-child-index-before-array" => some .retChildIndexBeforeArray
  | "ret-child-index-at-or-past-array" => some .retChildIndexAtOrPastArray
  | _ => none

def allRawCallRetPaths : List RawCallRetPath :=
  [ .callStackWriteBeforeStack
  , .callStackWriteAtOrPastStack
  , .callLookupFault
  , .callEntered
  , .callNoOp
  , .retStackReadBeforeStack
  , .retStackReadAtOrPastStack
  , .retRestored
  , .retExitChild
  , .retChildIndexBeforeArray
  , .retChildIndexAtOrPastArray ]

def RawCallRetPath.isCall : RawCallRetPath -> Bool
  | .callStackWriteBeforeStack
  | .callStackWriteAtOrPastStack
  | .callLookupFault
  | .callEntered
  | .callNoOp => true
  | _ => false

def RawCallRetPath.isRet (path : RawCallRetPath) : Bool :=
  !path.isCall

inductive RawConditionalCallPath where
  | conditionFalse (cursor : CursorGoal)
  | callStackWriteBeforeStack
  | callStackWriteAtOrPastStack
  | callLookupFault
  | callEntered
  | callNoOp
deriving Repr, DecidableEq

def RawConditionalCallPath.name : RawConditionalCallPath -> String
  | .conditionFalse cursor => "condcall-false-" ++ cursor.name
  | .callStackWriteBeforeStack => "condcall-stack-write-before-stack"
  | .callStackWriteAtOrPastStack => "condcall-stack-write-at-or-past-stack"
  | .callLookupFault => "condcall-lookup-fault"
  | .callEntered => "condcall-entered"
  | .callNoOp => "condcall-no-op"

def RawConditionalCallPath.parse? : String -> Option RawConditionalCallPath
  | "condcall-false-before-buffer" => some (.conditionFalse .beforeBuffer)
  | "condcall-false-non-progress" => some (.conditionFalse .nonProgress)
  | "condcall-false-in-bounds" => some (.conditionFalse .inBounds)
  | "condcall-false-at-or-past-end" => some (.conditionFalse .atOrPastEnd)
  | "condcall-stack-write-before-stack" => some .callStackWriteBeforeStack
  | "condcall-stack-write-at-or-past-stack" => some .callStackWriteAtOrPastStack
  | "condcall-lookup-fault" => some .callLookupFault
  | "condcall-entered" => some .callEntered
  | "condcall-no-op" => some .callNoOp
  | _ => none

def allRawConditionalCallPaths : List RawConditionalCallPath :=
  allCursorGoals.map RawConditionalCallPath.conditionFalse ++
    [ .callStackWriteBeforeStack
    , .callStackWriteAtOrPastStack
    , .callLookupFault
    , .callEntered
    , .callNoOp ]

def RawConditionalCallPath.isTakenCall : RawConditionalCallPath -> Bool
  | .conditionFalse _ => false
  | _ => true

inductive RawIntBinaryPath where
  | outputRawCell
  | outputResolvedHost
  | outputDefaultRawCell
  | nonIntOutput
  | divisorZero (rhs : RawIntResolverPath)
  | divideOverflow (rhs : RawIntResolverPath)
deriving Repr, DecidableEq

def RawIntBinaryPath.name : RawIntBinaryPath -> String
  | .outputRawCell => "int-binary-output-raw-cell"
  | .outputResolvedHost => "int-binary-output-resolved-host"
  | .outputDefaultRawCell => "int-binary-output-default-raw-cell"
  | .nonIntOutput => "int-binary-non-int-output"
  | .divisorZero rhs => "int-binary-divisor-zero-" ++ rhs.name
  | .divideOverflow rhs => "int-binary-divide-overflow-" ++ rhs.name

def RawIntBinaryPath.parse? : String -> Option RawIntBinaryPath
  | "int-binary-output-raw-cell" => some .outputRawCell
  | "int-binary-output-resolved-host" => some .outputResolvedHost
  | "int-binary-output-default-raw-cell" => some .outputDefaultRawCell
  | "int-binary-non-int-output" => some .nonIntOutput
  | "int-binary-divisor-zero-raw-immediate" => some (.divisorZero .rawImmediate)
  | "int-binary-divisor-zero-resolved-host" => some (.divisorZero .resolvedHost)
  | "int-binary-divisor-zero-resolved-default-raw" => some (.divisorZero .resolvedDefaultRaw)
  | "int-binary-divide-overflow-raw-immediate" => some (.divideOverflow .rawImmediate)
  | "int-binary-divide-overflow-resolved-host" => some (.divideOverflow .resolvedHost)
  | "int-binary-divide-overflow-resolved-default-raw" => some (.divideOverflow .resolvedDefaultRaw)
  | _ => none

def allRawIntBinaryPaths : List RawIntBinaryPath :=
  [ .outputRawCell
  , .outputResolvedHost
  , .outputDefaultRawCell
  , .nonIntOutput ] ++
    allRawIntResolverPaths.map RawIntBinaryPath.divisorZero ++
    allRawIntResolverPaths.map RawIntBinaryPath.divideOverflow

inductive RawBossIntReadPath where
  | valueRawNoBossRead
  | bossIndexBeforeArray
  | bossIndexAtOrPastArray
  | bossNullDeref
  | bossValueResolvedHost
  | bossValueResolvedDefaultRaw
deriving Repr, DecidableEq

def RawBossIntReadPath.name : RawBossIntReadPath -> String
  | .valueRawNoBossRead => "boss-int-value-raw-no-boss-read"
  | .bossIndexBeforeArray => "boss-int-index-before-array"
  | .bossIndexAtOrPastArray => "boss-int-index-at-or-past-array"
  | .bossNullDeref => "boss-int-null-deref"
  | .bossValueResolvedHost => "boss-int-value-resolved-host"
  | .bossValueResolvedDefaultRaw => "boss-int-value-resolved-default-raw"

def RawBossIntReadPath.parse? : String -> Option RawBossIntReadPath
  | "boss-int-value-raw-no-boss-read" => some .valueRawNoBossRead
  | "boss-int-index-before-array" => some .bossIndexBeforeArray
  | "boss-int-index-at-or-past-array" => some .bossIndexAtOrPastArray
  | "boss-int-null-deref" => some .bossNullDeref
  | "boss-int-value-resolved-host" => some .bossValueResolvedHost
  | "boss-int-value-resolved-default-raw" => some .bossValueResolvedDefaultRaw
  | _ => none

def allRawBossIntReadPaths : List RawBossIntReadPath :=
  [ .valueRawNoBossRead
  , .bossIndexBeforeArray
  , .bossIndexAtOrPastArray
  , .bossNullDeref
  , .bossValueResolvedHost
  , .bossValueResolvedDefaultRaw ]

inductive RawBossFloatReadPath where
  | valueRawNoBossRead
  | bossIndexBeforeArray
  | bossIndexAtOrPastArray
  | bossNullDeref
  | bossNullGuardedSkip
  | bossValueResolvedHost
  | bossValueResolvedDefaultRaw
deriving Repr, DecidableEq

def RawBossFloatReadPath.name : RawBossFloatReadPath -> String
  | .valueRawNoBossRead => "boss-float-value-raw-no-boss-read"
  | .bossIndexBeforeArray => "boss-float-index-before-array"
  | .bossIndexAtOrPastArray => "boss-float-index-at-or-past-array"
  | .bossNullDeref => "boss-float-null-deref"
  | .bossNullGuardedSkip => "boss-float-null-guarded-skip"
  | .bossValueResolvedHost => "boss-float-value-resolved-host"
  | .bossValueResolvedDefaultRaw => "boss-float-value-resolved-default-raw"

def RawBossFloatReadPath.parse? : String -> Option RawBossFloatReadPath
  | "boss-float-value-raw-no-boss-read" => some .valueRawNoBossRead
  | "boss-float-index-before-array" => some .bossIndexBeforeArray
  | "boss-float-index-at-or-past-array" => some .bossIndexAtOrPastArray
  | "boss-float-null-deref" => some .bossNullDeref
  | "boss-float-null-guarded-skip" => some .bossNullGuardedSkip
  | "boss-float-value-resolved-host" => some .bossValueResolvedHost
  | "boss-float-value-resolved-default-raw" => some .bossValueResolvedDefaultRaw
  | _ => none

def allRawBossFloatReadPaths : List RawBossFloatReadPath :=
  [ .valueRawNoBossRead
  , .bossIndexBeforeArray
  , .bossIndexAtOrPastArray
  , .bossNullDeref
  , .bossNullGuardedSkip
  , .bossValueResolvedHost
  , .bossValueResolvedDefaultRaw ]

def joinLines : List String -> String
  | [] => ""
  | line :: rest => line ++ "\n" ++ joinLines rest

def joinWith (sep : String) : List String -> String
  | [] => ""
  | value :: [] => value
  | value :: rest => value ++ sep ++ joinWith sep rest

def signedI16Range (name : String) : String :=
  "(assert (and (<= (- 32768) " ++ name ++ ") (<= " ++ name ++ " 32767)))"

def signedI32Range (name : String) : String :=
  "(assert (and (<= (- 2147483648) " ++ name ++ ") (<= " ++ name ++ " 2147483647)))"

def scalarRange (name : String) : TouhouFormal.ScalarWidth -> String
  | .u8 => "(assert (and (<= 0 " ++ name ++ ") (<= " ++ name ++ " 255)))"
  | .u16 => "(assert (and (<= 0 " ++ name ++ ") (<= " ++ name ++ " 65535)))"
  | .u32 => "(assert (and (<= 0 " ++ name ++ ") (<= " ++ name ++ " 4294967295)))"
  | .i16 => signedI16Range name
  | .i32 => signedI32Range name

def operandMaskSmtLines (rawShape : TouhouFormal.ECL.RawInstrShape) : List String :=
  match rawShape.operandMaskWidth with
  | none => ["(define-fun operandMask () Int 0)"]
  | some width =>
      [ "(declare-const operandMask Int)"
      , scalarRange "operandMask" width ]

def hexDigit : Nat -> String
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

def bv8 (value : Nat) : String :=
  "#x" ++ hexDigit ((value / 16) % 16) ++ hexDigit (value % 16)

def difficultyPassExpr : TouhouFormal.ECL.DifficultyMaskPolicy -> String
  | .intersectsActive =>
      "(not (= (bvand instructionMask activeMask) #x00))"
  | .containsActiveAndOverride =>
      "(= (bvand instructionMask requiredDifficultyMask) requiredDifficultyMask)"

def cursorGoalAssertion (targetName : String) : CursorGoal -> String
  | .beforeBuffer => "(assert (< " ++ targetName ++ " 0))"
  | .nonProgress => "(assert (= " ++ targetName ++ " fileOffset))"
  | .inBounds =>
      "(assert (and (<= 0 " ++ targetName ++ ") (< " ++ targetName ++ " bufferSize) (not (= " ++
        targetName ++ " fileOffset))))"
  | .atOrPastEnd => "(assert (<= bufferSize " ++ targetName ++ "))"

def maxJumpOperandIndex (jumpShape : TouhouFormal.ECL.RawFixedJumpShape) : Nat :=
  Nat.max jumpShape.targetTimeOperandIndex jumpShape.displacementOperandIndex

def maxDecJumpOperandIndex (decJumpShape : TouhouFormal.ECL.RawDecJumpShape) : Nat :=
  Nat.max
    (Nat.max decJumpShape.targetTimeOperandIndex decJumpShape.displacementOperandIndex)
    decJumpShape.counterOperandIndex

def maxIntConditionJumpOperandIndex
    (condShape : TouhouFormal.ECL.RawIntConditionJumpShape) : Nat :=
  Nat.max
    (Nat.max condShape.lhsOperandIndex condShape.rhsOperandIndex)
    (Nat.max condShape.targetTimeOperandIndex condShape.displacementOperandIndex)

def maxConditionalCallOperandIndex
    (callRet : TouhouFormal.ECL.RawCallRetShape)
    (condCall : TouhouFormal.ECL.RawConditionalCallShape) : Nat :=
  Nat.max
    (Nat.max condCall.lhsOperandIndex condCall.rhsOperandIndex)
    callRet.subIdOperandIndex

def maxIntBinaryOpOperandIndex
    (op : TouhouFormal.ECL.RawIntBinaryOpShape) : Nat :=
  Nat.max
    (Nat.max op.outputOperandIndex op.lhsOperandIndex)
    op.rhsOperandIndex

def maxBossIntReadOperandIndex
    (read : TouhouFormal.ECL.RawBossIntReadShape) : Nat :=
  Nat.max
    (Nat.max read.outputOperandIndex read.valueOperandIndex)
    read.bossIndexOperandIndex

def maxBossFloatReadOperandIndex
    (read : TouhouFormal.ECL.RawBossFloatReadShape) : Nat :=
  Nat.max
    (Nat.max read.outputOperandIndex read.valueOperandIndex)
    read.bossIndexOperandIndex

def maxNatList (values : List Nat) : Nat :=
  values.foldl (fun acc value => Nat.max acc value) 0

def intSelectorRangePredicate
    (valueName : String)
    (range : TouhouFormal.ECL.IntSelectorRange) : String :=
  "(and (<= " ++ toString range.first ++ " " ++ valueName ++ ") (<= " ++
    valueName ++ " " ++ toString range.last ++ "))"

def intSelectorSetPredicate
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
  let excludedRangePredicate :=
    match set.excludedRanges with
    | [] => "true"
    | ranges =>
        "(and " ++
          joinWith " " (ranges.map fun range =>
            "(not " ++ intSelectorRangePredicate valueName range ++ ")") ++
          ")"
  "(and " ++ rangePredicate ++ " " ++ exclusionPredicate ++ " " ++
    excludedRangePredicate ++ ")"

def intMaskBitSetPredicate (maskName : String) (slot : Nat) : String :=
  "(= (mod (div " ++ maskName ++ " " ++ toString (2 ^ slot) ++ ") 2) 1)"

def rawOperandSwitchPredicate
    (maskPolicy : TouhouFormal.ECL.RawIntOperandMaskPolicy)
    (slot : Nat)
    (maskName : String) : String :=
  match maskPolicy with
  | .noMaskAlwaysResolve => "true"
  | .bitSetMeansResolve => intMaskBitSetPredicate maskName slot

def intResolverSwitchPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (maskName : String) : String :=
  rawOperandSwitchPredicate resolver.maskPolicy slot maskName

def floatResolverSwitchPredicate
    (resolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (slot : Nat)
    (maskName : String) : String :=
  rawOperandSwitchPredicate resolver.maskPolicy slot maskName

def rawIntResolvedValueExpr
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (rawName hostName : String) : String :=
  "(ite (and " ++ intResolverSwitchPredicate resolver slot "operandMask" ++
    " " ++ intSelectorSetPredicate rawName resolver.knownRValueSelectors ++
    ") " ++ hostName ++ " " ++ rawName ++ ")"

def rawIntResolvedValueAssertions
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (rawName hostName resolvedName : String) : List String :=
  [ "(define-fun " ++ resolvedName ++ " () Int " ++
      rawIntResolvedValueExpr resolver slot rawName hostName ++ ")" ]

def rawIntRValuePathPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (rawName : String)
    (path : RawIntResolverPath) : String :=
  let switchPredicate := intResolverSwitchPredicate resolver slot "operandMask"
  let knownPredicate := intSelectorSetPredicate rawName resolver.knownRValueSelectors
  match path with
  | .rawImmediate =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "false"
      | .bitSetMeansResolve => "(not " ++ switchPredicate ++ ")"
  | .resolvedHost =>
      "(and " ++ switchPredicate ++ " " ++ knownPredicate ++ ")"
  | .resolvedDefaultRaw =>
      "(and " ++ switchPredicate ++ " (not " ++ knownPredicate ++ "))"

def rawIntLValuePathPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (rawName : String)
    (kind : TouhouFormal.ECL.RawIntLValueResolutionKind) : String :=
  let switchPredicate := intResolverSwitchPredicate resolver slot "operandMask"
  let knownPredicate := intSelectorSetPredicate rawName resolver.knownLValueSelectors
  match kind with
  | .rawOperandCell =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "false"
      | .bitSetMeansResolve => "(not " ++ switchPredicate ++ ")"
  | .resolvedHost =>
      "(and " ++ switchPredicate ++ " " ++ knownPredicate ++ ")"
  | .resolvedDefaultRawCell =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "false"
      | .bitSetMeansResolve => "(and " ++ switchPredicate ++ " (not " ++ knownPredicate ++ "))"
  | .nonIntOutput =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "(not " ++ knownPredicate ++ ")"
      | .bitSetMeansResolve => "false"

def rawIntLValueWritablePredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (_slot : Nat)
    (rawName : String) : String :=
  let knownPredicate := intSelectorSetPredicate rawName resolver.knownLValueSelectors
  match resolver.maskPolicy with
  | .noMaskAlwaysResolve => knownPredicate
  | .bitSetMeansResolve => "true"

def rawIntLValueValueExpr
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (slot : Nat)
    (rawName hostBeforeName : String) : String :=
  "(ite (and " ++ intResolverSwitchPredicate resolver slot "operandMask" ++
    " " ++ intSelectorSetPredicate rawName resolver.knownLValueSelectors ++
    ") " ++ hostBeforeName ++ " " ++ rawName ++ ")"

def rawFloatResolvedValueExpr
    (resolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (slot : Nat)
    (rawName hostName : String) : String :=
  "(ite (and " ++ floatResolverSwitchPredicate resolver slot "operandMask" ++
    " " ++ intSelectorSetPredicate rawName resolver.knownRValueSelectors ++
    ") " ++ hostName ++ " " ++ rawName ++ ")"

def rawFloatRValuePathPredicate
    (resolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (slot : Nat)
    (rawName : String)
    (path : RawIntResolverPath) : String :=
  let switchPredicate := floatResolverSwitchPredicate resolver slot "operandMask"
  let knownPredicate := intSelectorSetPredicate rawName resolver.knownRValueSelectors
  match path with
  | .rawImmediate =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "false"
      | .bitSetMeansResolve => "(not " ++ switchPredicate ++ ")"
  | .resolvedHost =>
      "(and " ++ switchPredicate ++ " " ++ knownPredicate ++ ")"
  | .resolvedDefaultRaw =>
      "(and " ++ switchPredicate ++ " (not " ++ knownPredicate ++ "))"

def rawFloatLValuePathPredicate
    (resolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (slot : Nat)
    (rawName : String)
    (kind : TouhouFormal.ECL.RawFloatLValueResolutionKind) : String :=
  let switchPredicate := floatResolverSwitchPredicate resolver slot "operandMask"
  let knownPredicate := intSelectorSetPredicate rawName resolver.knownLValueSelectors
  match kind with
  | .rawOperandCell =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "false"
      | .bitSetMeansResolve => "(not " ++ switchPredicate ++ ")"
  | .resolvedHost =>
      "(and " ++ switchPredicate ++ " " ++ knownPredicate ++ ")"
  | .resolvedDefaultRawCell =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "false"
      | .bitSetMeansResolve => "(and " ++ switchPredicate ++ " (not " ++ knownPredicate ++ "))"
  | .nonFloatOutput =>
      match resolver.maskPolicy with
      | .noMaskAlwaysResolve => "(not " ++ knownPredicate ++ ")"
      | .bitSetMeansResolve => "false"

def rawFloatLValueWritablePredicate
    (resolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (_slot : Nat)
    (_rawName : String) : String :=
  match resolver.maskPolicy with
  | .noMaskAlwaysResolve => intSelectorSetPredicate _rawName resolver.knownLValueSelectors
  | .bitSetMeansResolve => "true"

def rawIntBinaryLhsValueExpr
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (op : TouhouFormal.ECL.RawIntBinaryOpShape) : String :=
  match op.mode with
  | .assign =>
      rawIntResolvedValueExpr resolver op.lhsOperandIndex "lhsRaw" "lhsHost"
  | .updateInPlace =>
      rawIntLValueValueExpr resolver op.outputOperandIndex "outputRaw" "outputHostBefore"

def rawIntComparePredicate
    (op : TouhouFormal.ECL.RawIntCompareOp)
    (lhs rhs : String) : String :=
  match op with
  | .eq => "(= " ++ lhs ++ " " ++ rhs ++ ")"
  | .neq => "(not (= " ++ lhs ++ " " ++ rhs ++ "))"
  | .lt => "(< " ++ lhs ++ " " ++ rhs ++ ")"
  | .le => "(<= " ++ lhs ++ " " ++ rhs ++ ")"
  | .gt => "(> " ++ lhs ++ " " ++ rhs ++ ")"
  | .ge => "(>= " ++ lhs ++ " " ++ rhs ++ ")"

def requiredInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawStepPath) : Nat :=
  match path with
  | .jumped _ =>
      match rawShape.fixedJumpShape, rawShape.fixedI32OperandBaseOffset with
      | some jumpShape, some baseOffset =>
          baseOffset + rawShape.fixedI32OperandStride * (maxJumpOperandIndex jumpShape + 1)
      | _, _ => rawShape.fixedPrefixBytes
  | _ => rawShape.fixedPrefixBytes

def requiredBodyInstructionBytes
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

def requiredCallRetInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawCallRetPath) : Nat :=
  if path.isCall then
    match rawShape.callRetShape, rawShape.fixedI32OperandBaseOffset with
    | some callRet, some baseOffset =>
        baseOffset + rawShape.fixedI32OperandStride * (callRet.subIdOperandIndex + 1)
    | _, _ => rawShape.fixedPrefixBytes
  else
    rawShape.fixedPrefixBytes

def requiredConditionalCallInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (_path : RawConditionalCallPath) : Nat :=
  match rawShape.callRetShape, rawShape.fixedI32OperandBaseOffset with
  | some callRet, some baseOffset =>
      let maxOperand :=
        maxNatList (rawShape.conditionalCallShapes.map (maxConditionalCallOperandIndex callRet))
      if rawShape.conditionalCallShapes.isEmpty then
        rawShape.fixedPrefixBytes
      else
        baseOffset + rawShape.fixedI32OperandStride * (maxOperand + 1)
  | _, _ => rawShape.fixedPrefixBytes

def requiredIntBinaryInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (_path : RawIntBinaryPath) : Nat :=
  match rawShape.fixedI32OperandBaseOffset with
  | none => rawShape.fixedPrefixBytes
  | some baseOffset =>
      let maxOperand := maxNatList (rawShape.intBinaryOps.map maxIntBinaryOpOperandIndex)
      if rawShape.intBinaryOps.isEmpty then
        rawShape.fixedPrefixBytes
      else
        baseOffset + rawShape.fixedI32OperandStride * (maxOperand + 1)

def requiredBossIntReadInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (_path : RawBossIntReadPath) : Nat :=
  match rawShape.fixedI32OperandBaseOffset with
  | none => rawShape.fixedPrefixBytes
  | some baseOffset =>
      let maxOperand := maxNatList (rawShape.bossIntReads.map maxBossIntReadOperandIndex)
      if rawShape.bossIntReads.isEmpty then
        rawShape.fixedPrefixBytes
      else
        baseOffset + rawShape.fixedI32OperandStride * (maxOperand + 1)

def requiredBossFloatReadInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (_path : RawBossFloatReadPath) : Nat :=
  match rawShape.fixedI32OperandBaseOffset with
  | none => rawShape.fixedPrefixBytes
  | some baseOffset =>
      let maxOperand := maxNatList (rawShape.bossFloatReads.map maxBossFloatReadOperandIndex)
      if rawShape.bossFloatReads.isEmpty then
        rawShape.fixedPrefixBytes
      else
        baseOffset + rawShape.fixedI32OperandStride * (maxOperand + 1)

def opcodeExclusions (rawShape : TouhouFormal.ECL.RawInstrShape) : List Int :=
  let excludeJump :=
    match rawShape.fixedJumpShape with
    | none => []
    | some jumpShape => [jumpShape.opcode]
  let excludeUnimp :=
    match rawShape.unimplementedOpcode with
    | none => []
    | some opcode => [opcode]
  excludeJump ++ excludeUnimp

def notOpcodeAssertions (opcodes : List Int) : List String :=
  opcodes.map fun opcode => "(assert (not (= opcode " ++ toString opcode ++ ")))"

def opcodeSetAssertion (opcodes : List Int) : String :=
  match opcodes with
  | [] => "(assert false) ; no source-backed opcode for this body path"
  | [opcode] => "(assert (= opcode " ++ toString opcode ++ "))"
  | _ =>
      "(assert (or " ++
        joinWith " " (opcodes.map fun opcode => "(= opcode " ++ toString opcode ++ ")") ++
        "))"

def rawStepPathConstraints
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

def intConditionJumpCasePredicate
    (condShape : TouhouFormal.ECL.RawIntConditionJumpShape)
    (taken : Bool) : String :=
  let condition :=
    match condShape.source with
    | .compareRegister => rawIntComparePredicate condShape.op "compareRegister" "0"
    | .resolvedOperands => rawIntComparePredicate condShape.op "lhsResolvedValue" "rhsResolvedValue"
  "(and (= opcode " ++ toString condShape.opcode ++ ") " ++
    (if taken then condition else "(not " ++ condition ++ ")") ++
    ")"

def intConditionJumpPathConstraints
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

def rawBodyPathConstraints
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

def rawIntResolverPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawIntResolverPath)
    (slot : Nat) : List String :=
  match rawShape.intRValueResolver with
  | none => ["(assert false) ; profile has no integer rvalue resolver"]
  | some resolver =>
      [ "(assert " ++ rawIntRValuePathPredicate resolver slot "rawValue" path ++ ")" ]

def subLookupFaultPredicate
    (shape : TouhouFormal.ECL.HeaderShape)
    (subIdName subCountName : String) : String :=
  match shape.negativeSubIdPolicy with
  | .unchecked =>
      "(or (< " ++ subIdName ++ " 0) (<= " ++ subCountName ++ " " ++ subIdName ++ "))"
  | .noOp =>
      "(and (<= 0 " ++ subIdName ++ ") (<= " ++ subCountName ++ " " ++ subIdName ++ "))"

def subLookupOkOffsetPredicate (subIdName subCountName : String) : String :=
  "(and (<= 0 " ++ subIdName ++ ") (< " ++ subIdName ++ " " ++ subCountName ++ "))"

def subLookupNoOpPredicate
    (shape : TouhouFormal.ECL.HeaderShape)
    (subIdName : String) : String :=
  match shape.negativeSubIdPolicy with
  | .unchecked => "false"
  | .noOp => "(< " ++ subIdName ++ " 0)"

def callStackSafeOrDisabledPredicate
    (callRet : TouhouFormal.ECL.RawCallRetShape) : String :=
  "(or stackDisabled (and (<= 0 stackDepth) (< stackDepth " ++
    toString callRet.stackEntryCount ++ ")))"

def rawCallRetPathConstraints
    (shape : TouhouFormal.ECL.HeaderShape)
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawCallRetPath) : List String :=
  match rawShape.callRetShape with
  | none => ["(assert false) ; profile has no source-backed CALL/RET semantics"]
  | some callRet =>
      let common :=
        [ "(assert (= currentTime instrTime))"
        , "(assert difficultyPass)"
        , "(assert (and (<= (- 1) stackDepth) (<= stackDepth " ++
            toString (callRet.stackEntryCount + 1) ++ ")))"
        , "(assert (and (<= 0 subCount) (<= subCount 256)))"
        , "(assert (and (<= (- 1) childContextSlot) (<= childContextSlot " ++
            toString (callRet.childContextSlotCount + 1) ++ ")))"
        , "(define-fun returnCursor () Int (+ fileOffset nextOffset))"
        , "(define-fun stackDepthAfterRet () Int (- stackDepth 1))"
        , "(define-fun childContextIndex () Int (- childContextSlot 1))" ]
      let callPrefix := common ++
        [ "(assert (= opcode " ++ toString callRet.callOpcode ++ "))" ]
      let retPrefix := common ++
        [ "(assert (= opcode " ++ toString callRet.retOpcode ++ "))" ]
      match path with
      | .callStackWriteBeforeStack =>
          callPrefix ++
            [ "(assert (not stackDisabled))"
            , "(assert (< stackDepth 0))" ]
      | .callStackWriteAtOrPastStack =>
          callPrefix ++
            [ "(assert (not stackDisabled))"
            , "(assert (<= " ++ toString callRet.stackEntryCount ++ " stackDepth))" ]
      | .callLookupFault =>
          callPrefix ++
            [ "(assert " ++ callStackSafeOrDisabledPredicate callRet ++ ")"
            , "(assert " ++ subLookupFaultPredicate shape "subId" "subCount" ++ ")" ]
      | .callEntered =>
          callPrefix ++
            [ "(assert " ++ callStackSafeOrDisabledPredicate callRet ++ ")"
            , "(assert " ++ subLookupOkOffsetPredicate "subId" "subCount" ++ ")" ]
      | .callNoOp =>
          callPrefix ++
            [ "(assert " ++ callStackSafeOrDisabledPredicate callRet ++ ")"
            , "(assert " ++ subLookupNoOpPredicate shape "subId" ++ ")" ]
      | .retStackReadBeforeStack =>
          match callRet.retUnderflowPolicy with
          | .uncheckedSavedContextRead =>
              retPrefix ++ [ "(assert (< stackDepthAfterRet 0))" ]
          | .th08ChildContextExit =>
              retPrefix ++ [ "(assert false) ; TH08 routes depth underflow into child-context exit" ]
      | .retStackReadAtOrPastStack =>
          retPrefix ++
            [ "(assert (<= " ++ toString callRet.stackEntryCount ++ " stackDepthAfterRet))" ]
      | .retRestored =>
          retPrefix ++
            [ "(assert (and (<= 0 stackDepthAfterRet) (< stackDepthAfterRet " ++
                toString callRet.stackEntryCount ++ ")))" ]
      | .retExitChild =>
          match callRet.retUnderflowPolicy with
          | .uncheckedSavedContextRead =>
              retPrefix ++ [ "(assert false) ; this title restores from saved context on depth underflow" ]
          | .th08ChildContextExit =>
              retPrefix ++
                [ "(assert (< stackDepthAfterRet 0))"
                , "(assert (and (<= 0 childContextIndex) (< childContextIndex " ++
                    toString callRet.childContextSlotCount ++ ")))" ]
      | .retChildIndexBeforeArray =>
          match callRet.retUnderflowPolicy with
          | .uncheckedSavedContextRead =>
              retPrefix ++ [ "(assert false) ; this title has no child-context RET exit" ]
          | .th08ChildContextExit =>
              retPrefix ++
                [ "(assert (< stackDepthAfterRet 0))"
                , "(assert (< childContextIndex 0))" ]
      | .retChildIndexAtOrPastArray =>
          match callRet.retUnderflowPolicy with
          | .uncheckedSavedContextRead =>
              retPrefix ++ [ "(assert false) ; this title has no child-context RET exit" ]
          | .th08ChildContextExit =>
              retPrefix ++
                [ "(assert (< stackDepthAfterRet 0))"
                , "(assert (<= " ++ toString callRet.childContextSlotCount ++
                    " childContextIndex))" ]

def conditionalCallConditionPredicate
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (condCall : TouhouFormal.ECL.RawConditionalCallShape) : String :=
  match rawShape.intRValueResolver with
  | none => "false"
  | some resolver =>
      rawIntComparePredicate
        condCall.op
        (rawIntResolvedValueExpr resolver condCall.lhsOperandIndex "lhsRaw" "lhsHost")
        "rhsRaw"

def conditionalCallCasePredicate
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (condCall : TouhouFormal.ECL.RawConditionalCallShape)
    (taken : Bool) : String :=
  let condition := conditionalCallConditionPredicate rawShape condCall
  "(and (= opcode " ++ toString condCall.opcode ++ ") " ++
    (if taken then condition else "(not " ++ condition ++ ")") ++
    ")"

def conditionalCallOpcodeAndGuardAssertion
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (taken : Bool) : String :=
  match rawShape.conditionalCallShapes with
  | [] => "(assert false) ; profile has no conditional CALL opcodes"
  | [condCall] =>
      "(assert " ++ conditionalCallCasePredicate rawShape condCall taken ++ ")"
  | condCalls =>
      "(assert (or " ++
        joinWith " " (condCalls.map fun condCall =>
          conditionalCallCasePredicate rawShape condCall taken) ++
        "))"

def rawConditionalCallPathConstraints
    (shape : TouhouFormal.ECL.HeaderShape)
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawConditionalCallPath) : List String :=
  match rawShape.callRetShape with
  | none => ["(assert false) ; profile has no source-backed CALL/RET semantics"]
  | some callRet =>
      let common :=
        [ "(assert (= currentTime instrTime))"
        , "(assert difficultyPass)"
        , "(assert (and (<= (- 1) stackDepth) (<= stackDepth " ++
            toString (callRet.stackEntryCount + 1) ++ ")))"
        , "(assert (and (<= 0 subCount) (<= subCount 256)))"
        , "(define-fun returnCursor () Int (+ fileOffset nextOffset))" ]
      let takenPrefix := common ++
        [ conditionalCallOpcodeAndGuardAssertion rawShape true ]
      match path with
      | .conditionFalse cursor =>
          common ++
            [ conditionalCallOpcodeAndGuardAssertion rawShape false
            , cursorGoalAssertion "returnCursor" cursor ]
      | .callStackWriteBeforeStack =>
          takenPrefix ++
            [ "(assert (not stackDisabled))"
            , "(assert (< stackDepth 0))" ]
      | .callStackWriteAtOrPastStack =>
          takenPrefix ++
            [ "(assert (not stackDisabled))"
            , "(assert (<= " ++ toString callRet.stackEntryCount ++ " stackDepth))" ]
      | .callLookupFault =>
          takenPrefix ++
            [ "(assert " ++ callStackSafeOrDisabledPredicate callRet ++ ")"
            , "(assert " ++ subLookupFaultPredicate shape "subId" "subCount" ++ ")" ]
      | .callEntered =>
          takenPrefix ++
            [ "(assert " ++ callStackSafeOrDisabledPredicate callRet ++ ")"
            , "(assert " ++ subLookupOkOffsetPredicate "subId" "subCount" ++ ")" ]
      | .callNoOp =>
          takenPrefix ++
            [ "(assert " ++ callStackSafeOrDisabledPredicate callRet ++ ")"
            , "(assert " ++ subLookupNoOpPredicate shape "subId" ++ ")" ]

def intBinaryOpSetAssertion
    (ops : List TouhouFormal.ECL.RawIntBinaryOpShape)
    (extraPredicate : TouhouFormal.ECL.RawIntBinaryOpShape -> String) : String :=
  match ops with
  | [] => "(assert false) ; profile has no source-backed integer binary opcodes for this path"
  | [op] =>
      "(assert (and (= opcode " ++ toString op.opcode ++ ") " ++ extraPredicate op ++ "))"
  | ops =>
      "(assert (or " ++
        joinWith " " (ops.map fun op =>
          "(and (= opcode " ++ toString op.opcode ++ ") " ++ extraPredicate op ++ ")") ++
        "))"

def intBinaryOutputPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (op : TouhouFormal.ECL.RawIntBinaryOpShape)
    (kind : TouhouFormal.ECL.RawIntLValueResolutionKind) : String :=
  rawIntLValuePathPredicate resolver op.outputOperandIndex "outputRaw" kind

def intBinaryDivisorPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (op : TouhouFormal.ECL.RawIntBinaryOpShape)
    (rhsPath : RawIntResolverPath)
    (overflow : Bool) : String :=
  let rhsExpr := rawIntResolvedValueExpr resolver op.rhsOperandIndex "rhsRaw" "rhsHost"
  let lhsExpr := rawIntBinaryLhsValueExpr resolver op
  "(and " ++
    rawIntLValueWritablePredicate resolver op.outputOperandIndex "outputRaw" ++
    " " ++ rawIntRValuePathPredicate resolver op.rhsOperandIndex "rhsRaw" rhsPath ++
    " " ++
    (if overflow then
      "(and (= " ++ lhsExpr ++ " " ++ toString TouhouFormal.ECL.int32Min ++
        ") (= " ++ rhsExpr ++ " (- 1)))"
    else
      "(= " ++ rhsExpr ++ " 0)") ++
    ")"

def rawIntBinaryPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawIntBinaryPath) : List String :=
  let dispatchPrefix :=
    [ "(assert (= currentTime instrTime))"
    , "(assert difficultyPass)" ]
  match rawShape.intRValueResolver with
  | none => dispatchPrefix ++ ["(assert false) ; profile has no integer resolver"]
  | some resolver =>
      let nonHazardOps :=
        rawShape.intBinaryOps.filter fun op => !op.kind.isDivisorHazard
      let hazardOps :=
        rawShape.intBinaryOps.filter fun op => op.kind.isDivisorHazard
      dispatchPrefix ++
        match path with
        | .outputRawCell =>
            [ intBinaryOpSetAssertion nonHazardOps fun op =>
                intBinaryOutputPredicate resolver op .rawOperandCell ]
        | .outputResolvedHost =>
            [ intBinaryOpSetAssertion nonHazardOps fun op =>
                intBinaryOutputPredicate resolver op .resolvedHost ]
        | .outputDefaultRawCell =>
            [ intBinaryOpSetAssertion nonHazardOps fun op =>
                intBinaryOutputPredicate resolver op .resolvedDefaultRawCell ]
        | .nonIntOutput =>
            [ intBinaryOpSetAssertion rawShape.intBinaryOps fun op =>
                intBinaryOutputPredicate resolver op .nonIntOutput ]
        | .divisorZero rhsPath =>
            [ intBinaryOpSetAssertion hazardOps fun op =>
                intBinaryDivisorPredicate resolver op rhsPath false ]
        | .divideOverflow rhsPath =>
            [ intBinaryOpSetAssertion hazardOps fun op =>
                intBinaryDivisorPredicate resolver op rhsPath true ]

def bossIntReadSetAssertion
    (reads : List TouhouFormal.ECL.RawBossIntReadShape)
    (extraPredicate : TouhouFormal.ECL.RawBossIntReadShape -> String) : String :=
  match reads with
  | [] => "(assert false) ; profile has no source-backed boss integer-read opcode for this path"
  | [read] =>
      "(assert (and (= opcode " ++ toString read.opcode ++ ") " ++ extraPredicate read ++ "))"
  | reads =>
      "(assert (or " ++
        joinWith " " (reads.map fun read =>
          "(and (= opcode " ++ toString read.opcode ++ ") " ++ extraPredicate read ++ ")") ++
        "))"

def bossIntValueNeedsBossPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossIntReadShape) : String :=
  intResolverSwitchPredicate resolver read.valueOperandIndex "operandMask"

def bossIntIndexValueExpr
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossIntReadShape) : String :=
  rawIntResolvedValueExpr resolver read.bossIndexOperandIndex "bossIndexRaw" "bossIndexHost"

def bossIntOutputWritablePredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossIntReadShape) : String :=
  rawIntLValueWritablePredicate resolver read.outputOperandIndex "outputRaw"

def bossIntIndexInBoundsPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossIntReadShape) : String :=
  let indexExpr := bossIntIndexValueExpr resolver read
  "(and (<= 0 " ++ indexExpr ++ ") (< " ++ indexExpr ++ " " ++
    toString read.bossSlotCount ++ "))"

def bossIntReadPathPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossIntReadShape)
    (path : RawBossIntReadPath) : String :=
  let valueNeedsBoss := bossIntValueNeedsBossPredicate resolver read
  let indexExpr := bossIntIndexValueExpr resolver read
  let outputWritable := bossIntOutputWritablePredicate resolver read
  let indexInBounds := bossIntIndexInBoundsPredicate resolver read
  match path with
  | .valueRawNoBossRead =>
      "(and " ++ outputWritable ++ " (not " ++ valueNeedsBoss ++ "))"
  | .bossIndexBeforeArray =>
      "(and " ++ outputWritable ++ " " ++ valueNeedsBoss ++ " (< " ++ indexExpr ++ " 0))"
  | .bossIndexAtOrPastArray =>
      "(and " ++ outputWritable ++ " " ++ valueNeedsBoss ++ " (<= " ++
        toString read.bossSlotCount ++ " " ++ indexExpr ++ "))"
  | .bossNullDeref =>
      "(and " ++ outputWritable ++ " " ++
        bossIntValueNeedsBossPredicate resolver read ++
        " " ++ intSelectorSetPredicate "valueRaw" read.nullDerefValueSelectors ++
        " " ++ indexInBounds ++ " (not bossPresent))"
  | .bossValueResolvedHost =>
      "(and " ++ outputWritable ++ " " ++
        rawIntRValuePathPredicate resolver read.valueOperandIndex "valueRaw" .resolvedHost ++
        " " ++ indexInBounds ++ " bossPresent)"
  | .bossValueResolvedDefaultRaw =>
      "(and " ++ outputWritable ++ " " ++
        rawIntRValuePathPredicate resolver read.valueOperandIndex "valueRaw" .resolvedDefaultRaw ++
        " " ++ indexInBounds ++ " bossPresent)"

def rawBossIntReadPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawBossIntReadPath) : List String :=
  let dispatchPrefix :=
    [ "(assert (= currentTime instrTime))"
    , "(assert difficultyPass)" ]
  match rawShape.intRValueResolver with
  | none => dispatchPrefix ++ ["(assert false) ; profile has no integer resolver"]
  | some resolver =>
      dispatchPrefix ++
        [ bossIntReadSetAssertion rawShape.bossIntReads fun read =>
            bossIntReadPathPredicate resolver read path ]

def bossFloatReadSetAssertion
    (reads : List TouhouFormal.ECL.RawBossFloatReadShape)
    (extraPredicate : TouhouFormal.ECL.RawBossFloatReadShape -> String) : String :=
  match reads with
  | [] => "(assert false) ; profile has no source-backed boss float-read opcode for this path"
  | [read] =>
      "(assert (and (= opcode " ++ toString read.opcode ++ ") " ++ extraPredicate read ++ "))"
  | reads =>
      "(assert (or " ++
        joinWith " " (reads.map fun read =>
          "(and (= opcode " ++ toString read.opcode ++ ") " ++ extraPredicate read ++ ")") ++
        "))"

def bossFloatValueNeedsBossPredicate
    (resolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossFloatReadShape) : String :=
  floatResolverSwitchPredicate resolver read.valueOperandIndex "operandMask"

def bossFloatIndexValueExpr
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossFloatReadShape) : String :=
  rawIntResolvedValueExpr resolver read.bossIndexOperandIndex "bossIndexRaw" "bossIndexHost"

def bossFloatOutputWritablePredicate
    (resolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossFloatReadShape) : String :=
  rawFloatLValueWritablePredicate resolver read.outputOperandIndex "outputRaw"

def bossFloatIndexInBoundsPredicate
    (resolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossFloatReadShape) : String :=
  let indexExpr := bossFloatIndexValueExpr resolver read
  "(and (<= 0 " ++ indexExpr ++ ") (< " ++ indexExpr ++ " " ++
    toString read.bossSlotCount ++ "))"

def bossFloatNullPolicyPredicate
    (read : TouhouFormal.ECL.RawBossFloatReadShape)
    (policy : TouhouFormal.ECL.RawBossReadNullPolicy) : String :=
  if read.nullPolicy == policy then "true" else "false"

def bossFloatReadPathPredicate
    (intResolver : TouhouFormal.ECL.RawIntOperandResolverShape)
    (floatResolver : TouhouFormal.ECL.RawFloatOperandResolverShape)
    (read : TouhouFormal.ECL.RawBossFloatReadShape)
    (path : RawBossFloatReadPath) : String :=
  let valueNeedsBoss := bossFloatValueNeedsBossPredicate floatResolver read
  let indexExpr := bossFloatIndexValueExpr intResolver read
  let outputWritable := bossFloatOutputWritablePredicate floatResolver read
  let indexInBounds := bossFloatIndexInBoundsPredicate intResolver read
  match path with
  | .valueRawNoBossRead =>
      "(and " ++ outputWritable ++ " (not " ++ valueNeedsBoss ++ "))"
  | .bossIndexBeforeArray =>
      "(and " ++ outputWritable ++ " " ++ valueNeedsBoss ++ " (< " ++ indexExpr ++ " 0))"
  | .bossIndexAtOrPastArray =>
      "(and " ++ outputWritable ++ " " ++ valueNeedsBoss ++ " (<= " ++
        toString read.bossSlotCount ++ " " ++ indexExpr ++ "))"
  | .bossNullDeref =>
      "(and " ++ outputWritable ++ " " ++ valueNeedsBoss ++
        " " ++ bossFloatNullPolicyPredicate read .unguardedDeref ++
        " " ++ intSelectorSetPredicate "valueRaw" read.nullDerefValueSelectors ++
        " " ++ indexInBounds ++ " (not bossPresent))"
  | .bossNullGuardedSkip =>
      "(and " ++ outputWritable ++ " " ++ valueNeedsBoss ++
        " " ++ bossFloatNullPolicyPredicate read .guardedSkip ++
        " " ++ indexInBounds ++ " (not bossPresent))"
  | .bossValueResolvedHost =>
      "(and " ++ outputWritable ++ " " ++
        rawFloatRValuePathPredicate floatResolver read.valueOperandIndex "valueRaw" .resolvedHost ++
        " " ++ indexInBounds ++ " bossPresent)"
  | .bossValueResolvedDefaultRaw =>
      "(and " ++ outputWritable ++ " " ++
        rawFloatRValuePathPredicate floatResolver read.valueOperandIndex "valueRaw" .resolvedDefaultRaw ++
        " " ++ indexInBounds ++ " bossPresent)"

def rawBossFloatReadPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawBossFloatReadPath) : List String :=
  let dispatchPrefix :=
    [ "(assert (= currentTime instrTime))"
    , "(assert difficultyPass)" ]
  match rawShape.intRValueResolver, rawShape.floatRValueResolver with
  | none, _ => dispatchPrefix ++ ["(assert false) ; profile has no integer resolver"]
  | _, none => dispatchPrefix ++ ["(assert false) ; profile has no float resolver"]
  | some intResolver, some floatResolver =>
      dispatchPrefix ++
        [ bossFloatReadSetAssertion rawShape.bossFloatReads fun read =>
            bossFloatReadPathPredicate intResolver floatResolver read path ]

end TouhouFormal.Search.Symbolic
