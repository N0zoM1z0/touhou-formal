import TouhouFormal

open TouhouFormal
open TouhouFormal.TH06

def main : IO Unit := do
  let result := runBounded stepTimeline 1 arg0_256State
  IO.println "TH06 timeline/subTable counterexample seed"
  IO.println s!"subCount={oneSubFile.subCount}, timeline opcode={timelineArg0_256.opcode}, arg0={timelineArg0_256.arg0}"
  match result with
  | .faulted fuelRemaining fault =>
      IO.println s!"counterexample: {fault.describe}"
      IO.println s!"fuelRemaining={fuelRemaining}"
  | other =>
      IO.println s!"unexpected-result: {reprStr other}"
