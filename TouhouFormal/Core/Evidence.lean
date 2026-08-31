namespace TouhouFormal

structure SourceRef where
  path : String
  startLine : Nat
  endLine : Nat
  claim : String
deriving Repr, DecidableEq

def SourceRef.format (ref : SourceRef) : String :=
  ref.path ++ ":" ++ toString ref.startLine ++ "-" ++ toString ref.endLine ++
    " " ++ ref.claim

end TouhouFormal
