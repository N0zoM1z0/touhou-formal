import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH08

def title : String := "TH08"

def rawHeaderFixedPrefixBytes : Nat := 0x48
def expectedEclVersion : Nat := 0x800
def timelineOffsetCount : Nat := 16
def timelineInstrFixedSize : Nat := 0x24
def eclOpcodeJump : Int := 4
def eclOpcodeDecJump : Int := 5
def eclOpcodeJumpIfEq : Int := 40
def eclOpcodeJumpIfNeq : Int := 42
def eclOpcodeJumpIfLt : Int := 44
def eclOpcodeJumpIfLeq : Int := 46
def eclOpcodeJumpIfGt : Int := 48
def eclOpcodeJumpIfGeq : Int := 50

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
    { path := "reference/th08/src/EclOperandsInt.cpp"
      startLine := 26
      endLine := 150
      claim := "ResolveInt maps known selector ids to host/context values and returns the raw operand in the default case." },
    { path := "reference/th08/src/EclOperandsInt.cpp"
      startLine := 156
      endLine := 200
      claim := "ResolveIntLValue maps a smaller writable selector subset and returns the raw operand pointer when the bit is clear or selector is unknown." },
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
      startLine := 140
      endLine := 169
      claim := "CompareOperands evaluates integer operations 0,2,4,6,8,10 over ReadInt slots 0 and 1, then taken branches set time from RawInt(2) and jump by RawInt(3)." },
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
      claim := "Timeline spawn opcodes pass args.ints[0] into SpawnEnemy1, which then calls CallEclSub." } ]

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
          intDivisorHazards :=
            [ { opcode := 13
                kind := .div
                divisorOperandIndex := 1 },
              { opcode := 14
                kind := .mod
                divisorOperandIndex := 1 },
              { opcode := 23
                kind := .div
                divisorOperandIndex := 2 },
              { opcode := 24
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
