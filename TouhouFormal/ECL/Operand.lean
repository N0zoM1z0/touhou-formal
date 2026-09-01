import TouhouFormal.ECL.Difficulty
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

inductive RawIntOperandResolutionKind where
  | rawImmediate
  | resolvedHost
  | resolvedDefaultRaw
deriving Repr, DecidableEq

inductive RawIntLValueResolutionKind where
  | rawOperandCell
  | resolvedHost
  | resolvedDefaultRawCell
  | nonIntOutput
deriving Repr, DecidableEq

inductive RawFloatOperandResolutionKind where
  | rawImmediate
  | resolvedHost
  | resolvedDefaultRaw
deriving Repr, DecidableEq

inductive RawFloatLValueResolutionKind where
  | rawOperandCell
  | resolvedHost
  | resolvedDefaultRawCell
  | nonFloatOutput
deriving Repr, DecidableEq

def RawIntOperandResolutionKind.name : RawIntOperandResolutionKind -> String
  | .rawImmediate => "raw-immediate"
  | .resolvedHost => "resolved-host"
  | .resolvedDefaultRaw => "resolved-default-raw"

def RawIntLValueResolutionKind.name : RawIntLValueResolutionKind -> String
  | .rawOperandCell => "raw-operand-cell"
  | .resolvedHost => "resolved-host"
  | .resolvedDefaultRawCell => "resolved-default-raw-cell"
  | .nonIntOutput => "non-int-output"

def RawFloatOperandResolutionKind.name : RawFloatOperandResolutionKind -> String
  | .rawImmediate => "raw-immediate"
  | .resolvedHost => "resolved-host"
  | .resolvedDefaultRaw => "resolved-default-raw"

def RawFloatLValueResolutionKind.name : RawFloatLValueResolutionKind -> String
  | .rawOperandCell => "raw-operand-cell"
  | .resolvedHost => "resolved-host"
  | .resolvedDefaultRawCell => "resolved-default-raw-cell"
  | .nonFloatOutput => "non-float-output"

structure RawIntOperandResolution where
  kind : RawIntOperandResolutionKind
  value : Int
  rawValue : Int
  hostValue : Option Int := none
  selectorKnown : Bool
  flagEnabled : Bool
deriving Repr, DecidableEq

structure RawIntLValueResolution where
  kind : RawIntLValueResolutionKind
  valueBefore : Option Int
  rawValue : Int
  hostValueBefore : Option Int := none
  selectorKnown : Bool
  flagEnabled : Bool
deriving Repr, DecidableEq

structure RawFloatOperandResolution where
  kind : RawFloatOperandResolutionKind
  value : Int
  rawValue : Int
  hostValue : Option Int := none
  selectorKnown : Bool
  flagEnabled : Bool
deriving Repr, DecidableEq

structure RawFloatLValueResolution where
  kind : RawFloatLValueResolutionKind
  valueBefore : Option Int
  rawValue : Int
  hostValueBefore : Option Int := none
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

private def missingIntLValueResolverFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclOperand.intLValue"
    detail := "profile does not define integer lvalue resolver semantics" }

private def missingFloatResolverFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclOperand.floatRValue"
    detail := "profile does not define float rvalue resolver semantics" }

private def missingFloatLValueResolverFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclOperand.floatLValue"
    detail := "profile does not define float lvalue resolver semantics" }

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

private def rawOperandFlagEnabledByPolicy
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (maskPolicy : RawIntOperandMaskPolicy) : Except Fault Bool :=
  match maskPolicy with
  | .noMaskAlwaysResolve => .ok true
  | .bitSetMeansResolve =>
      match rawPrefix.operandMask with
      | none => .error (missingOperandMaskFault shape)
      | some mask =>
          if mask < 0 then
            .error (negativeOperandMaskFault shape mask)
          else
            .ok (bitIsSet mask.toNat slot)

def rawIntOperandFlagEnabled
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (resolver : RawIntOperandResolverShape) : Except Fault Bool :=
  rawOperandFlagEnabledByPolicy shape rawPrefix slot resolver.maskPolicy

def rawFloatOperandFlagEnabled
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (resolver : RawFloatOperandResolverShape) : Except Fault Bool :=
  rawOperandFlagEnabledByPolicy shape rawPrefix slot resolver.maskPolicy

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

def resolveIntLValue
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (rawValue : Int)
    (hostValueBefore : Int) : Except Fault RawIntLValueResolution :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      match rawShape.intRValueResolver with
      | none => .error (missingIntLValueResolverFault shape)
      | some resolver => do
          let flagEnabled <- rawIntOperandFlagEnabled shape rawPrefix slot resolver
          let selectorKnown := resolver.knownLValueSelectors.contains rawValue
          match resolver.maskPolicy with
          | .noMaskAlwaysResolve =>
              if selectorKnown then
                .ok
                  { kind := .resolvedHost
                    valueBefore := some hostValueBefore
                    rawValue := rawValue
                    hostValueBefore := some hostValueBefore
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else
                .ok
                  { kind := .nonIntOutput
                    valueBefore := none
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
          | .bitSetMeansResolve =>
              if !flagEnabled then
                .ok
                  { kind := .rawOperandCell
                    valueBefore := some rawValue
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else if selectorKnown then
                .ok
                  { kind := .resolvedHost
                    valueBefore := some hostValueBefore
                    rawValue := rawValue
                    hostValueBefore := some hostValueBefore
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else
                .ok
                  { kind := .resolvedDefaultRawCell
                    valueBefore := some rawValue
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }

def resolveIntPointerLValue
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (rawValue : Int)
    (hostValueBefore : Int) : Except Fault RawIntLValueResolution :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      match rawShape.intRValueResolver with
      | none => .error (missingIntLValueResolverFault shape)
      | some resolver => do
          let flagEnabled <- rawIntOperandFlagEnabled shape rawPrefix slot resolver
          let selectorKnown := resolver.knownRValueSelectors.contains rawValue
          match resolver.maskPolicy with
          | .noMaskAlwaysResolve =>
              if selectorKnown then
                .ok
                  { kind := .resolvedHost
                    valueBefore := some hostValueBefore
                    rawValue := rawValue
                    hostValueBefore := some hostValueBefore
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else
                .ok
                  { kind := .resolvedDefaultRawCell
                    valueBefore := some rawValue
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
          | .bitSetMeansResolve =>
              if !flagEnabled then
                .ok
                  { kind := .rawOperandCell
                    valueBefore := some rawValue
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else if selectorKnown then
                .ok
                  { kind := .resolvedHost
                    valueBefore := some hostValueBefore
                    rawValue := rawValue
                    hostValueBefore := some hostValueBefore
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else
                .ok
                  { kind := .resolvedDefaultRawCell
                    valueBefore := some rawValue
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }

def resolveFloatRValue
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (rawValue : Int)
    (hostValue : Int) : Except Fault RawFloatOperandResolution :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      match rawShape.floatRValueResolver with
      | none => .error (missingFloatResolverFault shape)
      | some resolver => do
          let flagEnabled <- rawFloatOperandFlagEnabled shape rawPrefix slot resolver
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

def resolveFloatLValue
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (slot : Nat)
    (rawValue : Int)
    (hostValueBefore : Int) : Except Fault RawFloatLValueResolution :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      match rawShape.floatRValueResolver with
      | none => .error (missingFloatLValueResolverFault shape)
      | some resolver => do
          let flagEnabled <- rawFloatOperandFlagEnabled shape rawPrefix slot resolver
          let selectorKnown := resolver.knownLValueSelectors.contains rawValue
          match resolver.maskPolicy with
          | .noMaskAlwaysResolve =>
              if selectorKnown then
                .ok
                  { kind := .resolvedHost
                    valueBefore := some hostValueBefore
                    rawValue := rawValue
                    hostValueBefore := some hostValueBefore
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else
                .ok
                  { kind := .nonFloatOutput
                    valueBefore := none
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
          | .bitSetMeansResolve =>
              if !flagEnabled then
                .ok
                  { kind := .rawOperandCell
                    valueBefore := some rawValue
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else if selectorKnown then
                .ok
                  { kind := .resolvedHost
                    valueBefore := some hostValueBefore
                    rawValue := rawValue
                    hostValueBefore := some hostValueBefore
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }
              else
                .ok
                  { kind := .resolvedDefaultRawCell
                    valueBefore := some rawValue
                    rawValue := rawValue
                    hostValueBefore := none
                    selectorKnown := selectorKnown
                    flagEnabled := flagEnabled }

end TouhouFormal.ECL
