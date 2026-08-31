import TouhouFormal.Core.Evidence
import TouhouFormal.Core.Scalar

namespace TouhouFormal.ANM

inductive EntryChainPolicy where
  | singleEntry
  | nextOffsetUntilZero
deriving Repr, DecidableEq

def EntryChainPolicy.name : EntryChainPolicy -> String
  | .singleEntry => "single-entry"
  | .nextOffsetUntilZero => "nextOffset-until-zero"

structure EntryShape where
  title : String
  fixedEntryBytes : Nat
  numSpritesOffset : Nat
  numSpritesWidth : TouhouFormal.ScalarWidth
  numScriptsOffset : Nat
  numScriptsWidth : TouhouFormal.ScalarWidth
  nextOffsetOffset : Nat
  nextOffsetWidth : TouhouFormal.ScalarWidth
  embedsSpriteScriptTables : Bool
  chainPolicy : EntryChainPolicy
  evidence : List TouhouFormal.SourceRef := []
deriving Repr, DecidableEq

def EntryShape.summary (shape : EntryShape) : String :=
  shape.title ++
    " entryBytes=" ++ toString shape.fixedEntryBytes ++
    " nextOffset@=" ++ toString shape.nextOffsetOffset ++
    " chain=" ++ shape.chainPolicy.name

end TouhouFormal.ANM
