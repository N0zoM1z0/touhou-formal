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

inductive RawScalarKind where
  | int
  | float
deriving Repr, DecidableEq

def RawScalarKind.name : RawScalarKind -> String
  | .int => "int"
  | .float => "float"

inductive RawScalarAssignOutputPolicy where
  | intLValue
  | floatLValue
  | sourceSetVar
deriving Repr, DecidableEq

def RawScalarAssignOutputPolicy.name : RawScalarAssignOutputPolicy -> String
  | .intLValue => "int-lvalue"
  | .floatLValue => "float-lvalue"
  | .sourceSetVar => "source-set-var"

inductive RawScalarAssignRValuePolicy where
  | intBits
  | floatBits
deriving Repr, DecidableEq

def RawScalarAssignRValuePolicy.name : RawScalarAssignRValuePolicy -> String
  | .intBits => "int-bits"
  | .floatBits => "float-bits"

structure RawScalarAssignShape where
  opcode : Int
  outputPolicy : RawScalarAssignOutputPolicy
  rvaluePolicy : RawScalarAssignRValuePolicy
  outputOperandIndex : Nat
  valueOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawIntUnaryUpdateKind where
  | inc
  | dec
deriving Repr, DecidableEq

def RawIntUnaryUpdateKind.name : RawIntUnaryUpdateKind -> String
  | .inc => "inc"
  | .dec => "dec"

inductive RawIntUnaryUpdateOutputPolicy where
  | intLValue
  | sourceGetVarPointer
deriving Repr, DecidableEq

def RawIntUnaryUpdateOutputPolicy.name : RawIntUnaryUpdateOutputPolicy -> String
  | .intLValue => "int-lvalue"
  | .sourceGetVarPointer => "source-getvar-pointer"

structure RawIntUnaryUpdateShape where
  opcode : Int
  kind : RawIntUnaryUpdateKind
  outputPolicy : RawIntUnaryUpdateOutputPolicy
  outputOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawBinaryOpKind where
  | add
  | sub
  | mul
  | div
  | mod
deriving Repr, DecidableEq

abbrev RawIntBinaryOpKind := RawBinaryOpKind

def RawBinaryOpKind.name : RawBinaryOpKind -> String
  | .add => "add"
  | .sub => "sub"
  | .mul => "mul"
  | .div => "div"
  | .mod => "mod"

def RawBinaryOpKind.isDivisorHazard : RawBinaryOpKind -> Bool
  | .div | .mod => true
  | _ => false

inductive RawBinaryOpMode where
  | assign
  | updateInPlace
deriving Repr, DecidableEq

abbrev RawIntBinaryOpMode := RawBinaryOpMode

def RawBinaryOpMode.name : RawBinaryOpMode -> String
  | .assign => "assign"
  | .updateInPlace => "update-in-place"

structure RawIntBinaryOpShape where
  opcode : Int
  kind : RawBinaryOpKind
  mode : RawBinaryOpMode
  outputOperandIndex : Nat
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

structure RawFloatBinaryOpShape where
  opcode : Int
  kind : RawBinaryOpKind
  mode : RawBinaryOpMode
  outputOperandIndex : Nat
  lhsOperandIndex : Nat
  rhsOperandIndex : Nat
deriving Repr, DecidableEq

inductive RawFloatFunctionKind where
  | sin
  | cos
  | atan2
  | vectorAngle
  | normalizeAngle
deriving Repr, DecidableEq

def RawFloatFunctionKind.name : RawFloatFunctionKind -> String
  | .sin => "sin"
  | .cos => "cos"
  | .atan2 => "atan2"
  | .vectorAngle => "vector-angle"
  | .normalizeAngle => "normalize-angle"

inductive RawFloatFunctionInputPolicy where
  | floatRValues
  | sourceGetVarPointerBits
deriving Repr, DecidableEq

def RawFloatFunctionInputPolicy.name : RawFloatFunctionInputPolicy -> String
  | .floatRValues => "float-rvalues"
  | .sourceGetVarPointerBits => "source-getvar-pointer-bits"

structure RawFloatFunctionShape where
  opcode : Int
  kind : RawFloatFunctionKind
  outputPolicy : RawScalarAssignOutputPolicy
  inputPolicy : RawFloatFunctionInputPolicy
  outputOperandIndex : Nat
  inputOperandIndices : List Nat
deriving Repr, DecidableEq

inductive RawRandomOpKind where
  | intRange
  | intRangeAdd
  | floatRange
  | floatRangeAdd
  | intSign
  | floatSign
deriving Repr, DecidableEq

def RawRandomOpKind.name : RawRandomOpKind -> String
  | .intRange => "int-range"
  | .intRangeAdd => "int-range-add"
  | .floatRange => "float-range"
  | .floatRangeAdd => "float-range-add"
  | .intSign => "int-sign"
  | .floatSign => "float-sign"

def RawRandomOpKind.scalarKind : RawRandomOpKind -> RawScalarKind
  | .intRange | .intRangeAdd | .intSign => .int
  | .floatRange | .floatRangeAdd | .floatSign => .float

inductive RawRandomEntropyKind where
  | u32Range
  | floatZeroToOne
  | u16Parity
deriving Repr, DecidableEq

def RawRandomEntropyKind.name : RawRandomEntropyKind -> String
  | .u32Range => "u32-range"
  | .floatZeroToOne => "float-zero-to-one"
  | .u16Parity => "u16-parity"

def RawRandomOpKind.entropyKind : RawRandomOpKind -> RawRandomEntropyKind
  | .intRange | .intRangeAdd => .u32Range
  | .floatRange | .floatRangeAdd => .floatZeroToOne
  | .intSign | .floatSign => .u16Parity

def RawRandomOpKind.requiresAddend : RawRandomOpKind -> Bool
  | .intRangeAdd | .floatRangeAdd => true
  | _ => false

inductive RawRandomWritePolicy where
  | direct
  | sourceSetVarResolvesResultBits
deriving Repr, DecidableEq

def RawRandomWritePolicy.name : RawRandomWritePolicy -> String
  | .direct => "direct"
  | .sourceSetVarResolvesResultBits => "source-setvar-resolves-result-bits"

structure RawRandomOpShape where
  opcode : Int
  kind : RawRandomOpKind
  outputPolicy : RawScalarAssignOutputPolicy
  writePolicy : RawRandomWritePolicy
  outputOperandIndex : Nat
  valueOperandIndex : Nat
  addendOperandIndex : Option Nat := none
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
  excludedRanges : List IntSelectorRange := []
deriving Repr, DecidableEq

def IntSelectorSet.contains (set : IntSelectorSet) (value : Int) : Bool :=
  set.ranges.any (fun range => range.contains value) &&
    !set.exclusions.contains value &&
    !set.excludedRanges.any (fun range => range.contains value)

inductive RawBossReadNullPolicy where
  | unguardedDeref
  | guardedSkip
deriving Repr, DecidableEq

def RawBossReadNullPolicy.name : RawBossReadNullPolicy -> String
  | .unguardedDeref => "unguarded-deref"
  | .guardedSkip => "guarded-skip"

structure RawBossIntReadShape where
  opcode : Int
  outputOperandIndex : Nat
  valueOperandIndex : Nat
  bossIndexOperandIndex : Nat
  bossSlotCount : Nat
  nullDerefValueSelectors : IntSelectorSet := {}
deriving Repr, DecidableEq

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

structure RawFloatOperandResolverShape where
  maskPolicy : RawIntOperandMaskPolicy
  knownRValueSelectors : IntSelectorSet
  knownLValueSelectors : IntSelectorSet := {}
deriving Repr, DecidableEq

structure RawBossFloatReadShape where
  opcode : Int
  outputOperandIndex : Nat
  valueOperandIndex : Nat
  bossIndexOperandIndex : Nat
  bossSlotCount : Nat
  nullPolicy : RawBossReadNullPolicy
  nullDerefValueSelectors : IntSelectorSet := {}
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
  floatRValueResolver : Option RawFloatOperandResolverShape := none
  intConditionJumps : List RawIntConditionJumpShape := []
  callRetShape : Option RawCallRetShape := none
  conditionalCallShapes : List RawConditionalCallShape := []
  scalarAssignments : List RawScalarAssignShape := []
  intUnaryUpdates : List RawIntUnaryUpdateShape := []
  intBinaryOps : List RawIntBinaryOpShape := []
  floatBinaryOps : List RawFloatBinaryOpShape := []
  floatFunctions : List RawFloatFunctionShape := []
  randomOps : List RawRandomOpShape := []
  bossIntReads : List RawBossIntReadShape := []
  bossFloatReads : List RawBossFloatReadShape := []
  intDivisorHazards : List RawIntDivisorHazard := []
deriving Repr, DecidableEq

def RawInstrShape.findBossIntRead?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBossIntReadShape :=
  rawShape.bossIntReads.find? (fun read => read.opcode == opcode)

def RawInstrShape.findBossFloatRead?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawBossFloatReadShape :=
  rawShape.bossFloatReads.find? (fun read => read.opcode == opcode)

def RawInstrShape.findIntBinaryOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntBinaryOpShape :=
  rawShape.intBinaryOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findFloatBinaryOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawFloatBinaryOpShape :=
  rawShape.floatBinaryOps.find? (fun op => op.opcode == opcode)

def RawInstrShape.findFloatFunction?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawFloatFunctionShape :=
  rawShape.floatFunctions.find? (fun op => op.opcode == opcode)

def RawInstrShape.findRandomOp?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawRandomOpShape :=
  rawShape.randomOps.find? (fun op => op.opcode == opcode)

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

def RawInstrShape.findScalarAssign?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawScalarAssignShape :=
  rawShape.scalarAssignments.find? (fun op => op.opcode == opcode)

def RawInstrShape.findIntUnaryUpdate?
    (rawShape : RawInstrShape)
    (opcode : Int) : Option RawIntUnaryUpdateShape :=
  rawShape.intUnaryUpdates.find? (fun op => op.opcode == opcode)

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
