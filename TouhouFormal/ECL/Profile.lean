import TouhouFormal.Core.Evidence
import TouhouFormal.Core.Scalar

namespace TouhouFormal.ECL

inductive NegativeSubIdPolicy where
  | unchecked
  | noOp
deriving Repr, DecidableEq

inductive DifficultyMaskPolicy where
  | intersectsActive
  | containsActiveAndOverride
deriving Repr, DecidableEq

def NegativeSubIdPolicy.name : NegativeSubIdPolicy -> String
  | .unchecked => "unchecked"
  | .noOp => "no-op"

def DifficultyMaskPolicy.name : DifficultyMaskPolicy -> String
  | .intersectsActive => "intersects-active"
  | .containsActiveAndOverride => "contains-active-and-override"

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

structure RawFixedJumpShape where
  opcode : Int
  targetTimeOperandIndex : Nat
  displacementOperandIndex : Nat
deriving Repr, DecidableEq

structure RawDecJumpShape where
  opcode : Int
  targetTimeOperandIndex : Nat
  displacementOperandIndex : Nat
  counterOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawIntDivisorHazardKind where
  | div
  | mod
deriving Repr, DecidableEq

def RawIntDivisorHazardKind.name : RawIntDivisorHazardKind -> String
  | .div => "div"
  | .mod => "mod"

structure RawIntDivisorHazard where
  opcode : Int
  kind : RawIntDivisorHazardKind
  divisorOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawIntBinaryOpKind where
  | add
  | sub
  | mul
  | div
  | mod
deriving Repr, DecidableEq

def RawIntBinaryOpKind.name : RawIntBinaryOpKind -> String
  | .add => "add"
  | .sub => "sub"
  | .mul => "mul"
  | .div => "div"
  | .mod => "mod"

def RawIntBinaryOpKind.isDivisorHazard : RawIntBinaryOpKind -> Bool
  | .div | .mod => true
  | _ => false

inductive RawIntBinaryOpMode where
  | assign
  | updateInPlace
deriving Repr, DecidableEq

def RawIntBinaryOpMode.name : RawIntBinaryOpMode -> String
  | .assign => "assign"
  | .updateInPlace => "update-in-place"

structure RawIntBinaryOpShape where
  opcode : Int
  kind : RawIntBinaryOpKind
  mode : RawIntBinaryOpMode
  outputOperandIndex : Nat
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

structure IntSelectorRange where
  first : Int
  last : Int
deriving Repr, DecidableEq

def IntSelectorRange.contains (range : IntSelectorRange) (value : Int) : Bool :=
  decide (range.first <= value ∧ value <= range.last)

structure IntSelectorSet where
  ranges : List IntSelectorRange := []
  exclusions : List Int := []
deriving Repr, DecidableEq

def IntSelectorSet.contains (set : IntSelectorSet) (value : Int) : Bool :=
  set.ranges.any (fun range => range.contains value) &&
    !set.exclusions.contains value

inductive RawIntOperandMaskPolicy where
  | noMaskAlwaysResolve
  | bitSetMeansResolve
deriving Repr, DecidableEq

def RawIntOperandMaskPolicy.name : RawIntOperandMaskPolicy -> String
  | .noMaskAlwaysResolve => "no-mask-always-resolve"
  | .bitSetMeansResolve => "bit-set-means-resolve"

structure RawIntOperandResolverShape where
  maskPolicy : RawIntOperandMaskPolicy
  knownRValueSelectors : IntSelectorSet
  knownLValueSelectors : IntSelectorSet := {}
deriving Repr, DecidableEq

inductive RawIntCompareOp where
  | eq
  | neq
  | lt
  | le
  | gt
  | ge
deriving Repr, DecidableEq

def RawIntCompareOp.name : RawIntCompareOp -> String
  | .eq => "eq"
  | .neq => "neq"
  | .lt => "lt"
  | .le => "le"
  | .gt => "gt"
  | .ge => "ge"

def RawIntCompareOp.holds (op : RawIntCompareOp) (lhs rhs : Int) : Bool :=
  match op with
  | .eq => lhs == rhs
  | .neq => lhs != rhs
  | .lt => decide (lhs < rhs)
  | .le => decide (lhs <= rhs)
  | .gt => decide (lhs > rhs)
  | .ge => decide (lhs >= rhs)

inductive RawIntConditionSource where
  | compareRegister
  | resolvedOperands
deriving Repr, DecidableEq

def RawIntConditionSource.name : RawIntConditionSource -> String
  | .compareRegister => "compare-register"
  | .resolvedOperands => "resolved-operands"

structure RawIntConditionJumpShape where
  opcode : Int
  op : RawIntCompareOp
  source : RawIntConditionSource
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
  targetTimeOperandIndex : Nat
  displacementOperandIndex : Nat
deriving Repr, DecidableEq

structure RawConditionalCallShape where
  opcode : Int
  op : RawIntCompareOp
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawRetUnderflowPolicy where
  | uncheckedSavedContextRead
  | th08ChildContextExit
deriving Repr, DecidableEq

def RawRetUnderflowPolicy.name : RawRetUnderflowPolicy -> String
  | .uncheckedSavedContextRead => "unchecked-saved-context-read"
  | .th08ChildContextExit => "th08-child-context-exit"

structure RawCallRetShape where
  callOpcode : Int
  retOpcode : Int
  subIdOperandIndex : Nat
  stackEntryCount : Nat
  stackIncrementGuardExclusive : Nat
  retUnderflowPolicy : RawRetUnderflowPolicy
  childContextSlotCount : Nat := 0
deriving Repr, DecidableEq

structure RawInstrShape where
  fixedPrefixBytes : Nat
  timeOffset : Nat
  timeWidth : ScalarWidth
  opcodeOffset : Nat
  opcodeWidth : ScalarWidth
  unimplementedOpcode : Option Int := none
  nextOffsetOffset : Nat
  nextOffsetWidth : ScalarWidth
  difficultyMaskOffset : Option Nat := none
  difficultyMaskWidth : Option ScalarWidth := none
  difficultyMaskPolicy : Option DifficultyMaskPolicy := none
  operandMaskOffset : Option Nat := none
  operandMaskWidth : Option ScalarWidth := none
  fixedI32OperandBaseOffset : Option Nat := none
  fixedI32OperandStride : Nat := 4
  fixedJumpShape : Option RawFixedJumpShape := none
  fixedDecJumpShape : Option RawDecJumpShape := none
  intRValueResolver : Option RawIntOperandResolverShape := none
  intConditionJumps : List RawIntConditionJumpShape := []
  callRetShape : Option RawCallRetShape := none
  conditionalCallShapes : List RawConditionalCallShape := []
  intBinaryOps : List RawIntBinaryOpShape := []
  intDivisorHazards : List RawIntDivisorHazard := []
deriving Repr, DecidableEq

def RawInstrShape.findIntBinaryOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntBinaryOpShape :=
  rawShape.intBinaryOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findIntDivisorHazard?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntDivisorHazard :=
  rawShape.intDivisorHazards.find? (fun hazard => hazard.opcode == opcode)

def RawInstrShape.findIntConditionJump?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntConditionJumpShape :=
  rawShape.intConditionJumps.find? (fun jump => jump.opcode == opcode)

def RawInstrShape.findConditionalCall?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawConditionalCallShape :=
  rawShape.conditionalCallShapes.find? (fun call => call.opcode == opcode)

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
