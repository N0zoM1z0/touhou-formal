import TouhouFormal.ECL.LinkedChild
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.LinkedChild

open TouhouFormal.ECL

def linkedChildOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.linkedChildOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawLinkedChildOutcome) :
    Option RawLinkedChildEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawLinkedChildOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def outcomeAction?
    (result : Except TouhouFormal.Fault RawLinkedChildOutcome) :
    Option RawLinkedChildAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeCursor?
    (result : Except TouhouFormal.Fault RawLinkedChildOutcome) : Option Int :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.targetCursor

def preparedReadOrder?
    (result : Except TouhouFormal.Fault RawLinkedChildOutcome) :
    Option (List RawLinkedChildReadRole) :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared.map (fun prepared => prepared.readOrder)

def linkedPrefix (opcode : Int) : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := opcode
    nextOffset := 36
    difficultyMask := some 1
    operandMask := some 0x3e }

def validIntInputs : List RawLinkedChildIntInput :=
  [ { rawValue := 70000 },
    { rawValue := 10000, hostValue := 150 },
    { rawValue := 10001, hostValue := 255 },
    { rawValue := 10002, hostValue := 2500 } ]

def validFloatInputs : List RawLinkedChildFloatInput :=
  [ { rawBits := 1176272896, hostBits := 11 },
    { rawBits := 1176272896, hostBits := 12 } ]

def th08DivergingChainOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix TouhouFormal.TH08.eclOpcodeSpawnLinkedChild)
    { runtime :=
        { parentHasChain := true
          attachmentChainTerminates := false
          attachmentTailHops := 3 } }

def th08DeadParentOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix TouhouFormal.TH08.eclOpcodeSpawnLinkedChild)
    { runtime := { parentLife := 0 } }

def th08SpawnFailureOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix TouhouFormal.TH08.eclOpcodeSpawnLinkedChild)
    { intInputs := validIntInputs
      floatInputs := validFloatInputs
      runtime := { spawnSucceeds := false } }

def th08ScriptPositionOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix TouhouFormal.TH08.eclOpcodeSpawnLinkedChild)
    { intInputs := validIntInputs
      floatInputs := validFloatInputs
      runtime :=
        { parentHasChain := true
          attachmentTailHops := 4
          playerYoukaiReads := [true, false, true]
          childEnemyIndex := 3 } }

def th08ParentOffsetOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix TouhouFormal.TH08.eclOpcodeSpawnLinkedChildAtParentOffset)
    { intInputs := validIntInputs
      floatInputs := validFloatInputs
      runtime :=
        { parentWorldPositionBits := { x := 1, y := 2, z := 3 }
          parentOffsetResultBits := { x := 101, y := 202, z := 3 }
          playerYoukaiReads := [false, false, false] } }

def th08InheritedPositionOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix
      TouhouFormal.TH08.eclOpcodeSpawnLinkedChildInheritingPosition)
    { intInputs := validIntInputs
      floatInputs := validFloatInputs
      runtime :=
        { parentPositionBits := { x := 21, y := 22, z := 23 }
          inheritedWorldPositionResultBits := { x := 32, y := 34, z := 23 }
          playerYoukaiReads := [false, false, false] } }

def th08AlignmentEffectNullOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix TouhouFormal.TH08.eclOpcodeSpawnLinkedChild)
    { intInputs := validIntInputs
      floatInputs := validFloatInputs
      runtime :=
        { alignmentEffectSpawnSucceeds := false
          playerYoukaiReads := [false, false, true] } }

def th08ExistingAlignmentEffectOutcome :
    Except TouhouFormal.Fault RawLinkedChildOutcome :=
  rawLinkedChildStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (linkedPrefix TouhouFormal.TH08.eclOpcodeSpawnLinkedChild)
    { intInputs := validIntInputs
      floatInputs := validFloatInputs
      runtime :=
        { childAlignmentEffectPresent := true
          playerYoukaiReads := [true, false] } }

theorem th06_has_no_linked_child_opcode :
    linkedChildOpcodeCount TouhouFormal.TH06.headerShape = 0 := by
  rfl

theorem th07_has_no_linked_child_opcode :
    linkedChildOpcodeCount TouhouFormal.TH07.headerShape = 0 := by
  rfl

theorem th08_linked_child_profile_count :
    linkedChildOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem th08_nonterminating_attachment_chain_diverges_before_spawn :
    (outcomeAction? th08DivergingChainOutcome,
      outcomeCursor? th08DivergingChainOutcome,
      preparedReadOrder? th08DivergingChainOutcome,
      (outcomeEffect? th08DivergingChainOutcome).map
        (fun effect => (effect.spawnRequest, effect.soundRequest))) =
      (some .diverged, none, some [], some (none, none)) := by
  rfl

theorem th08_dead_parent_skips_operands_but_still_plays_sound :
    (preparedReadOrder? th08DeadParentOutcome,
      (outcomeEffect? th08DeadParentOutcome).map
        (fun effect =>
          (effect.spawnSuppressedByParentState, effect.lastSpawnFailed,
            effect.soundRequest.map (fun sound => sound.soundId)))) =
      (some [], some (true, true, some 0x24)) := by
  rfl

theorem th08_pool_failure_keeps_spawn_request_and_plays_sound :
    ((preparedReadOrder? th08SpawnFailureOutcome).map List.length,
      (outcomeEffect? th08SpawnFailureOutcome).map
        (fun effect =>
          (effect.spawnRequest.isSome, effect.spawnSucceeded,
            effect.initialization, effect.soundRequest.isSome))) =
      (some 6, some (true, false, none, true)) := by
  rfl

theorem th08_script_child_preserves_repeated_alignment_reads :
    ((outcomeEffect? th08ScriptPositionOutcome).bind
      (fun effect => effect.initialization)).map (fun init =>
          (init.playerYoukaiReads, init.youkaiAligned, init.drawGroup,
            init.alignmentRequest.map (fun request =>
              (request.interrupt, request.negatesAngularVelocityZ)),
            init.parentLinkWritten, init.tailLinkHops,
            init.parentLinkedChildCountDelta)) =
      some
        ([true, false, true], true, 2, some (2, true), true, some 4, 1) := by
  rfl

theorem th08_child_spawn_uses_source_widths_and_copy_size :
    ((outcomeEffect? th08ScriptPositionOutcome).bind
      (fun effect => effect.spawnRequest)).map (fun request =>
          (request.rawSubId, request.hostSubId,
            request.itemDrop, request.hostItemDrop,
            request.contextCopyBytes, request.position.finalSpawnPositionBits)) =
      some (70000, 4464, 255, -1, 0x78, { x := 11, y := 12, z := 0 }) := by
  rfl

theorem th08_parent_offset_constructor_uses_host_vector_sum :
    ((outcomeEffect? th08ParentOffsetOutcome).bind
      (fun effect => effect.spawnRequest)).map (fun request =>
          (request.position.mode,
            request.position.parentWorldPositionBits,
            request.position.finalSpawnPositionBits)) =
      some
        (.parentWorldOffset, { x := 1, y := 2, z := 3 },
          { x := 101, y := 202, z := 3 }) := by
  rfl

theorem th08_inherited_child_writes_offset_world_and_effect_position :
    ((outcomeEffect? th08InheritedPositionOutcome).bind
      (fun effect => effect.initialization)).map (fun init =>
          (init.positionOffsetWrite, init.worldPositionWrite,
            init.inheritParentPositionFlagSet,
            init.alignmentRequest.map (fun request =>
              (request.positionSource, request.positionBits)))) =
      some
        (some { x := 21, y := 22, z := 23 },
          some { x := 32, y := 34, z := 23 }, true,
          some (.childWorldPosition, { x := 32, y := 34, z := 23 })) := by
  rfl

theorem th08_alignment_null_fault_precedes_link_and_sound :
    ((outcomeFault? th08AlignmentEffectNullOutcome).map
      (fun fault => fault.kind),
      (outcomeEffect? th08AlignmentEffectNullOutcome).map
        (fun effect =>
          (effect.initialization.map (fun init => init.parentLinkWritten),
            effect.soundRequest))) =
      (some .nullDereference, some (some false, none)) := by
  rfl

theorem th08_existing_effect_suppresses_third_alignment_read :
    ((preparedReadOrder? th08ExistingAlignmentEffectOutcome).map List.length,
      ((outcomeEffect? th08ExistingAlignmentEffectOutcome).bind
        (fun effect => effect.initialization)).map (fun init =>
            (init.playerYoukaiReads, init.alignmentEffectAlreadyPresent,
              init.alignmentRequest, init.parentLinkWritten))) =
      (some 8, some ([true, false], true, none, true)) := by
  rfl

end TouhouFormal.Search.LinkedChild
