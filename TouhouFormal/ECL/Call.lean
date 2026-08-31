import TouhouFormal.Core.Fault
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

def subTableOobFault (shape : HeaderShape) (subId : Int) (subCount : Nat) : Fault :=
  Fault.outOfBoundsRead
    shape.title
    "EclManager.CallEclSub"
    "source reads this->subTable[subId] with only the title-specific negative-id policy"
    subId
    subCount

def isSubIdInBounds (subOffsets : Array Nat) (subId : Int) : Bool :=
  if subId < 0 then
    false
  else
    subId.toNat < subOffsets.size

def lookupSubOffset (shape : HeaderShape) (subOffsets : Array Nat) (subId : Int) :
    Except Fault (Option Nat) :=
  if subId < 0 then
    match shape.negativeSubIdPolicy with
    | .noOp => .ok none
    | .unchecked => .error (subTableOobFault shape subId subOffsets.size)
  else
    match subOffsets[subId.toNat]? with
    | some offset => .ok (some offset)
    | none => .error (subTableOobFault shape subId subOffsets.size)

end TouhouFormal.ECL
