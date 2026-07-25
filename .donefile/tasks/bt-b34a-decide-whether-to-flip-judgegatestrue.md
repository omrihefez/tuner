---
id: bt-b34a
title: Decide whether to flip judge_gates:true in capacity-engine — OMRI'S CALL, do not flip to
  generate data
status: blocked
priority: p3
tags:
  - capacity-engine
  - config
created: 2026-07-25
repo: capacity-engine
blocked:
  reason: "Omri's call — subjective config decision. Main (2026-07-25): must be decided against real
    measurements, not the void bt-c0a9/bt-e0c3 baseline; do not flip it to generate the data."
  since: 2026-07-25
---

judge_gates has always been false, and bt-3943 (2026-07-25) showed it would have been inert even if it had been turned on — the judge could not authenticate at all until commit 49fb294.

Now that it works, whether to flip it is a real decision again. Main's ruling (2026-07-25): this is Omri's call, and it must be made against real measurements, NOT against the void bt-c0a9/bt-e0c3 baseline (see bt-cc03). Explicitly: do not flip it in order to generate the data.

An agent picking this up should gather evidence and present it — not decide. Blocked on Omri.

## Log
- 2026-07-25 blocked: Omri's call — subjective config decision. Main (2026-07-25): must be decided against real measurements, not the void bt-c0a9/bt-e0c3 baseline; do not flip it to generate the data.
