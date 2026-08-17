---
id: bt-b34a
title: Decide whether to flip judge_gates:true in capacity-engine — OMRI'S CALL, do not flip to
  generate data
status: done
priority: p3
tags:
  - capacity-engine
  - config
created: 2026-07-25
repo: capacity-engine
done:
  at: 2026-08-13T15:09:53Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: c3055c2
    repo: .
    verified: 2026-08-13T15:09:53Z
  - type: test
    cmd: git -C /home/omri/projects/bass-tuner fetch origin --quiet && git -C
      /home/omri/projects/bass-tuner cat-file -e origin/main:.donefile/evidence/bt-b34a-decision.md
    exit: 0
    at: 2026-08-13T15:09:52Z
    log: evidence/bt-b34a-2026-08-13T15-09-52Z-test.txt
    sha256: e4d4a94c1cc7bfef2452653590bafe33e405bfe64763a5fb012dec5df5b6807e
    bytes: 166
---

judge_gates has always been false, and bt-3943 (2026-07-25) showed it would have been inert even if it had been turned on — the judge could not authenticate at all until commit 49fb294.

Now that it works, whether to flip it is a real decision again. Main's ruling (2026-07-25): this is Omri's call, and it must be made against real measurements, NOT against the void bt-c0a9/bt-e0c3 baseline (see bt-cc03). Explicitly: do not flip it in order to generate the data.

An agent picking this up should gather evidence and present it — not decide. Blocked on Omri.

## Gate
PROBE: git -C /home/omri/projects/bass-tuner fetch origin --quiet && git cat-file -e origin/main:.donefile/evidence/bt-b34a-decision.md
GATE-OWNER: omri

## Log
- 2026-07-25 blocked: Omri's call — subjective config decision. Main (2026-07-25): must be decided against real measurements, not the void bt-c0a9/bt-e0c3 baseline; do not flip it to generate the data.
- 2026-08-09 blocked reason updated: "Omri's call — subjective config decision. Main (2026-07-25): must be decided against real measurements, not the void bt-c0a9/bt-e0c3 baseline; do not flip it to generate the data." -> "Omri's call — subjective config decision (flip judge_gates:true in capacity-engine or explicitly keep it false), per Main's 2026-07-25 ruling: must be judged against real measurements, not the void bt-c0a9/bt-e0c3 baseline, and must NOT be flipped just to generate that data. Unblock predicate: a decision record committed at .donefile/evidence/bt-b34a-decision.md (either outcome — flip it, or explicitly keep it off — counts as decided)."
- 2026-08-13 unblocked
- 2026-08-13 done by capacity-engine/worker — commit c3055c2 (.), test `git -C /home/omri/projects/bass-tuner fetch origin --quiet && git -C /home/omri/projects/bass-tuner cat-file -e origin/main:.donefile/evidence/bt-b34a-decision.md` exit 0 (log: evidence/bt-b34a-2026-08-13T15-09-52Z-test.txt)
