---
id: bt-3f11
title: Migrate 5 argv-secret offenders in bass-tuner off live credential interpolation on argv (ma-529d)
status: done
priority: p2
tags:
  - security
  - argv-secrets
created: 2026-10-06
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-10-06T01:51:55Z
done:
  at: 2026-10-06T04:53:29Z
  by: omri@ubuntu-4gb-nbg1-1
  waived: "No commit: nothing needed changing here. The work was already done before I filed this, by
    the repo's own earlier task; the evidence is the scanner returning zero against the live tree."
evidence:
  - type: test
    cmd: python3 /home/omri/projects/meniapp/scripts/scan-argv-secret-exposure.py --root
      /home/omri/projects/bass-tuner 2>&1 | head -1
    exit: 0
    at: 2026-10-06T04:53:28Z
    expect: 0 total offender(s)
    log: evidence/bt-3f11-2026-10-06T04-53-28Z-test.txt
    sha256: fdcb6de4cb0a9a28d9a71f1533ed39b038609a72dd1f8c76c74a1d89c8624a86
    bytes: 221
  - type: note
    value: >-
      CLOSED AS ALREADY DONE — and this task should not have been filed. My mistake, recorded in
      full because the mechanism matters more than the apology.


      I drained this from ~/inbox/meni-board-queue on 2026-10-06 ~05:00. The queue file was written
      2026-10-05 04:40 and claimed 5 argv-secret offenders in this repo. Scanner run against the
      live tree just now: 0 total offenders. The fleet fixed them during the 24 hours between the
      snapshot and my drain, and the pre-dispatch dedup flagged exactly this ('looks like a
      duplicate of recently-closed ...; close it if it really is already done') before I checked.


      WHAT I GOT WRONG, precisely: I verified that each task FILE landed on disk before removing its
      queue file, guarding against the drained-and-lost failure. I never verified the FINDING was
      still true. All night I had been applying 'a closed task is not evidence the condition is
      handled now' — the symmetric truth is that a day-old finding is not evidence the condition is
      still broken, and I checked the freshness of indexes, exports, deploys and card premises while
      treating a 24-hour-old security snapshot as current fact.


      COST: real worker time. At least four of the nine were dispatched before I caught it.


      THE CHEAP GUARD I SHOULD HAVE USED is the one the queue file itself names: it says to run
      meniapp's scripts/scan-argv-secret-exposure.py --root <this repo> for exact line numbers,
      because the baseline hashes matched lines rather than numbers. One scan per repo, nine seconds
      total, would have filed one task instead of nine.
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
- 2026-10-06 done by omri@ubuntu-4gb-nbg1-1 — test `python3 /home/omri/projects/meniapp/scripts/scan-argv-secret-exposure.py --root /home/omri/projects/bass-tuner 2>&1 | head -1` exit 0 (--test-expect "0 total offender(s)") (log: evidence/bt-3f11-2026-10-06T04-53-28Z-test.txt) (evidence waived: No commit: nothing needed changing here. The work was already done before I filed this, by the repo's own earlier task; the evidence is the scanner returning zero against the live tree.)
