import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH08

def title : String := "TH08"

def rawHeaderFixedPrefixBytes : Nat := 0x48
def expectedEclVersion : Nat := 0x800
def timelineOffsetCount : Nat := 16
def timelineInstrFixedSize : Nat := 0x24
def eclOpcodeSetSecondaryTime : Int := 2
def eclOpcodeNoOp : Int := 3
def eclOpcodeJump : Int := 4
def eclOpcodeDecJump : Int := 5
def eclOpcodeJumpIfEq : Int := 40
def eclOpcodeJumpIfEqFloat : Int := 41
def eclOpcodeJumpIfNeq : Int := 42
def eclOpcodeJumpIfNeqFloat : Int := 43
def eclOpcodeJumpIfLt : Int := 44
def eclOpcodeJumpIfLtFloat : Int := 45
def eclOpcodeJumpIfLeq : Int := 46
def eclOpcodeJumpIfLeqFloat : Int := 47
def eclOpcodeJumpIfGt : Int := 48
def eclOpcodeJumpIfGtFloat : Int := 49
def eclOpcodeJumpIfGeq : Int := 50
def eclOpcodeJumpIfGeqFloat : Int := 51
def eclOpcodeSetInt : Int := 6
def eclOpcodeSetFloat : Int := 7
def eclOpcodeRandSign : Int := 8
def eclOpcodeRandSignFloat : Int := 9
def eclOpcodeIntAddInPlace : Int := 10
def eclOpcodeIntSubInPlace : Int := 11
def eclOpcodeIntMulInPlace : Int := 12
def eclOpcodeIntDivInPlace : Int := 13
def eclOpcodeIntModInPlace : Int := 14
def eclOpcodeFloatAddInPlace : Int := 15
def eclOpcodeFloatSubInPlace : Int := 16
def eclOpcodeFloatMulInPlace : Int := 17
def eclOpcodeFloatDivInPlace : Int := 18
def eclOpcodeFloatModInPlace : Int := 19
def eclOpcodeIntAdd : Int := 20
def eclOpcodeIntSub : Int := 21
def eclOpcodeIntMul : Int := 22
def eclOpcodeIntDiv : Int := 23
def eclOpcodeIntMod : Int := 24
def eclOpcodeFloatAdd : Int := 25
def eclOpcodeFloatSub : Int := 26
def eclOpcodeFloatMul : Int := 27
def eclOpcodeFloatDiv : Int := 28
def eclOpcodeFloatMod : Int := 29
def eclOpcodeInc : Int := 30
def eclOpcodeDec : Int := 31
def eclOpcodeSin : Int := 32
def eclOpcodeCos : Int := 33
def eclOpcodeVectorAngle : Int := 34
def eclOpcodeLerp : Int := 35
def eclOpcodeInstallInterpolation : Int := 36
def eclOpcodePolarToCartesian : Int := 38
def eclOpcodeDistance2d : Int := 39
def eclOpcodeNormalizeAngle : Int := 37
def eclOpcodeSubCall : Int := 52
def eclOpcodeSubRet : Int := 53
def eclOpcodeSetPrimaryAnm : Int := 54
def eclOpcodeSetPrimaryAnmSequential : Int := 55
def eclOpcodeSetPrimaryAnmExplicit : Int := 56
def eclOpcodeSetExtraAnm : Int := 57
def eclOpcodeSetAlternateAnm : Int := 58
def eclOpcodeSetAlternateAnmSequential : Int := 59
def eclOpcodeSetAlternateAnmExplicit : Int := 60
def eclOpcodeSetAlternateExtraAnm : Int := 61
def eclOpcodePlaySpecialAnm : Int := 62
def eclOpcodeSetPosition : Int := 63
def eclOpcodeMovePositionTimed : Int := 64
def eclOpcodeSetPolarVelocity : Int := 65
def eclOpcodeMoveDirectionTimed : Int := 66
def eclOpcodeMoveBoundaryAwareTimed : Int := 67
def eclOpcodeMoveAtPlayer : Int := 68
def eclOpcodeMoveAtPlayerTimed : Int := 69
def eclOpcodeSetAngularVelocity : Int := 70
def eclOpcodeSetAcceleration : Int := 71
def eclOpcodeMoveOrbit : Int := 72
def eclOpcodeMoveOrbitFromPosition : Int := 73
def eclOpcodeSetOrbitVelocities : Int := 74
def eclOpcodeSetMovementBounds : Int := 75
def eclOpcodeDisableMovementBounds : Int := 76
def eclOpcodeSetPrimaryHitbox : Int := 77
def eclOpcodeSetSecondaryHitbox : Int := 78
def eclOpcodeReplaceEnemyFlags : Int := 79
def eclOpcodeDisableEnemyFlags : Int := 80
def eclOpcodeEnableEnemyFlags : Int := 81
def eclOpcodeSetMinimumPlayerDistance : Int := 82
def eclOpcodeSetFormEffect : Int := 83
def eclOpcodeOrdinaryAdvance84 : Int := 84
def eclOpcodeOrdinaryAdvance85 : Int := 85
def eclOpcodeGetBossInt : Int := 86
def eclOpcodeGetBossFloat : Int := 87
def eclOpcodeCallBossSub : Int := 88
def eclOpcodeSetBossPendingSub : Int := 89
def eclOpcodeSpawnLinkedChild : Int := 90
def eclOpcodeSpawnLinkedChildAtParentOffset : Int := 91
def eclOpcodeSpawnLinkedChildInheritingPosition : Int := 92
def eclOpcodeSpawnEnemyAbs : Int := 93
def eclOpcodeSpawnEnemyRel : Int := 94
def eclOpcodeKillAllNonBossEnemies : Int := 95
def eclOpcodeSpawnBulletPatternFirst : Int := 96
def eclOpcodeSpawnBulletPatternLast : Int := 104
def eclOpcodeSetShootInterval : Int := 105
def eclOpcodeSetRandomShootInterval : Int := 106
def eclOpcodeDisableShooting : Int := 107
def eclOpcodeEnableShooting : Int := 108
def eclOpcodeSpawnPreviousPattern : Int := 109
def eclOpcodeSetShootOffset : Int := 110
def eclOpcodeInitBulletTransform : Int := 111
def eclOpcodeClearBulletsForTransition : Int := 112
def eclOpcodeSetBulletSound : Int := 113
def eclOpcodeSpawnLaserFixed : Int := 114
def eclOpcodeSpawnLaserAimed : Int := 115
def eclOpcodeSetLaserIdx : Int := 116
def eclOpcodeAddLaserAngle : Int := 117
def eclOpcodeAimLaserAngleAtPlayer : Int := 118
def eclOpcodeSetLaserPosRel : Int := 119
def eclOpcodeTestLaserInUse : Int := 120
def eclOpcodeStopLaser : Int := 121
def eclOpcodeBeginSpellcard : Int := 122
def eclOpcodeEndSpellcard : Int := 123
def eclOpcodePlayPositionedSound : Int := 124
def eclOpcodeSetBoss : Int := 127
def eclOpcodeSpawnTrackedEffect : Int := 128
def eclOpcodeSetDeathMode : Int := 129
def eclOpcodeSetDeathCallbackSub : Int := 130
def eclOpcodeSetLife : Int := 131
def eclOpcodeSetBossTimer : Int := 132
def eclOpcodeSetLifeCallback : Int := 133
def eclOpcodeSetTimerCallback : Int := 134
def eclOpcodeSetChildContext : Int := 135
def eclOpcodeRunExtension : Int := 136
def eclOpcodeSetExtension : Int := 137
def eclOpcodeSetDeathAnm : Int := 138
def eclOpcodeSpawnEffect : Int := 139
def eclOpcodeSpawnMovingEffect : Int := 140
def eclOpcodeSpawnItem : Int := 141
def eclOpcodeSpawnItems : Int := 142
def eclOpcodeSetItemDropType : Int := 143
def eclOpcodeSetItemDropCounts : Int := 144
def eclOpcodeSetRotateAnmWithMovement : Int := 145
def eclOpcodeAddTime : Int := 146
def eclOpcodeSetBackgroundLabel : Int := 147
def eclOpcodeRunInterrupt : Int := 125
def eclOpcodeSetInterrupt : Int := 126
def eclOpcodeSetBossLifeMarkerCount : Int := 148
def eclOpcodeSetPrimaryVmInterrupt : Int := 149
def eclOpcodeSetSecondaryVmInterrupt : Int := 150
def eclOpcodeSetCallStackDisabled : Int := 151
def eclOpcodeSetBulletRankInfluence : Int := 152
def eclOpcodeBindTimerCallbackToDeath : Int := 153
def eclOpcodeClearLasers : Int := 154
def eclOpcodeSetTimeoutSpell : Int := 155
def eclOpcodeSetSpecialInteraction : Int := 156
def eclOpcodeSetTrail : Int := 157
def eclOpcodeSetBossGauge : Int := 158
def eclOpcodeSetDrawGroup : Int := 159
def eclOpcodeSetDamageReductionTimer : Int := 160
def eclOpcodeRemoveBulletsRadius : Int := 161
def eclOpcodeRemoveAllBulletsMode4 : Int := 162
def eclOpcodeSetEnemyManagerValue : Int := 163
def eclOpcodeSetSpellcardEffectTracking : Int := 164
def eclOpcodeSetPrimaryVmRotZ : Int := 165
def eclOpcodeVectorFromAngleMagnitude : Int := 166
def eclOpcodeSetLaserAngle : Int := 167
def eclOpcodeSpawnPointItems : Int := 168
def eclOpcodeRandomExitAngle : Int := 169
def eclOpcodeSetLaserHideCapDuringStartup : Int := 170
def eclOpcodeSetLaserStartLength : Int := 171
def eclOpcodeSetLaserOffsets : Int := 172
def eclOpcodeSetPauseTimer : Int := 173
def eclOpcodeSpawnAlignmentEffect : Int := 174
def eclOpcodeSuppressTimelineSpawns : Int := 175
def eclOpcodeConfigurePause : Int := 176
def eclOpcodeSetPhaseStartingLife : Int := 177
def eclOpcodeMoveRandomBiasedTimed : Int := 178
def eclOpcodeStartStageBackground : Int := 179
def eclOpcodeHideClock : Int := 180
def eclOpcodeAdvanceClock : Int := 181
def eclOpcodeSetExtraVmFixedOffset : Int := 182
def eclOpcodeSetNoDamageDuringStop : Int := 183
def eclOpcodeSetSpellcardBonusUpdatesDisabled : Int := 184
def enemyPoolSlots : Nat := 480
def secondaryAnmVmCount : Nat := 2
def laserSlotCount : Nat := 32

def enemySpawnIntInputs :
    List TouhouFormal.ECL.RawEnemyLifecycleIntInputShape :=
  TouhouFormal.ECL.rawEnemySpawnPacketIntInputs
    .rawI32 .intRValue .intRValue .intRValue

def enemySpawnFloatInputs :
    List TouhouFormal.ECL.RawEnemyLifecycleFloatInputShape :=
  TouhouFormal.ECL.rawEnemySpawnPacketFloatInputs .floatRValue

def linkedChildIntInputs :
    List TouhouFormal.ECL.RawLinkedChildIntInputShape :=
  [ { role := .subId, operandIndex := 0, policy := .rawI32 },
    { role := .life, operandIndex := 3, policy := .intRValue },
    { role := .itemDrop, operandIndex := 4, policy := .intRValue },
    { role := .score, operandIndex := 5, policy := .intRValue } ]

def linkedChildFloatInputs :
    List TouhouFormal.ECL.RawLinkedChildFloatInputShape :=
  [ { role := .positionX, operandIndex := 1 },
    { role := .positionY, operandIndex := 2 } ]

def enemySpawnLifecycleOp
    (opcode : Int)
    (positionMode : TouhouFormal.ECL.RawEnemySpawnPositionMode) :
    TouhouFormal.ECL.RawEnemyLifecycleOpShape :=
  TouhouFormal.ECL.rawEnemyLifecycleSpawnOp
    opcode
    positionMode
    enemySpawnIntInputs
    enemySpawnFloatInputs
    enemyPoolSlots
    true
    .activeIntVariables
    true

def laserSpawnIntInputs :
    List TouhouFormal.ECL.RawLaserSpawnIntInputShape :=
  [ { operandIndex := 0
      flagIndex := 0
      policy := .raw
      storePolicy := .signedI16 },
    { operandIndex := 1
      flagIndex := 1
      policy := .intRValue
      storePolicy := .signedI16 },
    { operandIndex := 7
      flagIndex := 8
      policy := .intRValue },
    { operandIndex := 8
      flagIndex := 9
      policy := .intRValue },
    { operandIndex := 9
      flagIndex := 10
      policy := .intRValue },
    { operandIndex := 10
      flagIndex := 10
      policy := .raw },
    { operandIndex := 11
      flagIndex := 11
      policy := .raw },
    { operandIndex := 12
      flagIndex := 12
      policy := .raw
      storePolicy := .u32 } ]

def laserSpawnFloatInputs :
    List TouhouFormal.ECL.RawLaserSpawnFloatInputShape :=
  [ { operandIndex := 1
      flagIndex := 2
      policy := .floatRValue },
    { operandIndex := 2
      flagIndex := 3
      policy := .floatRValue },
    { operandIndex := 3
      flagIndex := 4
      policy := .floatRValue },
    { operandIndex := 4
      flagIndex := 5
      policy := .floatRValue },
    { operandIndex := 5
      flagIndex := 6
      policy := .floatRValue },
    { operandIndex := 6
      flagIndex := 7
      policy := .floatRValue } ]

def laserSpawnOp
    (opcode : Int)
    (aimKind : TouhouFormal.ECL.RawLaserSpawnAimKind) :
    TouhouFormal.ECL.RawLaserSpawnOpShape :=
  { opcode := opcode
    descriptorTarget := .bulletSpawnDescriptor
    aimKind := aimKind
    positionSource := .enemyWorldPositionPlusShootOffset
    intInputs := laserSpawnIntInputs
    floatInputs := laserSpawnFloatInputs
    slotCount := laserSlotCount }

def eclEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th08/src/EclManager.hpp"
      startLine := 147
      endLine := 156
      claim := "EclRawInstruction stores time, opcode, nextOffset, difficultyMask, operandFlags, and operands." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 88
      endLine := 90
      claim := "RawInt reads a four-byte operand at operands + index * 4." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 97
      endLine := 119
      claim := "ReadInt uses the operandFlags bit to choose raw operands versus ResolveInt, while WriteInt uses the same bit-indexed lvalue resolver." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 194
      endLine := 201
      claim := "The opcode body uses RawInt for raw slots and ReadInt for operandFlags-resolved integer operands." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 244
      endLine := 250
      claim := "Low opcode 6 writes WriteInt slot 0 from ReadInt slot 1, while low opcode 7 writes WriteFloat slot 0 from resolved/raw float slot 1." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 252
      endLine := 261
      claim := "Low opcodes 8 and 9 multiply resolved integer/float slot 1 by a sign selected from GetRandomU16 parity and write slot 0." },
    { path := "reference/th08/src/EclOperandsInt.cpp"
      startLine := 26
      endLine := 150
      claim := "ResolveInt maps known selector ids to host/context values and returns the raw operand in the default case." },
    { path := "reference/th08/src/EclOperandsInt.cpp"
      startLine := 156
      endLine := 200
      claim := "ResolveIntLValue maps a smaller writable selector subset and returns the raw operand pointer when the bit is clear or selector is unknown." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 264
      endLine := 280
      claim := "Low opcodes 10 through 14 update an integer lvalue in place through WriteInt and read RHS operand slot 1 through ReadInt." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 291
      endLine := 323
      claim := "Low opcodes 20 through 24 assign integer ADD/SUB/MUL/DIV/MOD results to WriteInt slot 0 from ReadInt slots 1 and 2." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 265
      endLine := 288
      claim := "Low opcodes 15 through 18 update a float lvalue in place with operand slot 1; low opcode 19 writes fmodf of resolved/raw slot 0 and slot 1 back to slot 0." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 292
      endLine := 331
      claim := "Low opcodes 25 through 29 assign float ADD/SUB/MUL/DIV/MOD to WriteFloat slot 0 from resolved/raw operand slots 1 and 2; opcode 29 uses fmodf." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 333
      endLine := 334
      claim := "Low opcodes 30 and 31 increment or decrement WriteInt slot 0 in place." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 335
      endLine := 351
      claim := "Low opcodes 32 and 33 apply sinf/cosf to float slot 1; opcode 34 writes VectorAngle(slot4 - slot2, slot3 - slot1) to float slot 0." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 353
      endLine := 357
      claim := "Low opcode 37 resolves float slot 0 as both input and output and applies AddNormalizeAngle(value, 0)." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 238
      endLine := 242
      claim := "Low opcode 4 sets context time from RawInt(0) and jumps by RawInt(1)." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 233
      endLine := 241
      claim := "Low opcode 5 decrements operand slot 2 and falls through to opcode 4 jump only while the decremented value is positive." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 276
      endLine := 280
      claim := "Low opcodes 13 and 14 perform integer division/modulo by operand slot 1 without a zero-divisor guard." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 315
      endLine := 323
      claim := "Low opcodes 23 and 24 perform integer division/modulo by operand slot 2 without a zero-divisor guard." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 694
      endLine := 700
      claim := "Low opcode 86 writes slot 0 from RawInt slot 1 when operandFlags bit 1 is clear; when bit 1 is set, it resolves slot 1 against g_EnemyManager.bosses[ReadInt(slot 2)] with no boss index or null guard." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 703
      endLine := 710
      claim := "The adjacent float boss-read opcode checks the boss pointer before resolving, providing a source-level contrast with opcode 86's unguarded integer path." },
    { path := "reference/th08/src/EclOperandsFloat.cpp"
      startLine := 23
      endLine := 147
      claim := "Enemy::ResolveFloat casts the f32 operand to i32, resolves known selector ids, and returns the raw operand for default cases including selector 0x2772." },
    { path := "reference/th08/src/EclOperandsFloat.cpp"
      startLine := 155
      endLine := 210
      claim := "ResolveFloatLValue returns the raw f32 operand cell when the flag bit is clear and maps a sparse writable float selector subset when the bit is set." },
    { path := "reference/th08/src/EnemyManager.hpp"
      startLine := 447
      endLine := 447
      claim := "EnemyManager stores eight boss pointers in bosses[8]." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 140
      endLine := 169
      claim := "CompareOperands evaluates integer operations 0,2,4,6,8,10 over ReadInt slots 0 and 1, then taken branches set time from RawInt(2) and jump by RawInt(3)." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 140
      endLine := 169
      claim := "CompareOperands evaluates the interleaved float operations 1,3,5,7,9,11 over ReadFloat slots 0 and 1 and reuses the same raw jump operands." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 415
      endLine := 421
      claim := "Low opcodes 52 and 53 delegate to CallSubOnEnemy and PopEclContext for SUB_CALL/SUB_RET." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 496
      endLine := 571
      claim := "Immediate movement opcodes set a clamped XY position, normalized polar velocity, normalized player-relative motion, angular velocity, or acceleration with opcode-specific mode/timer updates." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 99
      endLine := 267
      claim := "Boundary-aware opcode 67 and random-biased opcode 178 derive their direction host-side, then share the immediate or timed polar-displacement writes without reading an angle operand." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 882
      endLine := 896
      claim := "High opcode 169 selects the same fixed-cone exit direction as TH07 RAND_EXIT_ANGLE and writes float operand 0." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 571
      endLine := 615
      claim := "Low opcodes 72 through 74 initialize or update orbit fields; opcode 72 writes only the X/Y origin components, while opcode 73 snapshots the full current position and zeros radius." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 617
      endLine := 631
      claim := "Low opcodes 75 and 76 resolve four float movement bounds and toggle the movement-bounds flag." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 633
      endLine := 648
      claim := "Low opcodes 77 and 78 resolve two float operands into primary and secondary XY hitbox dimensions without writing Z." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 650
      endLine := 688
      claim := "Low opcodes 79 through 81 resolve one integer mask and replace, disable, or enable six enemy flags; collision toggles in 80/81 also mirror into an attached alignment-effect VM." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 477
      endLine := 481
      claim := "High opcode 129 writes the raw low byte into the three-bit deathMode field only when presentation writes are allowed." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 520
      endLine := 531
      claim := "High opcode 131 resolves operand 0 into phaseStartingLife, life, and maxLife and clears primary-boss gauge slots." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 549
      endLine := 549
      claim := "High opcode 132 resolves operand 0 and assigns it through bossTimer's integer assignment operator." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 210
      endLine := 258
      claim := "High opcodes 105 through 110 resolve nonzero intervals before rank scaling, initialize the timer immediately or randomly, toggle the defer-pattern flag, spawn the previous descriptor, and resolve XY offset while forcing Z to zero." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 789
      endLine := 817
      claim := "High bullet-control opcodes clear bullets for transition, set or clear descriptor spawn-sound flags plus transformSound from resolved integers, and write rank-influence fields with signed-i16 count truncation." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 260
      endLine := 335
      claim := "High laser-spawn opcodes copy LaserSpawnArgs into laserSpawnDescriptor with operandFlags-controlled color/float/time fields, set FAN versus FAN_AIMED aim mode from opcode 114/115, call SpawnLaserPattern, and store the returned pointer in laserSlots[selectedLaserSlot]." },
    { path := "reference/th08/src/BulletManager.cpp"
      startLine := 720
      endLine := 758
      claim := "SpawnLaserPattern may return early during spawn suppression, otherwise fills a free laser, applies player angle only for FAN_AIMED, truncates transformFlags to u16 for runtime laser flags, initializes timer/state fields, and returns the Laser pointer." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 165
      endLine := 184
      claim := "High opcodes 96 through 104 skip dead enemies and copy the complete 0x2c-byte raw instruction into pendingShotInstruction while the defer flag is set; otherwise they share DispatchShotInstruction." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 335
      endLine := 424
      claim := "High laser slot opcodes set selectedLaserSlot, mutate indexed lasers through unchecked TH08_ECL_LASER slot reads, record in-use status, stop active lasers with state/timer/current-width writes, clear all 32 slots, and update hide/start-length/offset fields." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 428
      endLine := 495
      claim := "Low opcodes 54 through 62 choose primary or alternate ANM bank, write six-script primary tables, toggle the alternate-bank flag, or play the current special script." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 449
      endLine := 459
      claim := "SetPrimaryAnmScripts casts all six script inputs to i16, stores the named enemy script table, and sets anmDirection to 0xff." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 534
      endLine := 565
      claim := "SetExtraAnmScript diagnoses only indexes >= 2, repeatedly resolves index/script operands, and still accesses secondaryVms[index]." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 684
      endLine := 687
      claim := "High opcode 145 writes a raw byte into the one-bit rotateAnmWithMovement field." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 780
      endLine := 787
      claim := "High opcode 149 writes a resolved integer into primary vm.pendingInterrupt; opcode 150 writes a raw-u16 signed interrupt into secondaryVms[raw index] without bounds checking." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 864
      endLine := 867
      claim := "High opcode 165 resolves one float operand and writes primary vm.rotation.z." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 687
      endLine := 780
      claim := "DispatchShotInstruction filters player alignment and minimum distance before operand resolution, builds the shared descriptor with shifted operand-flag bits, skips rank and clamps during spellcards, and then spawns the pattern." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 483
      endLine := 488
      claim := "High opcode 130 presentation-guards a raw-u16 write into signed deathCallbackSubId." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 551
      endLine := 579
      claim := "High opcodes 133 and 134 configure unchecked indexed life callbacks and timer callbacks; presentation suppression removes sub-id writes but retains threshold writes and timer reset." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 820
      endLine := 825
      claim := "High opcode 153 binds timerCallbackSubId to signed deathCallbackSubId and resets bossTimer." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 488
      endLine := 520
      claim := "High opcodes 125/126 resolve a signed-i16 32-entry subroutine table and enter the selected subroutine after advancing/saving context; the call-stack depth increments even when saving is disabled." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 805
      endLine := 809
      claim := "High opcode 151 assigns the raw low byte into the one-bit disableEclCallStack flag." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 466
      endLine := 493
      claim := "CallSubOnEnemy saves activeEclContext at activeEclCallStack[activeEclCallStackDepth] before CallEclSub and increments depth only while depth < 15." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 499
      endLine := 527
      claim := "PopEclContext decrements activeEclCallStackDepth; negative depth exits a child context by indexing childEclBlocks[childContextSlot - 1], otherwise it restores activeEclCallStack[depth]." },
    { path := "reference/th08/src/EnemyManager.hpp"
      startLine := 211
      endLine := 218
      claim := "Enemy stores mainEclContextStorage, mainEclCallStackStorage[16], activeEclContext, activeEclCallStack, and signed call-stack depths." },
    { path := "reference/th08/src/EnemyManager.hpp"
      startLine := 284
      endLine := 289
      claim := "Enemy has four childEclBlocks, used by the RET child-context exit path." },
    { path := "reference/th08/src/EclManager.hpp"
      startLine := 181
      endLine := 187
      claim := "EclRawHeader stores version, subCount, timelineCount, sixteen timeline offsets, and subOffsets[1]." },
    { path := "reference/th08/src/EclManager.cpp"
      startLine := 38
      endLine := 45
      claim := "Load rejects ECL files whose version is not 0x800." },
    { path := "reference/th08/src/EclManager.cpp"
      startLine := 46
      endLine := 55
      claim := "Load rebases sixteen timeline offsets and subTable entries for index < subCount." },
    { path := "reference/th08/src/EclManager.cpp"
      startLine := 69
      endLine := 84
      claim := "CallEclSub returns success for negative sub ids and otherwise reads this->subTable[subId]." },
    { path := "reference/th08/src/EnemyManager.hpp"
      startLine := 419
      endLine := 431
      claim := "EclTimelineInstruction stores i32 time, i16 opcode, u8 size, u8 difficultyMask, and seven i32/f32 args." },
    { path := "reference/th08/src/EnemyTimeline.cpp"
      startLine := 120
      endLine := 230
      claim := "Timeline spawn opcodes pass args.ints[0] into SpawnEnemy1, which then calls CallEclSub." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 83
      endLine := 92
      claim := "SpawnPacketTyped stores eclSubroutineId, a three-float position, life, itemDropType, and score." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 717
      endLine := 779
      claim := "High opcodes 93 and 94 require the parent enemy to be alive, resolve position/life/item/score through operandFlags, add enemy position for relative spawn, and opcode 95 calls KillAllNonBossEnemies." },
    { path := "reference/th08/src/EnemyTimeline.cpp"
      startLine := 64
      endLine := 115
      claim := "SpawnEnemy2 scans 480 enemy slots, copies the spawn template, calls CallEclSub, copies the active context integer array, immediately runs the spawned ECL context, and truncates itemDropType to i8." },
    { path := "reference/th08/src/EnemyManager.cpp"
      startLine := 1424
      endLine := 1498
      claim := "KillAllNonBossEnemies skips inactive, boss, and noDeath enemies, clears life, may spawn point items/popups, detaches parent chains, and may enter death callbacks." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 639
      endLine := 710
      claim := "TH08 item opcodes resolve item-drop state fields, power-or-point loops, point-only loops, and single item ids through operandFlags, with 128/64 random spread and default item state." },
    { path := "reference/th08/src/EnemyManager.hpp"
      startLine := 447
      endLine := 447
      claim := "EnemyManager stores eight boss pointers in bosses[8]." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 426
      endLine := 456
      claim := "High opcode 127 resolves slot 0, writes bosses[slot] for every nonnegative slot without an upper-bound check, only sets GUI bossPresent for slot 0, stores enemy->bossSlot as u8, and clears using the stored slot on the negative branch." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 18
      endLine := 36
      claim := "TH08 spellcard instruction operands contain i16 enemyFace, u16 spellCardNumber, i32 bonus, 48-byte encoded name/owner fields, and two 64-byte comment lines after the raw instruction prefix." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 541
      endLine := 548
      claim := "High opcodes 122 and 123 call StartEnemySpell and EndEnemySpell at the opcode boundary." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 38
      endLine := 56
      claim := "StartEnemySpell forwards spellCardNumber, encoded text, enemy face, bonus, and the enemy pointer to g_Spellcard.StartSpell; EndEnemySpell calls g_Spellcard.EndSpell." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 530
      endLine := 538
      claim := "High opcode 158 resolves four integer operands and writes GUI boss gauge slot start/stop ratios divided by enemy->maxLife plus gauge color without an opcode-level slot bound check." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 712
      endLine := 715
      claim := "High opcode 148 writes a resolved boss life marker count and also increments one spellcard history bonus field by 0x708." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 826
      endLine := 830
      claim := "High opcode 155 writes the raw low byte into timeoutSpell and sets g_Spellcard.scoreLimit to 99999990." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 856
      endLine := 862
      claim := "High opcode 164 resolves the effect-tracking flag first, always writes g_Spellcard.effectTrackingDisabled, and resolves/stores three float operands only when that value is zero." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 954
      endLine := 954
      claim := "High opcode 177 writes a resolved integer to phaseStartingLife." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 972
      endLine := 972
      claim := "High opcode 184 resolves one integer and forwards it to g_Spellcard.SetBonusUpdatesDisabled." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 690
      endLine := 692
      claim := "Low opcodes 84 and 85 are explicit ordinary-advance handlers." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 425
      endLine := 475
      claim := "High opcodes 163 and 159 resolve one integer into EnemyManager state and the enemy u8 draw group." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 711
      endLine := 711
      claim := "High opcode 147 resolves the pending background stage-script label." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 832
      endLine := 934
      claim := "The late enemy-state cluster includes raw-byte special interaction, signed-i16 trail setup and division, damage/pause timers, pause-mode flags, squared minimum distance, and the form-effect bit." },
    { path := "reference/th08/src/EclRunHigh.inl"
      startLine := 953
      endLine := 970
      claim := "The final host-state cluster controls timeline suppression, GUI background/clock calls, signed-i8 clock advancement with u8 wrap, and the extra-VM offset flag." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 712
      endLine := 727
      claim := "Low opcode 88 indexes and dereferences bosses[resolved slot] before calling into that enemy; opcode 89 null-guards one resolved slot but resolves the slot again for the pending-sub write." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 466
      endLine := 494
      claim := "CallSubOnEnemy advances the target instruction, optionally saves its active context before the depth guard, calls CallEclSub with an i16 sub id, copies 0x20 call-parameter bytes, and conditionally increments depth." },
    { path := "reference/th08/src/EclRunLow.inl"
      startLine := 729
      endLine := 918
      claim := "Low opcodes 90 through 92 share attachment-tail lookup, child spawn, repeated player-alignment reads, collision/effect initialization, parent-chain linking, count increment, and unconditional familiar-spawn sound; opcode 91 offsets by parent world position and opcode 92 installs inherited-position state." },
    { path := "reference/th08/src/EclDependencies.cpp"
      startLine := 570
      endLine := 644
      claim := "The attachment helper follows next pointers until null, while both child constructors gate on positive parent life and suppress-death-effects, resolve XY plus life/item/score, and call SpawnEnemy2 with active integer variables." },
    { path := "reference/th08/src/EnemyTimeline.cpp"
      startLine := 64
      endLine := 115
      claim := "SpawnEnemy2 scans 480 slots, i16-truncates the sub id, copies 0x78 active integer-variable bytes, runs the child ECL immediately, i8-truncates itemDropType, and reports failure through lastSpawnFailed." } ]

def headerShape : TouhouFormal.ECL.HeaderShape :=
  { title := title
    hasVersionField := true
    versionOffset := some 0
    expectedVersion := some expectedEclVersion
    subCountOffset := 4
    timelineCountOffset := 6
    timelineTableOffset := 8
    fixedHeaderBytes := rawHeaderFixedPrefixBytes
    timelineSlots := timelineOffsetCount
    loaderTimelineSlots := timelineOffsetCount
    subTableField := "subOffsets[1]"
    negativeSubIdPolicy := .noOp
    timelineShape :=
      some
        { fixedSize := timelineInstrFixedSize
          timeOffset := 0
          timeWidth := .i32
          opcodeOffset := 4
          opcodeWidth := .i16
          sizeOffset := 6
          sizeWidth := .u8
          firstArgOffset := some 8
          firstArgWidth := some .i32 }
    rawInstrShape :=
      some
        { fixedPrefixBytes := 12
          timeOffset := 0
          timeWidth := .i32
          opcodeOffset := 4
          opcodeWidth := .i16
          unimplementedOpcode := some 1
          nextOffsetOffset := 6
          nextOffsetWidth := .i16
          difficultyMaskOffset := some 9
          difficultyMaskWidth := some .u8
          difficultyMaskPolicy := some .containsActiveAndOverride
          operandMaskOffset := some 10
          operandMaskWidth := some .u16
          fixedI32OperandBaseOffset := some 12
          fixedI32OperandStride := 4
          fixedJumpShape :=
            some
              { opcode := eclOpcodeJump
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 }
          fixedDecJumpShape :=
            some
              { opcode := eclOpcodeDecJump
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1
                counterOperandIndex := 2 }
          intRValueResolver :=
            some
              { maskPolicy := .bitSetMeansResolve
                knownRValueSelectors :=
                  { ranges := [ { first := 10000, last := 10100 } ]
                    exclusions := [10079, 10080, 10081, 10082] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := 10000, last := 10015 },
                        { first := 10036, last := 10041 },
                        { first := 10049, last := 10049 },
                        { first := 10051, last := 10051 },
                        { first := 10053, last := 10056 },
                        { first := 10061, last := 10064 },
                        { first := 10092, last := 10093 } ]
                    exclusions := [] } }
          floatRValueResolver :=
            some
              { maskPolicy := .bitSetMeansResolve
                knownRValueSelectors :=
                  { ranges := [ { first := 1176256512, last := 1176358911 } ]
                    exclusions := []
                    excludedRanges := [ { first := 1176356864, last := 1176357887 } ] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := 1176272896, last := 1176289279 },
                        { first := 1176299520, last := 1176305663 },
                        { first := 1176314880, last := 1176318975 },
                        { first := 1176323072, last := 1176340479 },
                        { first := 1176352768, last := 1176354815 } ]
                    exclusions := [] } }
          intConditionJumps :=
            [ { opcode := eclOpcodeJumpIfEq
                op := .eq
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfNeq
                op := .neq
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLt
                op := .lt
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLeq
                op := .le
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGt
                op := .gt
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGeq
                op := .ge
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 } ]
          floatConditionJumps :=
            [ { opcode := eclOpcodeJumpIfEqFloat
                op := .eq
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfNeqFloat
                op := .neq
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLtFloat
                op := .lt
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLeqFloat
                op := .le
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGtFloat
                op := .gt
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGeqFloat
                op := .ge
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 } ]
          callRetShape :=
            some
              { callOpcode := eclOpcodeSubCall
                retOpcode := eclOpcodeSubRet
                subIdOperandIndex := 0
                stackEntryCount := 16
                stackIncrementGuardExclusive := 15
                retUnderflowPolicy := .th08ChildContextExit
                childContextSlotCount := 4 }
          scalarAssignments :=
            [ { opcode := eclOpcodeSetInt
                outputPolicy := .intLValue
                rvaluePolicy := .intBits
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeSetFloat
                outputPolicy := .floatLValue
                rvaluePolicy := .floatBits
                outputOperandIndex := 0
                valueOperandIndex := 1 } ]
          randomOps :=
            [ { opcode := eclOpcodeRandSign
                kind := .intSign
                outputPolicy := .intLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeRandSignFloat
                kind := .floatSign
                outputPolicy := .floatLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1 } ]
          movementOps :=
            [ { opcode := eclOpcodeSetPosition
                kind := .setPosition
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ]
                clampPosition := true
                zeroPositionZ := true },
              { opcode := eclOpcodeSetPolarVelocity
                kind := .setPolarVelocity
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ]
                anglePolicy := .derivedNormalizedInput
                modeUpdate := some .polar
                resetMovementTimers := true },
              { opcode := eclOpcodeMoveAtPlayer
                kind := .moveAtPlayer
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ]
                anglePolicy := .derivedNormalizedPlayerRelative },
              { opcode := eclOpcodeSetAngularVelocity
                kind := .setAngularVelocity
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeSetAcceleration
                kind := .setAcceleration
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeSetMovementBounds
                kind := .setBounds
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue },
                    { operandIndex := 3, policy := .floatRValue } ] },
              { opcode := eclOpcodeDisableMovementBounds
                kind := .disableBounds } ]
          randomDirectionOps :=
            [ { opcode := eclOpcodeMoveBoundaryAwareTimed
                generator := .playerSide
                boundaryPolicy := .rectangle .currentEnemyAngle
                outputPolicy := .hostAngle },
              { opcode := eclOpcodeRandomExitAngle
                generator := .arenaExit
                outputPolicy := .floatLValue 0 },
              { opcode := eclOpcodeMoveRandomBiasedTimed
                generator := .hostCandidate
                boundaryPolicy := .vertical
                outputPolicy := .hostAngle } ]
          timedMovementFamilies :=
            [ { firstOpcode := eclOpcodeMovePositionTimed
                lastOpcode := eclOpcodeMovePositionTimed
                kind := .position
                floatInputs :=
                  [ { role := .targetX, operandIndex := 2, policy := .rValue },
                    { role := .targetY, operandIndex := 3, policy := .rValue } ]
                durationPolicy := .intRValue
                easingPolicy := .intRValue 1
                originSource := .position
                deltaBaseSource := .worldPosition
                mirrorDeltaX := true
                zeroVelocity := true
                zeroTargetZ := true },
              { firstOpcode := eclOpcodeMoveDirectionTimed
                lastOpcode := eclOpcodeMoveDirectionTimed
                kind := .direction
                floatInputs :=
                  [ { role := .angle, operandIndex := 2, policy := .rValue },
                    { role := .speed, operandIndex := 3, policy := .rValue } ]
                durationPolicy := .intRValue
                easingPolicy := .intRValue 1
                nonpositivePolicy := .immediatePolarZeroTimers
                originSource := .worldPosition
                deltaBaseSource := .worldPosition
                normalizeDirectionAngle := true
                mirrorDeltaX := true },
              { firstOpcode := eclOpcodeMoveAtPlayerTimed
                lastOpcode := eclOpcodeMoveAtPlayerTimed
                kind := .playerDirection
                floatInputs :=
                  [ { role := .angle, operandIndex := 2, policy := .rValue },
                    { role := .speed, operandIndex := 3, policy := .rValue } ]
                durationPolicy := .intRValue
                easingPolicy := .intRValue 1
                nonpositivePolicy := .immediatePolarResolvedTimers
                originSource := .worldPosition
                deltaBaseSource := .worldPosition
                normalizeDirectionAngle := true
                mirrorDeltaX := true },
              { firstOpcode := eclOpcodeMoveBoundaryAwareTimed
                lastOpcode := eclOpcodeMoveBoundaryAwareTimed
                kind := .hostDirection
                floatInputs :=
                  [ { role := .speed, operandIndex := 2, policy := .rValue } ]
                durationPolicy := .intRValue
                easingPolicy := .intRValue 1
                nonpositivePolicy := .immediatePolarZeroTimers
                originSource := .worldPosition
                deltaBaseSource := .worldPosition },
              { firstOpcode := eclOpcodeMoveRandomBiasedTimed
                lastOpcode := eclOpcodeMoveRandomBiasedTimed
                kind := .hostDirection
                floatInputs :=
                  [ { role := .speed, operandIndex := 2, policy := .rValue } ]
                durationPolicy := .intRValue
                easingPolicy := .intRValue 1
                nonpositivePolicy := .immediatePolarZeroTimers
                originSource := .worldPosition
                deltaBaseSource := .worldPosition } ]
          orbitMovementOps :=
            [ { opcode := eclOpcodeMoveOrbit
                kind := .startFull
                floatInputs :=
                  [ { role := .originX, operandIndex := 1 },
                    { role := .originY, operandIndex := 2 },
                    { role := .angle, operandIndex := 3 },
                    { role := .angularVelocity, operandIndex := 4 },
                    { role := .radius, operandIndex := 5 },
                    { role := .radialVelocity, operandIndex := 6 } ]
                durationOperandIndex := some 0
                originZFromOperand := false },
              { opcode := eclOpcodeMoveOrbitFromPosition
                kind := .startFromCurrentPosition
                floatInputs :=
                  [ { role := .angle, operandIndex := 1 },
                    { role := .angularVelocity, operandIndex := 2 },
                    { role := .radialVelocity, operandIndex := 3 } ]
                durationOperandIndex := some 0 },
              { opcode := eclOpcodeSetOrbitVelocities
                kind := .setVelocities
                floatInputs :=
                  [ { role := .angularVelocity, operandIndex := 1 },
                    { role := .radialVelocity, operandIndex := 2 } ]
                durationOperandIndex := some 0 } ]
          enemyStateOps :=
            [ { opcode := eclOpcodeSetPrimaryHitbox
                kind := .setPrimaryHitbox 2
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetSecondaryHitbox
                kind := .setSecondaryHitbox 2
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeReplaceEnemyFlags
                kind := .replaceFlagMask
                intInputPolicy := some .intRValue },
              { opcode := eclOpcodeDisableEnemyFlags
                kind := .disableFlagMask
                intInputPolicy := some .intRValue },
              { opcode := eclOpcodeEnableEnemyFlags
                kind := .enableFlagMask
                intInputPolicy := some .intRValue },
              { opcode := eclOpcodeSetDeathMode
                kind := .setField .deathMode
                intInputPolicy := some .rawByte
                presentationGuard := true },
              { opcode := eclOpcodeSetLife
                kind := .setLife
                intInputPolicy := some .intRValue
                writePhaseStartingLife := true
                clearBossGaugeForPrimaryBoss := true },
              { opcode := eclOpcodeSetBossTimer
                kind := .setTimer
                intInputPolicy := some .intRValue } ]
          enemyLifecycleOps :=
            [ enemySpawnLifecycleOp eclOpcodeSpawnEnemyAbs .absolute,
              enemySpawnLifecycleOp eclOpcodeSpawnEnemyRel .relativeToEnemy,
              TouhouFormal.ECL.rawEnemyLifecycleRemoveAllOp
                eclOpcodeKillAllNonBossEnemies
                .killAllNonBossEnemies
                enemyPoolSlots ]
          itemOps :=
            [ TouhouFormal.ECL.rawItemSingleOp
                eclOpcodeSpawnItem
                (TouhouFormal.ECL.rawItemSingleInputs .intRValue),
              TouhouFormal.ECL.rawItemLoopOp
                eclOpcodeSpawnItems
                .powerOrPointByPlayerPower
                (TouhouFormal.ECL.rawItemLoopCountInputs .intRValue)
                128
                64,
              TouhouFormal.ECL.rawItemDropTypeOp
                eclOpcodeSetItemDropType
                (TouhouFormal.ECL.rawItemSingleInputs .intRValue),
              TouhouFormal.ECL.rawItemDropCountsOp
                eclOpcodeSetItemDropCounts
                (TouhouFormal.ECL.rawItemDropCountInputs .intRValue),
              TouhouFormal.ECL.rawItemLoopOp
                eclOpcodeSpawnPointItems
                .pointOnly
                (TouhouFormal.ECL.rawItemLoopCountInputs .intRValue)
                128
                64 ]
          bossLifecycleOps :=
            [ { opcode := eclOpcodeBeginSpellcard
                kind := .beginSpellcard
                intInputs :=
                  [ { role := .spellSprite
                      operandIndex := 0
                      policy := .rawI16
                      halfIndex := 0 },
                    { role := .spellId
                      operandIndex := 0
                      policy := .rawU16
                      halfIndex := 1 },
                    { role := .spellBonus
                      operandIndex := 1
                      policy := .rawI32 } ]
                spellTextPolicy := some (.th08EncodedRecord 48 48 64)
                beginHostStartSpell := true },
              { opcode := eclOpcodeEndSpellcard
                kind := .endSpellcard
                endHostEndSpell := true },
              { opcode := eclOpcodeSetBoss
                kind := .setBoss
                intInputs :=
                  [ { role := .bossSlot
                      operandIndex := 0
                      policy := .intRValue } ]
                bossSlotCount := 8
                bossSlotStoragePolicy := .u8
                setBossPresentPolicy := .primarySlotOnly
                clearBossPresentPolicy := .currentSlotBelowGuiSlots
                setHealthBarToFull := true
                resetMinimumPlayerDistance := true
                markerInterruptOnSet := some 1
                markerInterruptOnClear := some 2
                releaseAttachedEffectsOnClear := true
                moveMarkerOffscreenOnClear := true },
              { opcode := eclOpcodeSetBossLifeMarkerCount
                kind := .setLifeMarkerCount
                intInputs :=
                  [ { role := .lifeMarkerCount
                      operandIndex := 0
                      policy := .intRValue } ]
                lifeMarkerHistoryBonusDelta := some 0x708 },
              { opcode := eclOpcodeSetTimeoutSpell
                kind := .setTimeoutSpell
                intInputs :=
                  [ { role := .flagValue
                      operandIndex := 0
                      policy := .rawU8
                      byteIndex := 0 } ]
                timeoutScoreLimit := some 99999990 },
              { opcode := eclOpcodeSetBossGauge
                kind := .setBossGauge
                intInputs :=
                  [ { role := .gaugeSlot
                      operandIndex := 0
                      policy := .intRValue },
                    { role := .gaugeStart
                      operandIndex := 1
                      policy := .intRValue },
                    { role := .gaugeStop
                      operandIndex := 2
                      policy := .intRValue },
                    { role := .gaugeColor
                      operandIndex := 3
                      policy := .intRValue } ]
                bossGaugeSlotCount := 8 },
              { opcode := eclOpcodeSetSpellcardEffectTracking
                kind := .setSpellcardEffectTracking
                intInputs :=
                  [ { role := .flagValue
                      operandIndex := 0
                      policy := .intRValue } ]
                floatInputs :=
                  [ { role := .storedVectorX
                      operandIndex := 1
                      policy := .floatRValue },
                    { role := .storedVectorY
                      operandIndex := 2
                      policy := .floatRValue },
                    { role := .storedVectorZ
                      operandIndex := 3
                      policy := .floatRValue } ]
                effectTrackingStoresVectorWhenZero := true },
              { opcode := eclOpcodeSetPhaseStartingLife
                kind := .setPhaseStartingLife
                intInputs :=
                  [ { role := .phaseStartingLife
                      operandIndex := 0
                      policy := .intRValue } ] },
              { opcode := eclOpcodeSetSpellcardBonusUpdatesDisabled
                kind := .setSpellcardBonusUpdatesDisabled
                intInputs :=
                  [ { role := .flagValue
                      operandIndex := 0
                      policy := .intRValue } ] } ]
          hostEffectOps :=
            [ { opcode := eclOpcodeSpawnTrackedEffect
                kind := .spawnTrackedEffect
                floatInputs :=
                  [ { role := .vectorX, operandIndex := 1, policy := .rawBits },
                    { role := .vectorY, operandIndex := 2, policy := .rawBits },
                    { role := .vectorZ, operandIndex := 3, policy := .rawBits },
                    { role := .distance, operandIndex := 4, policy := .rawBits } ]
                trackedSlotCount := 24
                fixedEffectId := some 13
                fixedCount := some 1
                fixedColor := some 0xFF6060D0 },
              { opcode := eclOpcodePlayPositionedSound
                kind := .playSound
                intInputs :=
                  [ { role := .soundId, operandIndex := 0, policy := .intRValue } ]
                positionedSound := true },
              { opcode := eclOpcodeSpawnEffect
                kind := .spawnParticles false
                intInputs :=
                  [ { role := .effectId, operandIndex := 0, policy := .intRValue },
                    { role := .count, operandIndex := 1, policy := .intRValue },
                    { role := .color, operandIndex := 2, policy := .intPointerValue } ] },
              { opcode := eclOpcodeSpawnMovingEffect
                kind := .spawnParticles true
                intInputs :=
                  [ { role := .effectId, operandIndex := 0, policy := .intRValue },
                    { role := .count, operandIndex := 1, policy := .intRValue },
                    { role := .color, operandIndex := 2, policy := .intPointerValue } ]
                floatInputs :=
                  [ { role := .vectorX, operandIndex := 3, policy := .floatRValue },
                    { role := .vectorY, operandIndex := 4, policy := .floatRValue },
                    { role := .vectorZ, operandIndex := 5, policy := .floatRValue } ] },
              { opcode := eclOpcodeSpawnAlignmentEffect
                kind := .spawnAlignmentEffect
                intInputs :=
                  [ { role := .effectId, operandIndex := 0, policy := .intRValue } ]
                positionSource := .enemyWorldPosition
                effectIdBase := 0x20 } ]
          shootingOps :=
            [ { opcode := eclOpcodeSetShootInterval
                kind := .setInterval
                intInputPolicy := some .intRValue },
              { opcode := eclOpcodeSetRandomShootInterval
                kind := .setRandomizedInterval
                intInputPolicy := some .intRValue },
              { opcode := eclOpcodeDisableShooting
                kind := .disableShooting
                gatePolicy := .deferPattern },
              { opcode := eclOpcodeEnableShooting
                kind := .enableShooting
                gatePolicy := .deferPattern },
              { opcode := eclOpcodeSpawnPreviousPattern
                kind := .spawnPreviousPattern },
              { opcode := eclOpcodeSetShootOffset
                kind := .setShootOffset
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ]
                zeroOffsetZ := true } ]
          timeControlOps :=
            [ { opcode := eclOpcodeSetSecondaryTime
                kind := .setTimer .contextSecondaryTime
                intInput :=
                  some { operandIndex := 0, policy := .intRValue } },
              { opcode := eclOpcodeNoOp
                kind := .noOp },
              { opcode := eclOpcodeAddTime
                kind := .addToTime
                intInput :=
                  some { operandIndex := 0, policy := .intRValue } } ]
          bulletControlOps :=
            [ { opcode := eclOpcodeClearBulletsForTransition
                kind := .clear .clearForTransition },
              { opcode := eclOpcodeSetBulletSound
                kind := .setSound
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue },
                    { operandIndex := 1, policy := .intRValue } ]
                soundTarget := .bulletSpawnDescriptor
                soundHasOverride := true
                soundRepeatsPrimaryOnEnable := true },
              { opcode := eclOpcodeSetBulletRankInfluence
                kind := .setRankInfluence
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ]
                intInputs :=
                  [ { operandIndex := 2, policy := .intRValue },
                    { operandIndex := 3, policy := .intRValue },
                    { operandIndex := 4, policy := .intRValue },
                    { operandIndex := 5, policy := .intRValue } ] },
              { opcode := eclOpcodeRemoveBulletsRadius
                kind := .clear .removeRadius
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ] },
              { opcode := eclOpcodeRemoveAllBulletsMode4
                kind := .clear (.removeAllMode 4) } ]
          bulletTransformOps :=
            [ { opcode := eclOpcodeInitBulletTransform
                kind := .transformRecord
                intInputs :=
                  [ { role := .index, operandIndex := 0 },
                    { role := .kind, operandIndex := 1 },
                    { role := .allowWhileActive, operandIndex := 2 },
                    { role := .payloadInt0, operandIndex := 3 },
                    { role := .payloadInt1, operandIndex := 4 } ]
                floatInputs :=
                  [ { role := .payloadFloat0, operandIndex := 5 },
                    { role := .payloadFloat1, operandIndex := 6 } ]
                tableCount := 18 } ]
          laserSpawnOps :=
            [ laserSpawnOp eclOpcodeSpawnLaserFixed .fixed,
              laserSpawnOp eclOpcodeSpawnLaserAimed .aimedAtPlayer ]
          laserOps :=
            [ { opcode := eclOpcodeSetLaserIdx
                kind := .setSelectedSlot
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeAddLaserAngle
                kind := .writeAngle .addNormalized
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetLaserAngle
                kind := .writeAngle .set
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeAimLaserAngleAtPlayer
                kind := .writeAngle .aimAtPlayer
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetLaserPosRel
                kind := .writeRelativePosition
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue },
                    { operandIndex := 3, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetLaserHideCapDuringStartup
                kind := .writeHideWarning
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue },
                    { operandIndex := 1, policy := .intRValue } ]
                hideTruncatesToU8 := true },
              { opcode := eclOpcodeTestLaserInUse
                kind := .testInUse
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                testTarget := .extraIntVariable 2
                testActiveValue := 1
                testInactiveValue := 0 },
              { opcode := eclOpcodeStopLaser
                kind := .stop
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                stopCopiesCurrentWidth := true },
              { opcode := eclOpcodeClearLasers
                kind := .clearAll
                slotCount := laserSlotCount },
              { opcode := eclOpcodeSetLaserStartLength
                kind := .writeStartLength
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetLaserOffsets
                kind := .writeOffsets
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ] } ]
          animationOps :=
            [ { opcode := eclOpcodeSetPrimaryAnm
                kind := .setPrimaryScript
                scriptSource := some (.intRValue 0)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                setAlternateBankFlag := some false },
              { opcode := eclOpcodeSetPrimaryAnmSequential
                kind := .setPrimaryScriptTableSequential
                scriptSource := some (.intRValue 0)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                setAlternateBankFlag := some false },
              { opcode := eclOpcodeSetPrimaryAnmExplicit
                kind := .setPrimaryScriptTableExplicit
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue },
                    { operandIndex := 1, policy := .intRValue },
                    { operandIndex := 2, policy := .intRValue },
                    { operandIndex := 3, policy := .intRValue },
                    { operandIndex := 4, policy := .intRValue },
                    { operandIndex := 5, policy := .intRValue } ]
                setAlternateBankFlag := some false },
              { opcode := eclOpcodeSetExtraAnm
                kind := .setSecondaryScript
                bankPolicy := .runtimeFlag
                secondaryAccess :=
                  some
                    { slotCount := secondaryAnmVmCount
                      slotInput := { operandIndex := 0, policy := .intRValue }
                      scriptInput := { operandIndex := 1, policy := .intRValue }
                      scriptMode := .runWhenNonnegativeElseClear
                      repeatedSlotReadForAccess := true
                      repeatedScriptReadForHostCall := true }
                setAlternateBankFlag := some false },
              { opcode := eclOpcodeSetAlternateAnm
                kind := .setPrimaryScript
                bankPolicy := .fixed .alternate
                scriptSource := some (.intRValue 0)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                setAlternateBankFlag := some true },
              { opcode := eclOpcodeSetAlternateAnmSequential
                kind := .setPrimaryScriptTableSequential
                bankPolicy := .fixed .alternate
                scriptSource := some (.intRValue 0)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ]
                setAlternateBankFlag := some true },
              { opcode := eclOpcodeSetAlternateAnmExplicit
                kind := .setPrimaryScriptTableExplicit
                bankPolicy := .fixed .alternate
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue },
                    { operandIndex := 1, policy := .intRValue },
                    { operandIndex := 2, policy := .intRValue },
                    { operandIndex := 3, policy := .intRValue },
                    { operandIndex := 4, policy := .intRValue },
                    { operandIndex := 5, policy := .intRValue } ]
                setAlternateBankFlag := some true },
              { opcode := eclOpcodeSetAlternateExtraAnm
                kind := .setSecondaryScript
                bankPolicy := .fixed .alternate
                secondaryAccess :=
                  some
                    { slotCount := secondaryAnmVmCount
                      slotInput := { operandIndex := 0, policy := .intRValue }
                      scriptInput := { operandIndex := 1, policy := .intRValue }
                      scriptMode := .runWhenNonnegativeElseClear
                      repeatedSlotReadForAccess := true
                      repeatedScriptReadForHostCall := true }
                setAlternateBankFlag := some true },
              { opcode := eclOpcodePlaySpecialAnm
                kind := .playPrimarySpecialScript
                bankPolicy := .runtimeFlag
                scriptSource := some .runtimeSpecial },
              { opcode := eclOpcodeSetDeathAnm
                kind := .setDeathScripts
                intInputs :=
                  [ { operandIndex := 0, policy := .rawByte, byteIndex := 0 },
                    { operandIndex := 0, policy := .rawByte, byteIndex := 1 },
                    { operandIndex := 0, policy := .rawByte, byteIndex := 2 } ] },
              { opcode := eclOpcodeSetRotateAnmWithMovement
                kind := .setAutoRotate
                intInputs :=
                  [ { operandIndex := 0, policy := .rawByte } ] },
              { opcode := eclOpcodeSetPrimaryVmInterrupt
                kind := .setPrimaryInterrupt
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetSecondaryVmInterrupt
                kind := .setSecondaryInterrupt
                secondaryAccess :=
                  some
                    { slotCount := secondaryAnmVmCount
                      diagnoseHighOnly := false
                      slotInput := { operandIndex := 0, policy := .rawI32 }
                      interruptInput :=
                        { operandIndex := 1, policy := .rawU16ToI16 } } },
              { opcode := eclOpcodeSetPrimaryVmRotZ
                kind := .setPrimaryRotationZ
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ] } ]
          bulletPatternFamilies :=
            [ { firstOpcode := eclOpcodeSpawnBulletPatternFirst
                lastOpcode := eclOpcodeSpawnBulletPatternLast
                bulletTypePolicy := .intRValue
                rankPolicy := .unlessSpellcardActive
                skipWhenEnemyDead := true
                gatePolicy := .deferPattern
                deferredCopyBytes := 0x2c
                filterPlayerAlignment := true
                filterMinimumPlayerDistance := true } ]
          callbackConfigOps :=
            [ { opcode := eclOpcodeSetDeathCallbackSub
                kind := .setDeathSub
                intPolicy := .rawU16ToI16
                guardAllWritesByPresentation := true },
              { opcode := eclOpcodeSetLifeCallback
                kind := .setLifePairIndexed
                guardSubWriteByPresentation := true },
              { opcode := eclOpcodeSetTimerCallback
                kind := .setTimerPair
                guardSubWriteByPresentation := true
                resetBossTimer := true },
              { opcode := eclOpcodeBindTimerCallbackToDeath
                kind := .bindTimerToDeath
                resetBossTimer := true } ]
          interruptOps :=
            [ { opcode := eclOpcodeSetInterrupt
                kind := .setTableEntry
                intPolicy := .intRValue
                tableEntryCount := 32
                truncateStoredSubToI16 := true },
              { opcode := eclOpcodeRunInterrupt
                kind := .run
                intPolicy := .intRValue
                tableEntryCount := 32
                truncateRunIndexToI16 := true },
              { opcode := eclOpcodeSetCallStackDisabled
                kind := .setStackDisabled
                intPolicy := .rawU8 } ]
          extensionOps :=
            [ { opcode := eclOpcodeRunExtension
                kind := .callNow
                intPolicy := .intRValue
                tableEntryCount := 32 },
              { opcode := eclOpcodeSetExtension
                kind := .installPerFrame
                intPolicy := .intRValue
                tableEntryCount := 32
                repeatIndexReadOnInstall := true } ]
          childContextOps :=
            [ { opcode := eclOpcodeSetChildContext
                intPolicy := .intRValue
                slotCount := 4
                repeatSubReadAfterAllocation := true
                truncateCallSubToI16 := true
                blockByteCount := 0x24b0
                copiedVariableBytes := 0x78 } ]
          miscOps :=
            [ { opcode := eclOpcodeOrdinaryAdvance84
                kind := .noOp },
              { opcode := eclOpcodeOrdinaryAdvance85
                kind := .noOp },
              { opcode := eclOpcodeSetMinimumPlayerDistance
                kind := .setMinimumPlayerDistance
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetFormEffect
                kind := .writeInt .enemyFormEffect (.unsignedBits 1)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetBackgroundLabel
                kind := .writeInt .backgroundPendingLabel .identityI32
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetSpecialInteraction
                kind := .setSpecialInteraction
                intInputs :=
                  [ { operandIndex := 0, policy := .rawByte } ] },
              { opcode := eclOpcodeSetTrail
                kind := .configureTrail
                intInputs :=
                  [ { operandIndex := 0, policy := .rawByte },
                    { operandIndex := 1, policy := .intRValue },
                    { operandIndex := 2, policy := .intRValue },
                    { operandIndex := 3, policy := .intRValue } ] },
              { opcode := eclOpcodeSetDrawGroup
                kind := .writeInt .enemyDrawGroup (.unsignedBits 8)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetDamageReductionTimer
                kind := .writeTimer .damageReduction
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetEnemyManagerValue
                kind := .writeInt .enemyManagerOpcode163 .identityI32
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetPauseTimer
                kind := .writeInt .enemyPauseTimer (.unsignedBits 1)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSuppressTimelineSpawns
                kind := .writeInt .suppressTimelineSpawns .identityI32
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeConfigurePause
                kind := .configurePause },
              { opcode := eclOpcodeStartStageBackground
                kind := .gui .startStageBackgroundSequence },
              { opcode := eclOpcodeHideClock
                kind := .gui .hideClockTime },
              { opcode := eclOpcodeAdvanceClock
                kind := .advanceClock },
              { opcode := eclOpcodeSetExtraVmFixedOffset
                kind := .writeInt .enemyExtraVmFixedOffset (.unsignedBits 1)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetNoDamageDuringStop
                kind := .writeInt .enemyNoDamageDuringStop (.unsignedBits 1)
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] } ]
          bossDispatchOps :=
            [ { opcode := eclOpcodeCallBossSub
                kind := .callSubOnBoss
                subIdPolicy := .rawI32
                bossSlotCount := 8 },
              { opcode := eclOpcodeSetBossPendingSub
                kind := .setPendingSubOnBoss
                subIdPolicy := .intRValue
                bossSlotCount := 8
                repeatBossIndexRead := true } ]
          linkedChildOps :=
            [ { opcode := eclOpcodeSpawnLinkedChild
                positionMode := .scriptPosition
                intInputs := linkedChildIntInputs
                floatInputs := linkedChildFloatInputs
                poolSearchSlots := enemyPoolSlots
                contextCopyBytes := 0x78 },
              { opcode := eclOpcodeSpawnLinkedChildAtParentOffset
                positionMode := .parentWorldOffset
                intInputs := linkedChildIntInputs
                floatInputs := linkedChildFloatInputs
                poolSearchSlots := enemyPoolSlots
                contextCopyBytes := 0x78 },
              { opcode := eclOpcodeSpawnLinkedChildInheritingPosition
                positionMode := .scriptPosition
                intInputs := linkedChildIntInputs
                floatInputs := linkedChildFloatInputs
                poolSearchSlots := enemyPoolSlots
                contextCopyBytes := 0x78
                setParentPositionOffset := true
                inheritParentPosition := true
                effectPositionSource := .childWorldPosition } ]
          intUnaryUpdates :=
            [ { opcode := eclOpcodeInc
                kind := .inc
                outputPolicy := .intLValue
                outputOperandIndex := 0 },
              { opcode := eclOpcodeDec
                kind := .dec
                outputPolicy := .intLValue
                outputOperandIndex := 0 } ]
          intBinaryOps :=
            [ { opcode := eclOpcodeIntAddInPlace
                kind := .add
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeIntSubInPlace
                kind := .sub
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeIntMulInPlace
                kind := .mul
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeIntDivInPlace
                kind := .div
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeIntModInPlace
                kind := .mod
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeIntAdd
                kind := .add
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntSub
                kind := .sub
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntMul
                kind := .mul
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntDiv
                kind := .div
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntMod
                kind := .mod
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 } ]
          floatBinaryOps :=
            [ { opcode := eclOpcodeFloatAddInPlace
                kind := .add
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeFloatSubInPlace
                kind := .sub
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeFloatMulInPlace
                kind := .mul
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeFloatDivInPlace
                kind := .div
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeFloatModInPlace
                kind := .mod
                mode := .updateInPlace
                outputOperandIndex := 0
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeFloatAdd
                kind := .add
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatSub
                kind := .sub
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatMul
                kind := .mul
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatDiv
                kind := .div
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatMod
                kind := .mod
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 } ]
          floatFunctions :=
            [ { opcode := eclOpcodeSin
                kind := .sin
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [1] },
              { opcode := eclOpcodeCos
                kind := .cos
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [1] },
              { opcode := eclOpcodeVectorAngle
                kind := .vectorAngle
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [1, 2, 3, 4] },
              { opcode := eclOpcodeNormalizeAngle
                kind := .normalizeAngle
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [0] } ]
          numericSpecialOps :=
            [ { opcode := eclOpcodeLerp
                kind := .lerp
                outputPolicy := .floatLValue
                outputOperandIndices := [0]
                inputOperandIndices := [1, 2, 3, 2] },
              { opcode := eclOpcodePolarToCartesian
                kind := .polarToCartesian
                outputPolicy := .floatLValue
                outputOperandIndices := [1, 0]
                inputOperandIndices := [2, 3, 2, 3] },
              { opcode := eclOpcodeDistance2d
                kind := .distance2d
                outputPolicy := .floatLValue
                outputOperandIndices := [0]
                inputOperandIndices := [1, 3, 2, 4] },
              { opcode := eclOpcodeVectorFromAngleMagnitude
                kind := .polarToCartesian
                outputPolicy := .floatLValue
                outputOperandIndices := [1, 0]
                inputOperandIndices := [2, 3, 2, 3] } ]
          interpolationOps :=
            [ { opcode := eclOpcodeInstallInterpolation } ]
          bossIntReads :=
            [ { opcode := eclOpcodeGetBossInt
                outputOperandIndex := 0
                valueOperandIndex := 1
                bossIndexOperandIndex := 2
                bossSlotCount := 8
                nullDerefValueSelectors :=
                  { ranges := [ { first := 10000, last := 10000 } ]
                    exclusions := [] } } ]
          bossFloatReads :=
            [ { opcode := eclOpcodeGetBossFloat
                outputOperandIndex := 0
                valueOperandIndex := 1
                bossIndexOperandIndex := 2
                bossSlotCount := 8
                nullPolicy := .guardedSkip
                nullDerefValueSelectors :=
                  { ranges := [ { first := 1176272896, last := 1176289279 } ]
                    exclusions := [] } } ]
          intDivisorHazards :=
            [ { opcode := eclOpcodeIntDivInPlace
                kind := .div
                divisorOperandIndex := 1 },
              { opcode := eclOpcodeIntModInPlace
                kind := .mod
                divisorOperandIndex := 1 },
              { opcode := eclOpcodeIntDiv
                kind := .div
                divisorOperandIndex := 2 },
              { opcode := eclOpcodeIntMod
                kind := .mod
                divisorOperandIndex := 2 } ] }
    evidence := eclEvidence }

theorem headerShape_timelineTableEnd :
    headerShape.timelineTableEnd = rawHeaderFixedPrefixBytes := by
  rfl

theorem headerShape_loaderTimelineSlots :
    headerShape.loaderTimelineSlots = timelineOffsetCount := by
  rfl

end TouhouFormal.TH08
