# Retail Validation Notes

Retail binaries are kept outside the formal repo under
`/home/yann/yann/touhou/formal/game_exe`. Treat that directory as immutable
input. Formal counterexamples should become small, reproducible mutations before
running Wine.

## Inventory

Use the read-only inventory helper:

```bash
./scripts/retail_inventory.sh
```

Current environment notes:

- `wine`, `7z`, and `unrar` are installed.
- `unrar lb` reports a UTF-16-to-locale conversion error for these archives.
- `7z l -slt` successfully lists executable and data entries.
- `7z x` can partially extract TH06 but reports unsupported RAR methods for many
  entries in this copy. Use `unar` for full extraction before Wine validation.

Observed archive inventory on 2026-08-31:

| Title | Archive SHA-256 | Main executable | Main data archive |
| --- | --- | --- | --- |
| TH06 | `6b013b24c101ae846b97a2778abf461d537640611a835824a42533c692be55d6` | `th06.exe` size `512000`, CRC `AEB8799E` | `紅魔郷ST.DAT` size `2964458`, CRC `0B6FC19D` |
| TH07 | `37d2a95fd687554cfd1aece23795d36acf0fac35f8aa20df3efc3b2e7dd363ed` | `th07.exe` size `650752`, CRC `079C77F3` | `th07.dat` size `23829135`, CRC `E9B6EDAB` |
| TH08 | `23c8d14e99993f58e78ad92a5e795ca1c20ecb1f4bd7323cdf33a412e04d05b4` | `th08.exe` size `840704`, CRC `16EF207E` | `th08.dat` size `46838025`, CRC `B946BC7E` |

## Extraction And Running

When a counterexample is ready for retail validation, extract into an explicit
workspace-owned directory such as `/home/yann/yann/touhou/formal/retail_extract`;
do not modify `reference/` or the original RARs. Use one Wine prefix per title,
for example:

```bash
./scripts/extract_retail_th06.sh
WINEPREFIX=/home/yann/yann/touhou/formal/wine-prefixes/th06 wine th06.exe
```

Record the exact archive hash, extracted executable CRC, mutated script, Wine
prefix path, command, and observed result next to the counterexample report.

## TH06 formal arg0=256 retail confirmation

`scripts/retail_confirm_th06_arg0_256.py` turns the formal
`TH06-ECL-SUBTABLE-ARG0-256` counterexample into the smallest current retail
mutation:

- read `紅魔郷ST.DAT` from an isolated TH06 extraction;
- extract `ecldata5.ecl`;
- mutate only timeline instruction index `1`, field `arg0`, to `256`;
- write the mutated ECL as an override payload consumed by DanmakuFuzz's retail
  harness;
- compare the mutant against a clean baseline under Wine.

Prepare only:

```bash
python3 scripts/retail_confirm_th06_arg0_256.py \
  --source-game-dir /home/yann/yann/touhou/formal/retail_extract/th06-20260831-unar/th06 \
  --artifact-dir retail_validation/formal-th06-stage5-arg0-256-prepare \
  --prepare-only
```

Full confirmation command used on 2026-08-31:

```bash
python3 scripts/retail_confirm_th06_arg0_256.py \
  --source-game-dir /home/yann/yann/touhou/formal/retail_extract/th06-20260831-unar/th06 \
  --artifact-dir retail_validation/formal-th06-stage5-arg0-256-run3-long-probe \
  --repeat 1 \
  --timeout-seconds 28 \
  --stage-entry-wait-seconds 4 \
  --progress-probe-seconds 12 \
  --progress-probe-frames 450 \
  --startup-normalization auto
```

Observed report:

- result JSON:
  `retail_validation/formal-th06-stage5-arg0-256-run3-long-probe/source-result/result.json`
- override payload:
  `retail_validation/formal-th06-stage5-arg0-256-run3-long-probe/source-result/override/data/ecldata5.ecl`
- mutated payload SHA-256:
  `2ff0c53669575690e60298536be0f43d32affa7be1e6f9073f793c5488d02304`
- patched archive SHA-256:
  `22c23b353601aff7ab2fab8ef2458c937bd3db12610acf187a5674429c4714ed`
- clean baseline classification: `game-window-live`
- mutant classification: `retail-frame-stall`
- DanmakuFuzz oracle: `interesting = true`, expectation passed.

The long progress probe is part of the oracle. A short two-second probe can
misclassify this case as still live because the mutated script enters stage 5
but then stops making enough frame progress.

## TH06 raw ECL symbolic jump-before-buffer confirmation

`scripts/retail_confirm_th06_raw_symex.py` turns a Z3/Lean raw-step witness into
a reachable TH06 stage mutation:

- ask `scripts/symex_materialize_raw_step.py` for a TH06 raw-step path witness;
- default to `symex-path = jumped-before-buffer`;
- default to stage 5, `ecldata5.ecl`, subroutine `0`, instruction `0`;
- default the formal active mask to `1 << retail_difficulty`, matching
  `reference/th06/src/EclManager.cpp:120`;
- replace that raw instruction with the Lean-materialized bytes;
- write an override payload for DanmakuFuzz's retail harness;
- compare the mutant against a clean baseline under Wine.

Prepare only:

```bash
python3 scripts/retail_confirm_th06_raw_symex.py \
  --symex-path jumped-before-buffer \
  --prepare-only
```

Repeated confirmation command used on 2026-08-31:

```bash
python3 scripts/retail_confirm_th06_raw_symex.py \
  --symex-path jumped-before-buffer \
  --expect-classification crash-dialog \
  --repeat 2 \
  --require 2 \
  --timeout-seconds 28 \
  --stage-entry-wait-seconds 4 \
  --progress-probe-seconds 12 \
  --progress-probe-frames 450 \
  --startup-normalization auto
```

Observed report:

- result JSON:
  `retail_validation/formal-th06-raw-symex-jumped-before-buffer-20260831T111946Z/source-result/result.json`
- repeated summary:
  `retail_validation/formal-th06-raw-symex-jumped-before-buffer-20260831T111946Z/report.json`
- run reports:
  `retail_validation/formal-th06-raw-symex-jumped-before-buffer-20260831T111946Z/run-001/report.json`
  and
  `retail_validation/formal-th06-raw-symex-jumped-before-buffer-20260831T111946Z/run-002/report.json`
- Lean/Z3 materialized raw instruction:
  `00000000020000000008000000000000ffffffff`
- mutated payload SHA-256:
  `f98076878c4cd7d3f30c210c3eaa559b85ba42479a199db6076f3c171a593ba1`
- patched archive SHA-256:
  `1f721f629c4fcba2e45a2dbdf65c7d1e3d2dd5f44f8e3f4323f9f94e6a144a96`
- clean baseline classification: `game-window-live`
- mutant classification: `crash-dialog`
- repeated expectation: `2/2` attempts passed.

The Wine crash signature normalizes to
`crash-dialog:wine: unhandled page fault on read access to <value> at address <addr> (thread <thread>), starting debugger...`.

## TH07/TH08 boss integer-read witness lowering

`scripts/retail_confirm_boss_int_read.py` lowers a Lean/Z3 boss-int witness into
an isolated TH07 or TH08 retail mutation:

- ask `scripts/symex_materialize_boss_int_read.py` for the requested symbolic
  path;
- extract `ecldata1.ecl` from `th07.dat`/`th08.dat`;
- decrypt and re-encrypt TH08 ECL entry blobs when the `edz` file-level crypt
  marker is present;
- preserve the original ECL layout and replace one equal-sized raw instruction;
- rebuild the PBG4/PBGZ archive with only that entry changed;
- write a source-backed windowed cfg before Wine launch;
- run a generic title-menu key probe and record screenshots, window census, Wine
  log classification, and a root `report.json`.

The default site selector is `reachable-timeline-spawn`. It does not use a
pre-found crash site. It reads the stage timeline, finds an early source-backed
enemy spawn opcode, and patches a same-sized raw instruction in the spawned
subroutine.

Normal-difficulty materialization is important for the default retail menu path:
TH07/TH08 `defaultDifficulty = 1` corresponds to active mask `2`, not the
Lunatic mask `8`.

### TH08 null boss read: retail-confirmed crash

Command used on 2026-09-01:

```bash
python3 scripts/retail_confirm_boss_int_read.py th08 \
  --symex-path boss-int-null-deref \
  --active-mask 2 \
  --override-mask 0 \
  --cfg-safe-video-flags \
  --post-input-wait-seconds 12
```

Observed report:

- artifact:
  `retail_validation/formal-th08-boss-int-boss-int-null-deref-20260901T024506Z`
- root report:
  `retail_validation/formal-th08-boss-int-boss-int-null-deref-20260901T024506Z/report.json`
- source result:
  `retail_validation/formal-th08-boss-int-boss-int-null-deref-20260901T024506Z/source-result/result.json`
- witness bytes:
  `000000005600180000020200000000801027000000000000`
- selected placement:
  `timeline0/instr0 -> sub14/instr1`, source timeline opcode `0`, time `1`,
  difficulty mask `255`;
- patched `th08.dat` SHA-256:
  `3e097bcb413646bc443eca4dd3be243f110246f0222b331f4721df6b014c12c6`
- cfg SHA-256:
  `595b7c04f94acb6f81e01f947a132083cc3d5991164ab008e43744f96a67796a`
- oracle classification: `crash-dialog`, `interesting = true`;
- Wine signature:
  `wine: Unhandled page fault on read access to 00002CA0 at address 0041F456 (thread 0148), starting debugger...`

This is the first TH08 retail crash produced by the formal boss-int lane. The
crash is not a hand-written ECL case: the 24-byte instruction comes from the
solver witness, then the retail lowering chooses an early timeline-spawned
subroutine.

### TH07 and boss-index OOB status

The same lowering path also produces runnable TH07 artifacts, but the current
generic Wine oracle did not classify them as crashes:

| Case | Artifact | Oracle |
| --- | --- | --- |
| TH07 `boss-int-null-deref`, active mask `2` | `retail_validation/formal-th07-boss-int-boss-int-null-deref-20260901T024506Z` | `game-window-live` |
| TH07 `boss-int-index-at-or-past-array`, active mask `2` | `retail_validation/formal-th07-boss-int-boss-int-index-at-or-past-array-20260901T024614Z` | `game-window-live` |
| TH08 `boss-int-index-at-or-past-array`, active mask `2` | `retail_validation/formal-th08-boss-int-boss-int-index-at-or-past-array-20260901T024614Z` | `game-window-live` |

These are still useful calibration cases. The formal OOB property is a memory
safety statement about `g_EnemyManager.bosses[index]`, not a guarantee that the
retail process will immediately fault: an out-of-bounds read can land on mapped
adjacent state. The TH07 null-deref result is also host-state dependent; the
chosen early spawned context did not reproduce a null boss slot at the moment of
execution.

## TH07/TH08 boss float-read witness lowering

`scripts/retail_confirm_boss_float_read.py` reuses the same boss-read lowering
pipeline as boss-int:

- ask `scripts/symex_materialize_boss_float_read.py` for a solver witness;
- splice the resulting equal-sized 24-byte raw ECL instruction into a
  timeline-spawned TH07/TH08 subroutine;
- rebuild `th07.dat`/`th08.dat` with only `ecldata1.ecl` changed;
- run the generic Wine title-menu probe in an isolated game copy.

Commands used on 2026-09-01:

```bash
python3 scripts/retail_confirm_boss_float_read.py th07 \
  --symex-path boss-float-null-deref \
  --active-mask 8 \
  --override-mask 0

python3 scripts/retail_confirm_boss_float_read.py th08 \
  --symex-path boss-float-null-guarded-skip \
  --active-mask 8 \
  --override-mask 0

python3 scripts/retail_confirm_boss_float_read.py th08 \
  --symex-path boss-float-index-at-or-past-array \
  --active-mask 8 \
  --override-mask 0

python3 scripts/retail_confirm_boss_float_read.py th07 \
  --symex-path boss-float-index-at-or-past-array \
  --active-mask 8 \
  --override-mask 0
```

Observed reports:

| Case | Witness bytes | Placement | Patched archive SHA-256 | Artifact | Oracle |
| --- | --- | --- | --- | --- | --- |
| TH07 `boss-float-null-deref` | `000000002c001800000802000000008000501c4600000000` | `timeline1/instr0 -> sub1/instr1` | `49000c3748a68bf371d7e6adc3183fe0af03ded16142c1a843a0a27427405a2f` | `retail_validation/formal-th07-boss-float-boss-float-null-deref-20260901T034027Z` | `game-window-live` |
| TH07 `boss-float-index-at-or-past-array` | `000000002c00180000080200000000800000008008000000` | `timeline1/instr0 -> sub1/instr1` | `7f0c12f8df75b2a7c702cd1767f77194f9812f25b107271e59a9468a1f18fd60` | `retail_validation/formal-th07-boss-float-boss-float-index-at-or-past-array-20260901T034254Z` | `game-window-live` |
| TH08 `boss-float-null-guarded-skip` | `000000005700180000080200000000800000008000000000` | `timeline0/instr0 -> sub14/instr1` | `9d56e04b9e83fc1a85ebbc83fc2e858b070ae629b19db22511576599917b545c` | `retail_validation/formal-th08-boss-float-boss-float-null-guarded-skip-20260901T034119Z` | `game-window-live` |
| TH08 `boss-float-index-at-or-past-array` | `000000005700180000080200000000800000008008000000` | `timeline0/instr0 -> sub14/instr1` | `419c24e1041b5d7de7a918b97c25cdf25256f436460d81c8e98e12593a83811f` | `retail_validation/formal-th08-boss-float-boss-float-index-at-or-past-array-20260901T034207Z` | `game-window-live` |

These four runs are calibration evidence. The formal model is finding source
memory-safety path classes at the opcode boundary. The current retail oracle
then answers a different question: whether the selected stage-entry placement
turns that path into an immediately visible process crash.
