# Formal Results Artifacts

This directory stores generated, reviewable formal-methods artifacts that are
small enough to keep in Git.

`ce_campaigns/` contains timestamped symbolic counterexample campaign outputs:
full lane queues, the aggregate effectiveness report, and a compact summary.
The campaign runner intentionally stores solver witnesses before any retail
lowering step, so these artifacts remain useful even when a later Wine/DAT
validation attempt is still pending.
