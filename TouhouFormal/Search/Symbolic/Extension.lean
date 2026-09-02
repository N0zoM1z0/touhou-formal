import TouhouFormal.ECL.Extension
import TouhouFormal.Search.Symbolic.Common

namespace TouhouFormal.Search.Symbolic

inductive RawExtensionPath where
  | callTableIndexBeforeArray
  | callTableIndexAtOrPastArray
  | callAdvanced
  | installNegativeClear
  | installTableIndexBeforeArray
  | installTableIndexAtOrPastArray
  | installAdvanced
deriving Repr, DecidableEq

def RawExtensionPath.name : RawExtensionPath -> String
  | .callTableIndexBeforeArray => "extension-call-index-before-array"
  | .callTableIndexAtOrPastArray => "extension-call-index-at-or-past-array"
  | .callAdvanced => "extension-call-advanced"
  | .installNegativeClear => "extension-install-negative-clear"
  | .installTableIndexBeforeArray => "extension-install-index-before-array"
  | .installTableIndexAtOrPastArray => "extension-install-index-at-or-past-array"
  | .installAdvanced => "extension-install-advanced"

def RawExtensionPath.parse? : String -> Option RawExtensionPath
  | "extension-call-index-before-array" => some .callTableIndexBeforeArray
  | "extension-call-index-at-or-past-array" => some .callTableIndexAtOrPastArray
  | "extension-call-advanced" => some .callAdvanced
  | "extension-install-negative-clear" => some .installNegativeClear
  | "extension-install-index-before-array" => some .installTableIndexBeforeArray
  | "extension-install-index-at-or-past-array" => some .installTableIndexAtOrPastArray
  | "extension-install-advanced" => some .installAdvanced
  | _ => none

def allRawExtensionPaths : List RawExtensionPath :=
  [ .callTableIndexBeforeArray
  , .callTableIndexAtOrPastArray
  , .callAdvanced
  , .installNegativeClear
  , .installTableIndexBeforeArray
  , .installTableIndexAtOrPastArray
  , .installAdvanced ]

def listRawExtensionPathsText : String :=
  joinLines (allRawExtensionPaths.map RawExtensionPath.name)

private def rawExtensionPathKind : RawExtensionPath -> TouhouFormal.ECL.RawExtensionOpKind
  | .callTableIndexBeforeArray
  | .callTableIndexAtOrPastArray
  | .callAdvanced => .callNow
  | .installNegativeClear
  | .installTableIndexBeforeArray
  | .installTableIndexAtOrPastArray
  | .installAdvanced => .installPerFrame

private def extensionKindMatches
    (actual expected : TouhouFormal.ECL.RawExtensionOpKind) : Bool :=
  match actual, expected with
  | .callNow, .callNow => true
  | .installPerFrame, .installPerFrame => true
  | _, _ => false

private def requiredExtensionInstructionBytes
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (_path : RawExtensionPath) : Nat :=
  match rawShape.fixedI32OperandBaseOffset with
  | none => rawShape.fixedPrefixBytes
  | some baseOffset =>
      if rawShape.extensionOps.isEmpty then
        rawShape.fixedPrefixBytes
      else
        baseOffset + rawShape.fixedI32OperandStride

private def extensionResolverAvailablePredicate
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (op : TouhouFormal.ECL.RawExtensionOpShape) : String :=
  match op.intPolicy, rawShape.intRValueResolver with
  | .intRValue, none => "false"
  | _, _ => "true"

private def rawExtensionIndexExpr
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (op : TouhouFormal.ECL.RawExtensionOpShape)
    (rawName hostName : String) : String :=
  match op.intPolicy with
  | .rawI32 => rawName
  | .intRValue =>
      match rawShape.intRValueResolver with
      | none => rawName
      | some resolver => rawIntResolvedValueExpr resolver 0 rawName hostName

private def extensionInBoundsPredicate (indexExpr : String) (entryCount : Nat) : String :=
  "(and (<= 0 " ++ indexExpr ++ ") (< " ++ indexExpr ++ " " ++
    toString entryCount ++ "))"

private def extensionCallCasePredicate
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (op : TouhouFormal.ECL.RawExtensionOpShape)
    (path : RawExtensionPath) : String :=
  let indexExpr := rawExtensionIndexExpr rawShape op "indexRaw0" "indexHost0"
  let resolverOk := extensionResolverAvailablePredicate rawShape op
  let pathPredicate :=
    match path with
    | .callTableIndexBeforeArray => "(< " ++ indexExpr ++ " 0)"
    | .callTableIndexAtOrPastArray =>
        "(<= " ++ toString op.tableEntryCount ++ " " ++ indexExpr ++ ")"
    | .callAdvanced => extensionInBoundsPredicate indexExpr op.tableEntryCount
    | _ => "false"
  "(and (= opcode " ++ toString op.opcode ++ ") " ++ resolverOk ++ " " ++
    pathPredicate ++ ")"

private def extensionInstallCasePredicate
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (op : TouhouFormal.ECL.RawExtensionOpShape)
    (path : RawExtensionPath) : String :=
  let guardExpr := rawExtensionIndexExpr rawShape op "indexRaw0" "indexHost0"
  let repeatedExpr := rawExtensionIndexExpr rawShape op "indexRaw1" "indexHost1"
  let tableExpr :=
    if op.repeatIndexReadOnInstall then repeatedExpr else guardExpr
  let resolverOk := extensionResolverAvailablePredicate rawShape op
  let guardNonnegative := "(<= 0 " ++ guardExpr ++ ")"
  let pathPredicate :=
    match path with
    | .installNegativeClear => "(< " ++ guardExpr ++ " 0)"
    | .installTableIndexBeforeArray =>
        "(and " ++ guardNonnegative ++ " (< " ++ tableExpr ++ " 0))"
    | .installTableIndexAtOrPastArray =>
        "(and " ++ guardNonnegative ++ " (<= " ++ toString op.tableEntryCount ++
          " " ++ tableExpr ++ "))"
    | .installAdvanced =>
        "(and " ++ guardNonnegative ++ " " ++
          extensionInBoundsPredicate tableExpr op.tableEntryCount ++ ")"
    | _ => "false"
  "(and (= opcode " ++ toString op.opcode ++ ") " ++ resolverOk ++ " " ++
    pathPredicate ++ ")"

private def extensionCasePredicate
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawExtensionPath)
    (op : TouhouFormal.ECL.RawExtensionOpShape) : String :=
  match op.kind with
  | .callNow => extensionCallCasePredicate rawShape op path
  | .installPerFrame => extensionInstallCasePredicate rawShape op path

private def extensionOpSetAssertion
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawExtensionPath) : String :=
  let matchingOps :=
    rawShape.extensionOps.filter (fun op =>
      extensionKindMatches op.kind (rawExtensionPathKind path))
  match matchingOps with
  | [] => "(assert false) ; profile has no source-backed extension opcode for this path"
  | [op] => "(assert " ++ extensionCasePredicate rawShape path op ++ ")"
  | ops =>
      "(assert (or " ++
        joinWith " " (ops.map fun op => extensionCasePredicate rawShape path op) ++
        "))"

private def rawExtensionPathConstraints
    (rawShape : TouhouFormal.ECL.RawInstrShape)
    (path : RawExtensionPath) : List String :=
  [ "(assert (= currentTime instrTime))"
  , "(assert difficultyPass)"
  , "(assert (= indexRaw1 indexRaw0)) ; repeated install reads reuse the same raw operand"
  , extensionOpSetAssertion rawShape path ]

private def rawExtensionValueTerms : String :=
  "(currentTime instrTime opcode nextOffset instructionMask operandMask activeMask overrideMask requiredDifficultyMask indexRaw0 indexHost0 indexRaw1 indexHost1 bufferSize difficultyPass)"

private def rawExtensionQueryWith
    (includeModel includeValues : Bool)
    (title : Title)
    (path : RawExtensionPath)
    (activeMask overrideMask : Nat) : String :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none =>
      joinLines
        [ "(set-logic ALL)"
        , "; symbolic raw ECL extension-dispatch query"
        , "; profile has no raw instruction shape"
        , "(assert false)"
        , "(check-sat)" ]
  | some rawShape =>
      let difficultyExpr :=
        match rawShape.difficultyMaskPolicy with
        | none => "true"
        | some policy => difficultyPassExpr policy
      let requiredBytes := requiredExtensionInstructionBytes rawShape path
      joinLines
        ([ "(set-logic ALL)"
         , "; Symbolic execution query generated from shared ECL extension-dispatch semantics."
         , "; Title: " ++ shape.title
         , "; Extension path: " ++ path.name
         , "(declare-const currentTime Int)"
         , "(declare-const instrTime Int)"
         , "(declare-const opcode Int)"
         , "(declare-const nextOffset Int)"
         , "(declare-const indexRaw0 Int)"
         , "(declare-const indexHost0 Int)"
         , "(declare-const indexRaw1 Int)"
         , "(declare-const indexHost1 Int)"
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
         , signedI32Range "indexRaw0"
         , signedI32Range "indexHost0"
         , signedI32Range "indexRaw1"
         , signedI32Range "indexHost1"
         , "(assert (and (<= 0 currentTime) (<= currentTime 1000000)))"
         , "(assert (= nextOffset " ++ toString requiredBytes ++ "))"
         , "(assert (= bufferSize " ++ toString requiredBytes ++ "))" ] ++
         operandMaskSmtLines rawShape ++
         rawExtensionPathConstraints rawShape path ++
         [ "(check-sat)" ] ++
         (if includeModel then ["(get-model)"] else []) ++
         (if includeValues then ["(get-value " ++ rawExtensionValueTerms ++ ")"] else []))

def rawExtensionQuery
    (title : Title)
    (path : RawExtensionPath)
    (activeMask overrideMask : Nat) : String :=
  rawExtensionQueryWith false false title path activeMask overrideMask

def rawExtensionValuesQuery
    (title : Title)
    (path : RawExtensionPath)
    (activeMask overrideMask : Nat) : String :=
  rawExtensionQueryWith false true title path activeMask overrideMask

structure RawExtensionWitness where
  currentTime : Int
  instrTime : Int
  opcode : Int
  nextOffset : Int
  instructionMask : Nat
  operandMask : Int
  activeMask : Nat
  overrideMask : Nat
  indexRaw0 : Int
  indexHost0 : Int
  indexRaw1 : Int
  indexHost1 : Int
  bufferSize : Nat
deriving Repr, DecidableEq

structure RawExtensionMaterialization where
  bytes : TouhouFormal.Bytes
  rawPrefix : TouhouFormal.ECL.RawInstrPrefix
  result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome
  matchesPath : Bool
deriving Repr

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

private def findExtensionOp
    (shape : TouhouFormal.ECL.HeaderShape)
    (opcode : Int) :
    Except String TouhouFormal.ECL.RawExtensionOpShape :=
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape =>
      match rawShape.findExtensionOp? opcode with
      | none =>
          .error
            ("opcode " ++ toString opcode ++
              " is not a source-backed extension opcode for " ++ shape.title)
      | some op => .ok op

private def rawExtensionWitnessBaseBytes
    (title : Title)
    (path : RawExtensionPath)
    (witness : RawExtensionWitness) : Except String TouhouFormal.Bytes :=
  let shape := title.headerShape
  match shape.rawInstrShape with
  | none => .error ("profile has no raw ECL instruction shape for " ++ shape.title)
  | some rawShape => do
      let requiredBytes := requiredExtensionInstructionBytes rawShape path
      if witness.bufferSize < requiredBytes then
        .error
          ("bufferSize=" ++ toString witness.bufferSize ++
            " is smaller than required extension-dispatch bytes=" ++ toString requiredBytes)
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
        writeOptionalScalar
          bytes
          "operandMask"
          rawShape.operandMaskOffset
          rawShape.operandMaskWidth
          witness.operandMask

private def rawExtensionWitnessBytes
    (title : Title)
    (path : RawExtensionPath)
    (witness : RawExtensionWitness) : Except String TouhouFormal.Bytes := do
  let bytes <- rawExtensionWitnessBaseBytes title path witness
  writeFixedI32OperandValue
    bytes
    title.headerShape
    0
    witness.indexRaw0
    "extensionIndexRaw0"

private def decodeRawExtensionOperands
    (title : Title)
    (witness : RawExtensionWitness)
    (bytes : TouhouFormal.Bytes)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix) :
    Except String
      (TouhouFormal.ECL.RawExtensionOpShape × TouhouFormal.ECL.RawExtensionOperands) := do
  let shape := title.headerShape
  let op <- findExtensionOp shape rawPrefix.opcode
  let indexRaw0 <-
    liftFaultToString
      (TouhouFormal.ECL.readFixedI32Operand
        shape
        bytes
        rawPrefix
        0)
  if witness.indexRaw1 != indexRaw0 then
    .error
      ("extension repeated raw read must reuse operand 0; indexRaw1=" ++
        toString witness.indexRaw1 ++ " decoded indexRaw0=" ++ toString indexRaw0)
  else
    .ok
      ( op
      , { inputs :=
            [ { rawValue := indexRaw0, hostValue := witness.indexHost0 }
            , { rawValue := indexRaw0, hostValue := witness.indexHost1 } ] } )

private def runRawExtensionResult
    (title : Title)
    (witness : RawExtensionWitness)
    (rawPrefix : TouhouFormal.ECL.RawInstrPrefix)
    (operands : TouhouFormal.ECL.RawExtensionOperands) :
    Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome :=
  TouhouFormal.ECL.rawExtensionStep
    title.headerShape
    witness.currentTime
    witness.activeMask
    witness.overrideMask
    8
    witness.bufferSize
    rawPrefix
    operands

private def faultIndexBeforeZero (faultValue : TouhouFormal.Fault) : Bool :=
  match faultValue.index with
  | some index => decide (index < 0)
  | none => false

private def faultIndexAtOrPastBound (faultValue : TouhouFormal.Fault) : Bool :=
  match faultValue.index, faultValue.bound with
  | some index, some bound => decide (Int.ofNat bound <= index)
  | _, _ => false

private def extensionEffect?
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) :
    Option TouhouFormal.ECL.RawExtensionEffect :=
  match result with
  | .ok outcome => outcome.effect
  | .error _ => none

private def extensionFault?
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .ok outcome => outcome.fault
  | .error faultValue => some faultValue

private def extensionTableFaultMatches
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome)
    (indexCheck : TouhouFormal.Fault -> Bool) : Bool :=
  match result with
  | .ok outcome =>
      outcome.action == .hostFault &&
        match outcome.fault with
        | some faultValue =>
            faultValue.kind == .outOfBoundsRead &&
              faultValue.component == "EclRun.extension.callbackTable" &&
              indexCheck faultValue
        | none => false
  | .error _ => false

private def RawExtensionPath.matchesResult
    (path : RawExtensionPath)
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) : Bool :=
  match path, result with
  | .callTableIndexBeforeArray, _ =>
      extensionTableFaultMatches result faultIndexBeforeZero
  | .callTableIndexAtOrPastArray, _ =>
      extensionTableFaultMatches result faultIndexAtOrPastBound
  | .callAdvanced, .ok outcome =>
      outcome.action == .advanced &&
        match outcome.effect with
        | some effect => effect.calledNow
        | none => false
  | .installNegativeClear, .ok outcome =>
      outcome.action == .advanced &&
        match outcome.effect with
        | some effect => effect.callbackCleared
        | none => false
  | .installTableIndexBeforeArray, _ =>
      extensionTableFaultMatches result faultIndexBeforeZero
  | .installTableIndexAtOrPastArray, _ =>
      extensionTableFaultMatches result faultIndexAtOrPastBound
  | .installAdvanced, .ok outcome =>
      outcome.action == .advanced &&
        match outcome.effect with
        | some effect => effect.callbackInstalled && effect.perFrameInstructionStored
        | none => false
  | _, _ => false

def rawExtensionMaterialize
    (title : Title)
    (path : RawExtensionPath)
    (witness : RawExtensionWitness) : Except String RawExtensionMaterialization := do
  let bytes <- rawExtensionWitnessBytes title path witness
  let rawPrefix <- liftFaultToString (TouhouFormal.ECL.decodeRawInstrPrefix title.headerShape bytes 0)
  let (_op, operands) <- decodeRawExtensionOperands title witness bytes rawPrefix
  let result := runRawExtensionResult title witness rawPrefix operands
  .ok
    { bytes := bytes
      rawPrefix := rawPrefix
      result := result
      matchesPath := path.matchesResult result }

private def rawExtensionActionName : TouhouFormal.ECL.RawExtensionAction -> String
  | .yielded => "yielded"
  | .skipped => "skipped"
  | .advanced => "advanced"
  | .hostFault => "host-fault"
  | .vmError => "vm-error"

private def optionIntText : Option Int -> String
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

private def bytesHex (bytes : TouhouFormal.Bytes) : String :=
  concatStrings (bytes.toList.map byteHex)

private def extensionResultActionText
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) : String :=
  match result with
  | .ok outcome => rawExtensionActionName outcome.action
  | .error faultValue => "fault:" ++ faultValue.kind.name

private def extensionResultFaultKind
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) : String :=
  match extensionFault? result with
  | none => "-"
  | some faultValue => faultValue.kind.name

private def extensionResultFaultDetail
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) : String :=
  match extensionFault? result with
  | none => "-"
  | some faultValue => faultValue.detail

private def extensionResultTargetCursor
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) : Option Int :=
  match result with
  | .ok outcome => outcome.targetCursor
  | .error _ => none

private def extensionResultCursorClass
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawExtensionOutcome) :
    Option TouhouFormal.CursorClass :=
  match result with
  | .ok outcome => outcome.cursorClass
  | .error _ => none

private def effectGuardIndex
    (effect? : Option TouhouFormal.ECL.RawExtensionEffect) : Option Int :=
  match effect? with
  | none => none
  | some effect => effect.guardIndex

private def effectTableIndex
    (effect? : Option TouhouFormal.ECL.RawExtensionEffect) : Option Int :=
  match effect? with
  | none => none
  | some effect => effect.tableIndex

private def effectCalledNow
    (effect? : Option TouhouFormal.ECL.RawExtensionEffect) : Option Bool :=
  match effect? with
  | none => none
  | some effect => some effect.calledNow

private def effectCallbackInstalled
    (effect? : Option TouhouFormal.ECL.RawExtensionEffect) : Option Bool :=
  match effect? with
  | none => none
  | some effect => some effect.callbackInstalled

private def effectPerFrameInstructionStored
    (effect? : Option TouhouFormal.ECL.RawExtensionEffect) : Option Bool :=
  match effect? with
  | none => none
  | some effect => some effect.perFrameInstructionStored

private def effectCallbackCleared
    (effect? : Option TouhouFormal.ECL.RawExtensionEffect) : Option Bool :=
  match effect? with
  | none => none
  | some effect => some effect.callbackCleared

def RawExtensionMaterialization.report
    (materialization : RawExtensionMaterialization) : String :=
  let effect? := extensionEffect? materialization.result
  joinLines
    [ "size=" ++ toString materialization.bytes.size
    , "hex=" ++ bytesHex materialization.bytes
    , "decodedTime=" ++ toString materialization.rawPrefix.time
    , "decodedOpcode=" ++ toString materialization.rawPrefix.opcode
    , "decodedNextOffset=" ++ toString materialization.rawPrefix.nextOffset
    , "decodedDifficultyMask=" ++ optionIntText materialization.rawPrefix.difficultyMask
    , "decodedOperandMask=" ++ optionIntText materialization.rawPrefix.operandMask
    , "action=" ++ extensionResultActionText materialization.result
    , "targetCursor=" ++ optionIntText (extensionResultTargetCursor materialization.result)
    , "cursorClass=" ++ optionCursorClassText (extensionResultCursorClass materialization.result)
    , "guardIndex=" ++ optionIntText (effectGuardIndex effect?)
    , "tableIndex=" ++ optionIntText (effectTableIndex effect?)
    , "calledNow=" ++ optionBoolText (effectCalledNow effect?)
    , "callbackInstalled=" ++ optionBoolText (effectCallbackInstalled effect?)
    , "perFrameInstructionStored=" ++ optionBoolText (effectPerFrameInstructionStored effect?)
    , "callbackCleared=" ++ optionBoolText (effectCallbackCleared effect?)
    , "faultKind=" ++ extensionResultFaultKind materialization.result
    , "faultDetail=" ++ extensionResultFaultDetail materialization.result
    , "matchesPath=" ++ toString materialization.matchesPath ]

end TouhouFormal.Search.Symbolic
