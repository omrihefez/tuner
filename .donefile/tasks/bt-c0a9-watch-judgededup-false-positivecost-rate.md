---
id: bt-c0a9
title: Watch judge_dedup false-positive/cost rate over the next week now that it's default-on across
  all boards, not just bass-tuner
status: done
priority: p3
tags:
  - tooling
  - donefile
created: 2026-07-23
done:
  at: 2026-07-25T03:15:17Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: cd /home/omri/projects/capacity-engine && node test.mjs
    exit: 0
    at: 2026-07-25T03:15:16Z
    log: evidence/bt-c0a9-2026-07-25T03-15-16Z-test.txt
    sha256: 39b9f2e9a129b109135885ed35b375e484b160de56a7205bccd53fb0ffdbffbe
    bytes: 79
  - type: note
    value: "judge_dedup went default-on 2026-07-23T19:46Z (capacity-engine 4b15111). Baseline check ~33h
      in: 319/319 dedup-skips across all 10 boards since the flip scored 0.9 (deterministic
      threshold catch), zero in the [0.35,0.75) borderline band -- judge has not fired once yet,
      cost $0, false-positive rate has no samples. Root cause of the gap: only a 'duplicate' verdict
      was ever logged (dropped[].viaJudge); a 'not duplicate' call left no trace, so cost was
      unmeasurable even after real invocations start. Fixed: state.judgeDedupStats
      (calls/duplicates/errors) + a log line per call, in capacity-engine commits d31d59d and
      bcbd9f7 (pushed to origin/main). engine.mjs status now surfaces the counter. This is a
      genuinely week-long watch that can't complete in one session -- filed a follow-up to check
      state.judgeDedupStats and journalctl -u capacity-engine.service for 'judge_dedup:' lines once
      real borderline candidates and judge calls have accumulated."
---

## Log
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 done by capacity-engine/worker — test `cd /home/omri/projects/capacity-engine && node test.mjs` exit 0 (log: evidence/bt-c0a9-2026-07-25T03-15-16Z-test.txt)
