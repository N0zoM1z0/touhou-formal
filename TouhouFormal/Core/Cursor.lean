namespace TouhouFormal

inductive CursorClass where
  | beforeBuffer
  | atOrPastEnd
  | nonProgress
  | inBounds
deriving Repr, DecidableEq

def CursorClass.name : CursorClass -> String
  | .beforeBuffer => "before-buffer"
  | .atOrPastEnd => "at-or-past-end"
  | .nonProgress => "non-progress"
  | .inBounds => "in-bounds"

def relativeCursor (sourceOffset : Nat) (displacement : Int) : Int :=
  Int.ofNat sourceOffset + displacement

def classifyCursorTransfer (sourceOffset : Nat) (targetCursor : Int) (bufferSize : Nat) :
    CursorClass :=
  if targetCursor < 0 then
    .beforeBuffer
  else if bufferSize <= targetCursor.toNat then
    .atOrPastEnd
  else if targetCursor = Int.ofNat sourceOffset then
    .nonProgress
  else
    .inBounds

def classifyRelativeCursor (sourceOffset : Nat) (displacement : Int) (bufferSize : Nat) :
    CursorClass :=
  classifyCursorTransfer sourceOffset (relativeCursor sourceOffset displacement) bufferSize

end TouhouFormal
