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
