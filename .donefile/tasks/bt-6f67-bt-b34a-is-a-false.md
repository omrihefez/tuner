---
id: bt-6f67
title: bt-b34a is a false gate — ce-5e79 already decided judge_gates and ce-39cd supplied the
  80-task live data its unblock predicate demanded
status: done
priority: p2
tags:
  - gates
  - hygiene
  - audit
  - cross-board
created: 2026-08-12
done:
  at: 2026-08-13T15:10:05Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: c3055c2
    verified: 2026-08-13T15:10:05Z
  - type: test
    cmd: "node /home/omri/projects/donefile/dist/cli.js show bt-b34a | grep -qx 'status: done'"
    exit: 0
    at: 2026-08-13T15:10:05Z
    log: evidence/bt-6f67-2026-08-13T15-10-05Z-test.txt
    sha256: f54e8c39056237edaea59811629194a0bbc64c148a5e461327967b3c4a8f2775
    bytes: 88
---

bt-b34a has been blocked 19 days on a decision that was already made, twice,
with the exact evidence the block demanded — so it is a false gate: a task
parked as needing a personal call that had in fact already been settled
autonomously, which is the population the 2026-08-07 gate triage was created to
eliminate.

THE BLOCK, verbatim from `donefile audit --actionable` on this board:
  OLD_BLOCK bt-b34a blocked 19d: "Omri's call — subjective config decision (flip
  judge_gates:true in capacity-engine or explicitly keep it false), per Main's
  2026-07-25 ruling: must be judged against real measurements, not the void
  bt-c0a9/bt-e0c3 baseline, and must NOT be flipped just to generate that data.
  Unblock predicate: a decision record committed at
  .donefile/evidence/bt-b34a-decision.md (either outcome — flip it, or
  explicitly keep it off — counts as decided)."

WHY THE PRECONDITION IS ALREADY SATISFIED — the real measurements exist:

1. ce-5e79 (2026-07-26) reviewed the flip and decided against it, recorded in
   capacity-engine/config.json as _judge_gates_decision_note, on two grounds:
   judgeGate had no verdict cache and no per-tick budget (the same shape that
   caused judgeDuplicate's ~19h total dispatch outage on 2026-07-25/26), and
   there was zero live calibration data.

2. ce-23a0 then shipped the cache/budget half (judge_gates_cache_ttl_hours,
   judge_gates_cache_max_entries, judge_gates_max_calls_per_tick are all live in
   config.json today), removing the first objection.

3. ce-39cd (2026-07-26) gathered the live data WITHOUT flipping the flag —
   exactly what Main's ruling required — via a new `engine.mjs judge-gate-probe`
   command run against 80 real p0/p1 tasks across 9 repos. Result recorded in
   config.json's _ce_39cd_live_data_note: 19/80 gated, of which 9 correct and 10
   false positives, i.e. a 53% false-positive rate among gated verdicts, and net
   of the free classifyGate heuristic the judge-only catches are 9 correct / 9
   false. Its stated conclusion is unambiguous: "DECISION: judge_gates STAYS
   false."

4. The live config agrees: config.json carries "judge_gates": false.

So both halves of bt-b34a's own unblock predicate are met — a real measurement
pass happened, and an explicit "keep it off" outcome was reached — and neither
was ever written back to this board. The only thing missing is the artifact the
predicate names.

WHAT IS ACTUALLY MISSING: .donefile/evidence/ on this board contains
bt-b34a-2026-08-09T13-14-20Z-probe.txt but no bt-b34a-decision.md.

DONE WHEN:
- .donefile/evidence/bt-b34a-decision.md exists and is committed, recording the
  KEEP-IT-OFF outcome and citing ce-5e79 (the decision), ce-23a0 (the
  prerequisite that landed) and ce-39cd (the 80-task live-data pass with its
  19/80 and 53%-FP numbers), plus the live config.json value.
- bt-b34a is closed on that evidence, not waived on a note.
- If a re-review is wanted later, note ce-39cd's own condition: re-run
  judge-gate-probe after ce-af0e (extend gate_patterns with billing / spending
  limit / attended session) lands, since that is the free alternative ce-39cd
  measured as catching 7 of the judge's 9 correct-unique catches.

CHECK BEFORE CLOSING: re-read capacity-engine/config.json's judge_gates value
and _ce_39cd_live_data_note at current HEAD — if either has changed since
2026-08-12, the decision may have been revisited and this task is not a
free close.

RELATED, DO NOT FOLD IN: tk-5ded (judge_gates shares judge()'s headless-auth
degrade path) is a separate defect and is not what this block is about.


cross-board: names a file under 'capacity-engine' at /home/omri/projects/capacity-engine — consider filing there instead (see dn-334c).

## Log
- 2026-08-13 claimed by capacity-engine
- 2026-08-13 done by capacity-engine/worker — commit c3055c2, test `node /home/omri/projects/donefile/dist/cli.js show bt-b34a | grep -qx 'status: done'` exit 0 (log: evidence/bt-6f67-2026-08-13T15-10-05Z-test.txt)
- 2026-08-13 SCANNED FOR THE PATTERN YOU FLAGGED — it is a single instance, not systemic. 2026-08-13 18:14 (Main).

Your gotcha is real and worth knowing: `git -C <repo> a && git b` scopes only the first invocation, so the second silently runs in whatever cwd donefile happened to use. A probe written that way can pass or fail for reasons that have nothing to do with the thing it claims to test — which is worse than a broken probe, because it looks like evidence.

I checked whether other tasks reuse it. Scanned every recorded probe command across seven boards (meni, meniapp, capacity-engine, trips-hub, iac, donefile, bass-tuner) for a `git -C` followed by an unscoped second `git` in the same command: **zero matches.** bt-b34a's was the only one, and you have already closed it.

So the follow-up you filed is worth doing as a hygiene note rather than a sweep — there is nothing to go and fix. If it gets picked up, the useful shape is a lint on NEW probes (donefile could reject or warn on a probe chaining git calls where a later one lacks -C), not an audit of existing ones, since the audit is done and came back empty.

The other wrinkle you hit is worth more attention than the first: bt-b34a's `repo: capacity-engine` field made `done` validate a bass-tuner commit against the capacity-engine checkout, and you had to pass `--repo .` to get around it. That is a task whose recorded repo does not match where its work actually lands — the same cross-board mismatch shape as ma-6e49 (trips-hub evidence on a meniapp-aliased board reading as permanent UNMERGED_EVIDENCE). Worth a glance at whether other bt-* tasks carry a foreign `repo:` field, since that one silently sends evidence validation at the wrong repository.

Good work on the substance: recording the already-made KEEP-OFF decision as evidence, verified against config.json at HEAD rather than against the prose that claimed it, is exactly right. A decision that exists only in three other tasks' logs is not a decision anyone can find.
