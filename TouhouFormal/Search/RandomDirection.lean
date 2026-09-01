import TouhouFormal.ECL.RandomTimedMovement
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.RandomDirection

open TouhouFormal.ECL

def f32ZeroBits : Int := 0
def f32OneBits : Int := 1065353216
def f32TwoBits : Int := 1073741824
def f32NegativeOneBits : Int := 3212836864
def f32ThreeHundredBits : Int := 1133903872
def f32QuietNaNBits : Int := 2143289344
def th07FloatLValueBits : Int := 1176260608
def th08FloatLValueBits : Int := 1176272896

def randomDirectionOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.randomDirectionOps.length

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawRandomDirectionOutcome) :
    Option RawRandomDirectionPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawRandomDirectionOutcome) :
    Option RawRandomDirectionEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def compositeOutcomePrepared?
    (result : Except TouhouFormal.Fault RawRandomTimedMovementOutcome) :
    Option RawRandomTimedMovementPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def th06RandomPrefix (opcode : Int) : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := opcode
    nextOffset := 24
    difficultyMask := some 1
    operandMask := none }

def th06RandomOutcome : Except TouhouFormal.Fault RawRandomDirectionOutcome :=
  rawRandomDirectionStep
    TouhouFormal.TH06.headerShape 0 1 0 8 64
    (th06RandomPrefix TouhouFormal.TH06.eclOpcodeMoveRandom)
    { slots :=
        [ { rawValue := f32ZeroBits },
          { rawValue := f32TwoBits } ]
      hostResults := { candidateAngleBits := f32OneBits } }

def rightBoundaryHostResults : RawRandomDirectionHostResults :=
  { candidateAngleBits := f32OneBits
    leftCandidateAngleBits := f32OneBits
    rightCandidateAngleBits := f32OneBits
    lowerXPlusMarginBits := f32ZeroBits
    upperXMinusMarginBits := f32OneBits
    lowerYPlusMarginBits := f32ZeroBits
    upperYMinusMarginBits := f32TwoBits
    rightPositiveCandidateResultBits := 777
    rightPositiveCurrentResultBits := 888 }

def th06BoundedOutcome :
    Except TouhouFormal.Fault RawRandomDirectionOutcome :=
  rawRandomDirectionStep
    TouhouFormal.TH06.headerShape 0 1 0 8 64
    (th06RandomPrefix TouhouFormal.TH06.eclOpcodeMoveRandomInBounds)
    { slots :=
        [ { rawValue := f32ZeroBits },
          { rawValue := f32TwoBits } ]
      runtime :=
        { enemyXBits := f32TwoBits
          enemyYBits := f32OneBits
          currentEnemyAngleBits := f32TwoBits }
      hostResults := rightBoundaryHostResults }

def th07GetExitPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeGetExitAngle
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07GetExitOutcome :
    Except TouhouFormal.Fault RawRandomDirectionOutcome :=
  rawRandomDirectionStep
    TouhouFormal.TH07.headerShape 0 1 0 8 64 th07GetExitPrefix
    { slots := [{ rawValue := th07FloatLValueBits, hostValue := 123 }]
      runtime :=
        { playerXBits := f32ZeroBits
          enemyXBits := f32TwoBits
          enemyYBits := f32OneBits
          currentEnemyAngleBits := f32TwoBits }
      hostResults := rightBoundaryHostResults }

def th07ArenaExitPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeRandomExitAngle
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07ArenaExitOutcome :
    Except TouhouFormal.Fault RawRandomDirectionOutcome :=
  rawRandomDirectionStep
    TouhouFormal.TH07.headerShape 0 1 0 8 64 th07ArenaExitPrefix
    { slots := [{ rawValue := th07FloatLValueBits, hostValue := 123 }]
      runtime :=
        { playerXBits := f32ThreeHundredBits
          enemyXBits := f32ThreeHundredBits }
      hostResults :=
        { leftCandidateAngleBits := 333
          rightCandidateAngleBits := 444 } }

def th08BoundaryPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeMoveBoundaryAwareTimed
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 0 }

def th08BoundaryDirectionOperands : RawRandomDirectionOperands :=
  { runtime :=
      { playerXBits := f32ZeroBits
        enemyXBits := f32TwoBits
        enemyYBits := f32OneBits
        currentEnemyAngleBits := f32TwoBits }
    hostResults := rightBoundaryHostResults }

def th08BoundaryOutcome :
    Except TouhouFormal.Fault RawRandomDirectionOutcome :=
  rawRandomDirectionStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08BoundaryPrefix
    th08BoundaryDirectionOperands

def th08BoundaryCompositeOutcome :
    Except TouhouFormal.Fault RawRandomTimedMovementOutcome :=
  rawRandomTimedMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08BoundaryPrefix
    { direction := th08BoundaryDirectionOperands
      movement :=
        { slots :=
            [ { rawValue := 0 },
              { rawValue := 0 },
              { rawValue := f32OneBits } ]
          floatResults :=
            { effectiveDirectionAngleBits := 999
              playerRelativeAngleBits := 0
              interpolationDelta := { x := 0, y := 0, z := 0 } } } }

def th08BiasedPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeMoveRandomBiasedTimed
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 0 }

def th08BiasedVerticalOutcome :
    Except TouhouFormal.Fault RawRandomDirectionOutcome :=
  rawRandomDirectionStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08BiasedPrefix
    { runtime := { enemyYBits := f32ZeroBits }
      hostResults :=
        { candidateAngleBits := f32NegativeOneBits
          lowerYPlusMarginBits := f32OneBits
          upperYMinusMarginBits := f32TwoBits } }

theorem th06_random_direction_profile_count :
    randomDirectionOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_random_direction_profile_count :
    randomDirectionOpcodeCount TouhouFormal.TH07.headerShape = 2 := by
  rfl

theorem th08_random_direction_profile_count :
    randomDirectionOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem ordered_ge_rejects_nan_instead_of_treating_not_less_as_true :
    TouhouFormal.f32GreaterOrEqualBits f32QuietNaNBits f32ZeroBits = false := by
  rfl

theorem th06_random_range_reads_raw_words_and_writes_enemy_angle :
    (outcomePrepared? th06RandomOutcome).map
      (fun prepared =>
        (prepared.reads.map (fun read => read.resolution.bits),
          prepared.candidateBranch,
          prepared.effect.enemyAngleWrite)) =
      some ([f32ZeroBits, f32TwoBits], .operandRange, some f32OneBits) := by
  rfl

theorem th06_right_reflection_uses_the_generated_candidate :
    (outcomePrepared? th06BoundedOutcome).map
      (fun prepared =>
        (prepared.finalAngleBits,
          prepared.reflections.map
            (fun reflection =>
              (reflection.kind, reflection.formulaSourceBits)))) =
      some (777, [(.rightPositiveCandidate, f32OneBits)]) := by
  rfl

theorem th07_right_reflection_uses_the_old_enemy_angle :
    (outcomePrepared? th07GetExitOutcome).map
      (fun prepared =>
        (prepared.finalAngleBits,
          prepared.reflections.map
            (fun reflection =>
              (reflection.kind, reflection.formulaSourceBits)),
          prepared.effect.floatLValueWrite)) =
      some
        (888, [(.rightPositiveCurrent, f32TwoBits)], some 888) := by
  rfl

theorem th07_far_right_arena_forces_the_left_exit_branch :
    (outcomePrepared? th07ArenaExitOutcome).map
      (fun prepared =>
        (prepared.candidateBranch, prepared.finalAngleBits)) =
      some (.arenaLeft, 333) := by
  rfl

theorem th08_boundary_move_reuses_the_old_angle_reflection_profile :
    (outcomePrepared? th08BoundaryOutcome).map
      (fun prepared =>
        (prepared.reflections.map
          (fun reflection =>
            (reflection.kind, reflection.formulaSourceBits)),
          prepared.effect.hostAngleResult)) =
      some ([(.rightPositiveCurrent, f32TwoBits)], some 888) := by
  rfl

theorem th08_boundary_angle_flows_into_timed_motion_without_manual_reentry :
    (compositeOutcomePrepared? th08BoundaryCompositeOutcome).map
        (fun prepared =>
          (prepared.direction.finalAngleBits,
            prepared.movement.effectiveAngleBits,
            prepared.movement.effect.angleWrite)) =
      some (888, some 888, some 888) := by
  rfl

theorem th08_biased_move_applies_vertical_reflection_after_host_generation :
    (outcomePrepared? th08BiasedVerticalOutcome).map
      (fun prepared =>
        (prepared.candidateBranch,
          prepared.reflections.map (fun reflection => reflection.kind),
          prepared.effect.hostAngleResult)) =
      some (.hostCandidate, [.lowerVertical], some f32OneBits) := by
  rfl

end TouhouFormal.Search.RandomDirection
