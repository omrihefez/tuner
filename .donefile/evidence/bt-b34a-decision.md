# bt-b34a decision record: judge_gates stays false

**Outcome: KEEP judge_gates:false.** Not flipped. Not flipped in order to
generate data — the live-data pass (ce-39cd) was run via a dedicated
`judge-gate-probe` command that exercises `judgeGate()` without ever touching
`CFG.judge_gates`, per Main's 2026-07-25 ruling on this task.

## Why this satisfies bt-b34a's unblock predicate

bt-b34a was blocked on: *"Omri's call — subjective config decision (flip
judge_gates:true in capacity-engine or explicitly keep it false)... must be
judged against real measurements, not the void bt-c0a9/bt-e0c3 baseline, and
must NOT be flipped just to generate that data."* The predicate accepts either
outcome, as long as it's backed by real measurement and recorded here.

That work already happened, in three capacity-engine tasks, before this
board's copy of the block was ever updated to point at it:

- **ce-5e79** (2026-07-26) — first reviewed the flip once bt-3943 fixed
  headless judge auth. Declined to flip, for two reasons: (1) `judgeGate()`
  had no verdict cache and no per-tick call budget — the same unbounded-retry
  shape that caused judgeDuplicate's ~19h total dispatch outage on
  2026-07-25/26 before ce-303b fixed it there; (2) zero live calibration data
  — `judge_gates` had been false since the code was written, so there was no
  measured false-positive rate to judge the flip against. Filed the
  cache/budget fix and a live-data pass as prerequisites.
- **ce-23a0** (2026-07-26) — shipped the cache/budget half: this repo's
  `config.json` carries `judge_gates_cache_ttl_hours: 168`,
  `judge_gates_cache_max_entries: 500`, `judge_gates_max_calls_per_tick: 3`,
  mirroring ce-303b's fix for judgeDuplicate. Removes ce-5e79's first
  objection. Does not flip the gate itself.
- **ce-39cd** (2026-07-26) — the live-data half. Ran the new
  `engine.mjs judge-gate-probe` command — the real `judgeGate()` call, same
  prompt and schema as production — against 80 real p0/p1 tasks across 9
  repos, without touching `CFG.judge_gates` (no real dispatch was affected).
  Result: **19/80 gated (24%)**, spot-checked against each task's real
  done/blocked/open status. 9 were genuine correct catches (billing/GitHub
  Actions quota tasks, attended-session tasks, an OAuth-consent task, an
  explicit Omri-decision task — all actually blocked on him or closed via his
  real attendance). 10 were **false positives** — tasks the judge said needed
  Omri that had in fact already been closed autonomously with zero Omri
  involvement (bt-3943, tkn-23b2, vs-5b68, th-7680, dn-e72e, th-87de, sb-64ec,
  sb-6b25, ce-06ad, sb-cbdc). That's a **53% false-positive rate (10/19)**
  among gated verdicts. Net of the free `classifyGate` heuristic (only 1 of
  19 gates was redundant with it), the 18 unique judge-only catches split
  9 correct / 9 false — a coin flip — and 7 of the 9 correct-unique catches
  are cheaply pattern-matchable ("billing", "spending limit", "attended
  session") without any LLM call. Stated conclusion: **"DECISION: judge_gates
  STAYS false."**

## Current live config (verified at commit time)

`capacity-engine/config.json` (HEAD `16dd45beca8c9a3d9bf516bc62e10eaa2bfa115c`,
2026-08-13 17:56:09 +0300 — checked immediately before writing this file, no
drift from the numbers above):

```
"judge_gates": false,
"judge_gates_cache_ttl_hours": 168,
"judge_gates_cache_max_entries": 500,
"judge_gates_max_calls_per_tick": 3,
```

plus `_judge_gates_decision_note` (ce-5e79), `_judge_gates_cache_note`
(ce-23a0), and `_ce_39cd_live_data_note` (ce-39cd) recording the above in
full detail.

## If a re-review is wanted later

ce-39cd's own stated condition: re-run `judge-gate-probe` after ce-af0e
(extend `gate_patterns` with billing / spending limit / attended session)
lands — that free heuristic extension was measured as catching 7 of the 9
correct-unique catches judgeGate found in this 80-task sample, at zero
LLM cost and zero false-positive risk. A fresh `judge-gate-probe` run after
that lands would show how much marginal value judgeGate still adds once the
free patterns absorb its cheapest wins.

## Not part of this decision

tk-5ded (judgeGate shares judge()'s headless-auth degrade path) is a separate
defect, not a fact about whether the gate's judgment is trustworthy, and is
not folded into this record.
