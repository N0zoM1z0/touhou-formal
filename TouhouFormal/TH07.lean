import TouhouFormal.ECL.Call
import TouhouFormal.TH07.Wire

namespace TouhouFormal.TH07

def oneSubOffsets : Array Nat :=
  #[rawHeaderFixedPrefixBytes]

def arg0_256Fault : TouhouFormal.Fault :=
  TouhouFormal.ECL.subTableOobFault headerShape 256 oneSubOffsets.size

def negativeSubIdFault : TouhouFormal.Fault :=
  TouhouFormal.ECL.subTableOobFault headerShape (-1) oneSubOffsets.size

theorem arg0_256_uses_shared_unchecked_lookup :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets 256 =
      .error arg0_256Fault := by
  rfl

theorem negative_sub_id_faults :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets (-1) =
      .error negativeSubIdFault := by
  rfl

end TouhouFormal.TH07
