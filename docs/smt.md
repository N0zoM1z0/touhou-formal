# SMT Seeds

The first SMT bridge is deliberately narrow. Lean owns the executable TH06
timeline model, while `TouhouFormal.Search.SMT` emits an audit-friendly SMT-LIB
query for the same sub-table safety relation:

```text
safe(subId, subCount) := 0 <= subId && subId < subCount
```

`lake exe th06_smt th06-sub-oob | z3 -in` checks the retail-calibrated seed
`subCount = 1, arg0 = 256`.

`lake exe th06_smt th06-find-oob | z3 -in` asks Z3 for any signed 16-bit
timeline argument that violates the same relation for a bounded positive
`subCount`.

The next step is to replace these handwritten relations with generated queries
from shared Lean-side transition facts once more of the VM is encoded.
