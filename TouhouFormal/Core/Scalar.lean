import TouhouFormal.Core.Bytes

namespace TouhouFormal

inductive ScalarWidth where
  | u8
  | u16
  | u32
  | i16
  | i32
deriving Repr, DecidableEq

def ScalarWidth.bytes : ScalarWidth -> Nat
  | .u8 => 1
  | .u16 => 2
  | .u32 => 4
  | .i16 => 2
  | .i32 => 4

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

end TouhouFormal
