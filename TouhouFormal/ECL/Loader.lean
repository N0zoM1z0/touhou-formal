import TouhouFormal.Core.Bytes
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

inductive LoadRejection where
  | versionMismatch (expected actual : Nat)
deriving Repr, DecidableEq

inductive LoadError where
  | fault (fault : Fault)
  | rejected (rejection : LoadRejection)
deriving Repr, DecidableEq

structure LoadedHeader where
  shape : HeaderShape
  bytes : TouhouFormal.Bytes
  subCount : Int
  timelineCount : Int
  timelineOffsets : Array Nat
  subOffsets : Array Nat
deriving Repr, DecidableEq

def LoadError.describe : LoadError -> String
  | LoadError.fault faultValue => faultValue.describe
  | LoadError.rejected (LoadRejection.versionMismatch expected actual) =>
      "EclManager.Load: version-mismatch expected=" ++ toString expected ++
        " actual=" ++ toString actual

private def liftFault : Except Fault α -> Except LoadError α
  | .ok value => .ok value
  | .error faultValue => .error (.fault faultValue)

private def readU32ArrayAt
    (shape : HeaderShape)
    (bytes : TouhouFormal.Bytes)
    (component : String)
    (offset count : Nat) :
    Except LoadError (Array Nat) :=
  let rec go (nextOffset remaining : Nat) (acc : Array Nat) :
      Except LoadError (Array Nat) :=
    match remaining with
    | 0 => .ok acc
    | remaining' + 1 => do
        let value <- liftFault (readU32LE shape.title component bytes nextOffset)
        go (nextOffset + 4) remaining' (acc.push value)
  go offset count #[]

private def nonnegativeLoopCount (value : Int) : Nat :=
  if value < 0 then 0 else value.toNat

def loadHeaderOffsets (shape : HeaderShape) (bytes : TouhouFormal.Bytes) :
    Except LoadError LoadedHeader := do
  match shape.expectedVersion, shape.versionOffset with
  | some expected, some offset =>
      let actual <- liftFault (readU32LE shape.title "EclManager.Load.version" bytes offset)
      if actual = expected then
        pure ()
      else
        .error (.rejected (.versionMismatch expected actual))
  | _, _ => pure ()

  let timelineOffsets <-
    readU32ArrayAt
      shape
      bytes
      "EclManager.Load.timelineOffsets"
      shape.timelineTableOffset
      shape.loaderTimelineSlots
  let subCount <- liftFault (readI16LE shape.title "EclManager.Load.subCount" bytes shape.subCountOffset)
  let timelineCount <-
    liftFault (readI16LE shape.title "EclManager.Load.timelineCount" bytes shape.timelineCountOffset)
  let subOffsets <-
    readU32ArrayAt
      shape
      bytes
      "EclManager.Load.subTable"
      shape.fixedHeaderBytes
      (nonnegativeLoopCount subCount)
  pure
    { shape := shape
      bytes := bytes
      subCount := subCount
      timelineCount := timelineCount
      timelineOffsets := timelineOffsets
      subOffsets := subOffsets }

end TouhouFormal.ECL
