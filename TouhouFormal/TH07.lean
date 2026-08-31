import TouhouFormal.Core.Bytes
import TouhouFormal.TH07.ANM
import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Instruction
import TouhouFormal.TH07.Wire

namespace TouhouFormal.TH07

def oneSubOffsets : Array Nat :=
  #[rawHeaderFixedPrefixBytes]

def arg0_256Fault : TouhouFormal.Fault :=
  TouhouFormal.ECL.subTableOobFault headerShape 256 oneSubOffsets.size

def negativeSubIdFault : TouhouFormal.Fault :=
  TouhouFormal.ECL.subTableOobFault headerShape (-1) oneSubOffsets.size

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

theorem arg0_256_uses_shared_unchecked_lookup :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets 256 =
      .error arg0_256Fault := by
  rfl

theorem negative_sub_id_faults :
    TouhouFormal.ECL.lookupSubOffset headerShape oneSubOffsets (-1) =
      .error negativeSubIdFault := by
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

end TouhouFormal.TH07
