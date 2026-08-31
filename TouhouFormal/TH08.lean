import TouhouFormal.Core.Bytes
import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Loader
import TouhouFormal.ECL.Timeline
import TouhouFormal.TH08.Wire

namespace TouhouFormal.TH08

def oneSubOffsets : Array Nat :=
  #[rawHeaderFixedPrefixBytes]

def arg0_256Fault : TouhouFormal.Fault :=
  TouhouFormal.ECL.subTableOobFault headerShape 256 oneSubOffsets.size

def rawWrongVersionHeader : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 0x700 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.zeroBytes 64).toArray

def rawTimelinePrefixBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 441 ++
    TouhouFormal.leU16Bytes 0 ++
    [TouhouFormal.byteOfNat timelineInstrFixedSize, TouhouFormal.byteOfNat 0xff] ++
    TouhouFormal.leU32Bytes 256 ++
    TouhouFormal.zeroBytes 24).toArray

theorem negative_sub_id_noops :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets (-1) =
      .ok (none : Option Nat) := by
  rfl

theorem arg0_256_uses_shared_positive_lookup :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets 256 =
      .error arg0_256Fault := by
  rfl

theorem wrong_version_rejects_before_rebase :
    TouhouFormal.ECL.loadHeaderOffsets headerShape rawWrongVersionHeader =
      .error (.rejected (.versionMismatch expectedEclVersion 0x700)) := by
  rfl

theorem timeline_prefix_decodes_th08_shape :
    TouhouFormal.ECL.decodeTimelinePrefix headerShape rawTimelinePrefixBytes 0 =
      .ok
        { fileOffset := 0
          time := 441
          opcode := 0
          size := Int.ofNat timelineInstrFixedSize
          firstArg := some 256 } := by
  rfl

end TouhouFormal.TH08
