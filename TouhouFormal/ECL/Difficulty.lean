import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

def bitIsSet (mask bit : Nat) : Bool :=
  decide (((mask / (2 ^ bit)) % 2) = 1)

def intersectsMaskUpTo (maxBits instructionMask activeMask : Nat) : Bool :=
  (List.range maxBits).any fun bit =>
    bitIsSet instructionMask bit && bitIsSet activeMask bit

def containsActiveAndOverrideUpTo
    (maxBits instructionMask activeMask overrideMask : Nat) : Bool :=
  (List.range maxBits).all fun bit =>
    if bitIsSet activeMask bit || bitIsSet overrideMask bit then
      bitIsSet instructionMask bit
    else
      true

def DifficultyMaskPolicy.shouldExecute
    (policy : DifficultyMaskPolicy)
    (instructionMask activeMask overrideMask maxBits : Nat) : Bool :=
  match policy with
  | .intersectsActive =>
      intersectsMaskUpTo maxBits instructionMask activeMask
  | .containsActiveAndOverride =>
      containsActiveAndOverrideUpTo maxBits instructionMask activeMask overrideMask

def rawInstrShouldExecute?
    (shape : HeaderShape)
    (instructionMask activeMask overrideMask maxBits : Nat) : Option Bool :=
  match shape.rawInstrShape with
  | none => none
  | some rawShape =>
      rawShape.difficultyMaskPolicy.map fun policy =>
        policy.shouldExecute instructionMask activeMask overrideMask maxBits

end TouhouFormal.ECL
