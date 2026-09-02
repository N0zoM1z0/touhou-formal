import TouhouFormal.Search.Symbolic.Common

namespace TouhouFormal.Search.Symbolic

private def rawStepValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask jumpTargetTime jumpDisplacement bufferSize difficultyPass)"

private def rawBodyValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask jumpTargetTime jumpDisplacement counterBefore divisorValue lhsRaw rhsRaw lhsHost rhsHost compareRegister bufferSize difficultyPass)"

private def rawCallRetValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask subId stackDepth stackDisabled subCount childContextSlot bufferSize difficultyPass)"

private def rawConditionalCallValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask subId stackDepth stackDisabled subCount lhsRaw lhsHost rhsRaw bufferSize difficultyPass)"

private def rawIntBinaryValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask outputRaw outputHostBefore lhsRaw rhsRaw lhsHost rhsHost bufferSize difficultyPass)"

private def rawBossIntReadValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask outputRaw outputHostBefore valueRaw valueHost bossIndexRaw bossIndexHost bossPresent bufferSize difficultyPass)"

private def rawBossFloatReadValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask outputRaw outputHostBefore valueRaw valueHost bossIndexRaw bossIndexHost bossPresent bufferSize difficultyPass)"

private def rawStepQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawStepPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL step query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared raw ECL single-step semantics."
         , "; Title: " ++ shape.title
         , "; Path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const jumpTargetTime Int)"
         , "(declare-const jumpDisplacement Int)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI32Range "jumpTargetTime"
         , signedI32Range "jumpDisplacement"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (and (<= " ++ toString (requiredInstructionBytes rawShape path) ++
             " bufferSize) (<= bufferSize 1048576)))" ] ++
         operandMaskSmtLines rawShape ++
         rawStepPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawStepValueTerms ++ ")"] else []))

def rawStepQuery
    (title : Title)
    (path : RawStepPath)
    (activeMask overrideMask : Nat) : String :=
  rawStepQueryWith true false title path activeMask overrideMask

def rawStepValuesQuery
    (title : Title)
    (path : RawStepPath)
    (activeMask overrideMask : Nat) : String :=
  rawStepQueryWith false true title path activeMask overrideMask

def listRawStepPathsText : String :=
  joinLines (allRawStepPaths.map RawStepPath.name)

private def rawBodyQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawBodyPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL body query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared raw ECL body semantics."
         , "; Title: " ++ shape.title
         , "; Body path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const jumpTargetTime Int)"
         , "(declare-const jumpDisplacement Int)"
         , "(declare-const counterBefore Int)"
         , "(declare-const divisorValue Int)"
         , "(declare-const lhsRaw Int)"
         , "(declare-const rhsRaw Int)"
         , "(declare-const lhsHost Int)"
         , "(declare-const rhsHost Int)"
         , "(declare-const compareRegister Int)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI32Range "jumpTargetTime"
         , signedI32Range "jumpDisplacement"
         , signedI32Range "counterBefore"
         , signedI32Range "divisorValue"
         , signedI32Range "lhsRaw"
         , signedI32Range "rhsRaw"
         , signedI32Range "lhsHost"
         , signedI32Range "rhsHost"
         , signedI32Range "compareRegister"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (and (<= " ++ toString (requiredBodyInstructionBytes rawShape path) ++
             " bufferSize) (<= bufferSize 1048576)))" ] ++
         operandMaskSmtLines rawShape ++
         rawBodyPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawBodyValueTerms ++ ")"] else []))

def rawBodyQuery
    (title : Title)
    (path : RawBodyPath)
    (activeMask overrideMask : Nat) : String :=
  rawBodyQueryWith true false title path activeMask overrideMask

def rawBodyValuesQuery
    (title : Title)
    (path : RawBodyPath)
    (activeMask overrideMask : Nat) : String :=
  rawBodyQueryWith false true title path activeMask overrideMask

def listRawBodyPathsText : String :=
  joinLines (allRawBodyPaths.map RawBodyPath.name)

private def rawIntResolverValueTerms : String :=
  "(slot rawValue hostValue operandMask)"

private def rawIntResolverQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawIntResolverPath)
    (slot : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL integer resolver query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared integer operand resolver semantics."
         , "; Title: " ++ shape.title
         , "; Resolver path: " ++ path.name
         , "(define-fun slot () Int " ++ toString slot ++ ")"
         , "(declare-const rawValue Int)"
         , "(declare-const hostValue Int)"
         , signedI32Range "rawValue"
         , signedI32Range "hostValue" ] ++
         operandMaskSmtLines rawShape ++
         rawIntResolverPathConstraints rawShape path slot ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawIntResolverValueTerms ++ ")"] else []))

def rawIntResolverQuery
    (title : Title)
    (path : RawIntResolverPath)
    (slot : Nat) : String :=
  rawIntResolverQueryWith false false title path slot

def rawIntResolverValuesQuery
    (title : Title)
    (path : RawIntResolverPath)
    (slot : Nat) : String :=
  rawIntResolverQueryWith false true title path slot

def listRawIntResolverPathsText : String :=
  joinLines (allRawIntResolverPaths.map RawIntResolverPath.name)

private def rawCallRetQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawCallRetPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL CALL/RET query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared CALL/RET stack semantics."
         , "; Title: " ++ shape.title
         , "; CALL/RET path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const subId Int)"
         , "(declare-const stackDepth Int)"
         , "(declare-const stackDisabled Bool)"
         , "(declare-const subCount Int)"
         , "(declare-const childContextSlot Int)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI16Range "subId"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (and (<= " ++ toString (requiredCallRetInstructionBytes rawShape path) ++
             " bufferSize) (<= bufferSize 1048576)))" ] ++
         operandMaskSmtLines rawShape ++
         rawCallRetPathConstraints shape rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawCallRetValueTerms ++ ")"] else []))

def rawCallRetQuery
    (title : Title)
    (path : RawCallRetPath)
    (activeMask overrideMask : Nat) : String :=
  rawCallRetQueryWith false false title path activeMask overrideMask

def rawCallRetValuesQuery
    (title : Title)
    (path : RawCallRetPath)
    (activeMask overrideMask : Nat) : String :=
  rawCallRetQueryWith false true title path activeMask overrideMask

def listRawCallRetPathsText : String :=
  joinLines (allRawCallRetPaths.map RawCallRetPath.name)

private def rawConditionalCallQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawConditionalCallPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL conditional CALL query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared guarded-CALL semantics."
         , "; Title: " ++ shape.title
         , "; Conditional CALL path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const subId Int)"
         , "(declare-const stackDepth Int)"
         , "(declare-const stackDisabled Bool)"
         , "(declare-const subCount Int)"
         , "(declare-const lhsRaw Int)"
         , "(declare-const lhsHost Int)"
         , "(declare-const rhsRaw Int)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI16Range "subId"
         , signedI32Range "lhsRaw"
         , signedI32Range "lhsHost"
         , signedI32Range "rhsRaw"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (and (<= " ++ toString (requiredConditionalCallInstructionBytes rawShape path) ++
             " bufferSize) (<= bufferSize 1048576)))" ] ++
         operandMaskSmtLines rawShape ++
         rawConditionalCallPathConstraints shape rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawConditionalCallValueTerms ++ ")"] else []))

def rawConditionalCallQuery
    (title : Title)
    (path : RawConditionalCallPath)
    (activeMask overrideMask : Nat) : String :=
  rawConditionalCallQueryWith false false title path activeMask overrideMask

def rawConditionalCallValuesQuery
    (title : Title)
    (path : RawConditionalCallPath)
    (activeMask overrideMask : Nat) : String :=
  rawConditionalCallQueryWith false true title path activeMask overrideMask

def listRawConditionalCallPathsText : String :=
  joinLines (allRawConditionalCallPaths.map RawConditionalCallPath.name)

private def rawIntBinaryQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawIntBinaryPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL integer binary-op query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      let requiredBytes := requiredIntBinaryInstructionBytes rawShape path
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared integer binary-op semantics."
         , "; Title: " ++ shape.title
         , "; Integer binary path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const outputRaw Int)"
         , "(declare-const outputHostBefore Int)"
         , "(declare-const lhsRaw Int)"
         , "(declare-const rhsRaw Int)"
         , "(declare-const lhsHost Int)"
         , "(declare-const rhsHost Int)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI32Range "outputRaw"
         , signedI32Range "outputHostBefore"
         , signedI32Range "lhsRaw"
         , signedI32Range "rhsRaw"
         , signedI32Range "lhsHost"
         , signedI32Range "rhsHost"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (= nextOffset " ++ toString requiredBytes ++ "))"
         , "(assert (= bufferSize " ++ toString requiredBytes ++ "))" ] ++
         operandMaskSmtLines rawShape ++
         rawIntBinaryPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawIntBinaryValueTerms ++ ")"] else []))

def rawIntBinaryQuery
    (title : Title)
    (path : RawIntBinaryPath)
    (activeMask overrideMask : Nat) : String :=
  rawIntBinaryQueryWith false false title path activeMask overrideMask

def rawIntBinaryValuesQuery
    (title : Title)
    (path : RawIntBinaryPath)
    (activeMask overrideMask : Nat) : String :=
  rawIntBinaryQueryWith false true title path activeMask overrideMask

def listRawIntBinaryPathsText : String :=
  joinLines (allRawIntBinaryPaths.map RawIntBinaryPath.name)

private def rawBossIntReadQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawBossIntReadPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL boss integer-read query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      let requiredBytes := requiredBossIntReadInstructionBytes rawShape path
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared boss integer-read semantics."
         , "; Title: " ++ shape.title
         , "; Boss integer-read path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const outputRaw Int)"
         , "(declare-const outputHostBefore Int)"
         , "(declare-const valueRaw Int)"
         , "(declare-const valueHost Int)"
         , "(declare-const bossIndexRaw Int)"
         , "(declare-const bossIndexHost Int)"
         , "(declare-const bossPresent Bool)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI32Range "outputRaw"
         , signedI32Range "outputHostBefore"
         , signedI32Range "valueRaw"
         , signedI32Range "valueHost"
         , signedI32Range "bossIndexRaw"
         , signedI32Range "bossIndexHost"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (= nextOffset " ++ toString requiredBytes ++ "))"
         , "(assert (= bufferSize " ++ toString requiredBytes ++ "))" ] ++
         operandMaskSmtLines rawShape ++
         rawBossIntReadPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawBossIntReadValueTerms ++ ")"] else []))

def rawBossIntReadQuery
    (title : Title)
    (path : RawBossIntReadPath)
    (activeMask overrideMask : Nat) : String :=
  rawBossIntReadQueryWith false false title path activeMask overrideMask

def rawBossIntReadValuesQuery
    (title : Title)
    (path : RawBossIntReadPath)
    (activeMask overrideMask : Nat) : String :=
  rawBossIntReadQueryWith false true title path activeMask overrideMask

def listRawBossIntReadPathsText : String :=
  joinLines (allRawBossIntReadPaths.map RawBossIntReadPath.name)

private def rawBossFloatReadQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawBossFloatReadPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL boss float-read query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      let requiredBytes := requiredBossFloatReadInstructionBytes rawShape path
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared boss float-read semantics."
         , "; Title: " ++ shape.title
         , "; Boss float-read path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const outputRaw Int)"
         , "(declare-const outputHostBefore Int)"
         , "(declare-const valueRaw Int)"
         , "(declare-const valueHost Int)"
         , "(declare-const bossIndexRaw Int)"
         , "(declare-const bossIndexHost Int)"
         , "(declare-const bossPresent Bool)"
         , "(declare-const bufferSize Int)"
         , "(define-fun fileOffset () Int 0)"
         , "(declare-const instructionMask (_ BitVec 8))"
         , "(define-fun activeMask () (_ BitVec 8) " ++ bv8 activeMask ++ ")"
         , "(define-fun overrideMask () (_ BitVec 8) " ++ bv8 overrideMask ++ ")"
         , "(define-fun requiredDifficultyMask () (_ BitVec 8) (bvor activeMask overrideMask))"
         , "(define-fun difficultyPass () Bool " ++ difficultyExpr ++ ")"
         , scalarRange "instrTime" rawShape.timeWidth
         , scalarRange "opcode" rawShape.opcodeWidth
         , scalarRange "nextOffset" rawShape.nextOffsetWidth
         , signedI32Range "outputRaw"
         , signedI32Range "outputHostBefore"
         , signedI32Range "valueRaw"
         , signedI32Range "valueHost"
         , signedI32Range "bossIndexRaw"
         , signedI32Range "bossIndexHost"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (= nextOffset " ++ toString requiredBytes ++ "))"
         , "(assert (= bufferSize " ++ toString requiredBytes ++ "))" ] ++
         operandMaskSmtLines rawShape ++
         rawBossFloatReadPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawBossFloatReadValueTerms ++ ")"] else []))

def rawBossFloatReadQuery
    (title : Title)
    (path : RawBossFloatReadPath)
    (activeMask overrideMask : Nat) : String :=
  rawBossFloatReadQueryWith false false title path activeMask overrideMask

def rawBossFloatReadValuesQuery
    (title : Title)
    (path : RawBossFloatReadPath)
    (activeMask overrideMask : Nat) : String :=
  rawBossFloatReadQueryWith false true title path activeMask overrideMask

def listRawBossFloatReadPathsText : String :=
  joinLines (allRawBossFloatReadPaths.map RawBossFloatReadPath.name)

structure RawStepWitness where
  currentTime : Int
  instrTime : Int
  opcode : Int
  nextOffset : Int
  instructionMask : Nat
  operandMask : Int
  activeMask : Nat
  overrideMask : Nat
  jumpTargetTime : Int
  jumpDisplacement : Int
  bufferSize : Nat
deriving Repr, DecidableEq

structure RawBodyWitness extends RawStepWitness where
  counterBefore : Int
  divisorValue : Int
  lhsRaw : Int
  rhsRaw : Int
  lhsHost : Int
  rhsHost : Int
  compareRegister : Int
deriving Repr, DecidableEq

structure RawStepMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  jump : Option TouhouFormal.ECL.RawJumpOperands
  outcome : TouhouFormal.ECL.RawStepOutcome
  matchesPath : Bool
deriving Repr, DecidableEq

structure RawBodyMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome
  matchesPath : Bool
deriving Repr

structure RawIntResolverWitness where
  slot : Nat
  rawValue : Int
  hostValue : Int
  operandMask : Int
deriving Repr, DecidableEq

structure RawCallRetWitness extends RawStepWitness where
  subId : Int
  stackDepth : Int
  stackDisabled : Bool
  subCount : Nat
  childContextSlot : Int
deriving Repr, DecidableEq

structure RawConditionalCallWitness extends RawStepWitness where
  subId : Int
  stackDepth : Int
  stackDisabled : Bool
  subCount : Nat
  lhsRaw : Int
  lhsHost : Int
  rhsRaw : Int
deriving Repr, DecidableEq

structure RawIntBinaryWitness extends RawStepWitness where
  outputRaw : Int
  outputHostBefore : Int
  lhsRaw : Int
  rhsRaw : Int
  lhsHost : Int
  rhsHost : Int
deriving Repr, DecidableEq

structure RawBossIntReadWitness extends RawStepWitness where
  outputRaw : Int
  outputHostBefore : Int
  valueRaw : Int
  valueHost : Int
  bossIndexRaw : Int
  bossIndexHost : Int
  bossPresent : Bool
deriving Repr, DecidableEq

structure RawBossFloatReadWitness extends RawStepWitness where
  outputRaw : Int
  outputHostBefore : Int
  valueRaw : Int
  valueHost : Int
  bossIndexRaw : Int
  bossIndexHost : Int
  bossPresent : Bool
deriving Repr, DecidableEq

structure RawIntResolverMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  rawValue : Int
  resolution : TouhouFormal.ECL.RawIntOperandResolution
  matchesPath : Bool
deriving Repr, DecidableEq

structure RawCallRetMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome
  matchesPath : Bool
deriving Repr

structure RawConditionalCallMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome
  matchesPath : Bool
deriving Repr

structure RawIntBinaryMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpOutcome
  matchesPath : Bool
deriving Repr

structure RawBossIntReadMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadOutcome
  matchesPath : Bool
deriving Repr

structure RawBossFloatReadMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadOutcome
  matchesPath : Bool
deriving Repr

structure RawStepEclFileMaterialization where
  rawStep : RawStepMaterialization
  eclFile : TouhouFormal.Bytes
  subOffset : Nat
deriving Repr, DecidableEq

private partial def writeAt
    (bytes : TouhouFormal.Bytes)
    (offset : Nat) :
    List UInt8 -> Option TouhouFormal.Bytes
  | [] => some bytes
  | byte :: rest =>
      if offset < bytes.size then
        writeAt (bytes.set! offset byte) (offset + 1) rest
      else
        none

private def writeScalar
    (bytes : TouhouFormal.Bytes)
    (offset : Nat)
    (width : TouhouFormal.ScalarWidth)
    (value : Int)
    (fieldName : String) : Except String TouhouFormal.Bytes :=
  match width.encodeLE? value with
  | none =>
      .error
        ("cannot encode " ++ fieldName ++ "=" ++ toString value ++
          " as " ++ reprStr width)
  | some encoded =>
      match writeAt bytes offset encoded with
      | none =>
          .error
            ("field " ++ fieldName ++ " at offset " ++ toString offset ++
              " does not fit in buffer")
      | some updated => .ok updated

private def writeOptionalScalar
    (bytes : TouhouFormal.Bytes)
    (fieldName : String)
    (offset? : Option Nat)
    (width? : Option TouhouFormal.ScalarWidth)
    (value : Int) : Except String TouhouFormal.Bytes :=
  match offset?, width? with
  | some offset, some width => writeScalar bytes offset width value fieldName
  | none, none => .ok bytes
  | _, _ => .error ("profile has partial optional field shape for " ++ fieldName)

private def liftFaultToString {α : Type} : Except TouhouFormal.Fault α -> Except String α
  | .ok value => .ok value
  | .error faultValue => .error faultValue.describe

def rawStepWitnessBytes
    (title : Title)
    (path : RawStepPath)
    (witness : RawStepWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required raw instruction bytes=" ++ toString requiredBytes)
      else if 255 < witness.instructionMask then
        .error "instructionMask must fit in an unsigned byte"
      else if 255 < witness.activeMask || 255 < witness.overrideMask then
        .error "activeMask and overrideMask must fit in an unsigned byte"
      else
        let initial : TouhouFormal.Bytes := (TouhouFormal.zeroBytes witness.bufferSize).toArray
        let bytes <- writeScalar initial rawShape.timeOffset rawShape.timeWidth witness.instrTime "time"
        let bytes <- writeScalar bytes rawShape.opcodeOffset rawShape.opcodeWidth witness.opcode "opcode"
        let bytes <-
          writeScalar
            bytes
            rawShape.nextOffsetOffset
            rawShape.nextOffsetWidth
            witness.nextOffset
            "nextOffset"
        let bytes <-
          writeOptionalScalar
            bytes
            "difficultyMask"
            rawShape.difficultyMaskOffset
            rawShape.difficultyMaskWidth
            (Int.ofNat witness.instructionMask)
        let bytes <-
          writeOptionalScalar
            bytes
            "operandMask"
            rawShape.operandMaskOffset
            rawShape.operandMaskWidth
            witness.operandMask
        match path, rawShape.fixedJumpShape, rawShape.fixedI32OperandBaseOffset with
        | .jumped _, some jumpShape, some baseOffset =>
            let bytes <-
              writeScalar
                bytes
                (baseOffset + rawShape.fixedI32OperandStride * jumpShape.targetTimeOperandIndex)
                .i32
                witness.jumpTargetTime
                "jumpTargetTime"
            writeScalar
              bytes
              (baseOffset + rawShape.fixedI32OperandStride * jumpShape.displacementOperandIndex)
              .i32
              witness.jumpDisplacement
              "jumpDisplacement"
        | .jumped _, _, _ =>
            .error ("profile has no fixed jump operand shape for " ++ shape.title)
        | _, _, _ => .ok bytes

private def writeFixedI32OperandValue
    (bytes : TouhouFormal.Bytes)
    (shape : TouhouFormal.ECL.HeaderShape)
    (operandIndex : Nat)
    (value : Int)
    (fieldName : String) : Except String TouhouFormal.Bytes :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.fixedI32OperandBaseOffset with
      | none => .error ("profile has no fixed-width i32 raw operand shape for " ++ shape.title)
      | some baseOffset =>
          writeScalar
            bytes
            (baseOffset + rawShape.fixedI32OperandStride * operandIndex)
            .i32
            value
            fieldName

private def requiredResolverInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (slot : Nat) : Nat :=
  match rawShape.fixedI32OperandBaseOffset with
  | none => rawShape.fixedPrefixBytes
  | some baseOffset =>
      baseOffset + rawShape.fixedI32OperandStride * (slot + 1)

private def RawIntResolverPath.matchesResolution
    (path : RawIntResolverPath)
    (resolution : TouhouFormal.ECL.RawIntOperandResolution) : Bool :=
  match path, resolution.kind with
  | .rawImmediate, .rawImmediate => true
  | .resolvedHost, .resolvedHost => true
  | .resolvedDefaultRaw, .resolvedDefaultRaw => true
  | _, _ => false

def rawIntResolverMaterialize
    (title : Title)
    (path : RawIntResolverPath)
    (witness : RawIntResolverWitness) : Except String RawIntResolverMaterialization := do
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredResolverInstructionBytes rawShape witness.slot
      let baseBytes <-
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := 0
            instrTime := 0
            opcode := 0
            nextOffset := Int.ofNat rawShape.fixedPrefixBytes
            instructionMask := 1
            operandMask := witness.operandMask
            activeMask := 1
            overrideMask := 0
            jumpTargetTime := 0
            jumpDisplacement := 0
            bufferSize := requiredBytes }
      let bytes <-
        writeFixedI32OperandValue
          baseBytes
          shape
          witness.slot
          witness.rawValue
          "resolverRawValue"
      let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix shape bytes 0)
      let rawValue <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            witness.slot)
      let resolution <-
        liftFaultToString
          (TouhouFormal.ECL.resolveIntRValue
            shape
            rawPrefix
            witness.slot
            rawValue
            witness.hostValue)
      .ok
        { bytes := bytes
          rawPrefix := rawPrefix
          rawValue := rawValue
          resolution := resolution
          matchesPath := path.matchesResolution resolution }

private def symbolicSubOffsetsOfCount (subCount : Nat) : Array Nat :=
  (List.replicate subCount 0).toArray

private def findCallRetShape
    (shape : TouhouFormal.ECL.HeaderShape) :
    Except String TouhouFormal.ECL.RawCallRetShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.callRetShape with
      | none => .error ("profile has no CALL/RET shape for " ++ shape.title)
      | some callRet => .ok callRet

private def rawCallRetWitnessBaseBytes
    (title : Title)
    (path : RawCallRetPath)
    (witness : RawCallRetWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredCallRetInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required CALL/RET bytes=" ++ toString requiredBytes)
      else
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := witness.currentTime
            instrTime := witness.instrTime
            opcode := witness.opcode
            nextOffset := witness.nextOffset
            instructionMask := witness.instructionMask
            operandMask := witness.operandMask
            activeMask := witness.activeMask
            overrideMask := witness.overrideMask
            jumpTargetTime := witness.jumpTargetTime
            jumpDisplacement := witness.jumpDisplacement
            bufferSize := witness.bufferSize }

private def rawCallRetWitnessBytes
    (title : Title)
    (path : RawCallRetPath)
    (witness : RawCallRetWitness) : Except String TouhouFormal.Bytes := do
  let shape := title.headerShape
  let bytes <- rawCallRetWitnessBaseBytes title path witness
  if path.isCall then
    let callRet <- findCallRetShape shape
    writeFixedI32OperandValue
      bytes
      shape
      callRet.subIdOperandIndex
      witness.subId
      "callSubId"
  else
    .ok bytes

private def runRawCallRetResult
    (title : Title)
    (path : RawCallRetPath)
    (witness : RawCallRetWitness)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String (Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) :=
  let shape := title.headerShape
  if path.isCall then
    .ok
      (TouhouFormal.ECL.rawCallStep
        shape
        witness.currentTime
        witness.activeMask
        witness.overrideMask
        8
        witness.bufferSize
        rawPrefix
        { subId := witness.subId
          stackDepth := witness.stackDepth
          stackDisabled := witness.stackDisabled
          subOffsets := symbolicSubOffsetsOfCount witness.subCount })
  else
    .ok
      (TouhouFormal.ECL.rawRetStep
        shape
        witness.currentTime
        witness.activeMask
        witness.overrideMask
        8
        witness.bufferSize
        rawPrefix
        { stackDepth := witness.stackDepth
          stackDisabled := witness.stackDisabled
          childContextSlot := witness.childContextSlot })

private def findConditionalCall
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawConditionalCallShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findConditionalCall? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed conditional CALL for " ++ shape.title)
      | some condCall => .ok condCall

private def rawConditionalCallWitnessBaseBytes
    (title : Title)
    (path : RawConditionalCallPath)
    (witness : RawConditionalCallWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredConditionalCallInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required conditional CALL bytes=" ++ toString requiredBytes)
      else
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := witness.currentTime
            instrTime := witness.instrTime
            opcode := witness.opcode
            nextOffset := witness.nextOffset
            instructionMask := witness.instructionMask
            operandMask := witness.operandMask
            activeMask := witness.activeMask
            overrideMask := witness.overrideMask
            jumpTargetTime := witness.jumpTargetTime
            jumpDisplacement := witness.jumpDisplacement
            bufferSize := witness.bufferSize }

private def rawConditionalCallWitnessBytes
    (title : Title)
    (path : RawConditionalCallPath)
    (witness : RawConditionalCallWitness) : Except String TouhouFormal.Bytes := do
  let shape := title.headerShape
  let condCall <- findConditionalCall shape witness.opcode
  let callRet <- findCallRetShape shape
  let bytes <- rawConditionalCallWitnessBaseBytes title path witness
  let bytes <-
    writeFixedI32OperandValue
      bytes
      shape
      callRet.subIdOperandIndex
      witness.subId
      "conditionalCallSubId"
  let bytes <-
    writeFixedI32OperandValue
      bytes
      shape
      condCall.lhsOperandIndex
      witness.lhsRaw
      "conditionalCallLhsRaw"
  writeFixedI32OperandValue
    bytes
    shape
    condCall.rhsOperandIndex
    witness.rhsRaw
    "conditionalCallRhsRaw"

private def runRawConditionalCallResult
    (title : Title)
    (_path : RawConditionalCallPath)
    (witness : RawConditionalCallWitness)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String (Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) :=
  let shape := title.headerShape
  .ok
    (TouhouFormal.ECL.rawConditionalCallStep
      shape
      witness.currentTime
      witness.activeMask
      witness.overrideMask
      8
      witness.bufferSize
      rawPrefix
      { subId := witness.subId
        stackDepth := witness.stackDepth
        stackDisabled := witness.stackDisabled
        subOffsets := symbolicSubOffsetsOfCount witness.subCount
        lhsRaw := witness.lhsRaw
        lhsHost := witness.lhsHost
        rhsRaw := witness.rhsRaw })

private def findIntBinaryOp
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawIntBinaryOpShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findIntBinaryOp? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed integer binary opcode for " ++ shape.title)
      | some op => .ok op

private def findBossIntRead
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawBossIntReadShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findBossIntRead? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed boss integer-read opcode for " ++ shape.title)
      | some read => .ok read

private def findBossFloatRead
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawBossFloatReadShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findBossFloatRead? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed boss float-read opcode for " ++ shape.title)
      | some read => .ok read

private def rawIntBinaryWitnessBaseBytes
    (title : Title)
    (path : RawIntBinaryPath)
    (witness : RawIntBinaryWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredIntBinaryInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required integer-binary bytes=" ++ toString requiredBytes)
      else
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := witness.currentTime
            instrTime := witness.instrTime
            opcode := witness.opcode
            nextOffset := witness.nextOffset
            instructionMask := witness.instructionMask
            operandMask := witness.operandMask
            activeMask := witness.activeMask
            overrideMask := witness.overrideMask
            jumpTargetTime := witness.jumpTargetTime
            jumpDisplacement := witness.jumpDisplacement
            bufferSize := witness.bufferSize }

private def rawIntBinaryWitnessBytes
    (title : Title)
    (path : RawIntBinaryPath)
    (witness : RawIntBinaryWitness) : Except String TouhouFormal.Bytes := do
  let shape := title.headerShape
  let op <- findIntBinaryOp shape witness.opcode
  let bytes <- rawIntBinaryWitnessBaseBytes title path witness
  let bytes <-
    writeFixedI32OperandValue
      bytes
      shape
      op.outputOperandIndex
      witness.outputRaw
      "intBinaryOutputRaw"
  let bytes <-
    if op.mode == .assign then
      writeFixedI32OperandValue
        bytes
        shape
        op.lhsOperandIndex
        witness.lhsRaw
        "intBinaryLhsRaw"
    else
      .ok bytes
  writeFixedI32OperandValue
    bytes
    shape
    op.rhsOperandIndex
    witness.rhsRaw
    "intBinaryRhsRaw"

private def decodeRawIntBinaryOperands
    (title : Title)
    (witness : RawIntBinaryWitness)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String
      (TouhouFormal.ECL.RawIntBinaryOpShape × TouhouFormal.ECL.RawIntBinaryOpOperands) := do
  let shape := title.headerShape
  let op <- findIntBinaryOp shape rawPrefix.opcode
  let outputRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        op.outputOperandIndex)
  let lhsRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        op.lhsOperandIndex)
  let rhsRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        op.rhsOperandIndex)
  .ok
    ( op
    , { outputRaw := outputRaw
        outputHostBefore := witness.outputHostBefore
        lhsRaw := lhsRaw
        rhsRaw := rhsRaw
        lhsHost := witness.lhsHost
        rhsHost := witness.rhsHost } )

private def runRawIntBinaryResult
    (title : Title)
    (witness : RawIntBinaryWitness)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix)
    (operands : TouhouFormal.ECL.RawIntBinaryOpOperands) :
    Except String (Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpOutcome) :=
  let shape := title.headerShape
  .ok
    (TouhouFormal.ECL.rawIntBinaryStep
      shape
      witness.currentTime
      witness.activeMask
      witness.overrideMask
        8
        witness.bufferSize
        rawPrefix
        operands)

private def rawBossIntReadWitnessBaseBytes
    (title : Title)
    (path : RawBossIntReadPath)
    (witness : RawBossIntReadWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredBossIntReadInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required boss-integer-read bytes=" ++ toString requiredBytes)
      else
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := witness.currentTime
            instrTime := witness.instrTime
            opcode := witness.opcode
            nextOffset := witness.nextOffset
            instructionMask := witness.instructionMask
            operandMask := witness.operandMask
            activeMask := witness.activeMask
            overrideMask := witness.overrideMask
            jumpTargetTime := witness.jumpTargetTime
            jumpDisplacement := witness.jumpDisplacement
            bufferSize := witness.bufferSize }

private def rawBossIntReadWitnessBytes
    (title : Title)
    (path : RawBossIntReadPath)
    (witness : RawBossIntReadWitness) : Except String TouhouFormal.Bytes := do
  let shape := title.headerShape
  let read <- findBossIntRead shape witness.opcode
  let bytes <- rawBossIntReadWitnessBaseBytes title path witness
  let bytes <-
    writeFixedI32OperandValue
      bytes
      shape
      read.outputOperandIndex
      witness.outputRaw
      "bossIntReadOutputRaw"
  let bytes <-
    writeFixedI32OperandValue
      bytes
      shape
      read.valueOperandIndex
      witness.valueRaw
      "bossIntReadValueRaw"
  writeFixedI32OperandValue
    bytes
    shape
    read.bossIndexOperandIndex
    witness.bossIndexRaw
    "bossIntReadBossIndexRaw"

private def decodeRawBossIntReadOperands
    (title : Title)
    (witness : RawBossIntReadWitness)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String
      (TouhouFormal.ECL.RawBossIntReadShape × TouhouFormal.ECL.RawBossIntReadOperands) := do
  let shape := title.headerShape
  let read <- findBossIntRead shape rawPrefix.opcode
  let outputRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        read.outputOperandIndex)
  let valueRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        read.valueOperandIndex)
  let bossIndexRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        read.bossIndexOperandIndex)
  .ok
    ( read
    , { outputRaw := outputRaw
        outputHostBefore := witness.outputHostBefore
        valueRaw := valueRaw
        valueHost := witness.valueHost
        bossIndexRaw := bossIndexRaw
        bossIndexHost := witness.bossIndexHost
        bossPresent := witness.bossPresent } )

private def runRawBossIntReadResult
    (title : Title)
    (witness : RawBossIntReadWitness)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix)
    (operands : TouhouFormal.ECL.RawBossIntReadOperands) :
    Except String (Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadOutcome) :=
  let shape := title.headerShape
  .ok
    (TouhouFormal.ECL.rawBossIntReadStep
      shape
      witness.currentTime
      witness.activeMask
      witness.overrideMask
      8
      witness.bufferSize
      rawPrefix
      operands)

private def rawBossFloatReadWitnessBaseBytes
    (title : Title)
    (path : RawBossFloatReadPath)
    (witness : RawBossFloatReadWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredBossFloatReadInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required boss-float-read bytes=" ++ toString requiredBytes)
      else
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := witness.currentTime
            instrTime := witness.instrTime
            opcode := witness.opcode
            nextOffset := witness.nextOffset
            instructionMask := witness.instructionMask
            operandMask := witness.operandMask
            activeMask := witness.activeMask
            overrideMask := witness.overrideMask
            jumpTargetTime := witness.jumpTargetTime
            jumpDisplacement := witness.jumpDisplacement
            bufferSize := witness.bufferSize }

private def rawBossFloatReadWitnessBytes
    (title : Title)
    (path : RawBossFloatReadPath)
    (witness : RawBossFloatReadWitness) : Except String TouhouFormal.Bytes := do
  let shape := title.headerShape
  let read <- findBossFloatRead shape witness.opcode
  let bytes <- rawBossFloatReadWitnessBaseBytes title path witness
  let bytes <-
    writeFixedI32OperandValue
      bytes
      shape
      read.outputOperandIndex
      witness.outputRaw
      "bossFloatReadOutputRaw"
  let bytes <-
    writeFixedI32OperandValue
      bytes
      shape
      read.valueOperandIndex
      witness.valueRaw
      "bossFloatReadValueRaw"
  writeFixedI32OperandValue
    bytes
    shape
    read.bossIndexOperandIndex
    witness.bossIndexRaw
    "bossFloatReadBossIndexRaw"

private def decodeRawBossFloatReadOperands
    (title : Title)
    (witness : RawBossFloatReadWitness)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String
      (TouhouFormal.ECL.RawBossFloatReadShape × TouhouFormal.ECL.RawBossFloatReadOperands) := do
  let shape := title.headerShape
  let read <- findBossFloatRead shape rawPrefix.opcode
  let outputRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        read.outputOperandIndex)
  let valueRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        read.valueOperandIndex)
  let bossIndexRaw <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        read.bossIndexOperandIndex)
  .ok
    ( read
    , { outputRaw := outputRaw
        outputHostBefore := witness.outputHostBefore
        valueRaw := valueRaw
        valueHost := witness.valueHost
        bossIndexRaw := bossIndexRaw
        bossIndexHost := witness.bossIndexHost
        bossPresent := witness.bossPresent } )

private def runRawBossFloatReadResult
    (title : Title)
    (witness : RawBossFloatReadWitness)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix)
    (operands : TouhouFormal.ECL.RawBossFloatReadOperands) :
    Except String (Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadOutcome) :=
  let shape := title.headerShape
  .ok
    (TouhouFormal.ECL.rawBossFloatReadStep
      shape
      witness.currentTime
      witness.activeMask
      witness.overrideMask
      8
      witness.bufferSize
      rawPrefix
      operands)

private def rawBodyWitnessBaseBytes
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredBodyInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required raw body bytes=" ++ toString requiredBytes)
      else
        rawStepWitnessBytes
          title
          (.advanced .inBounds)
          { currentTime := witness.currentTime
            instrTime := witness.instrTime
            opcode := witness.opcode
            nextOffset := witness.nextOffset
            instructionMask := witness.instructionMask
            operandMask := witness.operandMask
            activeMask := witness.activeMask
            overrideMask := witness.overrideMask
            jumpTargetTime := witness.jumpTargetTime
            jumpDisplacement := witness.jumpDisplacement
            bufferSize := witness.bufferSize }

private def findBodyDivisorHazard
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawIntDivisorHazard :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findIntDivisorHazard? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed integer divisor hazard for " ++ shape.title)
      | some hazard => .ok hazard

private def findIntConditionJump
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawIntConditionJumpShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findIntConditionJump? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed integer conditional jump for " ++ shape.title)
      | some condShape => .ok condShape

private def rawBodyWitnessBytes
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness) : Except String TouhouFormal.Bytes := do
  let shape := title.headerShape
  let bytes <- rawBodyWitnessBaseBytes title path witness
  match path with
  | .decJumpTaken _ | .decJumpNotTaken _ =>
      match shape.rawInstrShape with
      | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
      | some rawShape =>
          match rawShape.fixedDecJumpShape with
          | none => .error ("profile has no JUMPDEC shape for " ++ shape.title)
          | some decJumpShape => do
              let bytes <-
                writeFixedI32OperandValue
                  bytes
                  shape
                  decJumpShape.targetTimeOperandIndex
                  witness.jumpTargetTime
                  "decJumpTargetTime"
              let bytes <-
                writeFixedI32OperandValue
                  bytes
                  shape
                  decJumpShape.displacementOperandIndex
                  witness.jumpDisplacement
                  "decJumpDisplacement"
              writeFixedI32OperandValue
                bytes
                shape
                decJumpShape.counterOperandIndex
                witness.counterBefore
                "decJumpCounterBefore"
  | .intCondJumpTaken _ | .intCondJumpNotTaken _ =>
      let condShape <- findIntConditionJump shape witness.opcode
      let bytes <-
        match condShape.source with
        | .compareRegister => .ok bytes
        | .resolvedOperands => do
            let bytes <-
              writeFixedI32OperandValue
                bytes
                shape
                condShape.lhsOperandIndex
                witness.lhsRaw
                "intCondJumpLhsRaw"
            writeFixedI32OperandValue
              bytes
              shape
              condShape.rhsOperandIndex
              witness.rhsRaw
              "intCondJumpRhsRaw"
      let bytes <-
        writeFixedI32OperandValue
          bytes
          shape
          condShape.targetTimeOperandIndex
          witness.jumpTargetTime
          "intCondJumpTargetTime"
      writeFixedI32OperandValue
        bytes
        shape
        condShape.displacementOperandIndex
        witness.jumpDisplacement
        "intCondJumpDisplacement"
  | .intDivisorZero =>
      let hazard <- findBodyDivisorHazard shape witness.opcode
      writeFixedI32OperandValue
        bytes
        shape
        hazard.divisorOperandIndex
        witness.divisorValue
        "intDivisor"

private def decodeJumpForWitness
    (title : Title)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String (Option TouhouFormal.ECL.RawJumpOperands) :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.fixedJumpShape with
      | some jumpShape =>
          if rawPrefix.opcode == jumpShape.opcode then
            match liftFaultToString (TouhouFormal.ECL.decodeProfileFixedJumpOperands shape bytes rawPrefix) with
            | .ok jump => .ok (some jump)
            | .error message => .error message
          else
            .ok none
      | none => .ok none

private def CursorGoal.toCursorClass : CursorGoal -> TouhouFormal.CursorClass
  | .beforeBuffer => .beforeBuffer
  | .nonProgress => .nonProgress
  | .inBounds => .inBounds
  | .atOrPastEnd => .atOrPastEnd

private def RawStepPath.matchesOutcome
    (path : RawStepPath)
    (outcome : TouhouFormal.ECL.RawStepOutcome) : Bool :=
  match path, outcome.action, outcome.cursorClass with
  | .yielded, .yielded, _ => true
  | .skipped cursor, .skipped, some actual => actual == cursor.toCursorClass
  | .advanced cursor, .advanced, some actual => actual == cursor.toCursorClass
  | .jumped cursor, .jumped, some actual => actual == cursor.toCursorClass
  | .vmError, .vmError, _ => true
  | _, _, _ => false

private def RawBodyPath.matchesResult
    (path : RawBodyPath)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : Bool :=
  match path, result with
  | .intDivisorZero, .error faultValue => faultValue.kind == .divideByZero
  | .decJumpTaken cursor, .ok outcome =>
      outcome.action == .jumped &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | .decJumpNotTaken cursor, .ok outcome =>
      outcome.action == .advanced &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | .intCondJumpTaken cursor, .ok outcome =>
      outcome.action == .jumped &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | .intCondJumpNotTaken cursor, .ok outcome =>
      outcome.action == .advanced &&
        match outcome.cursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | _, _ => false

private def faultIndexBeforeZero (faultValue : TouhouFormal.Fault) : Bool :=
  match faultValue.index with
  | some index => decide (index < 0)
  | none => false

private def faultIndexAtOrPastBound (faultValue : TouhouFormal.Fault) : Bool :=
  match faultValue.index, faultValue.bound with
  | some index, some bound => decide (Int.ofNat bound <= index)
  | _, _ => false

private def RawCallRetPath.matchesResult
    (path : RawCallRetPath)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : Bool :=
  match path, result with
  | .callStackWriteBeforeStack, .error faultValue =>
      faultValue.kind == .outOfBoundsWrite &&
        faultValue.component == "EclRun.stack.call" &&
        faultIndexBeforeZero faultValue
  | .callStackWriteAtOrPastStack, .error faultValue =>
      faultValue.kind == .outOfBoundsWrite &&
        faultValue.component == "EclRun.stack.call" &&
        faultIndexAtOrPastBound faultValue
  | .callLookupFault, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclManager.CallEclSub"
  | .callEntered, .ok outcome =>
      outcome.action == .callEntered
  | .callNoOp, .ok outcome =>
      outcome.action == .callNoOp
  | .retStackReadBeforeStack, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.stack.ret" &&
        faultIndexBeforeZero faultValue
  | .retStackReadAtOrPastStack, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.stack.ret" &&
        faultIndexAtOrPastBound faultValue
  | .retRestored, .ok outcome =>
      outcome.action == .retRestored
  | .retExitChild, .ok outcome =>
      outcome.action == .retExitedChild
  | .retChildIndexBeforeArray, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.stack.retChild" &&
        faultIndexBeforeZero faultValue
  | .retChildIndexAtOrPastArray, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.stack.retChild" &&
        faultIndexAtOrPastBound faultValue
  | _, _ => false

private def RawConditionalCallPath.matchesResult
    (path : RawConditionalCallPath)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : Bool :=
  match path, result with
  | .conditionFalse cursor, .ok outcome =>
      outcome.action == .callConditionFalse &&
        match outcome.returnCursorClass with
        | some actual => actual == cursor.toCursorClass
        | none => false
  | .callStackWriteBeforeStack, .error faultValue =>
      faultValue.kind == .outOfBoundsWrite &&
        faultValue.component == "EclRun.stack.call" &&
        faultIndexBeforeZero faultValue
  | .callStackWriteAtOrPastStack, .error faultValue =>
      faultValue.kind == .outOfBoundsWrite &&
        faultValue.component == "EclRun.stack.call" &&
        faultIndexAtOrPastBound faultValue
  | .callLookupFault, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclManager.CallEclSub"
  | .callEntered, .ok outcome =>
      outcome.action == .callEntered
  | .callNoOp, .ok outcome =>
      outcome.action == .callNoOp
  | _, _ => false

private def preparedOutputKind?
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) :
    Option TouhouFormal.ECL.RawIntLValueResolutionKind :=
  match prepared with
  | .ok value => some value.output.kind
  | .error _ => none

private def preparedRhsPath?
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) :
    Option RawIntResolverPath :=
  match prepared with
  | .ok value =>
      match value.rhsResolution with
      | none => none
      | some rhs =>
          match rhs.kind with
          | .rawImmediate => some .rawImmediate
          | .resolvedHost => some .resolvedHost
          | .resolvedDefaultRaw => some .resolvedDefaultRaw
  | .error _ => none

private def RawIntBinaryPath.matchesMaterialization
    (path : RawIntBinaryPath)
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpOutcome) : Bool :=
  match path, result with
  | .outputRawCell, .ok outcome =>
      outcome.action == .advanced &&
        preparedOutputKind? prepared == some .rawOperandCell
  | .outputResolvedHost, .ok outcome =>
      outcome.action == .advanced &&
        preparedOutputKind? prepared == some .resolvedHost
  | .outputDefaultRawCell, .ok outcome =>
      outcome.action == .advanced &&
        preparedOutputKind? prepared == some .resolvedDefaultRawCell
  | .nonIntOutput, .ok outcome =>
      outcome.action == .nonIntOutput &&
        preparedOutputKind? prepared == some .nonIntOutput
  | .divisorZero rhsPath, .error faultValue =>
      faultValue.kind == .divideByZero &&
        (preparedOutputKind? prepared).isSome &&
        preparedRhsPath? prepared == some rhsPath
  | .divideOverflow rhsPath, .error faultValue =>
      faultValue.kind == .arithmeticOverflow &&
        (preparedOutputKind? prepared).isSome &&
        preparedRhsPath? prepared == some rhsPath
  | _, _ => false

private def preparedBossValuePath?
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) :
    Option RawIntResolverPath :=
  match prepared with
  | .ok value =>
      match value.valueResolution with
      | none => none
      | some resolution =>
          match resolution.kind with
          | .rawImmediate => some .rawImmediate
          | .resolvedHost => some .resolvedHost
          | .resolvedDefaultRaw => some .resolvedDefaultRaw
  | .error _ => none

private def RawBossIntReadPath.matchesMaterialization
    (path : RawBossIntReadPath)
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadOutcome) : Bool :=
  match path, result with
  | .valueRawNoBossRead, .ok outcome =>
      outcome.action == .valueRawNoBossRead &&
        preparedBossValuePath? prepared == some .rawImmediate
  | .bossIndexBeforeArray, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.bossIntRead.bosses" &&
        faultIndexBeforeZero faultValue
  | .bossIndexAtOrPastArray, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.bossIntRead.bosses" &&
        faultIndexAtOrPastBound faultValue
  | .bossNullDeref, .error faultValue =>
      faultValue.kind == .nullDereference &&
        faultValue.component == "EclRun.bossIntRead.bosses"
  | .bossValueResolvedHost, .ok outcome =>
      outcome.action == .advanced &&
        preparedBossValuePath? prepared == some .resolvedHost
  | .bossValueResolvedDefaultRaw, .ok outcome =>
      outcome.action == .advanced &&
        preparedBossValuePath? prepared == some .resolvedDefaultRaw
  | _, _ => false

private def preparedBossFloatValuePath?
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) :
    Option RawIntResolverPath :=
  match prepared with
  | .ok value =>
      match value.valueResolution with
      | none => none
      | some resolution =>
          match resolution.kind with
          | .rawImmediate => some .rawImmediate
          | .resolvedHost => some .resolvedHost
          | .resolvedDefaultRaw => some .resolvedDefaultRaw
  | .error _ => none

private def RawBossFloatReadPath.matchesMaterialization
    (path : RawBossFloatReadPath)
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadOutcome) : Bool :=
  match path, result with
  | .valueRawNoBossRead, .ok outcome =>
      outcome.action == .valueRawNoBossRead &&
        preparedBossFloatValuePath? prepared == some .rawImmediate
  | .bossIndexBeforeArray, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.bossFloatRead.bosses" &&
        faultIndexBeforeZero faultValue
  | .bossIndexAtOrPastArray, .error faultValue =>
      faultValue.kind == .outOfBoundsRead &&
        faultValue.component == "EclRun.bossFloatRead.bosses" &&
        faultIndexAtOrPastBound faultValue
  | .bossNullDeref, .error faultValue =>
      faultValue.kind == .nullDereference &&
        faultValue.component == "EclRun.bossFloatRead.bosses"
  | .bossNullGuardedSkip, .ok outcome =>
      outcome.action == .nullGuardedSkip
  | .bossValueResolvedHost, .ok outcome =>
      outcome.action == .advanced &&
        preparedBossFloatValuePath? prepared == some .resolvedHost
  | .bossValueResolvedDefaultRaw, .ok outcome =>
      outcome.action == .advanced &&
        preparedBossFloatValuePath? prepared == some .resolvedDefaultRaw
  | _, _ => false

def rawStepMaterialize
    (title : Title)
    (path : RawStepPath)
    (witness : RawStepWitness) : Except String RawStepMaterialization := do
  let shape := title.headerShape
  let bytes <- rawStepWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix shape bytes 0)
  let jump <- decodeJumpForWitness title bytes rawPrefix
  let outcome <-
    liftFaultToString
      (TouhouFormal.ECL.rawStep
        shape
        witness.currentTime
        witness.activeMask
        witness.overrideMask
        8
        witness.bufferSize
        rawPrefix
        jump)
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      jump := jump
      outcome := outcome
      matchesPath := path.matchesOutcome outcome }

private def runRawBodyResult
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String (Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) :=
  let shape := title.headerShape
  match path with
  | .decJumpTaken _ | .decJumpNotTaken _ =>
      match shape.rawInstrShape with
      | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
      | some rawShape =>
          match rawShape.fixedDecJumpShape with
          | none => .error ("profile has no JUMPDEC shape for " ++ shape.title)
          | some decJumpShape => do
              let targetTime <-
                liftFaultToString
                  (TouhouFormal.ECL.readFixedI32Operand
                    shape
                    bytes
                    rawPrefix
                    decJumpShape.targetTimeOperandIndex)
              let displacement <-
                liftFaultToString
                  (TouhouFormal.ECL.readFixedI32Operand
                    shape
                    bytes
                    rawPrefix
                    decJumpShape.displacementOperandIndex)
              let counterBefore <-
                liftFaultToString
                  (TouhouFormal.ECL.readFixedI32Operand
                    shape
                    bytes
                    rawPrefix
                    decJumpShape.counterOperandIndex)
              .ok
                (TouhouFormal.ECL.rawDecJumpStep
                  shape
                  witness.currentTime
                  witness.activeMask
                  witness.overrideMask
                  8
                  witness.bufferSize
                  rawPrefix
                  { targetTime := targetTime
                    displacement := displacement
                    counterBefore := counterBefore })
  | .intCondJumpTaken _ | .intCondJumpNotTaken _ => do
      let condShape <- findIntConditionJump shape rawPrefix.opcode
      let targetTime <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            condShape.targetTimeOperandIndex)
      let displacement <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            condShape.displacementOperandIndex)
      let lhsRaw <-
        match condShape.source with
        | .compareRegister => .ok witness.lhsRaw
        | .resolvedOperands =>
            liftFaultToString
              (TouhouFormal.ECL.readFixedI32Operand
                shape
                bytes
                rawPrefix
                condShape.lhsOperandIndex)
      let rhsRaw <-
        match condShape.source with
        | .compareRegister => .ok witness.rhsRaw
        | .resolvedOperands =>
            liftFaultToString
              (TouhouFormal.ECL.readFixedI32Operand
                shape
                bytes
                rawPrefix
                condShape.rhsOperandIndex)
      .ok
        (TouhouFormal.ECL.rawIntConditionJumpStep
          shape
          witness.currentTime
          witness.activeMask
          witness.overrideMask
          8
          witness.bufferSize
          rawPrefix
          { lhsRaw := lhsRaw
            rhsRaw := rhsRaw
            lhsHost := witness.lhsHost
            rhsHost := witness.rhsHost
            compareRegister := witness.compareRegister
            targetTime := targetTime
            displacement := displacement })
  | .intDivisorZero => do
      let hazard <- findBodyDivisorHazard shape rawPrefix.opcode
      let divisor <-
        liftFaultToString
          (TouhouFormal.ECL.readFixedI32Operand
            shape
            bytes
            rawPrefix
            hazard.divisorOperandIndex)
      .ok
        (TouhouFormal.ECL.rawIntDivisorStep
          shape
          witness.currentTime
          witness.activeMask
          witness.overrideMask
          8
          witness.bufferSize
          rawPrefix
          { divisor := divisor })

def rawBodyMaterialize
    (title : Title)
    (path : RawBodyPath)
    (witness : RawBodyWitness) : Except String RawBodyMaterialization := do
  let bytes <- rawBodyWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let result <- runRawBodyResult title path witness bytes rawPrefix
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      result := result
      matchesPath := path.matchesResult result }

def rawCallRetMaterialize
    (title : Title)
    (path : RawCallRetPath)
    (witness : RawCallRetWitness) : Except String RawCallRetMaterialization := do
  let bytes <- rawCallRetWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let result <- runRawCallRetResult title path witness rawPrefix
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      result := result
      matchesPath := path.matchesResult result }

def rawConditionalCallMaterialize
    (title : Title)
    (path : RawConditionalCallPath)
    (witness : RawConditionalCallWitness) : Except String RawConditionalCallMaterialization := do
  let bytes <- rawConditionalCallWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let result <- runRawConditionalCallResult title path witness rawPrefix
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      result := result
      matchesPath := path.matchesResult result }

def rawIntBinaryMaterialize
    (title : Title)
    (path : RawIntBinaryPath)
    (witness : RawIntBinaryWitness) : Except String RawIntBinaryMaterialization := do
  let bytes <- rawIntBinaryWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let (_, operands) <- decodeRawIntBinaryOperands title witness bytes rawPrefix
  let op <- findIntBinaryOp title.headerShape rawPrefix.opcode
  let prepared :=
    TouhouFormal.ECL.rawIntBinaryPrepare
      title.headerShape
      rawPrefix
      op
      operands
  let result <- runRawIntBinaryResult title witness rawPrefix operands
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      prepared := prepared
      result := result
      matchesPath := path.matchesMaterialization prepared result }

def rawBossIntReadMaterialize
    (title : Title)
    (path : RawBossIntReadPath)
    (witness : RawBossIntReadWitness) : Except String RawBossIntReadMaterialization := do
  let bytes <- rawBossIntReadWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let (read, operands) <- decodeRawBossIntReadOperands title witness bytes rawPrefix
  let prepared :=
    TouhouFormal.ECL.rawBossIntReadPrepare
      title.headerShape
      rawPrefix
      read
      operands
  let result <- runRawBossIntReadResult title witness rawPrefix operands
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      prepared := prepared
      result := result
      matchesPath := path.matchesMaterialization prepared result }

def rawBossFloatReadMaterialize
    (title : Title)
    (path : RawBossFloatReadPath)
    (witness : RawBossFloatReadWitness) : Except String RawBossFloatReadMaterialization := do
  let bytes <- rawBossFloatReadWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let (read, operands) <- decodeRawBossFloatReadOperands title witness bytes rawPrefix
  let prepared :=
    TouhouFormal.ECL.rawBossFloatReadPrepare
      title.headerShape
      rawPrefix
      read
      operands
  let result <- runRawBossFloatReadResult title witness rawPrefix operands
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      prepared := prepared
      result := result
      matchesPath := path.matchesMaterialization prepared result }

private def rawStepActionName : TouhouFormal.ECL.RawStepAction -> String
  | .yielded => "yielded"
  | .skipped => "skipped"
  | .advanced => "advanced"
  | .jumped => "jumped"
  | .vmError => "vm-error"

private def rawCallRetActionName : TouhouFormal.ECL.RawCallRetAction -> String
  | .yielded => "yielded"
  | .skipped => "skipped"
  | .callEntered => "call-entered"
  | .callNoOp => "call-no-op"
  | .callConditionFalse => "call-condition-false"
  | .retRestored => "ret-restored"
  | .retExitedChild => "ret-exited-child"

private def rawIntBinaryActionName : TouhouFormal.ECL.RawIntBinaryOpAction -> String
  | .yielded => "yielded"
  | .skipped => "skipped"
  | .advanced => "advanced"
  | .nonIntOutput => "non-int-output"
  | .vmError => "vm-error"

private def rawBossIntReadActionName : TouhouFormal.ECL.RawBossIntReadAction -> String
  | .yielded => "yielded"
  | .skipped => "skipped"
  | .advanced => "advanced"
  | .valueRawNoBossRead => "value-raw-no-boss-read"
  | .nonIntOutput => "non-int-output"
  | .vmError => "vm-error"

private def rawBossFloatReadActionName : TouhouFormal.ECL.RawBossFloatReadAction -> String
  | .yielded => "yielded"
  | .skipped => "skipped"
  | .advanced => "advanced"
  | .valueRawNoBossRead => "value-raw-no-boss-read"
  | .nullGuardedSkip => "null-guarded-skip"
  | .nonFloatOutput => "non-float-output"
  | .vmError => "vm-error"

private def optionIntText : Option Int -> String
  | none => "-"
  | some value => toString value

private def optionNatText : Option Nat -> String
  | none => "-"
  | some value => toString value

private def optionBoolText : Option Bool -> String
  | none => "-"
  | some value => toString value

private def optionCursorClassText : Option TouhouFormal.CursorClass -> String
  | none => "-"
  | some cursorClass => cursorClass.name

private def byteHex (byte : UInt8) : String :=
  hexDigit ((byte.toNat / 16) % 16) ++ hexDigit (byte.toNat % 16)

private def concatStrings : List String -> String
  | [] => ""
  | value :: rest => value ++ concatStrings rest

def bytesHex (bytes : TouhouFormal.Bytes) : String :=
  concatStrings (bytes.toList.map byteHex)

def RawStepMaterialization.report (materialization : RawStepMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "action=" ++ rawStepActionName materialization.outcome.action
    , "targetCursor=" ++ optionIntText materialization.outcome.targetCursor
    , "cursorClass=" ++ optionCursorClassText materialization.outcome.cursorClass
    , "targetTime=" ++ optionIntText materialization.outcome.targetTime
    , "matchesPath=" ++ toString materialization.matchesPath ]

private def bodyResultActionText
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : String :=
  match result with
  | .ok outcome => rawStepActionName outcome.action
  | .error faultValue => "fault:" ++ faultValue.kind.name

private def bodyResultTargetCursor
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.targetCursor
  | .error _ => none

private def bodyResultCursorClass
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) :
    Option TouhouFormal.CursorClass :=
  match result with
  | .ok outcome => outcome.cursorClass
  | .error _ => none

private def bodyResultTargetTime
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.targetTime
  | .error _ => none

private def bodyResultFaultKind
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.kind.name

private def bodyResultFaultDetail
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.detail

def RawBodyMaterialization.report (materialization : RawBodyMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "action=" ++ bodyResultActionText materialization.result
    , "targetCursor=" ++ optionIntText (bodyResultTargetCursor materialization.result)
    , "cursorClass=" ++ optionCursorClassText (bodyResultCursorClass materialization.result)
    , "targetTime=" ++ optionIntText (bodyResultTargetTime materialization.result)
    , "faultKind=" ++ bodyResultFaultKind materialization.result
    , "faultDetail=" ++ bodyResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

private def callRetResultActionText
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : String :=
  match result with
  | .ok outcome => rawCallRetActionName outcome.action
  | .error faultValue => "fault:" ++ faultValue.kind.name

private def callRetResultStackDepthAfter
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.stackDepthAfter
  | .error _ => none

private def callRetResultReturnCursor
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.returnCursor
  | .error _ => none

private def callRetResultReturnCursorClass
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) :
    Option TouhouFormal.CursorClass :=
  match result with
  | .ok outcome => outcome.returnCursorClass
  | .error _ => none

private def callRetResultTargetSubOffset
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : Option Nat :=
  match result with
  | .ok outcome => outcome.targetSubOffset
  | .error _ => none

private def callRetResultChildContextIndex
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.childContextIndex
  | .error _ => none

private def callRetResultFaultKind
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.kind.name

private def callRetResultFaultDetail
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallRetOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.detail

def RawCallRetMaterialization.report
    (materialization : RawCallRetMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "action=" ++ callRetResultActionText materialization.result
    , "stackDepthAfter=" ++ optionIntText (callRetResultStackDepthAfter materialization.result)
    , "returnCursor=" ++ optionIntText (callRetResultReturnCursor materialization.result)
    , "returnCursorClass=" ++ optionCursorClassText (callRetResultReturnCursorClass materialization.result)
    , "targetSubOffset=" ++ optionNatText (callRetResultTargetSubOffset materialization.result)
    , "childContextIndex=" ++ optionIntText (callRetResultChildContextIndex materialization.result)
    , "faultKind=" ++ callRetResultFaultKind materialization.result
    , "faultDetail=" ++ callRetResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

def RawConditionalCallMaterialization.report
    (materialization : RawConditionalCallMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "action=" ++ callRetResultActionText materialization.result
    , "stackDepthAfter=" ++ optionIntText (callRetResultStackDepthAfter materialization.result)
    , "returnCursor=" ++ optionIntText (callRetResultReturnCursor materialization.result)
    , "returnCursorClass=" ++ optionCursorClassText (callRetResultReturnCursorClass materialization.result)
    , "targetSubOffset=" ++ optionNatText (callRetResultTargetSubOffset materialization.result)
    , "childContextIndex=" ++ optionIntText (callRetResultChildContextIndex materialization.result)
    , "faultKind=" ++ callRetResultFaultKind materialization.result
    , "faultDetail=" ++ callRetResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

private def intBinaryResultActionText
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpOutcome) : String :=
  match result with
  | .ok outcome => rawIntBinaryActionName outcome.action
  | .error faultValue => "fault:" ++ faultValue.kind.name

private def intBinaryResultFaultKind
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.kind.name

private def intBinaryResultFaultDetail
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.detail

private def intBinaryResultValue
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.result
  | .error _ => none

private def preparedOutputKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value => value.output.kind.name
  | .error _ => "-"

private def preparedOutputKnownText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value => toString value.output.selectorKnown
  | .error _ => "-"

private def preparedOutputFlagText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value => toString value.output.flagEnabled
  | .error _ => "-"

private def preparedLhsKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value =>
      match value.lhsResolution with
      | none => "output-before"
      | some lhs => lhs.kind.name
  | .error _ => "-"

private def preparedRhsKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value =>
      match value.rhsResolution with
      | none => "-"
      | some rhs => rhs.kind.name
  | .error _ => "-"

private def preparedLhsValueText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value => optionIntText value.lhsValue
  | .error _ => "-"

private def preparedRhsValueText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value => optionIntText value.rhsValue
  | .error _ => "-"

private def preparedOpText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntBinaryOpPrepared) : String :=
  match prepared with
  | .ok value => value.op.kind.name ++ "/" ++ value.op.mode.name
  | .error _ => "-"

def RawIntBinaryMaterialization.report
    (materialization : RawIntBinaryMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "op=" ++ preparedOpText materialization.prepared
    , "outputKind=" ++ preparedOutputKindText materialization.prepared
    , "outputSelectorKnown=" ++ preparedOutputKnownText materialization.prepared
    , "outputFlagEnabled=" ++ preparedOutputFlagText materialization.prepared
    , "lhsKind=" ++ preparedLhsKindText materialization.prepared
    , "rhsKind=" ++ preparedRhsKindText materialization.prepared
    , "lhsValue=" ++ preparedLhsValueText materialization.prepared
    , "rhsValue=" ++ preparedRhsValueText materialization.prepared
    , "action=" ++ intBinaryResultActionText materialization.result
    , "result=" ++ optionIntText (intBinaryResultValue materialization.result)
    , "faultKind=" ++ intBinaryResultFaultKind materialization.result
    , "faultDetail=" ++ intBinaryResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

private def bossIntReadResultActionText
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadOutcome) : String :=
  match result with
  | .ok outcome => rawBossIntReadActionName outcome.action
  | .error faultValue => "fault:" ++ faultValue.kind.name

private def bossIntReadResultFaultKind
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.kind.name

private def bossIntReadResultFaultDetail
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.detail

private def bossIntReadResultValue
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.result
  | .error _ => none

private def bossIntReadPreparedOutputKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value => value.output.kind.name
  | .error _ => "-"

private def bossIntReadPreparedOutputKnownText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value => toString value.output.selectorKnown
  | .error _ => "-"

private def bossIntReadPreparedOutputFlagText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value => toString value.output.flagEnabled
  | .error _ => "-"

private def bossIntReadPreparedBossIndexKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value =>
      match value.bossIndexResolution with
      | none => "-"
      | some bossIndex => bossIndex.kind.name
  | .error _ => "-"

private def bossIntReadPreparedBossIndexValueText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value => optionIntText value.bossIndexValue
  | .error _ => "-"

private def bossIntReadPreparedValueKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value =>
      match value.valueResolution with
      | none => "-"
      | some readValue => readValue.kind.name
  | .error _ => "-"

private def bossIntReadPreparedValueText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value => optionIntText value.value
  | .error _ => "-"

private def bossIntReadPreparedBossPresentText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossIntReadPrepared) : String :=
  match prepared with
  | .ok value => optionBoolText value.bossPresent
  | .error _ => "-"

def RawBossIntReadMaterialization.report
    (materialization : RawBossIntReadMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "outputKind=" ++ bossIntReadPreparedOutputKindText materialization.prepared
    , "outputSelectorKnown=" ++ bossIntReadPreparedOutputKnownText materialization.prepared
    , "outputFlagEnabled=" ++ bossIntReadPreparedOutputFlagText materialization.prepared
    , "bossIndexKind=" ++ bossIntReadPreparedBossIndexKindText materialization.prepared
    , "bossIndexValue=" ++ bossIntReadPreparedBossIndexValueText materialization.prepared
    , "bossPresent=" ++ bossIntReadPreparedBossPresentText materialization.prepared
    , "valueKind=" ++ bossIntReadPreparedValueKindText materialization.prepared
    , "value=" ++ bossIntReadPreparedValueText materialization.prepared
    , "action=" ++ bossIntReadResultActionText materialization.result
    , "result=" ++ optionIntText (bossIntReadResultValue materialization.result)
    , "faultKind=" ++ bossIntReadResultFaultKind materialization.result
    , "faultDetail=" ++ bossIntReadResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

private def bossFloatReadResultActionText
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadOutcome) : String :=
  match result with
  | .ok outcome => rawBossFloatReadActionName outcome.action
  | .error faultValue => "fault:" ++ faultValue.kind.name

private def bossFloatReadResultFaultKind
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.kind.name

private def bossFloatReadResultFaultDetail
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadOutcome) : String :=
  match result with
  | .ok _ => "-"
  | .error faultValue => faultValue.detail

private def bossFloatReadResultValue
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.result
  | .error _ => none

private def bossFloatReadPreparedOutputKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value => value.output.kind.name
  | .error _ => "-"

private def bossFloatReadPreparedOutputKnownText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value => toString value.output.selectorKnown
  | .error _ => "-"

private def bossFloatReadPreparedOutputFlagText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value => toString value.output.flagEnabled
  | .error _ => "-"

private def bossFloatReadPreparedBossIndexKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value =>
      match value.bossIndexResolution with
      | none => "-"
      | some bossIndex => bossIndex.kind.name
  | .error _ => "-"

private def bossFloatReadPreparedBossIndexValueText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value => optionIntText value.bossIndexValue
  | .error _ => "-"

private def bossFloatReadPreparedValueKindText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value =>
      match value.valueResolution with
      | none => "-"
      | some readValue => readValue.kind.name
  | .error _ => "-"

private def bossFloatReadPreparedValueText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value => optionIntText value.value
  | .error _ => "-"

private def bossFloatReadPreparedBossPresentText
    (prepared : Except TouhouFormal.Fault TouhouFormal.ECL.RawBossFloatReadPrepared) : String :=
  match prepared with
  | .ok value => optionBoolText value.bossPresent
  | .error _ => "-"

def RawBossFloatReadMaterialization.report
    (materialization : RawBossFloatReadMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "outputKind=" ++ bossFloatReadPreparedOutputKindText materialization.prepared
    , "outputSelectorKnown=" ++ bossFloatReadPreparedOutputKnownText materialization.prepared
    , "outputFlagEnabled=" ++ bossFloatReadPreparedOutputFlagText materialization.prepared
    , "bossIndexKind=" ++ bossFloatReadPreparedBossIndexKindText materialization.prepared
    , "bossIndexValue=" ++ bossFloatReadPreparedBossIndexValueText materialization.prepared
    , "bossPresent=" ++ bossFloatReadPreparedBossPresentText materialization.prepared
    , "valueKind=" ++ bossFloatReadPreparedValueKindText materialization.prepared
    , "value=" ++ bossFloatReadPreparedValueText materialization.prepared
    , "action=" ++ bossFloatReadResultActionText materialization.result
    , "result=" ++ optionIntText (bossFloatReadResultValue materialization.result)
    , "faultKind=" ++ bossFloatReadResultFaultKind materialization.result
    , "faultDetail=" ++ bossFloatReadResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

def RawIntResolverMaterialization.report
    (materialization : RawIntResolverMaterialization) : String :=
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "rawValue=" ++ toString materialization.rawValue
    , "resolvedKind=" ++ materialization.resolution.kind.name
    , "resolvedValue=" ++ toString materialization.resolution.value
    , "selectorKnown=" ++ toString materialization.resolution.selectorKnown
    , "flagEnabled=" ++ toString materialization.resolution.flagEnabled
    , "hostValue=" ++ optionIntText materialization.resolution.hostValue
    , "matchesPath=" ++ toString materialization.matchesPath ]

private def writeOptionalVersion
    (bytes : TouhouFormal.Bytes)
    (shape : TouhouFormal.ECL.HeaderShape) : Except String TouhouFormal.Bytes :=
  match shape.expectedVersion, shape.versionOffset with
  | some version, some offset => writeScalar bytes offset .u32 (Int.ofNat version) "version"
  | none, none => .ok bytes
  | _, _ => .error ("profile has partial version field shape for " ++ shape.title)

def rawStepEclFileMaterialize
    (title : Title)
    (path : RawStepPath)
    (witness : RawStepWitness) : Except String RawStepEclFileMaterialization := do
  let materialization <- rawStepMaterialize title path witness
  let shape := title.headerShape
  let subOffset := shape.fixedHeaderBytes + 4
  let totalSize := subOffset + materialization.bytes.size
  let initial : TouhouFormal.Bytes := (TouhouFormal.zeroBytes totalSize).toArray
  let bytes <- writeOptionalVersion initial shape
  let bytes <- writeScalar bytes shape.subCountOffset .i16 1 "subCount"
  let bytes <- writeScalar bytes shape.timelineCountOffset .i16 0 "timelineCount"
  let bytes <- writeScalar bytes shape.fixedHeaderBytes .u32 (Int.ofNat subOffset) "subOffset[0]"
  let bytes <-
    match writeAt bytes subOffset materialization.bytes.toList with
    | some updated => .ok updated
    | none => .error "raw instruction bytes did not fit in generated ECL file"
  .ok
    { rawStep := materialization
      eclFile := bytes
      subOffset := subOffset }

def RawStepEclFileMaterialization.report
    (materialization : RawStepEclFileMaterialization) : String :=
  joinLines
    [ "rawInstructionSize=" ++ toString materialization.rawStep.bytes.size
    , "rawInstructionHex=" ++ bytesHex materialization.rawStep.bytes
    , "eclFileSize=" ++ toString materialization.eclFile.size
    , "eclFileHex=" ++ bytesHex materialization.eclFile
    , "subOffset=" ++ toString materialization.subOffset
    , "action=" ++ rawStepActionName materialization.rawStep.outcome.action
    , "targetCursor=" ++ optionIntText materialization.rawStep.outcome.targetCursor
    , "cursorClass=" ++ optionCursorClassText materialization.rawStep.outcome.cursorClass
    , "targetTime=" ++ optionIntText materialization.rawStep.outcome.targetTime
    , "matchesPath=" ++ toString materialization.rawStep.matchesPath ]

def th08ConcreteJumpBeforeBufferStep : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome :=
  TouhouFormal.ECL.rawStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    20
    { fileOffset := 0
      time := 0
      opcode := TouhouFormal.TH08.eclOpcodeJump
      nextOffset := 12
      difficultyMask := some 1
      operandMask := some 0 }
    (some { targetTime := 0, displacement := -1 })

def th08ConcreteOverrideSkipStep : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome :=
  TouhouFormal.ECL.rawStep
    TouhouFormal.TH08.headerShape
    0
    1
    2
    8
    64
    { fileOffset := 0
      time := 0
      opcode := TouhouFormal.TH08.eclOpcodeJump
      nextOffset := 12
      difficultyMask := some 1
      operandMask := some 0 }
    (some { targetTime := 0, displacement := -1 })

theorem th08_concrete_jump_before_buffer_step :
    th08ConcreteJumpBeforeBufferStep =
      .ok
        { action := .jumped
          targetCursor := some (-1)
          cursorClass := some .beforeBuffer
          targetTime := some 0 } := by
  rfl

theorem th08_concrete_override_skip_precedes_jump_effect :
    th08ConcreteOverrideSkipStep =
      .ok
        { action := .skipped
          targetCursor := some 12
          cursorClass := some .inBounds
          targetTime := none } := by
  rfl

end TouhouFormal.Search.Symbolic
