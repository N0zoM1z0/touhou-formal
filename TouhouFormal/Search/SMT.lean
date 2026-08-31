import TouhouFormal.ECL.Profile
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
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

private def signedI32Range (name : String) : String :=
  "(assert (and (<= (- 2147483648) " ++ name ++ ") (<= " ++ name ++ " 2147483647)))"

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

end TouhouFormal.Search.SMT
