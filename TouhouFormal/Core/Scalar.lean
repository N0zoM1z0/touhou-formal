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

private def signedBitsToNat (modulus : Nat) (value : Int) : Nat :=
  if value < 0 then
    (value + Int.ofNat modulus).toNat
  else
    value.toNat

def ScalarWidth.encodeLE? (width : ScalarWidth) (value : Int) : Option (List UInt8) :=
  match width with
  | .u8 =>
      if decide (0 <= value ∧ value <= 255) then
        some [byteOfNat value.toNat]
      else
        none
  | .u16 =>
      if decide (0 <= value ∧ value <= 65535) then
        some (leU16Bytes value.toNat)
      else
        none
  | .u32 =>
      if decide (0 <= value ∧ value <= 4294967295) then
        some (leU32Bytes value.toNat)
      else
        none
  | .i16 =>
      if decide ((-32768 : Int) <= value ∧ value <= 32767) then
        some (leU16Bytes (signedBitsToNat 0x10000 value))
      else
        none
  | .i32 =>
      if decide ((-2147483648 : Int) <= value ∧ value <= 2147483647) then
        some (leU32Bytes (signedBitsToNat 0x100000000 value))
      else
        none

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

def ScalarWidth.cursorDeltaSamples : ScalarWidth -> List Int
  | .u8 => [0, 1, 12, 24, 255]
  | .u16 => [0, 1, 12, 24, 65535]
  | .u32 => [0, 1, 12, 24, 4294967295]
  | .i16 => [-1, 0, 1, 12, 24, 32767]
  | .i32 => [-1, 0, 1, 12, 24, 2147483647]

def ScalarWidth.canRepresentNegative : ScalarWidth -> Bool
  | .u8 | .u16 | .u32 => false
  | .i16 | .i32 => true

end TouhouFormal
