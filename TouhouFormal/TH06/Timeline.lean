import TouhouFormal.Core.Transition
import TouhouFormal.TH06.Wire

namespace TouhouFormal.TH06

structure EclFile where
  subOffsets : Array Nat
deriving Repr, DecidableEq

def EclFile.subCount (file : EclFile) : Nat :=
  file.subOffsets.size

structure EnemyContext where
  currentInstr : Option Nat := none
  subId : Int := -1
  time : Nat := 0
deriving Repr, DecidableEq

def defaultContext : EnemyContext := {}

structure TimelineInstr where
  time : Int
  arg0 : Int
  opcode : Int
  size : Nat := timelineInstrFixedSize
deriving Repr, DecidableEq

structure TimelineState where
  ecl : EclFile
  instrs : Array TimelineInstr
  pc : Nat
  currentTime : Int
  bossPresent : Bool := false
  spawnedEnemies : Nat := 0
deriving Repr, DecidableEq

def subTableOobFault (subId : Int) (subCount : Nat) : Fault :=
  Fault.outOfBoundsRead
    title
    "EclManager.CallEclSub"
    "source reads this->subTable[subId] without validating the timeline-provided sub id"
    subId
    subCount

def isSubIdInBounds (file : EclFile) (subId : Int) : Bool :=
  if subId < 0 then
    false
  else
    subId.toNat < file.subCount

def callEclSub (file : EclFile) (ctx : EnemyContext) (subId : Int) : Except Fault EnemyContext :=
  if subId < 0 then
    .error (subTableOobFault subId file.subCount)
  else
    match file.subOffsets[subId.toNat]? with
    | some offset => .ok { ctx with currentInstr := some offset, subId := subId, time := 0 }
    | none => .error (subTableOobFault subId file.subCount)

def advanceTimeline (state : TimelineState) : TimelineState :=
  { state with pc := state.pc + 1 }

def spawnFromTimeline (state : TimelineState) (subId : Int) : StepResult TimelineState :=
  match callEclSub state.ecl defaultContext subId with
  | .ok _ =>
      .next { state with pc := state.pc + 1, spawnedEnemies := state.spawnedEnemies + 1 }
  | .error fault => .fault fault

def stepTimeline (state : TimelineState) : StepResult TimelineState :=
  match state.instrs[state.pc]? with
  | none => .halt state
  | some instr =>
      if instr.time < 0 then
        .halt state
      else if state.currentTime = instr.time then
        if isTimelineSpawnOpcode instr.opcode && !state.bossPresent then
          spawnFromTimeline state instr.arg0
        else
          .next (advanceTimeline state)
      else if state.currentTime < instr.time then
        .yield state
      else
        .next (advanceTimeline state)

def oneSubFile : EclFile :=
  { subOffsets := #[0x10] }

def timelineArg0_256 : TimelineInstr :=
  { time := 441, arg0 := 256, opcode := 0 }

def arg0_256State : TimelineState :=
  { ecl := oneSubFile
    instrs := #[timelineArg0_256]
    pc := 0
    currentTime := 441
    bossPresent := false }

def arg0_256Fault : Fault :=
  subTableOobFault 256 oneSubFile.subCount

theorem callEclSub_arg0_256_faults :
    callEclSub oneSubFile defaultContext 256 = .error arg0_256Fault := by
  rfl

theorem arg0_256_counterexample :
    runBounded stepTimeline 1 arg0_256State = .faulted 0 arg0_256Fault := by
  native_decide

def timelineArg0_0 : TimelineInstr :=
  { time := 441, arg0 := 0, opcode := 0 }

def arg0_0State : TimelineState :=
  { ecl := oneSubFile
    instrs := #[timelineArg0_0]
    pc := 0
    currentTime := 441
    bossPresent := false }

def arg0_0Advanced : TimelineState :=
  { arg0_0State with pc := 1, spawnedEnemies := 1 }

theorem arg0_0_advances :
    runBounded stepTimeline 1 arg0_0State = .boundExhausted arg0_0Advanced := by
  native_decide

end TouhouFormal.TH06
