import TouhouFormal.Core.Evidence

namespace TouhouFormal.ECL

inductive NegativeSubIdPolicy where
  | unchecked
  | noOp
deriving Repr, DecidableEq

def NegativeSubIdPolicy.name : NegativeSubIdPolicy -> String
  | .unchecked => "unchecked"
  | .noOp => "no-op"

structure HeaderShape where
  title : String
  hasVersionField : Bool
  expectedVersion : Option Nat := none
  fixedHeaderBytes : Nat
  timelineSlots : Nat
  subTableField : String
  negativeSubIdPolicy : NegativeSubIdPolicy
  evidence : List TouhouFormal.SourceRef := []
deriving Repr, DecidableEq

private def showOptNat : Option Nat -> String
  | none => "-"
  | some value => toString value

def HeaderShape.summary (shape : HeaderShape) : String :=
  shape.title ++
    " headerBytes=" ++ toString shape.fixedHeaderBytes ++
    " timelineSlots=" ++ toString shape.timelineSlots ++
    " expectedVersion=" ++ showOptNat shape.expectedVersion ++
    " negativeSubId=" ++ shape.negativeSubIdPolicy.name

end TouhouFormal.ECL
