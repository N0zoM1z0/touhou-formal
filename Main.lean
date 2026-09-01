import TouhouFormal

open TouhouFormal

set_option maxRecDepth 2048

private def describeFaultLookup : Except Fault (Option Nat) -> String
  | .ok (some offset) => "ok offset=" ++ toString offset
  | .ok none => "ok no-op"
  | .error faultValue => faultValue.describe

private def describeLoadLookup : Except TouhouFormal.ECL.LoadError (Option Nat) -> String
  | .ok (some offset) => "ok offset=" ++ toString offset
  | .ok none => "ok no-op"
  | .error err => err.describe

private def describeLookupProbe? : Option TouhouFormal.Search.Call.LookupProbe -> String
  | none => "none"
  | some probe =>
      let faultText :=
        match probe.fault with
        | none => ""
        | some faultValue => " fault=" ++ faultValue.describe
      "title=" ++ probe.title ++
        " subCount=" ++ toString probe.subCount ++
        " subId=" ++ toString probe.subId ++
        " class=" ++ probe.lookupClass.name ++
        faultText

private def describeLoadedHeader : Except TouhouFormal.ECL.LoadError TouhouFormal.ECL.LoadedHeader -> String
  | .ok header =>
      "ok subCount=" ++ toString header.subCount ++
        " timelineOffsets=" ++ toString header.timelineOffsets.size ++
        " subOffsets=" ++ toString header.subOffsets.size
  | .error err => err.describe

private def describeTimelinePrefix : Except Fault TouhouFormal.ECL.TimelinePrefix -> String
  | .ok timelinePrefix =>
      "ok time=" ++ toString timelinePrefix.time ++
        " opcode=" ++ toString timelinePrefix.opcode ++
        " size=" ++ toString timelinePrefix.size ++
        " nextCursor=" ++ toString timelinePrefix.nextCursor
  | .error faultValue => faultValue.describe

private def describeRawInstrPrefix : Except Fault TouhouFormal.ECL.RawInstrPrefix -> String
  | .ok rawPrefix =>
      "ok time=" ++ toString rawPrefix.time ++
        " opcode=" ++ toString rawPrefix.opcode ++
        " nextOffset=" ++ toString rawPrefix.nextOffset ++
        " nextCursor=" ++ toString rawPrefix.nextCursor ++
        " difficulty=" ++ toString rawPrefix.difficultyMask ++
        " operandMask=" ++ toString rawPrefix.operandMask
  | .error faultValue => faultValue.describe

private def describeJumpOperands : Except Fault TouhouFormal.ECL.RawJumpOperands -> String
  | .ok jump =>
      "ok targetTime=" ++ toString jump.targetTime ++
        " displacement=" ++ toString jump.displacement
  | .error faultValue => faultValue.describe

private def describeRawDifficultyProbe
    (probe : TouhouFormal.Search.Difficulty.RawDifficultyProbe) : String :=
  "title=" ++ probe.title ++
    " instructionMask=" ++ toString probe.instructionMask ++
    " activeMask=" ++ toString probe.activeMask ++
    " overrideMask=" ++ toString probe.overrideMask ++
    " executes=" ++ toString probe.executes

private def describeFloatBinaryOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawFloatBinaryOpOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let resultBits :=
        match outcome.result with
        | none => "none"
        | some value => toString value.resultBits
      "action=" ++ reprStr outcome.action ++
        " resultBits=" ++ resultBits
        ++ " cursor=" ++ toString outcome.targetCursor

private def describeFloatFunctionOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawFloatFunctionOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let functionKind :=
        match outcome.result with
        | none => "none"
        | some value => value.kind.name
      let resultBits :=
        match outcome.result with
        | none => "none"
        | some value => toString value.resultBits
      "action=" ++ reprStr outcome.action ++
        " function=" ++ functionKind ++
        " resultBits=" ++ resultBits ++
        " cursor=" ++ toString outcome.targetCursor

private def describeRandomOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawRandomOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let details :=
        match outcome.result with
        | none => "kind=none generatedWord=none writtenWord=none"
        | some value =>
            "kind=" ++ value.kind.name ++
              " generatedWord=" ++ toString value.generatedWord ++
              " writtenWord=" ++ toString value.writtenWord
      "action=" ++ reprStr outcome.action ++
        " " ++ details ++
        " cursor=" ++ toString outcome.targetCursor

private def describeCompareRegisterOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCompareRegisterOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      "action=" ++ reprStr outcome.action ++
        " compareRegister=" ++ toString outcome.compareRegister ++
        " cursor=" ++ toString outcome.targetCursor

private def describeRawStepOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawStepOutcome) : String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      "action=" ++ reprStr outcome.action ++
        " targetTime=" ++ toString outcome.targetTime ++
        " cursor=" ++ toString outcome.targetCursor

private def describeMovementOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawMovementOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let effectSummary :=
        match outcome.effect with
        | none => "effect=none"
        | some effect =>
            "mode=" ++ reprStr effect.modeWrite ++
              " angle=" ++ reprStr effect.angleWrite ++
              " position=" ++ reprStr effect.positionWrite ++
              " timers=" ++ reprStr
                (effect.movementDurationWrite, effect.movementTimerWrite)
      "action=" ++ reprStr outcome.action ++
        " " ++ effectSummary ++
        " cursor=" ++ toString outcome.targetCursor

private def describeEnemyStateOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawEnemyStateOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let effectSummary :=
        match outcome.effect with
        | none => "effect=none"
        | some effect =>
            "primaryHitbox=" ++ reprStr effect.primaryHitboxWrite ++
              " secondaryHitbox=" ++ reprStr effect.secondaryHitboxWrite ++
              " fields=" ++ reprStr effect.fieldWrites ++
              " alignmentCollision=" ++
                reprStr effect.alignmentEffectCollisionWrite ++
              " presentationSuppressed=" ++
                toString effect.suppressedByPresentationPolicy ++
              " life=" ++ reprStr
                (effect.lifeWrite,
                  effect.maxLifeWrite,
                  effect.phaseStartingLifeWrite) ++
              " timer=" ++ reprStr effect.timerWrite ++
              " clearBossGauge=" ++ toString effect.clearBossGauge
      "action=" ++ reprStr outcome.action ++
        " " ++ effectSummary ++
        " cursor=" ++ toString outcome.targetCursor

private def describeShootingOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawShootingOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let effectSummary :=
        match outcome.effect with
        | none => "effect=none"
        | some effect =>
            "interval=" ++ reprStr effect.shootIntervalWrite ++
              " timer=" ++ reprStr effect.shootIntervalTimerWrite ++
              " gate=" ++ reprStr effect.shootingGateWrite ++
              " spawn=" ++ toString effect.spawnPreviousPattern ++
              " offset=" ++ reprStr effect.shootOffsetWrite
      "action=" ++ reprStr outcome.action ++
        " " ++ effectSummary ++
        " cursor=" ++ toString outcome.targetCursor

private def describeBulletPatternOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawBulletPatternOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let effectSummary :=
        match outcome.effect with
        | none => "effect=none"
        | some effect =>
            "disposition=" ++ effect.disposition.name ++
              " pending=" ++ toString effect.pendingInstructionWrite.isSome ++
              " descriptor=" ++ toString effect.descriptorWrite.isSome ++
              " spawn=" ++ toString effect.spawnCall
      "action=" ++ reprStr outcome.action ++
        " " ++ effectSummary ++
        " cursor=" ++ toString outcome.targetCursor

private def describeCallbackConfigOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawCallbackConfigOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let effectSummary :=
        match outcome.effect with
        | none => "effect=none"
        | some effect =>
            "death=" ++ reprStr effect.deathCallbackSubWrite ++
              " lifeThresholds=" ++ reprStr effect.lifeThresholdWrites ++
              " lifeSubs=" ++ reprStr effect.lifeSubWrites ++
              " timer=" ++ reprStr
                (effect.timerThresholdWrite,
                  effect.timerSubWrite,
                  effect.bossTimerWrite) ++
              " periodic=" ++ reprStr
                (effect.periodicIntervalWrite, effect.periodicSubWrite) ++
              " suppressed=" ++
                toString effect.suppressedByPresentationPolicy
      let faultSummary :=
        match outcome.fault with
        | none => ""
        | some fault => " fault=" ++ fault.describe
      "action=" ++ reprStr outcome.action ++
        " " ++ effectSummary ++ faultSummary ++
        " cursor=" ++ toString outcome.targetCursor

private def describeInterruptOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawInterruptOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let effectSummary :=
        match outcome.effect with
        | none => "effect=none"
        | some effect =>
            "tableWrite=" ++ reprStr effect.tableWrite ++
              " stackDisabled=" ++ reprStr effect.stackDisabledWrite ++
              " run=" ++ reprStr effect.runIndexWrite ++
              " save=" ++ reprStr effect.stackContextWriteIndex ++
              " called=" ++ reprStr effect.calledSubId ++
              " target=" ++ reprStr effect.targetSubOffset ++
              " depth=" ++ reprStr effect.stackDepthWrite ++
              " advancedWithoutSave=" ++
                toString effect.stackAdvancedWithoutSave
      let faultSummary :=
        match outcome.fault with
        | none => ""
        | some fault => " fault=" ++ fault.describe
      "action=" ++ reprStr outcome.action ++
        " " ++ effectSummary ++ faultSummary ++
        " cursor=" ++ toString outcome.targetCursor

private def describeScalarAssignOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawScalarAssignOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let writtenKind :=
        match outcome.writtenKind with
        | none => "none"
        | some kind => kind.name
      let valueBits :=
        match outcome.valueBits with
        | none => "none"
        | some value => toString value
      "action=" ++ reprStr outcome.action ++
        " writtenKind=" ++ writtenKind ++
        " valueBits=" ++ valueBits ++
        " cursor=" ++ toString outcome.targetCursor

private def describeIntUnaryUpdateOutcome
    (result : Except TouhouFormal.Fault TouhouFormal.ECL.RawIntUnaryUpdateOutcome) :
    String :=
  match result with
  | .error faultValue => faultValue.describe
  | .ok outcome =>
      let resultValue :=
        match outcome.result with
        | none => "none"
        | some value => toString value
      let outputKind :=
        match outcome.prepared with
        | none => "none"
        | some prepared => prepared.output.kind.name
      "action=" ++ reprStr outcome.action ++
        " outputKind=" ++ outputKind ++
        " result=" ++ resultValue ++
        " cursor=" ++ toString outcome.targetCursor

private def describeAnmEntry : Except Fault TouhouFormal.ANM.EntryHeader -> String
  | .ok entry =>
      "ok sprites=" ++ toString entry.numSprites ++
        " scripts=" ++ toString entry.numScripts ++
        " nextOffset=" ++ toString entry.nextOffset ++
        " nextCursor=" ++ toString entry.nextCursor
  | .error faultValue => faultValue.describe

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
  IO.println s!"TH06 first bounded lookup fault: {describeLookupProbe? TouhouFormal.Search.Call.th06FirstFault?}"
  IO.println s!"TH07 first bounded lookup fault: {describeLookupProbe? TouhouFormal.Search.Call.th07FirstFault?}"
  IO.println s!"TH08 first bounded lookup fault: {describeLookupProbe? TouhouFormal.Search.Call.th08FirstFault?}"
  IO.println ""
  IO.println "Bounded loader controls"
  IO.println s!"TH06 zero-count 7 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH06.headerShape (TouhouFormal.Search.Bounded.zeroBytesOfLength 7))}"
  IO.println s!"TH06 zero-count 8 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH06.headerShape TouhouFormal.Search.Bounded.th06ZeroCountMinimalBytes)}"
  IO.println s!"TH08 versioned 71 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH08.headerShape TouhouFormal.Search.Bounded.th08AlmostMinimalBytes)}"
  IO.println s!"TH08 versioned 72 bytes: {describeLoadedHeader (TouhouFormal.ECL.loadHeaderOffsets TouhouFormal.TH08.headerShape TouhouFormal.Search.Bounded.th08ZeroCountMinimalBytes)}"
  IO.println ""
  IO.println "Timeline cursor controls"
  IO.println s!"TH06 size=0 prefix: {describeTimelinePrefix (TouhouFormal.ECL.decodeTimelinePrefix TouhouFormal.TH06.headerShape TouhouFormal.TH06.rawZeroSizeTimelinePrefixBytes 0)}"
  IO.println s!"TH06 size=-1 after advance: {describeTimelinePrefix (TouhouFormal.ECL.decodeTimelinePrefixAfterAdvance TouhouFormal.TH06.headerShape TouhouFormal.TH06.rawNegativeSizeTimelinePrefixBytes { fileOffset := 0, time := 441, opcode := 0, size := -1, firstArg := some 0 })}"
  IO.println s!"TH06 timeline size sweep: {reprStr TouhouFormal.Search.Cursor.th06TimelineSizeSweep}"
  IO.println s!"TH07 timeline size sweep: {reprStr TouhouFormal.Search.Cursor.th07TimelineSizeSweep}"
  IO.println s!"TH08 timeline size sweep: {reprStr TouhouFormal.Search.Cursor.th08TimelineSizeSweep}"
  IO.println ""
  IO.println "Raw ECL instruction prefix controls"
  IO.println s!"TH06 nextOffset=0 prefix: {describeRawInstrPrefix (TouhouFormal.ECL.decodeRawInstrPrefix TouhouFormal.TH06.headerShape TouhouFormal.TH06.rawZeroNextOffsetInstrPrefixBytes 0)}"
  IO.println s!"TH06 nextOffset=-1 after advance: {describeRawInstrPrefix (TouhouFormal.ECL.decodeRawInstrPrefixAfterAdvance TouhouFormal.TH06.headerShape TouhouFormal.TH06.rawNegativeNextOffsetInstrPrefixBytes { fileOffset := 0, time := 441, opcode := 0, nextOffset := -1, difficultyMask := some 0, operandMask := none })}"
  IO.println s!"TH07 prefix: {describeRawInstrPrefix (TouhouFormal.ECL.decodeRawInstrPrefix TouhouFormal.TH07.headerShape TouhouFormal.TH07.rawInstrPrefixBytes 0)}"
  IO.println s!"TH08 prefix: {describeRawInstrPrefix (TouhouFormal.ECL.decodeRawInstrPrefix TouhouFormal.TH08.headerShape TouhouFormal.TH08.rawInstrPrefixBytes 0)}"
  IO.println s!"TH06 raw nextOffset sweep: {reprStr TouhouFormal.Search.Cursor.th06RawNextOffsetSweep}"
  IO.println s!"TH07 raw nextOffset sweep: {reprStr TouhouFormal.Search.Cursor.th07RawNextOffsetSweep}"
  IO.println s!"TH08 raw nextOffset sweep: {reprStr TouhouFormal.Search.Cursor.th08RawNextOffsetSweep}"
  IO.println ""
  IO.println "Raw difficulty-mask controls"
  for probe in TouhouFormal.Search.Difficulty.rawDifficultyOverrideDeltaSweep do
    IO.println s!"{describeRawDifficultyProbe probe}"
  IO.println ""
  IO.println "Float arithmetic controls"
  IO.println s!"TH06 float binary opcode count: {TouhouFormal.Search.FloatArithmetic.floatBinaryOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 float binary opcode count: {TouhouFormal.Search.FloatArithmetic.floatBinaryOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 float binary opcode count: {TouhouFormal.Search.FloatArithmetic.floatBinaryOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 float add: {describeFloatBinaryOutcome TouhouFormal.Search.FloatArithmetic.th06FloatAddOutcome}"
  IO.println s!"TH07 float add: {describeFloatBinaryOutcome TouhouFormal.Search.FloatArithmetic.th07FloatAddOutcome}"
  IO.println s!"TH08 float add in-place: {describeFloatBinaryOutcome TouhouFormal.Search.FloatArithmetic.th08FloatAddInPlaceOutcome}"
  IO.println ""
  IO.println "Float function controls"
  IO.println s!"TH06 float function opcode count: {TouhouFormal.Search.FloatFunction.floatFunctionOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 float function opcode count: {TouhouFormal.Search.FloatFunction.floatFunctionOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 float function opcode count: {TouhouFormal.Search.FloatFunction.floatFunctionOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 atan2: {describeFloatFunctionOutcome TouhouFormal.Search.FloatFunction.th06Atan2Outcome}"
  IO.println s!"TH07 sin: {describeFloatFunctionOutcome TouhouFormal.Search.FloatFunction.th07SinOutcome}"
  IO.println s!"TH08 vector angle: {describeFloatFunctionOutcome TouhouFormal.Search.FloatFunction.th08VectorAngleOutcome}"
  IO.println ""
  IO.println "Random opcode controls"
  IO.println s!"TH06 random opcode count: {TouhouFormal.Search.Random.randomOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 random opcode count: {TouhouFormal.Search.Random.randomOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 random opcode count: {TouhouFormal.Search.Random.randomOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 int range: {describeRandomOutcome TouhouFormal.Search.Random.th06IntRandOutcome}"
  IO.println s!"TH07 float range add: {describeRandomOutcome TouhouFormal.Search.Random.th07FloatRandAddOutcome}"
  IO.println s!"TH08 int sign: {describeRandomOutcome TouhouFormal.Search.Random.th08IntSignOutcome}"
  IO.println ""
  IO.println "Comparison controls"
  IO.println s!"TH06 compare-register opcode count: {TouhouFormal.Search.Comparison.compareRegisterOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 float conditional-jump count: {TouhouFormal.Search.Comparison.floatConditionJumpOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 float conditional-jump count: {TouhouFormal.Search.Comparison.floatConditionJumpOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 cmp int: {describeCompareRegisterOutcome TouhouFormal.Search.Comparison.th06CmpIntOutcome}"
  IO.println s!"TH06 cmp float unordered: {describeCompareRegisterOutcome TouhouFormal.Search.Comparison.th06CmpFloatUnorderedOutcome}"
  IO.println s!"TH07 float neq unordered: {describeRawStepOutcome TouhouFormal.Search.Comparison.th07FloatNeqUnorderedOutcome}"
  IO.println s!"TH08 float ge less: {describeRawStepOutcome TouhouFormal.Search.Comparison.th08FloatGeLessOutcome}"
  IO.println ""
  IO.println "Movement controls"
  IO.println s!"TH06 movement opcode count: {TouhouFormal.Search.Movement.movementOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 movement opcode count: {TouhouFormal.Search.Movement.movementOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 movement opcode count: {TouhouFormal.Search.Movement.movementOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 move at player: {describeMovementOutcome TouhouFormal.Search.Movement.th06MoveAtPlayerOutcome}"
  IO.println s!"TH07 axis velocity: {describeMovementOutcome TouhouFormal.Search.Movement.th07AxisVelocityOutcome}"
  IO.println s!"TH08 polar velocity: {describeMovementOutcome TouhouFormal.Search.Movement.th08PolarVelocityOutcome}"
  IO.println s!"TH08 position: {describeMovementOutcome TouhouFormal.Search.Movement.th08PositionOutcome}"
  IO.println ""
  IO.println "Enemy state controls"
  IO.println s!"TH06 enemy-state opcode count: {TouhouFormal.Search.EnemyState.enemyStateOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 enemy-state opcode count: {TouhouFormal.Search.EnemyState.enemyStateOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 enemy-state opcode count: {TouhouFormal.Search.EnemyState.enemyStateOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 hitbox: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th06HitboxOutcome}"
  IO.println s!"TH07 hitbox: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th07HitboxOutcome}"
  IO.println s!"TH08 replace flags: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th08ReplaceFlagsOutcome}"
  IO.println s!"TH08 disable collision: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th08DisableCollisionOutcome}"
  IO.println s!"TH08 suppressed death mode: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th08SuppressedDeathModeOutcome}"
  IO.println s!"TH06 life: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th06LifeOutcome}"
  IO.println s!"TH07 life: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th07LifeOutcome}"
  IO.println s!"TH08 life: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th08LifeOutcome}"
  IO.println s!"TH08 timer: {describeEnemyStateOutcome TouhouFormal.Search.EnemyState.th08TimerOutcome}"
  IO.println ""
  IO.println "Shooting controls"
  IO.println s!"TH06 shooting opcode count: {TouhouFormal.Search.Shooting.shootingOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 shooting opcode count: {TouhouFormal.Search.Shooting.shootingOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 shooting opcode count: {TouhouFormal.Search.Shooting.shootingOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 zero interval: {describeShootingOutcome TouhouFormal.Search.Shooting.th06ZeroIntervalOutcome}"
  IO.println s!"TH07 zero interval: {describeShootingOutcome TouhouFormal.Search.Shooting.th07ZeroIntervalOutcome}"
  IO.println s!"TH08 random interval: {describeShootingOutcome TouhouFormal.Search.Shooting.th08RandomIntervalOutcome}"
  IO.println s!"TH06 offset: {describeShootingOutcome TouhouFormal.Search.Shooting.th06OffsetOutcome}"
  IO.println s!"TH08 offset: {describeShootingOutcome TouhouFormal.Search.Shooting.th08OffsetOutcome}"
  IO.println ""
  IO.println "Bullet-pattern controls"
  IO.println s!"TH06 bullet-pattern opcode count: {TouhouFormal.Search.BulletPattern.bulletPatternOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 bullet-pattern opcode count: {TouhouFormal.Search.BulletPattern.bulletPatternOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 bullet-pattern opcode count: {TouhouFormal.Search.BulletPattern.bulletPatternOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 suppressed pattern: {describeBulletPatternOutcome TouhouFormal.Search.BulletPattern.th06SuppressedOutcome}"
  IO.println s!"TH07 dead pattern: {describeBulletPatternOutcome TouhouFormal.Search.BulletPattern.th07DeadOutcome}"
  IO.println s!"TH07 spellcard pattern: {describeBulletPatternOutcome TouhouFormal.Search.BulletPattern.th07SpellcardOutcome}"
  IO.println s!"TH08 deferred pattern: {describeBulletPatternOutcome TouhouFormal.Search.BulletPattern.th08DeferredOutcome}"
  IO.println s!"TH08 alignment-filtered pattern: {describeBulletPatternOutcome TouhouFormal.Search.BulletPattern.th08AlignmentFilteredOutcome}"
  IO.println s!"TH08 distance-filtered pattern: {describeBulletPatternOutcome TouhouFormal.Search.BulletPattern.th08DistanceFilteredOutcome}"
  IO.println s!"TH08 spawned pattern: {describeBulletPatternOutcome TouhouFormal.Search.BulletPattern.th08SpawnOutcome}"
  IO.println ""
  IO.println "Callback-configuration controls"
  IO.println s!"TH06 callback-config opcode count: {TouhouFormal.Search.Callback.callbackConfigOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 callback-config opcode count: {TouhouFormal.Search.Callback.callbackConfigOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 callback-config opcode count: {TouhouFormal.Search.Callback.callbackConfigOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 timer threshold: {describeCallbackConfigOutcome TouhouFormal.Search.Callback.th06TimerThresholdOutcome}"
  IO.println s!"TH07 repeated-index partial fault: {describeCallbackConfigOutcome TouhouFormal.Search.Callback.th07LifePairPartialFaultOutcome}"
  IO.println s!"TH07 periodic callback: {describeCallbackConfigOutcome TouhouFormal.Search.Callback.th07PeriodicOutcome}"
  IO.println s!"TH08 suppressed death callback: {describeCallbackConfigOutcome TouhouFormal.Search.Callback.th08SuppressedDeathOutcome}"
  IO.println s!"TH08 suppressed life callback: {describeCallbackConfigOutcome TouhouFormal.Search.Callback.th08SuppressedLifePairOutcome}"
  IO.println s!"TH08 suppressed timer callback: {describeCallbackConfigOutcome TouhouFormal.Search.Callback.th08SuppressedTimerPairOutcome}"
  IO.println s!"TH08 bind timer callback: {describeCallbackConfigOutcome TouhouFormal.Search.Callback.th08BindOutcome}"
  IO.println ""
  IO.println "Interrupt controls"
  IO.println s!"TH06 interrupt opcode count: {TouhouFormal.Search.Interrupt.interruptOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 interrupt opcode count: {TouhouFormal.Search.Interrupt.interruptOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 interrupt opcode count: {TouhouFormal.Search.Interrupt.interruptOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 disabled-stack interrupt: {describeInterruptOutcome TouhouFormal.Search.Interrupt.th06DisabledStackRunOutcome}"
  IO.println s!"TH06 interrupt subTable fault: {describeInterruptOutcome TouhouFormal.Search.Interrupt.th06SubTableFaultOutcome}"
  IO.println s!"TH07 interrupt table-read fault: {describeInterruptOutcome TouhouFormal.Search.Interrupt.th07TableReadFaultOutcome}"
  IO.println s!"TH08 signed table write: {describeInterruptOutcome TouhouFormal.Search.Interrupt.th08SetTableOutcome}"
  IO.println s!"TH08 negative-sub interrupt: {describeInterruptOutcome TouhouFormal.Search.Interrupt.th08NegativeSubNoOpOutcome}"
  IO.println s!"TH08 signed run-index fault: {describeInterruptOutcome TouhouFormal.Search.Interrupt.th08TruncatedRunIndexFaultOutcome}"
  IO.println ""
  IO.println "Scalar assignment controls"
  IO.println s!"TH06 scalar assignment opcode count: {TouhouFormal.Search.ScalarAssignment.scalarAssignOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 scalar assignment opcode count: {TouhouFormal.Search.ScalarAssignment.scalarAssignOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 scalar assignment opcode count: {TouhouFormal.Search.ScalarAssignment.scalarAssignOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 set float: {describeScalarAssignOutcome TouhouFormal.Search.ScalarAssignment.th06SetFloatOutcome}"
  IO.println s!"TH07 set float: {describeScalarAssignOutcome TouhouFormal.Search.ScalarAssignment.th07SetFloatOutcome}"
  IO.println s!"TH08 set int: {describeScalarAssignOutcome TouhouFormal.Search.ScalarAssignment.th08SetIntOutcome}"
  IO.println ""
  IO.println "Integer unary update controls"
  IO.println s!"TH06 int unary update opcode count: {TouhouFormal.Search.IntUnaryUpdate.intUnaryUpdateOpcodeCount TouhouFormal.TH06.headerShape}"
  IO.println s!"TH07 int unary update opcode count: {TouhouFormal.Search.IntUnaryUpdate.intUnaryUpdateOpcodeCount TouhouFormal.TH07.headerShape}"
  IO.println s!"TH08 int unary update opcode count: {TouhouFormal.Search.IntUnaryUpdate.intUnaryUpdateOpcodeCount TouhouFormal.TH08.headerShape}"
  IO.println s!"TH06 inc unknown raw cell: {describeIntUnaryUpdateOutcome TouhouFormal.Search.IntUnaryUpdate.th06IncUnknownOutcome}"
  IO.println s!"TH07 inc resolved host: {describeIntUnaryUpdateOutcome TouhouFormal.Search.IntUnaryUpdate.th07IncResolvedOutcome}"
  IO.println s!"TH08 dec raw cell: {describeIntUnaryUpdateOutcome TouhouFormal.Search.IntUnaryUpdate.th08DecRawCellOutcome}"
  IO.println ""
  IO.println "Relative jump controls"
  IO.println s!"TH06 jump operands: {describeJumpOperands TouhouFormal.TH06.rawJumpMinusOneOperands}"
  IO.println s!"TH06 jump=-1 target decode: {describeRawInstrPrefix (TouhouFormal.ECL.decodeRawInstrPrefixAfterRelativeJump TouhouFormal.TH06.headerShape TouhouFormal.TH06.rawJumpMinusOneInstrBytes { fileOffset := 0, time := 441, opcode := TouhouFormal.TH06.eclOpcodeJump, nextOffset := 12, difficultyMask := some 0, operandMask := none } { targetTime := 0, displacement := -1 })}"
  IO.println s!"TH07 jump operands: {describeJumpOperands TouhouFormal.TH07.rawJumpMinusOneOperands}"
  IO.println s!"TH07 jump=-1 target decode: {describeRawInstrPrefix (TouhouFormal.ECL.decodeRawInstrPrefixAfterRelativeJump TouhouFormal.TH07.headerShape TouhouFormal.TH07.rawJumpMinusOneInstrBytes { fileOffset := 0, time := 441, opcode := TouhouFormal.TH07.eclOpcodeJump, nextOffset := 12, difficultyMask := some 255, operandMask := some 0 } { targetTime := 0, displacement := -1 })}"
  IO.println s!"TH08 jump operands: {describeJumpOperands TouhouFormal.TH08.rawJumpMinusOneOperands}"
  IO.println s!"TH08 jump=-1 target decode: {describeRawInstrPrefix (TouhouFormal.ECL.decodeRawInstrPrefixAfterRelativeJump TouhouFormal.TH08.headerShape TouhouFormal.TH08.rawJumpMinusOneInstrBytes { fileOffset := 0, time := 441, opcode := TouhouFormal.TH08.eclOpcodeJump, nextOffset := 12, difficultyMask := some 255, operandMask := some 0 } { targetTime := 0, displacement := -1 })}"
  IO.println s!"TH06 jump sweep: {reprStr TouhouFormal.Search.Cursor.th06JumpSweep}"
  IO.println s!"TH07 jump sweep: {reprStr TouhouFormal.Search.Cursor.th07JumpSweep}"
  IO.println s!"TH08 jump sweep: {reprStr TouhouFormal.Search.Cursor.th08JumpSweep}"
  IO.println ""
  IO.println "ANM entry controls"
  IO.println s!"TH06 ANM zero entry: {describeAnmEntry (TouhouFormal.ANM.decodeEntryHeader TouhouFormal.TH06.ANM.entryShape TouhouFormal.TH06.ANM.zeroEntryBytes 0)}"
  IO.println s!"TH07 ANM next entry: {describeAnmEntry (TouhouFormal.ANM.decodeEntryHeader TouhouFormal.TH07.ANM.entryShape TouhouFormal.TH07.ANM.nextEntryBytes 0)}"
  IO.println s!"TH08 ANM next entry: {describeAnmEntry (TouhouFormal.ANM.decodeEntryHeader TouhouFormal.TH08.ANM.entryShape TouhouFormal.TH08.ANM.nextEntryBytes 0)}"
