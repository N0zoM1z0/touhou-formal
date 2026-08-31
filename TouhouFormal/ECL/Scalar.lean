import TouhouFormal.Core.Bytes
import TouhouFormal.ECL.Profile

namespace TouhouFormal.ECL

def readScalar (title component : String) (bytes : TouhouFormal.Bytes) (offset : Nat)
    (width : ScalarWidth) : Except Fault Int :=
  match width with
  | .u8 => do
      let value <- readU8 title component bytes offset
      pure (Int.ofNat value.toNat)
  | .u16 => do
      let value <- readU16LE title component bytes offset
      pure (Int.ofNat value)
  | .u32 => do
      let value <- readU32LE title component bytes offset
      pure (Int.ofNat value)
  | .i16 => readI16LE title component bytes offset
  | .i32 => readI32LE title component bytes offset

end TouhouFormal.ECL
