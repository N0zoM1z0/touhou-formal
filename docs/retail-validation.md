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
  --artifact-dir /home/yann/yann/touhou/formal/retail_validation/formal-th06-stage5-arg0-256-prepare \
  --prepare-only
```

Full confirmation command used on 2026-08-31:

```bash
python3 scripts/retail_confirm_th06_arg0_256.py \
  --source-game-dir /home/yann/yann/touhou/formal/retail_extract/th06-20260831-unar/th06 \
  --artifact-dir /home/yann/yann/touhou/formal/retail_validation/formal-th06-stage5-arg0-256-run3-long-probe \
  --repeat 1 \
  --timeout-seconds 28 \
  --stage-entry-wait-seconds 4 \
  --progress-probe-seconds 12 \
  --progress-probe-frames 450 \
  --startup-normalization auto
```

Observed report:

- result JSON:
  `/home/yann/yann/touhou/formal/retail_validation/formal-th06-stage5-arg0-256-run3-long-probe/source-result/result.json`
- override payload:
  `/home/yann/yann/touhou/formal/retail_validation/formal-th06-stage5-arg0-256-run3-long-probe/source-result/override/data/ecldata5.ecl`
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
