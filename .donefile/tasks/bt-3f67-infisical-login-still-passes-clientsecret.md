---
id: bt-3f67
title: Infisical login still passes clientSecret as curl -d argv (3 call sites, now caught by
  meniapp's widened scanner)
status: done
priority: p3
tags:
  - security
  - from-omri
created: 2026-10-14
filed:
  owner: meni-worker/scan-argv-secret-exposur-5b86bc
  at: 2026-10-14T10:27:00Z
done:
  at: 2026-10-14T13:25:28Z
  by: capacity-engine/worker
  waived: "security tag false-positives activation-gating here: this change touches only backend
    cron/ops scripts (check-model-ids-resolve.sh, check-unregistered-live-hosts.sh,
    renew-wildcard-cert.sh), none of which are part of the Vercel-served PWA surface (pwa/ux/vercel
    tags) that this board's activation gate exists to catch. Nothing to deploy or restart."
evidence:
  - type: commit
    value: 3b034e50c5cef80ac1063c3b47c12e36a88c5cbd
    verified: 2026-10-14T13:25:28Z
  - type: test
    cmd: cd /home/omri/projects/meniapp && python3 scripts/scan-argv-secret-exposure.py --root
      /home/omri/projects/bass-tuner
    exit: 0
    at: 2026-10-14T13:25:27Z
    log: evidence/bt-3f67-2026-10-14T13-25-27Z-test.txt
    sha256: 0bd667ff78efc9e59f6b098b885f69845f2b86619ce1077bf12b8f30f5adb9c3
    bytes: 212
---

ma-005c widened meniapp's scan-argv-secret-exposure.py to catch secrets in -d/--data*/-F/--form bodies, not just secrety-named flags. That surfaced 3 pre-existing bass-tuner call sites using -d '{"clientId":...,"clientSecret":"$VAR"}' against the Infisical login endpoint, same shape iac just migrated off of (iac-3737, commit 7d9d66d5 in iac, using --data @<(printf '%s' ...) instead of inline $VAR interpolation):

  scripts/check-model-ids-resolve.sh:265
  scripts/check-unregistered-live-hosts.sh:160
  scripts/renew-wildcard-cert.sh:129

Enrolled in meniapp's deploy/argv-secret-exposure-baseline.tsv so the fleet-wide guard stays green; this task tracks the actual migration (copy iac-3737's --data @<(printf ...) pattern, or route through infisical-secret.sh's shape if bass-tuner has an equivalent helper).

## Log
- 2026-10-14 claimed by capacity-engine
- 2026-10-14 done by capacity-engine/worker — commit 3b034e50c5ce, test `cd /home/omri/projects/meniapp && python3 scripts/scan-argv-secret-exposure.py --root /home/omri/projects/bass-tuner` exit 0 (log: evidence/bt-3f67-2026-10-14T13-25-27Z-test.txt) (evidence waived: security tag false-positives activation-gating here: this change touches only backend cron/ops scripts (check-model-ids-resolve.sh, check-unregistered-live-hosts.sh, renew-wildcard-cert.sh), none of which are part of the Vercel-served PWA surface (pwa/ux/vercel tags) that this board's activation gate exists to catch. Nothing to deploy or restart.)
