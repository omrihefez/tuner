---
id: bt-0ead
title: Migrate bass-tuner's 5 argv-secret offenders to env-var/stdin-fed form (ma-529d)
status: open
priority: p3
tags:
  - security
  - fleet
created: 2026-10-05
filed:
  owner: meni-worker/migrate-the-177-baseline-c8a687
  at: 2026-10-05T01:35:45Z
---

Named in the finding: env-var/stdin-fed (ma-529d, meniapp).

5 argv-secret offenders (credential-shaped CLI flag/HTTP header fed a live
$VAR/${VAR}/$(...) interpolation instead of an env var or stdin-fed config)
tracked in meniapp's deploy/argv-secret-exposure-baseline.tsv, all under this
repo:

  scripts/check-model-ids-resolve.sh
  scripts/renew-wildcard-cert.sh

(run meniapp's scripts/scan-argv-secret-exposure.py --root <this repo> to get
exact line numbers — the baseline tsv hashes full matched lines, not numbers).

Safe shapes (meniapp's scripts/check-argv-secret-exposure.sh header has the
canonical writeup): drop --client-id=/--client-secret=, let infisical read
INFISICAL_UNIVERSAL_AUTH_CLIENT_ID/SECRET from env; feed a curl Authorization
header via `--config` on a stdin pipe (`printf 'header = "Authorization:
Bearer %s"\n' "$TOK" | curl --config - ...`) or, if the same header is reused
across several curl calls from one array/variable, a 600-mode tmp file
instead (a process-substitution fd can only be read once).

meniapp fixed its own 79-entry share of this same finding in ea6a0fa7..36ccbe88
(ma-529d) — same pattern, copy the shape, verify with a before/after
/proc/<pid>/cmdline check (curl's own argv should show --config /dev/fd/N or
--config <path>, never the secret) plus `bash -n` on every touched file.

DONE WHEN: these 5 call sites no longer put a live credential on argv, and
meniapp's deploy/argv-secret-exposure-baseline.tsv no longer needs these rows
(note here when done so meniapp can drop them, or drop them yourself if you
have write access there — path-scoped, do not touch other repos' rows).
