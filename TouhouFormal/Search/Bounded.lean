import TouhouFormal.Core.Bytes
import TouhouFormal.ECL.Loader
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Bounded

def zeroBytesOfLength (count : Nat) : TouhouFormal.Bytes :=
  (TouhouFormal.zeroBytes count).toArray

def zeroNat16 : Array Nat :=
  #[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

def th06ZeroCountMinimalBytes : TouhouFormal.Bytes :=
  zeroBytesOfLength (TouhouFormal.TH06.headerShape.timelineTableOffset + 4)

def th07ZeroCountMinimalBytes : TouhouFormal.Bytes :=
  zeroBytesOfLength TouhouFormal.TH07.rawHeaderFixedPrefixBytes

def th08ZeroCountMinimalBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes TouhouFormal.TH08.expectedEclVersion ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.zeroBytes 64).toArray

def th08AlmostMinimalBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes TouhouFormal.TH08.expectedEclVersion ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.zeroBytes 63).toArray

theorem th06_loader_faults_at_first_missing_timeline_byte :
    TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH06.headerShape (zeroBytesOfLength 7) =
      .error
        (.fault
          (Fault.outOfBoundsRead
            TouhouFormal.TH06.title
            "EclManager.Load.timelineOffsets"
            "byte read past end of ECL buffer"
            7
            7)) := by
  rfl

theorem th06_loader_accepts_eight_byte_zero_count_header :
    TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH06.headerShape th06ZeroCountMinimalBytes =
      .ok
        { shape := TouhouFormal.TH06.headerShape
          bytes := th06ZeroCountMinimalBytes
          subCount := 0
          timelineCount := 0
          timelineOffsets := #[0]
          subOffsets := #[] } := by
  rfl

theorem th07_loader_accepts_fixed_prefix_zero_count_header :
    TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH07.headerShape th07ZeroCountMinimalBytes =
      .ok
        { shape := TouhouFormal.TH07.headerShape
          bytes := th07ZeroCountMinimalBytes
          subCount := 0
          timelineCount := 0
          timelineOffsets := zeroNat16
          subOffsets := #[] } := by
  rfl

theorem th08_loader_faults_at_first_missing_timeline_byte :
    TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH08.headerShape th08AlmostMinimalBytes =
      .error
        (.fault
          (Fault.outOfBoundsRead
            TouhouFormal.TH08.title
            "EclManager.Load.timelineOffsets"
            "byte read past end of ECL buffer"
            71
            71)) := by
  rfl

theorem th08_loader_accepts_fixed_prefix_zero_count_header :
    TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH08.headerShape th08ZeroCountMinimalBytes =
      .ok
        { shape := TouhouFormal.TH08.headerShape
          bytes := th08ZeroCountMinimalBytes
          subCount := 0
          timelineCount := 0
          timelineOffsets := zeroNat16
          subOffsets := #[] } := by
  rfl

end TouhouFormal.Search.Bounded
