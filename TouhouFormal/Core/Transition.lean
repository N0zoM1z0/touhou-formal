import TouhouFormal.Core.Fault

namespace TouhouFormal

inductive StepResult (σ : Type u) where
  | next (state : σ)
  | yield (state : σ)
  | halt (state : σ)
  | fault (fault : Fault)
deriving Repr, DecidableEq

inductive RunResult (σ : Type u) where
  | completed (state : σ)
  | yielded (state : σ)
  | faulted (fuelRemaining : Nat) (fault : Fault)
  | boundExhausted (state : σ)
deriving Repr, DecidableEq

def runBounded {σ : Type u} (step : σ -> StepResult σ) : Nat -> σ -> RunResult σ
  | 0, state => .boundExhausted state
  | fuel + 1, state =>
      match step state with
      | .next nextState => runBounded step fuel nextState
      | .yield nextState => .yielded nextState
      | .halt nextState => .completed nextState
      | .fault fault => .faulted fuel fault

@[simp]
theorem runBounded_zero {σ : Type u} (step : σ -> StepResult σ) (state : σ) :
    runBounded step 0 state = .boundExhausted state := rfl

@[simp]
theorem runBounded_one_fault
    {σ : Type u}
    (step : σ -> StepResult σ)
    (state : σ)
    (fault : Fault)
    (h : step state = .fault fault) :
    runBounded step 1 state = .faulted 0 fault := by
  simp [runBounded, h]

end TouhouFormal
