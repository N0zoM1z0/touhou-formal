import TouhouFormal.Core.Evidence

namespace TouhouFormal.ECL

inductive NegativeSubIdPolicy where
  | unchecked
  | noOp
deriving Repr, DecidableEq

def NegativeSubIdPolicy.name : NegativeSubIdPolicy -> String
  | .unchecked => "unchecked"
  | .noOp => "no-op"

inductive ScalarWidth where
  | u8
  | u16
  | u32
  | i16
  | i32
deriving Repr, DecidableEq

def ScalarWidth.bytes : ScalarWidth -> Nat
  | .u8 => 1
  | .u16 => 2
  | .u32 => 4
  | .i16 => 2
  | .i32 => 4

structure TimelineShape where
  fixedSize : Nat
  timeOffset : Nat
  timeWidth : ScalarWidth
  opcodeOffset : Nat
  opcodeWidth : ScalarWidth
  sizeOffset : Nat
  sizeWidth : ScalarWidth
  firstArgOffset : Option Nat := none
  firstArgWidth : Option ScalarWidth := none
deriving Repr, DecidableEq

structure RawInstrShape where
  fixedPrefixBytes : Nat
  timeOffset : Nat
  timeWidth : ScalarWidth
  opcodeOffset : Nat
  opcodeWidth : ScalarWidth
  nextOffsetOffset : Nat
  nextOffsetWidth : ScalarWidth
  difficultyMaskOffset : Option Nat := none
  difficultyMaskWidth : Option ScalarWidth := none
  operandMaskOffset : Option Nat := none
  operandMaskWidth : Option ScalarWidth := none
deriving Repr, DecidableEq

structure HeaderShape where
  title : String
  hasVersionField : Bool
  versionOffset : Option Nat := none
  expectedVersion : Option Nat := none
  subCountOffset : Nat
  timelineCountOffset : Nat
  timelineTableOffset : Nat
  fixedHeaderBytes : Nat
  timelineSlots : Nat
  loaderTimelineSlots : Nat
  subTableField : String
  negativeSubIdPolicy : NegativeSubIdPolicy
  timelineShape : Option TimelineShape := none
  rawInstrShape : Option RawInstrShape := none
  evidence : List TouhouFormal.SourceRef := []
deriving Repr, DecidableEq

private def showOptNat : Option Nat -> String
  | none => "-"
  | some value => toString value

def HeaderShape.summary (shape : HeaderShape) : String :=
  shape.title ++
    " headerBytes=" ++ toString shape.fixedHeaderBytes ++
    " timelineSlots=" ++ toString shape.timelineSlots ++
    " loaderTimelineSlots=" ++ toString shape.loaderTimelineSlots ++
    " expectedVersion=" ++ showOptNat shape.expectedVersion ++
    " negativeSubId=" ++ shape.negativeSubIdPolicy.name

def HeaderShape.timelineTableEnd (shape : HeaderShape) : Nat :=
  shape.timelineTableOffset + 4 * shape.timelineSlots

end TouhouFormal.ECL
