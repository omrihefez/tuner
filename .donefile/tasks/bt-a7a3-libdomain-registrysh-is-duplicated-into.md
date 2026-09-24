---
id: bt-a7a3
title: lib/domain-registry.sh is duplicated into meniapp with nothing asserting the copies agree — a
  comment is the only guard
status: done
priority: p2
tags:
  - monitoring
  - reliability
created: 2026-09-24
filed:
  owner: meni-worker/board-refill-work-discov-dde22f
  at: 2026-09-24T17:08:16Z
done:
  at: 2026-09-24T17:23:30Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: da9d5270845e44b2482a068d0bde6ae167839907
    verified: 2026-09-24T17:23:30Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/lib/domain-registry.test.sh
    exit: 0
    at: 2026-09-24T17:23:29Z
    log: evidence/bt-a7a3-2026-09-24T17-23-29Z-test.txt
    sha256: 789f8a4dd1164fbc4349e767f591c1e8919958338db8de2bd7e330b94d241a6e
    bytes: 153
  - type: note
    value: "Added scripts/lib/domain-registry.test.sh comparing only the derive_registry_hosts()
      function body (not the whole file, since header prose deliberately differs per-repo). Verified
      fail-before/pass-after: ran unmodified (OK), then against a meniapp copy with one
      function-body line mutated via DOMAIN_REGISTRY_MENIAPP_COPY override (FAIL, diff shown), then
      confirmed a whole-file diff between the two repos IS red today as the task predicted. Also
      verified graceful SKIP (exit 0, not silent pass) when the meniapp copy path is unreadable.
      Pushed via promote/bt-a7a3-domain-registry-guard (bass-tuner enforces the same main-push
      branch-name guard as trips-hub/capacity-engine/donefile/kidai; not yet noted in the fleet
      doc's 4-repo table)."
---

`scripts/lib/domain-registry.sh` exists in TWO separate git repos with no shared
package, and the only thing keeping them in sync is a comment in their own
headers:

```
# This file is duplicated verbatim in meniapp and bass-tuner (separate git
# repos, no shared package) — keep the two copies identical.
```

Paths (both read 2026-09-24):
- `/home/omri/projects/bass-tuner/scripts/lib/domain-registry.sh`
- `/home/omri/projects/meniapp/scripts/lib/domain-registry.sh`

Nothing asserts that instruction. Grepping `domain-registry` across both repos'
`scripts/` trees returns six files — the two copies, meniapp's
`domain-registry.test.sh`, and three consumers — and not one of them opens the
other repo's copy. meniapp's test sources only its own copy
(`. "$HERE/lib/domain-registry.sh"`), so it stays green no matter what this
repo's copy says, and vice versa.

## Why this is the exact failure the file was built to prevent
Its own header says so. `derive_registry_hosts()` was written (ma-20c5) because
two HAND-COPIED host arrays had drifted from `~/meni/DOMAIN.md`:
meniapp's `check-cert-expiry.sh` `DEFAULT_HOSTS` was still watching `albumclub`
a week after its Vercel project, Cloudflare CNAME and Neon DB were all deleted,
and this repo's `audit-domains.sh` `SUBS` was missing `meniapp`, `meniapp-api`
and `tik-api` — its own header calls those "the three most production-critical
names in the zone". The fix removed the duplicated DATA and replaced it with
duplicated CODE, enforced by a comment. Same class of problem, one level up.

Blast radius here is larger than a list: this repo has TWO cron-driven consumers
of the function, `audit-domains.sh` (the Vercel half) and
`check-tunnel-liveness.sh` (the non-Vercel half, cron 06:12 daily via
`run-monitor.sh tunnel-liveness`). The two modes are complementary — `vercel`
keeps rows whose Host cell matches /Vercel/, `non-vercel` keeps the rest — so a
one-line edit to the filter in one copy silently moves hosts between "audited"
and "not audited at all" in this repo while meniapp's suite reports green.

## DO NOT implement this as a whole-file hash or `diff -q` — it fails today
The two copies are byte-identical from line 23 (`# derive_registry_hosts ...`)
through the closing brace at line 47. They deliberately DIFFER above that, in
the header prose, because each is written repo-relative: meniapp's line 8 reads
`bass-tuner/scripts/audit-domains.sh's SUBS was missing ...` where this repo's
line 7 reads `this repo's audit-domains.sh's SUBS was missing ...`, and the
surrounding lines re-wrap around it. Both files are 47 lines. So a
sha256/`diff -q` check goes red on the first run against unmodified `HEAD` in
both repos, which is the shape of check that gets disabled rather than fixed.

Compare the FUNCTION BODY (line 23 to EOF, or the `derive_registry_hosts()`
block), not the file.

## DONE WHEN
A check exists in this repo's shell-test suite (alongside
`scripts/audit-domains.test.sh` and `scripts/check-tunnel-liveness.test.sh`)
that reads BOTH copies and fails when the `derive_registry_hosts` body diverges,
and it degrades honestly when meniapp's copy is unreadable (skip-with-a-message,
not a silent pass — an absent file must not read as "they agree").

Evidence must be a check SEEN TO FAIL, not just seen to pass: run it against the
current tree (passes), then against a copy of one file with one line of the
function body altered, and show it goes red. Say both runs in the closing note.
A check that has only ever been green here is indistinguishable from one that
cannot fire, because the two copies agree right now.

Write the evidence command against `/home/omri/projects/bass-tuner`, not a
worktree path — the re-run happens after the worktree is gone.

## Log
- 2026-09-24 claimed by capacity-engine
- 2026-09-24 done by capacity-engine/worker — commit da9d5270845e, test `cd /home/omri/projects/bass-tuner && bash scripts/lib/domain-registry.test.sh` exit 0 (log: evidence/bt-a7a3-2026-09-24T17-23-29Z-test.txt)
