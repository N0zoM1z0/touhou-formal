import TouhouFormal

open TouhouFormal

private def describeFaultLookup : Except Fault (Option Nat) -> String
  | .ok (some offset) => "ok offset=" ++ toString offset
  | .ok none => "ok no-op"
  | .error faultValue => faultValue.describe

private def describeLoadLookup : Except TouhouFormal.ECL.LoadError (Option Nat) -> String
  | .ok (some offset) => "ok offset=" ++ toString offset
  | .ok none => "ok no-op"
  | .error err => err.describe

private def describeLoadedHeader : Except TouhouFormal.ECL.LoadError TouhouFormal.ECL.LoadedHeader -> String
  | .ok header =>
      "ok subCount=" ++ toString header.subCount ++
        " timelineOffsets=" ++ toString header.timelineOffsets.size ++
        " subOffsets=" ++ toString header.subOffsets.size
  | .error err => err.describe

def main : IO Unit := do
  let result := runBounded TouhouFormal.TH06.stepTimeline 1 TouhouFormal.TH06.arg0_256State
  IO.println "TH06 timeline/subTable counterexample seed"
  IO.println s!"subCount={TouhouFormal.TH06.oneSubFile.subCount}, timeline opcode={TouhouFormal.TH06.timelineArg0_256.opcode}, arg0={TouhouFormal.TH06.timelineArg0_256.arg0}"
  match result with
  | .faulted fuelRemaining fault =>
      IO.println s!"counterexample: {fault.describe}"
      IO.println s!"fuelRemaining={fuelRemaining}"
  | other =>
      IO.println s!"unexpected-result: {reprStr other}"
  IO.println ""
  IO.println "Shared raw-byte path"
  IO.println s!"TH06 raw bytes -> loader -> timeline prefix -> lookup: {describeLoadLookup TouhouFormal.TH06.rawOneSubArg0256Lookup}"
  IO.println ""
  IO.println "Cross-title lookup policy controls"
  IO.println s!"TH07 negative subId: {describeFaultLookup (TouhouFormal.ECL.lookupSubOffset TouhouFormal.TH07.headerShape TouhouFormal.TH07.oneSubOffsets (-1))}"
  IO.println s!"TH08 negative subId: {describeFaultLookup (TouhouFormal.ECL.lookupSubOffset TouhouFormal.TH08.headerShape TouhouFormal.TH08.oneSubOffsets (-1))}"
  IO.println ""
  IO.println "Bounded loader controls"
  IO.println s!"TH06 zero-count 7 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH06.headerShape (TouhouFormal.Search.Bounded.zeroBytesOfLength 7))}"
  IO.println s!"TH06 zero-count 8 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH06.headerShape TouhouFormal.Search.Bounded.th06ZeroCountMinimalBytes)}"
  IO.println s!"TH08 versioned 71 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH08.headerShape TouhouFormal.Search.Bounded.th08AlmostMinimalBytes)}"
  IO.println s!"TH08 versioned 72 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH08.headerShape TouhouFormal.Search.Bounded.th08ZeroCountMinimalBytes)}"
