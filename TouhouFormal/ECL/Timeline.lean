import TouhouFormal.ECL.Scalar

namespace TouhouFormal.ECL

structure TimelinePrefix where
  fileOffset : Nat
  time : Int
  opcode : Int
  size : Int
  firstArg : Option Int := none
deriving Repr, DecidableEq

def TimelinePrefix.nextCursor (timelinePrefix : TimelinePrefix) : Int :=
  Int.ofNat timelinePrefix.fileOffset + timelinePrefix.size

def TimelinePrefix.isNonProgressing (timelinePrefix : TimelinePrefix) : Bool :=
  timelinePrefix.nextCursor = Int.ofNat timelinePrefix.fileOffset

private def missingTimelineShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclTimeline.decode"
    detail := "profile does not define a timeline wire shape" }

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

private def negativeCursorFault (shape : HeaderShape) (bytes : TouhouFormal.Bytes)
    (cursor : Int) : Fault :=
  Fault.outOfBoundsRead
    shape.title
    "EclTimeline.decode.cursor"
    "timeline cursor moved before the beginning of the ECL buffer"
    cursor
    bytes.size

def decodeTimelinePrefixAtCursor (shape : HeaderShape) (bytes : TouhouFormal.Bytes)
    (cursor : Int) : Except Fault TimelinePrefix :=
  if cursor < 0 then
    .error (negativeCursorFault shape bytes cursor)
  else
    decodeTimelinePrefix shape bytes cursor.toNat

def decodeTimelinePrefixAfterAdvance (shape : HeaderShape) (bytes : TouhouFormal.Bytes)
    (timelinePrefix : TimelinePrefix) : Except Fault TimelinePrefix :=
  decodeTimelinePrefixAtCursor shape bytes timelinePrefix.nextCursor

end TouhouFormal.ECL
