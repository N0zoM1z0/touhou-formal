import TouhouFormal.ECL.Difficulty
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

inductive RawIntOperandResolutionKind where
  | rawImmediate
  | resolvedHost
  | resolvedDefaultRaw
deriving Repr, DecidableEq

def RawIntOperandResolutionKind.name : RawIntOperandResolutionKind -> String
  | .rawImmediate => "raw-immediate"
  | .resolvedHost => "resolved-host"
  | .resolvedDefaultRaw => "resolved-default-raw"

structure RawIntOperandResolution where
  kind : RawIntOperandResolutionKind
  value : Int
  rawValue : Int
  hostValue : Option Int := none
  selectorKnown : Bool
  flagEnabled : Bool
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclOperand.intRValue"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingIntResolverFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclOperand.intRValue"
    detail := "profile does not define integer rvalue resolver semantics" }

private def missingOperandMaskFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclOperand.intRValue"
    detail := "profile requires an operand mask but decoded prefix has none" }

private def negativeOperandMaskFault (shape : HeaderShape) (mask : Int) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclOperand.intRValue"
    detail := "decoded operand mask is negative"
    index := some mask }

def rawIntOperandFlagEnabled
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (resolver : RawIntOperandResolverShape) : Except Fault Bool :=
  match resolver.maskPolicy with
  | .noMaskAlwaysResolve => .ok true
  | .bitSetMeansResolve =>
      match rawPrefix.operandMask with
      | none => .error (missingOperandMaskFault shape)
      | some mask =>
          if mask < 0 then
            .error (negativeOperandMaskFault shape mask)
          else
            .ok (bitIsSet mask.toNat slot)

def resolveIntRValue
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (rawValue : Int)
    (hostValue : Int) : Except Fault RawIntOperandResolution :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      match rawShape.intRValueResolver with
      | none => .error (missingIntResolverFault shape)
      | some resolver => do
          let flagEnabled <- rawIntOperandFlagEnabled shape rawPrefix slot resolver
          let selectorKnown := resolver.knownRValueSelectors.contains rawValue
          if !flagEnabled then
            .ok
              { kind := .rawImmediate
                value := rawValue
                rawValue := rawValue
                hostValue := none
                selectorKnown := selectorKnown
                flagEnabled := flagEnabled }
          else if selectorKnown then
            .ok
              { kind := .resolvedHost
                value := hostValue
                rawValue := rawValue
                hostValue := some hostValue
                selectorKnown := selectorKnown
                flagEnabled := flagEnabled }
          else
            .ok
              { kind := .resolvedDefaultRaw
                value := rawValue
                rawValue := rawValue
                hostValue := none
                selectorKnown := selectorKnown
                flagEnabled := flagEnabled }

end TouhouFormal.ECL
