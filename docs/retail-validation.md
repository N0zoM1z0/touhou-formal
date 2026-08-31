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
