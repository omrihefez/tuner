---
id: bt-9777
title: install-cert-renewal-cron.sh:143 still substring-matches, so it silently deletes hand-added
  cert-renewal crontab lines — residual of bt-b38f, and bt-d428 already wrote both the fix and the
  test
status: claimed
priority: p2
tags:
  - ops
  - safety
created: 2026-08-14
claim:
  owner: capacity-engine
  at: 2026-08-14T05:31:00Z
---

`scripts/install-cert-renewal-cron.sh:143` still deletes any crontab line containing the substring "run-monitor.sh cert-renewal ", not just its own managed block:

    STRIPPED_CRON="$(printf '%s\n' "$STRIPPED_CRON" | grep -vF "run-monitor.sh cert-renewal " || true)"

So a hand-added or differently-scheduled cert-renewal line — one nobody asked this installer to manage — is silently removed the next time the installer runs. Destructive, silent, and it targets the user's own crontab entries.

CONFIRMED LIVE 2026-08-14 08:29 (Main): grepped the file, the line is there as written.

THIS IS THE RESIDUAL OF A FIX THAT ALREADY HAPPENED HERE. bt-b38f (p2, done) fixed this same file for this same class — "cleanup strips ANY crontab line naming renew-wildcard-cert.sh". The renew-wildcard-cert.sh pattern was scoped; the run-monitor.sh cert-renewal pattern on line 143 was not. One of two patterns in one file got fixed, which is the easiest kind of residual to miss and the reason it is worth its own row rather than a note on the closed task.

THE FIX IS ALREADY WRITTEN, ELSEWHERE. bt-d428 (2026-08-14, 7c21a04d) hit the identical defect in install-monitoring-crons.sh and fixed it by replacing the substring `grep -vF` with a full-line `grep -vFxf` match against the managed lines verbatim — which still removes an exact stray duplicate (e.g. from a corrupted marker pair) but cannot touch a hand-added or differently-scheduled line. Copy that change here.

AND THE TEST IS ALREADY WRITTEN TOO. bt-d428 added scripts/test-monitoring.sh step 6e: a fake-crontab negative control containing an unmanaged, differently-scheduled line, asserting it SURVIVES a --dry-run. That worker confirmed it fails against pre-fix code and passes after. Mirror it for the cert-renewal installer — and confirm the mirrored test fails against today's line 143 before changing it, or the test proves nothing.

Filed by Main rather than auto-filed: bt-d428's FOLLOW-UP line named this exactly and landed on no board. That is the third follow-up tonight to evaporate between the report that found it and the board that should hold it (see df-a2ce and df-a39d).

## Log
- 2026-08-14 claimed by capacity-engine
