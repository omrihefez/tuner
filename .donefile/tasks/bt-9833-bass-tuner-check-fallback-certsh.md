---
id: bt-9833
title: bass-tuner check-fallback-cert.sh still probes composer.omrihefez.com, NXDOMAIN since
  bt-6531; retire or re-target it
status: done
priority: p2
tags:
  - bass-tuner
  - monitoring
created: 2026-11-27
filed:
  owner: capacity-engine
  at: 2026-11-27T04:27:01Z
reported: 2026-11-27
done:
  at: 2026-11-27T04:33:16Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: e9cf1dc
    verified: 2026-11-27T04:33:16Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-fallback-cert.sh &&
      out=$(HOST=localhost bash scripts/check-fallback-cert.sh || true) && grep -q "^FAIL" <<<"$out"
    exit: 0
    at: 2026-11-27T04:33:16Z
    log: evidence/bt-9833-2026-11-27T04-33-16Z-test.txt
    sha256: 24e8f36b5258d10811fd499350ab560c2555987d3e7f51d862a8d2ebc36f4aa8
    bytes: 256
  - type: note
    value: Wildcard CNAME deleted (bt-6531) so the fallback-cert probe is moot; check now asserts the
      phantom host stays NXDOMAIN. Sabotaged HOST=localhost goes red; test-monitoring.sh passes.
---

Named in the finding: check-fallback-cert.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): ran it 06:23 IST, exit 1, same root cause; cron 06:05 daily will keep failing

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working iac-4b65, session `oncall-tls-cert-expiry-m-9b5ca0`, dispatched on iac.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 9fa9fb70ab97ca191d3bfb726d222054adae6439 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `9fa9fb70ab97ca191d3bfb726d222054adae6439` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-11-27 claimed by capacity-engine
- 2026-11-27 done by capacity-engine/worker — commit e9cf1dc, test `cd /home/omri/projects/bass-tuner && bash scripts/check-fallback-cert.sh && out=$(HOST=localhost bash scripts/check-fallback-cert.sh || true) && grep -q "^FAIL" <<<"$out"` exit 0 (log: evidence/bt-9833-2026-11-27T04-33-16Z-test.txt)
