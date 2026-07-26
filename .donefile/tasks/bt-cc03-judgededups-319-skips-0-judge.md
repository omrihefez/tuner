---
id: bt-cc03
title: judge_dedup's "319 skips, 0 judge calls, $0, zero false positives" baseline (bt-c0a9/bt-e0c3)
  is VOID — it was measured while the judge could not authenticate at all; re-measure and rewrite
  config.json's _judge_dedup_note and _bt_e0c3_decision_note
status: done
priority: p2
tags:
  - capacity-engine
  - dedup
  - tooling
created: 2026-07-25
repo: capacity-engine
done:
  at: 2026-07-26T09:28:36Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: d64af79
    repo: capacity-engine
    verified: 2026-07-26T09:28:36Z
  - type: test
    cmd: node /home/omri/projects/capacity-engine/engine.mjs judge-probe
    exit: 0
    at: 2026-07-26T09:28:26Z
    log: evidence/bt-cc03-2026-07-26T09-28-26Z-test.txt
    sha256: 4ff16ec34db7b457901c9ba4c851caecc958dc08eaa16cbd36c5e70741272309
    bytes: 185
---

Why the old numbers are void (state this in the rewritten notes — the reasoning matters more than the new figures):

bt-3943 (2026-07-25) found that judge()/judgeGate()/judgeDuplicate() had NEVER once authenticated. Two independent causes: the systemd timer has no CLAUDE_CODE_OAUTH_TOKEN, and --bare refuses OAuth by design (gated on CLAUDE_CODE_SIMPLE=1, so no flag works around it) on a box with no ANTHROPIC_API_KEY. Both callers catch and fail open, so every failure was silent.

That means bt-c0a9's and bt-e0c3's headline measurement — 319 dedup-skips, zero borderline judge calls, $0 cost, zero observed false positives — is not evidence that judge_dedup is cheap and precise. It is the signature of a component that never ran. Zero cost and zero false positives READ as success, and were recorded as such in config.json's _judge_dedup_note and _bt_e0c3_decision_note; bt-e0c3's 'AFFIRM judge_dedup:true' decision therefore rests on nothing. The affirmation may still be right — but it has not actually been tested.

Do:
1. Let real verdicts accumulate now that the judge authenticates (commit 49fb294). state.judgeDedupStats (calls/duplicates/errors) and the per-call log line already exist; `node engine.mjs status` reports them.
2. Rewrite _judge_dedup_note and _bt_e0c3_decision_note with the real cost/false-positive rate. Do NOT quietly swap the figures — say plainly that the prior baseline was void and why, so the next reader doesn't re-derive confidence from a number that measured nothing.
3. Sanity-check the judge is alive before trusting any new number: `node engine.mjs judge-probe` (exits non-zero if auth is broken).

Related: bt-5b65 asked this same question against the same void data. Anything that fails open needs an explicit liveness probe — that is the general lesson.

## Log
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 done by capacity-engine/worker — commit d64af79 (capacity-engine), test `node /home/omri/projects/capacity-engine/engine.mjs judge-probe` exit 0 (log: evidence/bt-cc03-2026-07-26T09-28-26Z-test.txt)
