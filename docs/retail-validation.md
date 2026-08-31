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
WINEPREFIX=/home/yann/yann/touhou/formal/wine-prefixes/th06 wine th06.exe
```

Record the exact archive hash, extracted executable CRC, mutated script, Wine
prefix path, command, and observed result next to the counterexample report.
