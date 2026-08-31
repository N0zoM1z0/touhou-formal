import TouhouFormal.Core.Bytes
import TouhouFormal.TH08.ANM
import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Loader
import TouhouFormal.ECL.Timeline
import TouhouFormal.TH08.Wire

namespace TouhouFormal.TH08

def oneSubOffsets : Array Nat :=
  #[rawHeaderFixedPrefixBytes]

def arg0_256Fault : TouhouFormal.Fault :=
  TouhouFormal.ECL.subTableOobFault headerShape 256 oneSubOffsets.size

def rawWrongVersionHeader : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 0x700 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.zeroBytes 64).toArray

def rawTimelinePrefixBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 441 ++
    TouhouFormal.leU16Bytes 0 ++
    [TouhouFormal.byteOfNat timelineInstrFixedSize, TouhouFormal.byteOfNat 0xff] ++
    TouhouFormal.leU32Bytes 256 ++
    TouhouFormal.zeroBytes 24).toArray

def rawInstrPrefixBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 441 ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU16Bytes 12 ++
    [TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0xff] ++
    TouhouFormal.leU16Bytes 3).toArray

def rawJumpMinusOneInstrBytes : TouhouFormal.Bytes :=
  (TouhouFormal.leU32Bytes 441 ++
    TouhouFormal.leU16Bytes eclOpcodeJump.toNat ++
    TouhouFormal.leU16Bytes 12 ++
    [TouhouFormal.byteOfNat 0, TouhouFormal.byteOfNat 0xff] ++
    TouhouFormal.leU16Bytes 0 ++
    TouhouFormal.leU32Bytes 0 ++
    TouhouFormal.leU32Bytes 0xffffffff).toArray

theorem negative_sub_id_noops :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets (-1) =
      .ok (none : Option Nat) := by
  rfl

theorem arg0_256_uses_shared_positive_lookup :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets 256 =
      .error arg0_256Fault := by
  rfl

theorem wrong_version_rejects_before_rebase :
    TouhouFormal.ECL.loadHeaderOffsets headerShape rawWrongVersionHeader =
      .error (.rejected (.versionMismatch expectedEclVersion 0x700)) := by
  rfl

theorem timeline_prefix_decodes_th08_shape :
    TouhouFormal.ECL.decodeTimelinePrefix headerShape rawTimelinePrefixBytes 0 =
      .ok
        { fileOffset := 0
          time := 441
          opcode := 0
          size := Int.ofNat timelineInstrFixedSize
          firstArg := some 256 } := by
  rfl

theorem raw_instr_prefix_decodes_shared_shape :
    TouhouFormal.ECL.decodeRawInstrPrefix headerShape rawInstrPrefixBytes 0 =
      .ok
        { fileOffset := 0
          time := 441
          opcode := 0
          nextOffset := 12
          difficultyMask := some 255
          operandMask := some 3 } := by
  rfl

def rawJumpMinusOneOperands : Except TouhouFormal.Fault TouhouFormal.ECL.RawJumpOperands :=
  match TouhouFormal.ECL.decodeRawInstrPrefix headerShape rawJumpMinusOneInstrBytes 0 with
  | .ok rawPrefix =>
      TouhouFormal.ECL.decodeProfileFixedJumpOperands headerShape rawJumpMinusOneInstrBytes rawPrefix
  | .error faultValue => .error faultValue

theorem raw_jump_minus_one_operands_decode :
    rawJumpMinusOneOperands =
      .ok
        { targetTime := 0
          displacement := -1 } := by
  rfl

theorem raw_jump_minus_one_after_jump_faults :
    TouhouFormal.ECL.decodeRawInstrPrefixAfterRelativeJump
      headerShape
      rawJumpMinusOneInstrBytes
      { fileOffset := 0
        time := 441
        opcode := eclOpcodeJump
        nextOffset := 12
        difficultyMask := some 255
        operandMask := some 0 }
      { targetTime := 0
        displacement := -1 } =
      .error
        (Fault.outOfBoundsRead
          title
          "EclRun.decode.cursor"
          "raw ECL instruction cursor moved before the beginning of the ECL buffer"
          (-1)
          rawJumpMinusOneInstrBytes.size) := by
  rfl

end TouhouFormal.TH08
