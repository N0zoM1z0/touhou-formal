import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH07

def title : String := "TH07"

def rawHeaderFixedPrefixBytes : Nat := 0x44
def timelinePointerCount : Nat := 16
def timelineInstrFixedSize : Nat := 0x20
def eclOpcodeJump : Int := 2
def eclOpcodeDecJump : Int := 3
def eclOpcodeJumpIfEq : Int := 28
def eclOpcodeJumpIfNeq : Int := 30
def eclOpcodeJumpIfLt : Int := 32
def eclOpcodeJumpIfLeq : Int := 34
def eclOpcodeJumpIfGt : Int := 36
def eclOpcodeJumpIfGeq : Int := 38
def eclOpcodeSetInt : Int := 4
def eclOpcodeSetFloat : Int := 5
def eclOpcodeIntAdd : Int := 12
def eclOpcodeIntSub : Int := 13
def eclOpcodeIntMul : Int := 14
def eclOpcodeIntDiv : Int := 15
def eclOpcodeIntMod : Int := 16
def eclOpcodeInc : Int := 17
def eclOpcodeDec : Int := 18
def eclOpcodeFloatAdd : Int := 19
def eclOpcodeFloatSub : Int := 20
def eclOpcodeFloatMul : Int := 21
def eclOpcodeFloatDiv : Int := 22
def eclOpcodeFloatMod : Int := 23
def eclOpcodeGetBossInt : Int := 43
def eclOpcodeGetBossFloat : Int := 44
def eclOpcodeSubCall : Int := 41
def eclOpcodeSubRet : Int := 42

def eclEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 277
      endLine := 285
      claim := "EclRawHeader stores subCount, timelineCount, sixteen timeline pointers, and subTable[]." },
    { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 291
      endLine := 305
      claim := "EclRawInstr stores time, id, size, difficulty skip byte, paramMask, and variable args." },
    { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 317
      endLine := 324
      claim := "EclTimelineInstr stores i16 time, arg0, opcode, size, and six AnyArg payload slots." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 23
      endLine := 33
      claim := "GET_INT_VALUE checks paramMask bit idx; a clear bit uses the raw operand and a set bit resolves the var id." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 70
      endLine := 101
      claim := "Load rebases sixteen timeline pointers and subTable entries for i < subCount." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 106
      endLine := 114
      claim := "CallEclSub reads this->subTable[subId] without checking subId." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 116
      endLine := 264
      claim := "GetVarValue resolves known ECL var ids and returns the raw operand value in the default case." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 268
      endLine := 323
      claim := "GetVar returns the raw operand cell when its paramMask bit is clear, maps a smaller writable selector subset when set, and defaults to the raw operand cell." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1011
      endLine := 1045
      claim := "Integer ADD/SUB/MUL/DIV/MOD write through GET_INT_PTR slot 0 and read operand slots 1 and 2 through GET_INT_VALUE." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1015
      endLine := 1049
      claim := "Float ADD/SUB/MUL/DIV/MOD write through GET_FLOAT_PTR slot 0 and read operand slots 1 and 2 through GET_FLOAT_VALUE; MOD_FLOAT uses fmodf." },
    { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 114
      endLine := 123
      claim := "TH07 assigns float arithmetic opcodes ECL_ADD_FLOAT=19 through ECL_MOD_FLOAT=23 alongside integer ADD=12 through MOD=16." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1001
      endLine := 1005
      claim := "ECL_GET_BOSS_INT writes slot 0 from GET_INT_VALUE(g_EnemyManager.bosses[GET_INT_VALUE(enemy, 2)], 1), so slot 1's mask bit decides whether a boss pointer is dereferenced." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 327
      endLine := 482
      claim := "GetFloatVarValue casts the f32 operand to i32, resolves known float selector ids, and returns the raw float operand in the default case." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 486
      endLine := 571
      claim := "GetFloatVar returns the raw f32 operand cell when the mask bit is clear, maps a writable float selector subset when set, and otherwise defaults to the raw f32 operand cell." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1006
      endLine := 1010
      claim := "ECL_GET_BOSS_FLOAT writes slot 0 from GET_FLOAT_VALUE(g_EnemyManager.bosses[GET_INT_VALUE(enemy, 2)], 1), so it shares boss index semantics with ECL_GET_BOSS_INT but uses float operand resolution." },
    { path := "reference/th07/src/th07/EnemyManager.hpp"
      startLine := 378
      endLine := 378
      claim := "EnemyManager stores eight boss pointers in bosses[8]." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 946
      endLine := 954
      claim := "DEC_JUMP decrements operand slot 2 and falls through to JUMP only while the decremented value is positive." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 956
      endLine := 961
      claim := "SET_INT writes GET_INT_PTR slot 0 from GET_INT_VALUE slot 1, while SET_FLOAT writes GET_FLOAT_PTR slot 0 from GET_FLOAT_VALUE slot 1." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 995
      endLine := 999
      claim := "INC and DEC update GET_INT_PTR slot 0 in place by +1 or -1." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1035
      endLine := 1037
      claim := "DIV performs integer division by operand slot 2 without a zero-divisor guard." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1043
      endLine := 1045
      claim := "MOD performs integer modulo by operand slot 2 without a zero-divisor guard." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1092
      endLine := 1166
      claim := "Integer JUMP_IF_* opcodes compare resolved operand slots 0 and 1, then taken branches set time from slot 2 and jump by slot 3." } ]
    ++
    [ { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1168
        endLine := 1195
        claim := "SUB_CALL saves the next instruction context at savedContextStack[stackDepth] before CallEclSub and increments depth only while stackDepth < ENEMY_STACK_SIZE; SUB_RET decrements stackDepth before restoring savedContextStack[stackDepth]." },
      { path := "reference/th07/src/th07/EnemyManager.hpp"
        startLine := 62
        endLine := 134
        claim := "ENEMY_STACK_SIZE is 15, and Enemy stores savedContextStack[ENEMY_STACK_SIZE + 1] plus signed stackDepth." } ]

def headerShape : TouhouFormal.ECL.HeaderShape :=
  { title := title
    hasVersionField := false
    versionOffset := none
    expectedVersion := none
    subCountOffset := 0
    timelineCountOffset := 2
    timelineTableOffset := 4
    fixedHeaderBytes := rawHeaderFixedPrefixBytes
    timelineSlots := timelinePointerCount
    loaderTimelineSlots := timelinePointerCount
    subTableField := "subTable[]"
    negativeSubIdPolicy := .unchecked
    timelineShape :=
      some
        { fixedSize := timelineInstrFixedSize
          timeOffset := 0
          timeWidth := .i16
          opcodeOffset := 4
          opcodeWidth := .i16
          sizeOffset := 6
          sizeWidth := .i16
          firstArgOffset := some 2
          firstArgWidth := some .i16 }
    rawInstrShape :=
      some
        { fixedPrefixBytes := 12
          timeOffset := 0
          timeWidth := .u32
          opcodeOffset := 4
          opcodeWidth := .i16
          unimplementedOpcode := some 1
          nextOffsetOffset := 6
          nextOffsetWidth := .i16
          difficultyMaskOffset := some 9
          difficultyMaskWidth := some .u8
          difficultyMaskPolicy := some .intersectsActive
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
                  { ranges := [ { first := 10000, last := 10073 } ]
                    exclusions := [10057, 10058, 10059, 10060] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := 10000, last := 10003 },
                        { first := 10012, last := 10017 },
                        { first := 10025, last := 10025 },
                        { first := 10027, last := 10027 },
                        { first := 10029, last := 10032 },
                        { first := 10037, last := 10040 },
                        { first := 10070, last := 10071 } ]
                    exclusions := [] } }
          floatRValueResolver :=
            some
              { maskPolicy := .bitSetMeansResolve
                knownRValueSelectors :=
                  { ranges := [ { first := 1176256512, last := 1176332287 } ]
                    exclusions := [] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := 1176260608, last := 1176268799 },
                        { first := 1176274944, last := 1176281087 },
                        { first := 1176290304, last := 1176294399 },
                        { first := 1176298496, last := 1176312831 },
                        { first := 1176314880, last := 1176317951 },
                        { first := 1176330240, last := 1176332287 } ]
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
          callRetShape :=
            some
              { callOpcode := eclOpcodeSubCall
                retOpcode := eclOpcodeSubRet
                subIdOperandIndex := 0
                stackEntryCount := 16
                stackIncrementGuardExclusive := 15
                retUnderflowPolicy := .uncheckedSavedContextRead
                childContextSlotCount := 0 }
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
            [ { opcode := eclOpcodeIntAdd
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
            [ { opcode := eclOpcodeFloatAdd
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
                nullPolicy := .unguardedDeref
                nullDerefValueSelectors :=
                  { ranges := [ { first := 1176260608, last := 1176268799 } ]
                    exclusions := [] } } ]
          intDivisorHazards :=
            [ { opcode := eclOpcodeIntDiv
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
    headerShape.loaderTimelineSlots = timelinePointerCount := by
  rfl

end TouhouFormal.TH07
