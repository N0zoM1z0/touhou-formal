import TouhouFormal.Search.SMT

def smtUsage : String :=
  "usage: lake exe smt <th06-sub-oob|th06-find-oob|th07-negative-oob|th08-negative-noop-unsat|th08-positive-oob|th06-jump-minus-one-oob|th07-jump-minus-one-oob|th08-jump-minus-one-oob>"

def main (args : List String) : IO UInt32 := do
  match args with
  | ["th06-sub-oob"] =>
      IO.print TouhouFormal.Search.SMT.th06SubTableOobQuery
      return 0
  | ["th06-find-oob"] =>
      IO.print TouhouFormal.Search.SMT.th06FindAnySubTableOobQuery
      return 0
  | ["th07-negative-oob"] =>
      IO.print TouhouFormal.Search.SMT.th07NegativeSubTableOobQuery
      return 0
  | ["th08-negative-noop-unsat"] =>
      IO.print TouhouFormal.Search.SMT.th08NegativeSubTableNoopUnsatQuery
      return 0
  | ["th08-positive-oob"] =>
      IO.print TouhouFormal.Search.SMT.th08PositiveSubTableOobQuery
      return 0
  | ["th06-jump-minus-one-oob"] =>
      IO.print TouhouFormal.Search.SMT.th06JumpMinusOneOobQuery
      return 0
  | ["th07-jump-minus-one-oob"] =>
      IO.print TouhouFormal.Search.SMT.th07JumpMinusOneOobQuery
      return 0
  | ["th08-jump-minus-one-oob"] =>
      IO.print TouhouFormal.Search.SMT.th08JumpMinusOneOobQuery
      return 0
  | _ =>
      IO.eprintln smtUsage
      return 2
