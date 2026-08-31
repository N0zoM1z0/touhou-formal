import TouhouFormal.Core.Bytes
import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Loader
import TouhouFormal.ECL.Timeline
import TouhouFormal.TH06.Timeline

namespace TouhouFormal.TH06

private def liftFault : Except Fault α -> Except TouhouFormal.ECL.LoadError α
  | .ok value => .ok value
  | .error faultValue => .error (.fault faultValue)

def rawOneSubArg0256Ecl : TouhouFormal.Bytes :=
  (TouhouFormal.leU16Bytes 1 ++
    TouhouFormal.leU16Bytes 1 ++
    TouhouFormal.leU32Bytes 0x14 ++
    TouhouFormal.leU32Bytes 0 ++
    TouhouFormal.leU32Bytes 0 ++
    TouhouFormal.leU32Bytes 0x30 ++
    TouhouFormal.leU16Bytes 441 ++
    TouhouFormal.leU16Bytes 256 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes timelineInstrFixedSize ++
    TouhouFormal.zeroBytes 20 ++
    TouhouFormal.zeroBytes 12).toArray

def rawZeroSizeTimelinePrefixBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU16Bytes 441 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.zeroBytes 20).toArray

def rawNegativeSizeTimelinePrefixBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU16Bytes 441 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0xffff ++
    TouhouFormal.zeroBytes 20).toArray

def rawZeroNextOffsetInstrPrefixBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 441 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    [TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0]).toArray

def rawNegativeNextOffsetInstrPrefixBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 441 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0xffff ++
    [TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0]).toArray

def rawOneSubArg0256Header : Except TouhouFormal.ECL.LoadError TouhouFormal.ECL.LoadedHeader :=
  TouhouFormal.ECL.loadHeaderOffsets headerShape rawOneSubArg0256Ecl

private def timelineSlotFault (slot : Int) (bound : Nat) : Fault :=
  Fault.outOfBoundsRead
    title
    "EclManager.GetTimeline"
    "timeline slot requested after profile-driven loader rebased fewer entries"
    slot
    bound

def rawOneSubArg0256Prefix : Except TouhouFormal.ECL.LoadError TouhouFormal.ECL.TimelinePrefix := do
  let loaded <- rawOneSubArg0256Header
  let timelineOffset <-
    match loaded.timelineOffsets[0]? with
    | some offset => .ok offset
    | none => .error (.fault (timelineSlotFault 0 loaded.timelineOffsets.size))
  liftFault (TouhouFormal.ECL.decodeTimelinePrefix headerShape rawOneSubArg0256Ecl timelineOffset)

private def missingFirstArgFault : Fault :=
  { kind := .invalidInstruction
    title := title
    component := "EclTimeline.spawn"
    detail := "timeline profile does not expose a first spawn argument" }

def rawOneSubArg0256Lookup : Except TouhouFormal.ECL.LoadError (Option Nat) := do
  let loaded <- rawOneSubArg0256Header
  let timelinePrefix <- rawOneSubArg0256Prefix
  let subId <-
    match timelinePrefix.firstArg with
    | some value => .ok value
    | none => .error (.fault missingFirstArgFault)
  liftFault (TouhouFormal.ECL.lookupSubOffset headerShape loaded.subOffsets subId)

theorem rawOneSubArg0256_header_loads :
    rawOneSubArg0256Header =
      .ok
        { shape := headerShape
          bytes := rawOneSubArg0256Ecl
          subCount := 1
          timelineCount := 1
          timelineOffsets := #[0x14]
          subOffsets := #[0x30] } := by
  rfl

theorem rawOneSubArg0256_prefix_decodes :
    rawOneSubArg0256Prefix =
      .ok
        { fileOffset := 0x14
          time := 441
          opcode := 0
          size := Int.ofNat timelineInstrFixedSize
          firstArg := some 256 } := by
  rfl

theorem rawOneSubArg0256_shared_counterexample :
    rawOneSubArg0256Lookup = .error (.fault arg0_256Fault) := by
  rfl

theorem rawZeroSizeTimelinePrefix_nonprogresses :
    TouhouFormal.ECL.decodeTimelinePrefix headerShape rawZeroSizeTimelinePrefixBytes 0 =
      .ok
        { fileOffset := 0
          time := 441
          opcode := 0
          size := 0
          firstArg := some 0 } := by
  rfl

theorem rawZeroSizeTimelinePrefix_next_cursor_stays :
    ( { fileOffset := 0
        time := 441
        opcode := 0
        size := 0
        firstArg := some 0 } : TouhouFormal.ECL.TimelinePrefix ).isNonProgressing = true := by
  rfl

theorem rawNegativeSizeTimelinePrefix_decodes :
    TouhouFormal.ECL.decodeTimelinePrefix headerShape rawNegativeSizeTimelinePrefixBytes 0 =
      .ok
        { fileOffset := 0
          time := 441
          opcode := 0
          size := -1
          firstArg := some 0 } := by
  rfl

theorem rawNegativeSizeTimelinePrefix_after_advance_faults :
    TouhouFormal.ECL.decodeTimelinePrefixAfterAdvance
      headerShape
      rawNegativeSizeTimelinePrefixBytes
      { fileOffset := 0
        time := 441
        opcode := 0
        size := -1
        firstArg := some 0 } =
      .error
        (Fault.outOfBoundsRead
          title
          "EclTimeline.decode.cursor"
          "timeline cursor moved before the beginning of the ECL buffer"
          (-1)
          rawNegativeSizeTimelinePrefixBytes.size) := by
  rfl

theorem rawZeroNextOffsetInstrPrefix_nonprogresses :
    TouhouFormal.ECL.decodeRawInstrPrefix headerShape rawZeroNextOffsetInstrPrefixBytes 0 =
      .ok
        { fileOffset := 0
          time := 441
          opcode := 0
          nextOffset := 0
          difficultyMask := some 0
          operandMask := none } := by
  rfl

theorem rawZeroNextOffsetInstrPrefix_next_cursor_stays :
    ( { fileOffset := 0
        time := 441
        opcode := 0
        nextOffset := 0
        difficultyMask := some 0
        operandMask := none } : TouhouFormal.ECL.RawInstrPrefix ).isNonProgressing = true := by
  rfl

theorem rawNegativeNextOffsetInstrPrefix_after_advance_faults :
    TouhouFormal.ECL.decodeRawInstrPrefixAfterAdvance
      headerShape
      rawNegativeNextOffsetInstrPrefixBytes
      { fileOffset := 0
        time := 441
        opcode := 0
        nextOffset := -1
        difficultyMask := some 0
        operandMask := none } =
      .error
        (Fault.outOfBoundsRead
          title
          "EclRun.decode.cursor"
          "raw ECL instruction cursor moved before the beginning of the ECL buffer"
          (-1)
          rawNegativeNextOffsetInstrPrefixBytes.size) := by
  rfl

end TouhouFormal.TH06
