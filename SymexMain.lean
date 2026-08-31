import TouhouFormal.Search.Symbolic

namespace SymexMain

private def usage : String :=
  "usage: lake exe symex <list-paths|query <th06|th07|th08> <path> [activeMask] [overrideMask]>"

private def parseNat? (value : String) : Option Nat :=
  value.toNat?

private def runQuery (titleText pathText : String) (activeMask overrideMask : Nat) :
    IO UInt32 := do
  if 255 < activeMask || 255 < overrideMask then
    IO.eprintln "activeMask and overrideMask must fit in an unsigned byte"
    IO.eprintln usage
    return 2
  else
    match TouhouFormal.Search.Symbolic.Title.parse? titleText,
          TouhouFormal.Search.Symbolic.RawStepPath.parse? pathText with
    | some title, some path =>
        IO.print (TouhouFormal.Search.Symbolic.rawStepQuery title path activeMask overrideMask)
        return 0
    | none, _ =>
        IO.eprintln s!"unknown title: {titleText}"
        IO.eprintln usage
        return 2
    | _, none =>
        IO.eprintln s!"unknown path: {pathText}"
        IO.eprintln usage
        return 2

def main (args : List String) : IO UInt32 := do
  match args with
  | ["list-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawStepPathsText
      return 0
  | ["query", title, path] =>
      runQuery title path 1 0
  | ["query", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runQuery title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | _ =>
      IO.eprintln usage
      return 2

end SymexMain

def main (args : List String) : IO UInt32 :=
  SymexMain.main args
