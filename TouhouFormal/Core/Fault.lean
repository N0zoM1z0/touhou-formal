namespace TouhouFormal

inductive FaultKind where
  | outOfBoundsRead
  | outOfBoundsWrite
  | stackUnderflow
  | stackOverflow
  | divideByZero
  | invalidInstruction
  | invalidHostIndex
  | malformedFile
deriving Repr, DecidableEq

def FaultKind.name : FaultKind -> String
  | .outOfBoundsRead => "out-of-bounds-read"
  | .outOfBoundsWrite => "out-of-bounds-write"
  | .stackUnderflow => "stack-underflow"
  | .stackOverflow => "stack-overflow"
  | .divideByZero => "divide-by-zero"
  | .invalidInstruction => "invalid-instruction"
  | .invalidHostIndex => "invalid-host-index"
  | .malformedFile => "malformed-file"

structure Fault where
  kind : FaultKind
  title : String
  component : String
  detail : String
  index : Option Int := none
  bound : Option Nat := none
deriving Repr, DecidableEq

private def showOptInt : Option Int -> String
  | none => "-"
  | some value => toString value

private def showOptNat : Option Nat -> String
  | none => "-"
  | some value => toString value

def Fault.describe (fault : Fault) : String :=
  fault.title ++ ":" ++ fault.component ++ ": " ++ fault.kind.name ++
    ": " ++ fault.detail ++
    " index=" ++ showOptInt fault.index ++
    " bound=" ++ showOptNat fault.bound

def Fault.outOfBoundsRead
    (title component detail : String)
    (index : Int)
    (bound : Nat) : Fault :=
  { kind := .outOfBoundsRead
    title := title
    component := component
    detail := detail
    index := some index
    bound := some bound }

end TouhouFormal
