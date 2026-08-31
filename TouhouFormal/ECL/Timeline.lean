import TouhouFormal.Core.Bytes
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

structure TimelinePrefix where
  fileOffset : Nat
  time : Int
  opcode : Int
  size : Int
  firstArg : Option Int := none
deriving Repr, DecidableEq

private def missingTimelineShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclTimeline.decode"
    detail := "profile does not define a timeline wire shape" }

def readScalar (title component : String) (bytes : TouhouFormal.Bytes) (offset : Nat)
    (width : ScalarWidth) : Except Fault Int :=
  match width with
  | .u8 => do
      let value <- readU8 title component bytes offset
      pure (Int.ofNat value.toNat)
  | .i16 => readI16LE title component bytes offset
  | .i32 => readI32LE title component bytes offset

def decodeTimelinePrefix (shape : HeaderShape) (bytes : TouhouFormal.Bytes) (fileOffset : Nat) :
    Except Fault TimelinePrefix :=
  match shape.timelineShape with
  | none => .error (missingTimelineShapeFault shape)
  | some timelineShape => do
      let time <-
        readScalar
          shape.title
          "EclTimeline.decode.time"
          bytes
          (fileOffset + timelineShape.timeOffset)
          timelineShape.timeWidth
      let opcode <-
        readScalar
          shape.title
          "EclTimeline.decode.opcode"
          bytes
          (fileOffset + timelineShape.opcodeOffset)
          timelineShape.opcodeWidth
      let size <-
        readScalar
          shape.title
          "EclTimeline.decode.size"
          bytes
          (fileOffset + timelineShape.sizeOffset)
          timelineShape.sizeWidth
      let firstArg <-
        match timelineShape.firstArgOffset, timelineShape.firstArgWidth with
        | some offset, some width => do
            let value <-
              readScalar
                shape.title
                "EclTimeline.decode.firstArg"
                bytes
                (fileOffset + offset)
                width
            pure (some value)
        | _, _ => pure none
      pure
        { fileOffset := fileOffset
          time := time
          opcode := opcode
          size := size
          firstArg := firstArg }

end TouhouFormal.ECL
