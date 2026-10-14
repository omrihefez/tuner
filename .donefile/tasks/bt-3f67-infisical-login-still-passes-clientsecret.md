---
id: bt-3f67
title: Infisical login still passes clientSecret as curl -d argv (3 call sites, now caught by
  meniapp's widened scanner)
status: open
priority: p3
tags:
  - security
  - from-omri
created: 2026-10-14
filed:
  owner: meni-worker/scan-argv-secret-exposur-5b86bc
  at: 2026-10-14T10:27:00Z
---

ma-005c widened meniapp's scan-argv-secret-exposure.py to catch secrets in -d/--data*/-F/--form bodies, not just secrety-named flags. That surfaced 3 pre-existing bass-tuner call sites using -d '{"clientId":...,"clientSecret":"$VAR"}' against the Infisical login endpoint, same shape iac just migrated off of (iac-3737, commit 7d9d66d5 in iac, using --data @<(printf '%s' ...) instead of inline $VAR interpolation):

  scripts/check-model-ids-resolve.sh:265
  scripts/check-unregistered-live-hosts.sh:160
  scripts/renew-wildcard-cert.sh:129

Enrolled in meniapp's deploy/argv-secret-exposure-baseline.tsv so the fleet-wide guard stays green; this task tracks the actual migration (copy iac-3737's --data @<(printf ...) pattern, or route through infisical-secret.sh's shape if bass-tuner has an equivalent helper).
