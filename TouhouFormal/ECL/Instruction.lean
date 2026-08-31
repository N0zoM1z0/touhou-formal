import TouhouFormal.ECL.Scalar
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

structure RawInstrPrefix where
  fileOffset : Nat
  time : Int
  opcode : Int
  nextOffset : Int
  difficultyMask : Option Int := none
  operandMask : Option Int := none
deriving Repr, DecidableEq

def RawInstrPrefix.nextCursor (rawPrefix : RawInstrPrefix) : Int :=
  Int.ofNat rawPrefix.fileOffset + rawPrefix.nextOffset

def RawInstrPrefix.isNonProgressing (rawPrefix : RawInstrPrefix) : Bool :=
  rawPrefix.nextCursor = Int.ofNat rawPrefix.fileOffset

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.decode"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def negativeCursorFault (shape : HeaderShape) (bytes : TouhouFormal.Bytes)
    (cursor : Int) : Fault :=
  Fault.outOfBoundsRead
    shape.title
    "EclRun.decode.cursor"
    "raw ECL instruction cursor moved before the beginning of the ECL buffer"
    cursor
    bytes.size

private def readOptionalScalar
    (shape : HeaderShape)
    (bytes : TouhouFormal.Bytes)
    (baseOffset : Nat)
    (component : String)
    (fieldOffset : Option Nat)
    (fieldWidth : Option ScalarWidth) :
    Except Fault (Option Int) :=
  match fieldOffset, fieldWidth with
  | some offset, some width => do
      let value <- readScalar shape.title component bytes (baseOffset + offset) width
      pure (some value)
  | _, _ => pure none

def decodeRawInstrPrefix (shape : HeaderShape) (bytes : TouhouFormal.Bytes) (fileOffset : Nat) :
    Except Fault RawInstrPrefix :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape => do
      let time <-
        readScalar
          shape.title
          "EclRun.decode.time"
          bytes
          (fileOffset + rawShape.timeOffset)
          rawShape.timeWidth
      let opcode <-
        readScalar
          shape.title
          "EclRun.decode.opcode"
          bytes
          (fileOffset + rawShape.opcodeOffset)
          rawShape.opcodeWidth
      let nextOffset <-
        readScalar
          shape.title
          "EclRun.decode.nextOffset"
          bytes
          (fileOffset + rawShape.nextOffsetOffset)
          rawShape.nextOffsetWidth
      let difficultyMask <-
        readOptionalScalar
          shape
          bytes
          fileOffset
          "EclRun.decode.difficultyMask"
          rawShape.difficultyMaskOffset
          rawShape.difficultyMaskWidth
      let operandMask <-
        readOptionalScalar
          shape
          bytes
          fileOffset
          "EclRun.decode.operandMask"
          rawShape.operandMaskOffset
          rawShape.operandMaskWidth
      pure
        { fileOffset := fileOffset
          time := time
          opcode := opcode
          nextOffset := nextOffset
          difficultyMask := difficultyMask
          operandMask := operandMask }

def decodeRawInstrPrefixAtCursor (shape : HeaderShape) (bytes : TouhouFormal.Bytes)
    (cursor : Int) : Except Fault RawInstrPrefix :=
  if cursor < 0 then
    .error (negativeCursorFault shape bytes cursor)
  else
    decodeRawInstrPrefix shape bytes cursor.toNat

def decodeRawInstrPrefixAfterAdvance (shape : HeaderShape) (bytes : TouhouFormal.Bytes)
    (rawPrefix : RawInstrPrefix) : Except Fault RawInstrPrefix :=
  decodeRawInstrPrefixAtCursor shape bytes rawPrefix.nextCursor

end TouhouFormal.ECL
