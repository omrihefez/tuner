---
id: bt-3f11
title: Migrate 5 argv-secret offenders in bass-tuner off live credential interpolation on argv (ma-529d)
status: open
priority: p2
tags:
  - security
  - argv-secrets
created: 2026-10-06
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-10-06T01:51:55Z
---

Drained onto this board by Main 2026-10-06 from ~/inbox/meni-board-queue/rescued-bass-tuner.md (queued 2026-10-05 04:40, 24h+ old).

Filed HERE rather than on the meni board the queue nominally drains to: the meni board is main-only and never dispatched, and this is ordinary dispatchable work in this repo. Same reasoning as df-8e47 -> ma-9fab earlier tonight.

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

## Log
- 2026-10-06 claimed by capacity-engine
- 2026-10-06 released by capacity-engine
