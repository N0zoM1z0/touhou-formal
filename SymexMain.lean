import TouhouFormal.Search.Symbolic

namespace SymexMain

private def usage : String :=
  "usage: lake exe symex <list-paths|query|query-values <th06|th07|th08> <path> [activeMask] [overrideMask]|materialize|materialize-file <th06|th07|th08> <path> <currentTime> <instrTime> <opcode> <nextOffset> <instructionMask> <operandMask> <activeMask> <overrideMask> <jumpTargetTime> <jumpDisplacement> <bufferSize>>"

private def parseNat? (value : String) : Option Nat :=
  value.toNat?

private def parseInt? (value : String) : Option Int :=
  value.toInt?

private def runQuery
    (valuesOnly : Bool)
    (titleText pathText : String)
    (activeMask overrideMask : Nat) :
    IO UInt32 := do
  if 255 < activeMask || 255 < overrideMask then
    IO.eprintln "activeMask and overrideMask must fit in an unsigned byte"
    IO.eprintln usage
    return 2
  else
    match TouhouFormal.Search.Symbolic.Title.parse? titleText,
          TouhouFormal.Search.Symbolic.RawStepPath.parse? pathText with
    | some title, some path =>
        if valuesOnly then
          IO.print
            (TouhouFormal.Search.Symbolic.rawStepValuesQuery title path activeMask overrideMask)
        else
          IO.print
            (TouhouFormal.Search.Symbolic.rawStepQuery title path activeMask overrideMask)
        return 0
    | none, _ =>
        IO.eprintln s!"unknown title: {titleText}"
        IO.eprintln usage
        return 2
    | _, none =>
        IO.eprintln s!"unknown path: {pathText}"
        IO.eprintln usage
        return 2

private def runMaterialize
    (asFile : Bool)
    (titleText pathText currentTimeText instrTimeText opcodeText nextOffsetText
      instructionMaskText operandMaskText activeMaskText overrideMaskText jumpTargetTimeText
      jumpDisplacementText bufferSizeText : String) : IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawStepPath.parse? pathText,
        parseInt? currentTimeText,
        parseInt? instrTimeText,
        parseInt? opcodeText,
        parseInt? nextOffsetText,
        parseNat? instructionMaskText,
        parseInt? operandMaskText,
        parseNat? activeMaskText,
        parseNat? overrideMaskText,
        parseInt? jumpTargetTimeText,
        parseInt? jumpDisplacementText,
        parseNat? bufferSizeText with
  | some title, some path, some currentTime, some instrTime, some opcode, some nextOffset,
      some instructionMask, some operandMask, some activeMask, some overrideMask,
      some jumpTargetTime, some jumpDisplacement, some bufferSize =>
      let witness : TouhouFormal.Search.Symbolic.RawStepWitness :=
        { currentTime := currentTime
          instrTime := instrTime
          opcode := opcode
          nextOffset := nextOffset
          instructionMask := instructionMask
          operandMask := operandMask
          activeMask := activeMask
          overrideMask := overrideMask
          jumpTargetTime := jumpTargetTime
          jumpDisplacement := jumpDisplacement
          bufferSize := bufferSize }
      if asFile then
        match TouhouFormal.Search.Symbolic.rawStepEclFileMaterialize title path witness with
        | .ok materialization =>
            IO.print materialization.report
            return 0
        | .error message =>
            IO.eprintln message
            return 1
      else
        match TouhouFormal.Search.Symbolic.rawStepMaterialize title path witness with
        | .ok materialization =>
            IO.print materialization.report
            return 0
        | .error message =>
            IO.eprintln message
            return 1
  | none, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown path: {pathText}"
      IO.eprintln usage
      return 2
  | _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln "invalid materialize witness field"
      IO.eprintln usage
      return 2

def main (args : List String) : IO UInt32 := do
  match args with
  | ["list-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawStepPathsText
      return 0
  | ["query", title, path] =>
      runQuery false title path 1 0
  | ["query-values", title, path] =>
      runQuery true title path 1 0
  | ["query", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runQuery false title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-values", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runQuery true title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | [ "materialize", title, path, currentTime, instrTime, opcode, nextOffset,
      instructionMask, operandMask, activeMask, overrideMask, jumpTargetTime,
      jumpDisplacement, bufferSize ] =>
      runMaterialize
        false
        title
        path
        currentTime
        instrTime
        opcode
        nextOffset
        instructionMask
        operandMask
        activeMask
        overrideMask
        jumpTargetTime
        jumpDisplacement
        bufferSize
  | [ "materialize-file", title, path, currentTime, instrTime, opcode, nextOffset,
      instructionMask, operandMask, activeMask, overrideMask, jumpTargetTime,
      jumpDisplacement, bufferSize ] =>
      runMaterialize
        true
        title
        path
        currentTime
        instrTime
        opcode
        nextOffset
        instructionMask
        operandMask
        activeMask
        overrideMask
        jumpTargetTime
        jumpDisplacement
        bufferSize
  | _ =>
      IO.eprintln usage
      return 2

end SymexMain

def main (args : List String) : IO UInt32 :=
  SymexMain.main args
