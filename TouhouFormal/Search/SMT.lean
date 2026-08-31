import TouhouFormal.ECL.Profile
import TouhouFormal.TH06.Raw
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.SMT

private def joinLines : List String -> String
  | [] => ""
  | line :: rest => line ++ "\n" ++ joinLines rest

private def subTableSafetyDefinition
    (predicate subIdName : String)
    (policy : TouhouFormal.ECL.NegativeSubIdPolicy) : String :=
  match policy with
  | .unchecked =>
      "(define-fun " ++ predicate ++ " () Bool (and (<= 0 " ++ subIdName ++
        ") (< " ++ subIdName ++ " subCount)))"
  | .noOp =>
      "(define-fun " ++ predicate ++ " () Bool (or (< " ++ subIdName ++
        " 0) (and (<= 0 " ++ subIdName ++ ") (< " ++ subIdName ++ " subCount))))"

private def concreteSubTableOobQuery
    (title predicate subIdName subIdSort subIdValue : String)
    (policy : TouhouFormal.ECL.NegativeSubIdPolicy)
    (subCountValue : Nat)
    (includeModel : Bool := true) : String :=
  joinLines
    ( [ "(set-logic QF_LIA)"
      , "; Concrete CallEclSub safety query generated from the title negative-sub-id policy."
      , "; Title: " ++ title
      , "(declare-const subCount Int)"
      , "(declare-const " ++ subIdName ++ " Int)"
      , "(assert (= subCount " ++ toString subCountValue ++ "))"
      , "(assert (= " ++ subIdName ++ " " ++ subIdValue ++ "))"
      , subIdSort
      , subTableSafetyDefinition predicate subIdName policy
      , "(assert (not " ++ predicate ++ "))"
      , "(check-sat)" ] ++
      if includeModel then ["(get-model)"] else [] )

private def boundedFindSubTableOobQuery
    (title predicate subIdName subIdSort : String)
    (policy : TouhouFormal.ECL.NegativeSubIdPolicy) : String :=
  joinLines
    [ "(set-logic QF_LIA)"
    , "; Bounded CallEclSub search generated from the title negative-sub-id policy."
    , "; Title: " ++ title
    , "(declare-const subCount Int)"
    , "(declare-const " ++ subIdName ++ " Int)"
    , "(assert (<= 1 subCount))"
    , "(assert (<= subCount 1024))"
    , subIdSort
    , subTableSafetyDefinition predicate subIdName policy
    , "(assert (not " ++ predicate ++ "))"
    , "(check-sat)"
    , "(get-model)" ]

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

def th06SubTableOobQuery : String :=
  concreteSubTableOobQuery
    "TH06"
    "th06_call_safe"
    "arg0"
    (signedI16Range "arg0")
    "256"
    TouhouFormal.TH06.headerShape.negativeSubIdPolicy
    1

def th06FindAnySubTableOobQuery : String :=
  boundedFindSubTableOobQuery
    "TH06"
    "th06_call_safe"
    "arg0"
    (signedI16Range "arg0")
    TouhouFormal.TH06.headerShape.negativeSubIdPolicy

def th07NegativeSubTableOobQuery : String :=
  concreteSubTableOobQuery
    "TH07"
    "th07_call_safe"
    "subId"
    (signedI16Range "subId")
    "(- 1)"
    TouhouFormal.TH07.headerShape.negativeSubIdPolicy
    1

def th08NegativeSubTableNoopUnsatQuery : String :=
  concreteSubTableOobQuery
    "TH08"
    "th08_call_safe"
    "subId"
    (signedI16Range "subId")
    "(- 1)"
    TouhouFormal.TH08.headerShape.negativeSubIdPolicy
    1
    false

def th08PositiveSubTableOobQuery : String :=
  concreteSubTableOobQuery
    "TH08"
    "th08_call_safe"
    "subId"
    (signedI16Range "subId")
    "256"
    TouhouFormal.TH08.headerShape.negativeSubIdPolicy
    1

private def concreteRelativeJumpOobQuery
    (title displacementValue : String)
    (bufferSize : Nat) : String :=
  joinLines
    [ "(set-logic QF_LIA)"
    , "; Concrete relative-jump target query generated from shared cursor-transfer semantics."
    , "; Title: " ++ title
    , "(declare-const fileOffset Int)"
    , "(declare-const displacement Int)"
    , "(declare-const bufferSize Int)"
    , "(assert (= fileOffset 0))"
    , "(assert (= displacement " ++ displacementValue ++ "))"
    , "(assert (= bufferSize " ++ toString bufferSize ++ "))"
    , signedI32Range "displacement"
    , "(define-fun targetCursor () Int (+ fileOffset displacement))"
    , "(define-fun cursor_safe () Bool (and (<= 0 targetCursor) (< targetCursor bufferSize)))"
    , "(assert (not cursor_safe))"
    , "(check-sat)"
    , "(get-model)" ]

def th06JumpMinusOneOobQuery : String :=
  concreteRelativeJumpOobQuery
    "TH06"
    "(- 1)"
    24

def th07JumpMinusOneOobQuery : String :=
  concreteRelativeJumpOobQuery
    "TH07"
    "(- 1)"
    20

def th08JumpMinusOneOobQuery : String :=
  concreteRelativeJumpOobQuery
    "TH08"
    "(- 1)"
    20

inductive CursorTarget where
  | beforeBuffer
  | nonProgress
  | atOrPastEnd
deriving Repr, DecidableEq

private def CursorTarget.name : CursorTarget -> String
  | .beforeBuffer => "before-buffer"
  | .nonProgress => "non-progress"
  | .atOrPastEnd => "at-or-past-end"

private def CursorTarget.assertion : CursorTarget -> String
  | .beforeBuffer => "(assert (< targetCursor 0))"
  | .nonProgress => "(assert (= targetCursor fileOffset))"
  | .atOrPastEnd => "(assert (<= bufferSize targetCursor))"

private def cursorDeltaClassQuery
    (title fieldName fieldDescription : String)
    (width : TouhouFormal.ScalarWidth)
    (bufferSize : Nat)
    (target : CursorTarget)
    (includeModel : Bool := true) : String :=
  joinLines
    ( [ "(set-logic QF_LIA)"
      , "; Cursor-delta query generated from shared cursor-transfer semantics and profile scalar width."
      , "; Title: " ++ title
      , "; Field: " ++ fieldDescription
      , "; Target: " ++ target.name
      , "(declare-const fileOffset Int)"
      , "(declare-const " ++ fieldName ++ " Int)"
      , "(declare-const bufferSize Int)"
      , "(assert (= fileOffset 0))"
      , "(assert (= bufferSize " ++ toString bufferSize ++ "))"
      , scalarRange fieldName width
      , "(define-fun targetCursor () Int (+ fileOffset " ++ fieldName ++ "))"
      , target.assertion
      , "(check-sat)" ] ++
      if includeModel then ["(get-model)"] else [] )

private def missingProfileQuery (title fieldDescription : String) : String :=
  joinLines
    [ "(set-logic QF_LIA)"
    , "; Profile is missing the requested cursor-delta field."
    , "; Title: " ++ title
    , "; Field: " ++ fieldDescription
    , "(assert false)"
    , "(check-sat)" ]

private def timelineSizeCursorQuery
    (shape : TouhouFormal.ECL.HeaderShape)
    (bufferSize : Nat)
    (target : CursorTarget)
    (includeModel : Bool := true) : String :=
  match shape.timelineShape with
  | none => missingProfileQuery shape.title "timeline.size"
  | some timelineShape =>
      cursorDeltaClassQuery
        shape.title
        "size"
        "timeline.size"
        timelineShape.sizeWidth
        bufferSize
        target
        includeModel

private def rawNextOffsetCursorQuery
    (shape : TouhouFormal.ECL.HeaderShape)
    (bufferSize : Nat)
    (target : CursorTarget)
    (includeModel : Bool := true) : String :=
  match shape.rawInstrShape with
  | none => missingProfileQuery shape.title "raw.nextOffset"
  | some rawShape =>
      cursorDeltaClassQuery
        shape.title
        "nextOffset"
        "raw.nextOffset"
        rawShape.nextOffsetWidth
        bufferSize
        target
        includeModel

def th06TimelineSizeBeforeBufferQuery : String :=
  timelineSizeCursorQuery
    TouhouFormal.TH06.headerShape
    TouhouFormal.TH06.rawZeroSizeTimelinePrefixBytes.size
    .beforeBuffer

def th07TimelineSizeBeforeBufferQuery : String :=
  timelineSizeCursorQuery
    TouhouFormal.TH07.headerShape
    TouhouFormal.TH07.timelineInstrFixedSize
    .beforeBuffer

def th08TimelineSizeBeforeBufferUnsatQuery : String :=
  timelineSizeCursorQuery
    TouhouFormal.TH08.headerShape
    TouhouFormal.TH08.rawTimelinePrefixBytes.size
    .beforeBuffer
    false

def th08TimelineSizeNonProgressQuery : String :=
  timelineSizeCursorQuery
    TouhouFormal.TH08.headerShape
    TouhouFormal.TH08.rawTimelinePrefixBytes.size
    .nonProgress

def th06RawNextOffsetBeforeBufferQuery : String :=
  rawNextOffsetCursorQuery
    TouhouFormal.TH06.headerShape
    TouhouFormal.TH06.rawZeroNextOffsetInstrPrefixBytes.size
    .beforeBuffer

def th07RawNextOffsetBeforeBufferQuery : String :=
  rawNextOffsetCursorQuery
    TouhouFormal.TH07.headerShape
    TouhouFormal.TH07.rawInstrPrefixBytes.size
    .beforeBuffer

def th08RawNextOffsetBeforeBufferQuery : String :=
  rawNextOffsetCursorQuery
    TouhouFormal.TH08.headerShape
    TouhouFormal.TH08.rawInstrPrefixBytes.size
    .beforeBuffer

def th08RawDifficultyOverrideDeltaQuery : String :=
  joinLines
    [ "(set-logic QF_BV)"
    , "; Find an instruction difficulty mask that old-style active-bit intersection would execute"
    , "; but TH08 raw ECL override semantics skips."
    , "; TH08 source requires instructionMask to contain difficultyMask | eclDifficultyMaskOverride."
    , "(declare-const instructionMask (_ BitVec 8))"
    , "(define-fun activeMask () (_ BitVec 8) #x01)"
    , "(define-fun overrideMask () (_ BitVec 8) #x02)"
    , "(define-fun requiredMask () (_ BitVec 8) (bvor activeMask overrideMask))"
    , "(define-fun old_intersects_active () Bool (not (= (bvand instructionMask activeMask) #x00)))"
    , "(define-fun th08_contains_active_and_override () Bool (= (bvand instructionMask requiredMask) requiredMask))"
    , "(assert old_intersects_active)"
    , "(assert (not th08_contains_active_and_override))"
    , "(check-sat)"
    , "(get-model)" ]

end TouhouFormal.Search.SMT
