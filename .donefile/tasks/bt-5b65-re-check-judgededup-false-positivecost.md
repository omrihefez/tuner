---
id: bt-5b65
title: Re-check judge_dedup false-positive/cost rate once state.judgeDedupStats shows real calls
  (journalctl -u capacity-engine.service since 2026-07-23
status: done
priority: p2
tags:
  - p3
created: 2026-07-25
done:
  at: 2026-07-25T04:28:28Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: ed290d2
    verified: 2026-07-25T04:28:28Z
  - type: test
    cmd: bash .donefile/evidence/verify-bt-5b65.sh
    exit: 0
    at: 2026-07-25T04:28:26Z
    log: evidence/bt-5b65-2026-07-25T04-28-26Z-test.txt
    sha256: 556d63919a64c9b66f7f67c4d9af74e16176ac102eefd460b4074c79c13ad872
    bytes: 908
  - type: note
    value: "258/258 judge_dedup calls since the 2026-07-23 flip errored (0 duplicates ever flagged).
      Root cause confirmed live: capacity-engine.service runs headless claude -p calls with NO
      CLAUDE_CODE_OAUTH_TOKEN in its env (no Environment=/EnvironmentFile= in the unit), and the
      on-disk ~/.claude/.credentials.json claudeAiOauth key was intentionally stripped 2026-06-20
      (meni mode #7 fix, memory/reference_meni_deaf_recovery_prevention.md) -- so judge() has zero
      auth paths available. Every judge_dedup call for every borderline candidate has been silently
      defaulting to 'keep' via the catch-block since go-live; false-positive/cost rate has no valid
      samples and cannot be computed until this is fixed. Filed follow-up to wire
      CLAUDE_CODE_OAUTH_TOKEN into capacity-engine.service (same infisical-secrets pattern as
      ~/bin/claude-hl's self-heal block) -- until then this watch stays blocked on bad data, not on
      sample size."
---

## Log
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 done by capacity-engine/worker — commit ed290d2, test `bash .donefile/evidence/verify-bt-5b65.sh` exit 0 (log: evidence/bt-5b65-2026-07-25T04-28-26Z-test.txt)
