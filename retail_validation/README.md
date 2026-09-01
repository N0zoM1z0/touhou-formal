# Retained Retail Validation Evidence

This directory keeps the small, reviewable outputs of retail-game validation
next to the formal model that produced them. Each run may create a full isolated
game copy, Wine prefix, patched archive, screenshots, and logs here, but Git
tracks only files named `result.json` or `report.json` plus this note.

The JSON files are preserved verbatim as experiment records. Consequently,
older records can contain absolute acquisition-time paths outside the checkout;
hashes, mutation metadata, commands, and observations remain the portable
evidence. The original game binaries are never part of this repository.

New validation scripts default to this directory. A typical retained layout is:

```text
retail_validation/
  formal-<title>-<finding>-<timestamp>/
    report.json
    source-result/
      result.json
```

See [`../docs/retail-validation.md`](../docs/retail-validation.md) for the
protocol and the interpretation of the current runs.
