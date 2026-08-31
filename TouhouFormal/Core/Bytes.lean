import TouhouFormal.Core.Fault

namespace TouhouFormal

abbrev Bytes := Array UInt8

def byteOfNat (value : Nat) : UInt8 :=
  UInt8.ofNat value

def zeroBytes (count : Nat) : List UInt8 :=
  List.replicate count (byteOfNat 0)

def leU16Bytes (value : Nat) : List UInt8 :=
  [ byteOfNat (value % 0x100)
  , byteOfNat ((value / 0x100) % 0x100) ]

def leU32Bytes (value : Nat) : List UInt8 :=
  [ byteOfNat (value % 0x100)
  , byteOfNat ((value / 0x100) % 0x100)
  , byteOfNat ((value / 0x10000) % 0x100)
  , byteOfNat ((value / 0x1000000) % 0x100) ]

def u16LE (lo hi : UInt8) : Nat :=
  lo.toNat + 0x100 * hi.toNat

def u32LE (b0 b1 b2 b3 : UInt8) : Nat :=
  b0.toNat + 0x100 * b1.toNat + 0x10000 * b2.toNat + 0x1000000 * b3.toNat

def i16FromU16 (value : Nat) : Int :=
  if value < 0x8000 then
    Int.ofNat value
  else
    Int.ofNat value - 0x10000

def i32FromU32 (value : Nat) : Int :=
  if value < 0x80000000 then
    Int.ofNat value
  else
    Int.ofNat value - 0x100000000

def readU8 (title component : String) (bytes : Bytes) (offset : Nat) :
    Except Fault UInt8 :=
  match bytes[offset]? with
  | some value => .ok value
  | none =>
      .error <|
        Fault.outOfBoundsRead
          title
          component
          "byte read past end of ECL buffer"
          (Int.ofNat offset)
          bytes.size

def readU16LE (title component : String) (bytes : Bytes) (offset : Nat) :
    Except Fault Nat := do
  let lo <- readU8 title component bytes offset
  let hi <- readU8 title component bytes (offset + 1)
  pure (u16LE lo hi)

def readI16LE (title component : String) (bytes : Bytes) (offset : Nat) :
    Except Fault Int := do
  let value <- readU16LE title component bytes offset
  pure (i16FromU16 value)

def readU32LE (title component : String) (bytes : Bytes) (offset : Nat) :
    Except Fault Nat := do
  let b0 <- readU8 title component bytes offset
  let b1 <- readU8 title component bytes (offset + 1)
  let b2 <- readU8 title component bytes (offset + 2)
  let b3 <- readU8 title component bytes (offset + 3)
  pure (u32LE b0 b1 b2 b3)

def readI32LE (title component : String) (bytes : Bytes) (offset : Nat) :
    Except Fault Int := do
  let value <- readU32LE title component bytes offset
  pure (i32FromU32 value)

end TouhouFormal
