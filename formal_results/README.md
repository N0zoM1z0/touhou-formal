# Formal Results Artifacts

This directory stores generated, reviewable formal-methods artifacts that are
small enough to keep in Git.

`ce_campaigns/` contains timestamped symbolic counterexample campaign outputs:
full lane queues, the aggregate effectiveness report, and a compact summary.
The campaign runner intentionally stores solver witnesses before any retail
lowering step, so these artifacts remain useful even when a later Wine/DAT
validation attempt is still pending.

Current retained full campaign:
`ce_campaigns/2026-09-02-extension-symex/summary.json`.

That run adds the extension-dispatch solver lane to the previous VM-core
campaign and records 328/328 satisfiable, replay-matched candidates: 209
high-priority counterexamples and 44 medium-priority semantic surprises.
