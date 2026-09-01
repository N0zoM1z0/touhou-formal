namespace TouhouFormal

def word32Modulus : Int := 4294967296
def word32SignBit : Int := 2147483648

def word16Modulus : Int := 65536
def word16SignBit : Int := 32768

def toWord32Bits (value : Int) : Int :=
  value % word32Modulus

def word32BitsToInt (value : Int) : Int :=
  let bits := toWord32Bits value
  if bits < word32SignBit then bits else bits - word32Modulus

def toWord16Bits (value : Int) : Int :=
  value % word16Modulus

def word16BitsToInt (value : Int) : Int :=
  let bits := toWord16Bits value
  if bits < word16SignBit then bits else bits - word16Modulus

def word32Add (lhs rhs : Int) : Int :=
  toWord32Bits (toWord32Bits lhs + toWord32Bits rhs)

def word32Neg (value : Int) : Int :=
  toWord32Bits (-word32BitsToInt value)

def word32BitSet (value : Int) (bit : Nat) : Bool :=
  (toWord32Bits value / (2 ^ bit)) % 2 == 1

def truncateUnsignedBits (value : Int) (width : Nat) : Int :=
  toWord32Bits value % (2 ^ width)

end TouhouFormal
