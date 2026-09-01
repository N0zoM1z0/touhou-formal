import TouhouFormal.Core.Word

namespace TouhouFormal

def f32SignificandMask : Int := 0x7fffff
def f32MagnitudeMask : Int := 0x7fffffff
def f32ExponentDivisor : Int := 0x800000
def f32ExponentMask : Int := 0xff
def f32SignMask : Int := 0x80000000

def f32MagnitudeBits (value : Int) : Int :=
  toWord32Bits value % (f32MagnitudeMask + 1)

def f32ExponentBits (value : Int) : Int :=
  (f32MagnitudeBits value / f32ExponentDivisor) % (f32ExponentMask + 1)

def f32SignificandBits (value : Int) : Int :=
  f32MagnitudeBits value % (f32SignificandMask + 1)

def f32SignBitSet (value : Int) : Bool :=
  word32BitSet value 31

/-- Toggle the IEEE-754 binary32 sign bit without evaluating the payload. -/
def f32NegBits (value : Int) : Int :=
  let bits := toWord32Bits value
  if f32SignBitSet bits then bits - f32SignMask else bits + f32SignMask

def f32IsZeroBits (value : Int) : Bool :=
  f32MagnitudeBits value == 0

def f32IsNaNBits (value : Int) : Bool :=
  f32ExponentBits value == f32ExponentMask &&
    f32SignificandBits value != 0

/-- IEEE-754 binary32 ordered less-than, evaluated directly on serialized bits. -/
def f32LessThanBits (lhs rhs : Int) : Bool :=
  if f32IsNaNBits lhs || f32IsNaNBits rhs then
    false
  else if f32IsZeroBits lhs && f32IsZeroBits rhs then
    false
  else if f32SignBitSet lhs != f32SignBitSet rhs then
    f32SignBitSet lhs
  else if f32SignBitSet lhs then
    decide (f32MagnitudeBits rhs < f32MagnitudeBits lhs)
  else
    decide (f32MagnitudeBits lhs < f32MagnitudeBits rhs)

def f32OrderedBits (lhs rhs : Int) : Bool :=
  !f32IsNaNBits lhs && !f32IsNaNBits rhs

def f32LessOrEqualBits (lhs rhs : Int) : Bool :=
  f32OrderedBits lhs rhs && !f32LessThanBits rhs lhs

def f32GreaterThanBits (lhs rhs : Int) : Bool :=
  f32LessThanBits rhs lhs

def f32GreaterOrEqualBits (lhs rhs : Int) : Bool :=
  f32OrderedBits lhs rhs && !f32LessThanBits lhs rhs

end TouhouFormal
