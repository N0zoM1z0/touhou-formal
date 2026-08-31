import TouhouFormal.ECL.Call
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Call

inductive LookupClass where
  | okOffset
  | okNoOp
  | fault
deriving Repr, DecidableEq

def LookupClass.name : LookupClass -> String
  | .okOffset => "ok-offset"
  | .okNoOp => "ok-no-op"
  | .fault => "fault"

structure LookupProbe where
  title : String
  subCount : Nat
  subId : Int
  lookupClass : LookupClass
  fault : Option TouhouFormal.Fault := none
deriving Repr, DecidableEq

def subOffsetsOfCount (subCount : Nat) : Array Nat :=
  (List.replicate subCount 0).toArray

def lookupClassOfResult : Except TouhouFormal.Fault (Option Nat) -> LookupClass
  | .ok (some _) => .okOffset
  | .ok none => .okNoOp
  | .error _ => .fault

def lookupFault? : Except TouhouFormal.Fault (Option Nat) -> Option TouhouFormal.Fault
  | .ok _ => none
  | .error faultValue => some faultValue

def probeLookup
    (shape : TouhouFormal.ECL.HeaderShape)
    (subCount : Nat)
    (subId : Int) : LookupProbe :=
  let result := TouhouFormal.ECL.lookupSubOffset shape (subOffsetsOfCount subCount) subId
  { title := shape.title
    subCount := subCount
    subId := subId
    lookupClass := lookupClassOfResult result
    fault := lookupFault? result }

def candidateSubCounts : List Nat :=
  [1, 2]

def candidateSubIds : List Int :=
  [-1, 0, 1, 256]

def lookupSweep (shape : TouhouFormal.ECL.HeaderShape) : List LookupProbe :=
  candidateSubCounts.flatMap fun subCount =>
    candidateSubIds.map fun subId =>
      probeLookup shape subCount subId

def LookupProbe.isFault (probe : LookupProbe) : Bool :=
  decide (probe.lookupClass = .fault)

def firstFault? (shape : TouhouFormal.ECL.HeaderShape) : Option LookupProbe :=
  (lookupSweep shape).find? LookupProbe.isFault

def th06FirstFault? : Option LookupProbe :=
  firstFault? TouhouFormal.TH06.headerShape

def th07FirstFault? : Option LookupProbe :=
  firstFault? TouhouFormal.TH07.headerShape

def th08FirstFault? : Option LookupProbe :=
  firstFault? TouhouFormal.TH08.headerShape

theorem th06_first_fault_expected :
    th06FirstFault? =
      some
        { title := TouhouFormal.TH06.title
          subCount := 1
          subId := -1
          lookupClass := .fault
          fault :=
            some
              (TouhouFormal.ECL.subTableOobFault
                TouhouFormal.TH06.headerShape
                (-1)
                1) } := by
  rfl

theorem th07_first_fault_expected :
    th07FirstFault? =
      some
        { title := TouhouFormal.TH07.title
          subCount := 1
          subId := -1
          lookupClass := .fault
          fault :=
            some
              (TouhouFormal.ECL.subTableOobFault
                TouhouFormal.TH07.headerShape
                (-1)
                1) } := by
  rfl

theorem th08_first_fault_expected :
    th08FirstFault? =
      some
        { title := TouhouFormal.TH08.title
          subCount := 1
          subId := 1
          lookupClass := .fault
          fault :=
            some
              (TouhouFormal.ECL.subTableOobFault
                TouhouFormal.TH08.headerShape
                1
                1) } := by
  rfl

end TouhouFormal.Search.Call
