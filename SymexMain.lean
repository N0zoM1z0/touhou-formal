import TouhouFormal.Search.Symbolic

namespace SymexMain

private def usage : String :=
  "usage: lake exe symex <list-paths|list-body-paths|list-int-resolver-paths|" ++
  "list-callret-paths|list-condcall-paths|list-int-binary-paths|list-boss-int-paths|" ++
  "query|query-values|query-body|query-body-values|query-int-resolver|query-int-resolver-values|" ++
  "query-callret|query-callret-values|query-condcall|query-condcall-values|" ++
  "query-int-binary|query-int-binary-values|query-boss-int|query-boss-int-values|" ++
  "materialize|materialize-file|materialize-body|materialize-int-resolver|" ++
  "materialize-callret|materialize-condcall|materialize-int-binary|materialize-boss-int ...>"

private def parseNat? (value : String) : Option Nat :=
  value.toNat?

private def parseInt? (value : String) : Option Int :=
  value.toInt?

private def parseBool? : String -> Option Bool
  | "true" => some true
  | "false" => some false
  | "1" => some true
  | "0" => some false
  | _ => none

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

private def runBodyQuery
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
          TouhouFormal.Search.Symbolic.RawBodyPath.parse? pathText with
    | some title, some path =>
        if valuesOnly then
          IO.print
            (TouhouFormal.Search.Symbolic.rawBodyValuesQuery title path activeMask overrideMask)
        else
          IO.print
            (TouhouFormal.Search.Symbolic.rawBodyQuery title path activeMask overrideMask)
        return 0
    | none, _ =>
        IO.eprintln s!"unknown title: {titleText}"
        IO.eprintln usage
        return 2
    | _, none =>
        IO.eprintln s!"unknown body path: {pathText}"
        IO.eprintln usage
        return 2

private def runIntResolverQuery
    (valuesOnly : Bool)
    (titleText pathText : String)
    (slot : Nat) :
    IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawIntResolverPath.parse? pathText with
  | some title, some path =>
      if valuesOnly then
        IO.print
          (TouhouFormal.Search.Symbolic.rawIntResolverValuesQuery title path slot)
      else
        IO.print
          (TouhouFormal.Search.Symbolic.rawIntResolverQuery title path slot)
      return 0
  | none, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none =>
      IO.eprintln s!"unknown integer resolver path: {pathText}"
      IO.eprintln usage
      return 2

private def runCallRetQuery
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
          TouhouFormal.Search.Symbolic.RawCallRetPath.parse? pathText with
    | some title, some path =>
        if valuesOnly then
          IO.print
            (TouhouFormal.Search.Symbolic.rawCallRetValuesQuery title path activeMask overrideMask)
        else
          IO.print
            (TouhouFormal.Search.Symbolic.rawCallRetQuery title path activeMask overrideMask)
        return 0
    | none, _ =>
        IO.eprintln s!"unknown title: {titleText}"
        IO.eprintln usage
        return 2
    | _, none =>
        IO.eprintln s!"unknown CALL/RET path: {pathText}"
        IO.eprintln usage
        return 2

private def runConditionalCallQuery
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
          TouhouFormal.Search.Symbolic.RawConditionalCallPath.parse? pathText with
    | some title, some path =>
        if valuesOnly then
          IO.print
            (TouhouFormal.Search.Symbolic.rawConditionalCallValuesQuery title path activeMask overrideMask)
        else
          IO.print
            (TouhouFormal.Search.Symbolic.rawConditionalCallQuery title path activeMask overrideMask)
        return 0
    | none, _ =>
        IO.eprintln s!"unknown title: {titleText}"
        IO.eprintln usage
        return 2
    | _, none =>
        IO.eprintln s!"unknown conditional CALL path: {pathText}"
        IO.eprintln usage
        return 2

private def runIntBinaryQuery
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
          TouhouFormal.Search.Symbolic.RawIntBinaryPath.parse? pathText with
    | some title, some path =>
        if valuesOnly then
          IO.print
            (TouhouFormal.Search.Symbolic.rawIntBinaryValuesQuery title path activeMask overrideMask)
        else
          IO.print
            (TouhouFormal.Search.Symbolic.rawIntBinaryQuery title path activeMask overrideMask)
        return 0
    | none, _ =>
        IO.eprintln s!"unknown title: {titleText}"
        IO.eprintln usage
        return 2
    | _, none =>
        IO.eprintln s!"unknown integer binary path: {pathText}"
        IO.eprintln usage
        return 2

private def runBossIntReadQuery
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
          TouhouFormal.Search.Symbolic.RawBossIntReadPath.parse? pathText with
    | some title, some path =>
        if valuesOnly then
          IO.print
            (TouhouFormal.Search.Symbolic.rawBossIntReadValuesQuery title path activeMask overrideMask)
        else
          IO.print
            (TouhouFormal.Search.Symbolic.rawBossIntReadQuery title path activeMask overrideMask)
        return 0
    | none, _ =>
        IO.eprintln s!"unknown title: {titleText}"
        IO.eprintln usage
        return 2
    | _, none =>
        IO.eprintln s!"unknown boss integer-read path: {pathText}"
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

private def runBodyMaterialize
    (titleText pathText currentTimeText instrTimeText opcodeText nextOffsetText
      instructionMaskText operandMaskText activeMaskText overrideMaskText jumpTargetTimeText
      jumpDisplacementText counterBeforeText divisorValueText lhsRawText rhsRawText lhsHostText
      rhsHostText compareRegisterText bufferSizeText : String) :
    IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawBodyPath.parse? pathText,
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
        parseInt? counterBeforeText,
        parseInt? divisorValueText,
        parseInt? lhsRawText,
        parseInt? rhsRawText,
        parseInt? lhsHostText,
        parseInt? rhsHostText,
        parseInt? compareRegisterText,
        parseNat? bufferSizeText with
  | some title, some path, some currentTime, some instrTime, some opcode, some nextOffset,
      some instructionMask, some operandMask, some activeMask, some overrideMask,
      some jumpTargetTime, some jumpDisplacement, some counterBefore, some divisorValue,
      some lhsRaw, some rhsRaw, some lhsHost, some rhsHost, some compareRegister, some bufferSize =>
      let witness : TouhouFormal.Search.Symbolic.RawBodyWitness :=
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
          bufferSize := bufferSize
          counterBefore := counterBefore
          divisorValue := divisorValue
          lhsRaw := lhsRaw
          rhsRaw := rhsRaw
          lhsHost := lhsHost
          rhsHost := rhsHost
          compareRegister := compareRegister }
      match TouhouFormal.Search.Symbolic.rawBodyMaterialize title path witness with
      | .ok materialization =>
          IO.print materialization.report
          return 0
      | .error message =>
          IO.eprintln message
          return 1
  | none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown body path: {pathText}"
      IO.eprintln usage
      return 2
  | _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln "invalid materialize-body witness field"
      IO.eprintln usage
      return 2

private def runIntResolverMaterialize
    (titleText pathText slotText rawValueText hostValueText operandMaskText : String) :
    IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawIntResolverPath.parse? pathText,
        parseNat? slotText,
        parseInt? rawValueText,
        parseInt? hostValueText,
        parseInt? operandMaskText with
  | some title, some path, some slot, some rawValue, some hostValue, some operandMask =>
      let witness : TouhouFormal.Search.Symbolic.RawIntResolverWitness :=
        { slot := slot
          rawValue := rawValue
          hostValue := hostValue
          operandMask := operandMask }
      match TouhouFormal.Search.Symbolic.rawIntResolverMaterialize title path witness with
      | .ok materialization =>
          IO.print materialization.report
          return 0
      | .error message =>
          IO.eprintln message
          return 1
  | none, _, _, _, _, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none, _, _, _, _ =>
      IO.eprintln s!"unknown integer resolver path: {pathText}"
      IO.eprintln usage
      return 2
  | _, _, _, _, _, _ =>
      IO.eprintln "invalid materialize-int-resolver witness field"
      IO.eprintln usage
      return 2

private def runCallRetMaterialize
    (titleText pathText currentTimeText instrTimeText opcodeText nextOffsetText
      instructionMaskText operandMaskText activeMaskText overrideMaskText subIdText
      stackDepthText stackDisabledText subCountText childContextSlotText bufferSizeText : String) :
    IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawCallRetPath.parse? pathText,
        parseInt? currentTimeText,
        parseInt? instrTimeText,
        parseInt? opcodeText,
        parseInt? nextOffsetText,
        parseNat? instructionMaskText,
        parseInt? operandMaskText,
        parseNat? activeMaskText,
        parseNat? overrideMaskText,
        parseInt? subIdText,
        parseInt? stackDepthText,
        parseBool? stackDisabledText,
        parseNat? subCountText,
        parseInt? childContextSlotText,
        parseNat? bufferSizeText with
  | some title, some path, some currentTime, some instrTime, some opcode, some nextOffset,
      some instructionMask, some operandMask, some activeMask, some overrideMask,
      some subId, some stackDepth, some stackDisabled, some subCount, some childContextSlot,
      some bufferSize =>
      let witness : TouhouFormal.Search.Symbolic.RawCallRetWitness :=
        { currentTime := currentTime
          instrTime := instrTime
          opcode := opcode
          nextOffset := nextOffset
          instructionMask := instructionMask
          operandMask := operandMask
          activeMask := activeMask
          overrideMask := overrideMask
          jumpTargetTime := 0
          jumpDisplacement := 0
          bufferSize := bufferSize
          subId := subId
          stackDepth := stackDepth
          stackDisabled := stackDisabled
          subCount := subCount
          childContextSlot := childContextSlot }
      match TouhouFormal.Search.Symbolic.rawCallRetMaterialize title path witness with
      | .ok materialization =>
          IO.print materialization.report
          return 0
      | .error message =>
          IO.eprintln message
          return 1
  | none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown CALL/RET path: {pathText}"
      IO.eprintln usage
      return 2
  | _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln "invalid materialize-callret witness field"
      IO.eprintln usage
      return 2

private def runConditionalCallMaterialize
    (titleText pathText currentTimeText instrTimeText opcodeText nextOffsetText
      instructionMaskText operandMaskText activeMaskText overrideMaskText subIdText
      stackDepthText stackDisabledText subCountText lhsRawText lhsHostText rhsRawText
      bufferSizeText : String) :
    IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawConditionalCallPath.parse? pathText,
        parseInt? currentTimeText,
        parseInt? instrTimeText,
        parseInt? opcodeText,
        parseInt? nextOffsetText,
        parseNat? instructionMaskText,
        parseInt? operandMaskText,
        parseNat? activeMaskText,
        parseNat? overrideMaskText,
        parseInt? subIdText,
        parseInt? stackDepthText,
        parseBool? stackDisabledText,
        parseNat? subCountText,
        parseInt? lhsRawText,
        parseInt? lhsHostText,
        parseInt? rhsRawText,
        parseNat? bufferSizeText with
  | some title, some path, some currentTime, some instrTime, some opcode, some nextOffset,
      some instructionMask, some operandMask, some activeMask, some overrideMask,
      some subId, some stackDepth, some stackDisabled, some subCount, some lhsRaw,
      some lhsHost, some rhsRaw, some bufferSize =>
      let witness : TouhouFormal.Search.Symbolic.RawConditionalCallWitness :=
        { currentTime := currentTime
          instrTime := instrTime
          opcode := opcode
          nextOffset := nextOffset
          instructionMask := instructionMask
          operandMask := operandMask
          activeMask := activeMask
          overrideMask := overrideMask
          jumpTargetTime := 0
          jumpDisplacement := 0
          bufferSize := bufferSize
          subId := subId
          stackDepth := stackDepth
          stackDisabled := stackDisabled
          subCount := subCount
          lhsRaw := lhsRaw
          lhsHost := lhsHost
          rhsRaw := rhsRaw }
      match TouhouFormal.Search.Symbolic.rawConditionalCallMaterialize title path witness with
      | .ok materialization =>
          IO.print materialization.report
          return 0
      | .error message =>
          IO.eprintln message
          return 1
  | none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown conditional CALL path: {pathText}"
      IO.eprintln usage
      return 2
  | _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln "invalid materialize-condcall witness field"
      IO.eprintln usage
      return 2

private def runIntBinaryMaterialize
    (titleText pathText currentTimeText instrTimeText opcodeText nextOffsetText
      instructionMaskText operandMaskText activeMaskText overrideMaskText outputRawText
      outputHostBeforeText lhsRawText rhsRawText lhsHostText rhsHostText bufferSizeText : String) :
    IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawIntBinaryPath.parse? pathText,
        parseInt? currentTimeText,
        parseInt? instrTimeText,
        parseInt? opcodeText,
        parseInt? nextOffsetText,
        parseNat? instructionMaskText,
        parseInt? operandMaskText,
        parseNat? activeMaskText,
        parseNat? overrideMaskText,
        parseInt? outputRawText,
        parseInt? outputHostBeforeText,
        parseInt? lhsRawText,
        parseInt? rhsRawText,
        parseInt? lhsHostText,
        parseInt? rhsHostText,
        parseNat? bufferSizeText with
  | some title, some path, some currentTime, some instrTime, some opcode, some nextOffset,
      some instructionMask, some operandMask, some activeMask, some overrideMask,
      some outputRaw, some outputHostBefore, some lhsRaw, some rhsRaw, some lhsHost,
      some rhsHost, some bufferSize =>
      let witness : TouhouFormal.Search.Symbolic.RawIntBinaryWitness :=
        { currentTime := currentTime
          instrTime := instrTime
          opcode := opcode
          nextOffset := nextOffset
          instructionMask := instructionMask
          operandMask := operandMask
          activeMask := activeMask
          overrideMask := overrideMask
          jumpTargetTime := 0
          jumpDisplacement := 0
          bufferSize := bufferSize
          outputRaw := outputRaw
          outputHostBefore := outputHostBefore
          lhsRaw := lhsRaw
          rhsRaw := rhsRaw
          lhsHost := lhsHost
          rhsHost := rhsHost }
      match TouhouFormal.Search.Symbolic.rawIntBinaryMaterialize title path witness with
      | .ok materialization =>
          IO.print materialization.report
          return 0
      | .error message =>
          IO.eprintln message
          return 1
  | none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown integer binary path: {pathText}"
      IO.eprintln usage
      return 2
  | _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln "invalid materialize-int-binary witness field"
      IO.eprintln usage
      return 2

private def runBossIntReadMaterialize
    (titleText pathText currentTimeText instrTimeText opcodeText nextOffsetText
      instructionMaskText operandMaskText activeMaskText overrideMaskText outputRawText
      outputHostBeforeText valueRawText valueHostText bossIndexRawText bossIndexHostText
      bossPresentText bufferSizeText : String) :
    IO UInt32 := do
  match TouhouFormal.Search.Symbolic.Title.parse? titleText,
        TouhouFormal.Search.Symbolic.RawBossIntReadPath.parse? pathText,
        parseInt? currentTimeText,
        parseInt? instrTimeText,
        parseInt? opcodeText,
        parseInt? nextOffsetText,
        parseNat? instructionMaskText,
        parseInt? operandMaskText,
        parseNat? activeMaskText,
        parseNat? overrideMaskText,
        parseInt? outputRawText,
        parseInt? outputHostBeforeText,
        parseInt? valueRawText,
        parseInt? valueHostText,
        parseInt? bossIndexRawText,
        parseInt? bossIndexHostText,
        parseBool? bossPresentText,
        parseNat? bufferSizeText with
  | some title, some path, some currentTime, some instrTime, some opcode, some nextOffset,
      some instructionMask, some operandMask, some activeMask, some overrideMask,
      some outputRaw, some outputHostBefore, some valueRaw, some valueHost,
      some bossIndexRaw, some bossIndexHost, some bossPresent, some bufferSize =>
      let witness : TouhouFormal.Search.Symbolic.RawBossIntReadWitness :=
        { currentTime := currentTime
          instrTime := instrTime
          opcode := opcode
          nextOffset := nextOffset
          instructionMask := instructionMask
          operandMask := operandMask
          activeMask := activeMask
          overrideMask := overrideMask
          jumpTargetTime := 0
          jumpDisplacement := 0
          bufferSize := bufferSize
          outputRaw := outputRaw
          outputHostBefore := outputHostBefore
          valueRaw := valueRaw
          valueHost := valueHost
          bossIndexRaw := bossIndexRaw
          bossIndexHost := bossIndexHost
          bossPresent := bossPresent }
      match TouhouFormal.Search.Symbolic.rawBossIntReadMaterialize title path witness with
      | .ok materialization =>
          IO.print materialization.report
          return 0
      | .error message =>
          IO.eprintln message
          return 1
  | none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown title: {titleText}"
      IO.eprintln usage
      return 2
  | _, none, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln s!"unknown boss integer-read path: {pathText}"
      IO.eprintln usage
      return 2
  | _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ =>
      IO.eprintln "invalid materialize-boss-int witness field"
      IO.eprintln usage
      return 2

def main (args : List String) : IO UInt32 := do
  match args with
  | ["list-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawStepPathsText
      return 0
  | ["list-body-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawBodyPathsText
      return 0
  | ["list-int-resolver-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawIntResolverPathsText
      return 0
  | ["list-callret-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawCallRetPathsText
      return 0
  | ["list-condcall-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawConditionalCallPathsText
      return 0
  | ["list-int-binary-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawIntBinaryPathsText
      return 0
  | ["list-boss-int-paths"] =>
      IO.print TouhouFormal.Search.Symbolic.listRawBossIntReadPathsText
      return 0
  | ["query", title, path] =>
      runQuery false title path 1 0
  | ["query-values", title, path] =>
      runQuery true title path 1 0
  | ["query-body", title, path] =>
      runBodyQuery false title path 1 0
  | ["query-body-values", title, path] =>
      runBodyQuery true title path 1 0
  | ["query-int-resolver", title, path] =>
      runIntResolverQuery false title path 0
  | ["query-int-resolver-values", title, path] =>
      runIntResolverQuery true title path 0
  | ["query-callret", title, path] =>
      runCallRetQuery false title path 1 0
  | ["query-callret-values", title, path] =>
      runCallRetQuery true title path 1 0
  | ["query-condcall", title, path] =>
      runConditionalCallQuery false title path 1 0
  | ["query-condcall-values", title, path] =>
      runConditionalCallQuery true title path 1 0
  | ["query-int-binary", title, path] =>
      runIntBinaryQuery false title path 1 0
  | ["query-int-binary-values", title, path] =>
      runIntBinaryQuery true title path 1 0
  | ["query-boss-int", title, path] =>
      runBossIntReadQuery false title path 1 0
  | ["query-boss-int-values", title, path] =>
      runBossIntReadQuery true title path 1 0
  | ["query", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runQuery false title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-body", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runBodyQuery false title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-body-values", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runBodyQuery true title path activeMask overrideMask
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
  | ["query-callret", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runCallRetQuery false title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-callret-values", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runCallRetQuery true title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-condcall", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runConditionalCallQuery false title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-condcall-values", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runConditionalCallQuery true title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-int-binary", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runIntBinaryQuery false title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-int-binary-values", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runIntBinaryQuery true title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-boss-int", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runBossIntReadQuery false title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-boss-int-values", title, path, activeMaskText, overrideMaskText] =>
      match parseNat? activeMaskText, parseNat? overrideMaskText with
      | some activeMask, some overrideMask =>
          runBossIntReadQuery true title path activeMask overrideMask
      | _, _ =>
          IO.eprintln "activeMask and overrideMask must be natural numbers"
          IO.eprintln usage
          return 2
  | ["query-int-resolver", title, path, slotText] =>
      match parseNat? slotText with
      | some slot => runIntResolverQuery false title path slot
      | none =>
          IO.eprintln "slot must be a natural number"
          IO.eprintln usage
          return 2
  | ["query-int-resolver-values", title, path, slotText] =>
      match parseNat? slotText with
      | some slot => runIntResolverQuery true title path slot
      | none =>
          IO.eprintln "slot must be a natural number"
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
  | [ "materialize-body", title, path, currentTime, instrTime, opcode, nextOffset,
      instructionMask, operandMask, activeMask, overrideMask, jumpTargetTime,
      jumpDisplacement, counterBefore, divisorValue, lhsRaw, rhsRaw, lhsHost,
      rhsHost, compareRegister, bufferSize ] =>
      runBodyMaterialize
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
        counterBefore
        divisorValue
        lhsRaw
        rhsRaw
        lhsHost
        rhsHost
        compareRegister
        bufferSize
  | [ "materialize-int-resolver", title, path, slot, rawValue, hostValue, operandMask ] =>
      runIntResolverMaterialize title path slot rawValue hostValue operandMask
  | [ "materialize-callret", title, path, currentTime, instrTime, opcode, nextOffset,
      instructionMask, operandMask, activeMask, overrideMask, subId, stackDepth,
      stackDisabled, subCount, childContextSlot, bufferSize ] =>
      runCallRetMaterialize
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
        subId
        stackDepth
        stackDisabled
        subCount
        childContextSlot
        bufferSize
  | [ "materialize-condcall", title, path, currentTime, instrTime, opcode, nextOffset,
      instructionMask, operandMask, activeMask, overrideMask, subId, stackDepth,
      stackDisabled, subCount, lhsRaw, lhsHost, rhsRaw, bufferSize ] =>
      runConditionalCallMaterialize
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
        subId
        stackDepth
        stackDisabled
        subCount
        lhsRaw
        lhsHost
        rhsRaw
        bufferSize
  | [ "materialize-int-binary", title, path, currentTime, instrTime, opcode, nextOffset,
      instructionMask, operandMask, activeMask, overrideMask, outputRaw, outputHostBefore,
      lhsRaw, rhsRaw, lhsHost, rhsHost, bufferSize ] =>
      runIntBinaryMaterialize
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
        outputRaw
        outputHostBefore
        lhsRaw
        rhsRaw
        lhsHost
        rhsHost
        bufferSize
  | [ "materialize-boss-int", title, path, currentTime, instrTime, opcode, nextOffset,
      instructionMask, operandMask, activeMask, overrideMask, outputRaw, outputHostBefore,
      valueRaw, valueHost, bossIndexRaw, bossIndexHost, bossPresent, bufferSize ] =>
      runBossIntReadMaterialize
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
        outputRaw
        outputHostBefore
        valueRaw
        valueHost
        bossIndexRaw
        bossIndexHost
        bossPresent
        bufferSize
  | _ =>
      IO.eprintln usage
      return 2

end SymexMain

def main (args : List String) : IO UInt32 :=
  SymexMain.main args
