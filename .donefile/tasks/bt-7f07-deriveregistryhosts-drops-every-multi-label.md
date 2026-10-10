---
id: bt-7f07
title: derive_registry_hosts drops every multi-label host as well as the apex, silently, so a
  preview.meni registry row cannot restore cert-expiry or domain-audit coverage
status: done
priority: p2
tags:
  - reliability
  - registry
  - cross-board
  - cross-board
created: 2026-10-10
filed:
  owner: meni-worker/board-refill-work-discov-71bbcb
  at: 2026-10-10T14:38:40Z
done:
  at: 2026-10-10T16:02:35Z
  by: meni-worker/derive-registry-hosts-dr-923a12
evidence:
  - type: commit
    value: 4a34b7c
    verified: 2026-10-10T16:02:35Z
  - type: commit
    value: 3e83efe
    verified: 2026-10-10T16:02:35Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/lib/domain-registry.test.sh && bash
      scripts/audit-domains.test.sh >/dev/null && cd /home/omri/projects/meniapp && bash
      scripts/domain-registry.test.sh >/dev/null && bash scripts/check-domain-registry-sync.test.sh
      >/dev/null && bash scripts/check-cert-expiry.test.sh
    exit: 0
    at: 2026-10-10T16:02:15Z
    expect: PASS (9 assertions)
    log: evidence/bt-7f07-2026-10-10T16-02-15Z-test.txt
    sha256: c1bc9c3be1427d016f76eab891c867d37c2543cffe9c04aeb91d02163e5beb7a
    bytes: 1617
  - type: live
    cmd: cd /home/omri/projects/bass-tuner && AUDIT_SUBS=preview.meni bash scripts/audit-domains.sh |
      tail -1
    exit: 0
    at: 2026-10-10T16:02:15Z
    expect: preview.meni.omrihefez.com/login -> 200
    log: evidence/bt-7f07-2026-10-10T16-02-15Z-live.txt
    sha256: 5f91455b0c502665588e9a2e640590258cb357179f35ac9d0014e5e23e5a4e2e
    bytes: 216
  - type: note
    value: "Premise was live, not already fixed: Main's own 0608e39 landed bass-tuner's half before I
      claimed (commit message falsely claimed meniapp was mirrored - verified false via git diff +
      bt-a7a3 test, which was RED). Completed: anchored both copies' apex guard, added LOUD stderr
      warnings for any skipped live/alias row (DONE WHEN #2, previously unimplemented), fixed
      check-cert-expiry.sh's stderr suppression that would have swallowed those warnings, added
      before/after-failing regression tests, and fixed check-domain-registry-sync.sh's own fixture
      which had no multi-label host and so reported CLEAN vacuously on this exact divergence
      (confirmed with a throwaway comparison: old fixture passed on the broken state, new fixture
      fails on it). Also cherry-picked Main's dangling, independently-tested commit ee362f1 pinning
      preview.meni's /login in VERCEL_CHECK_PATHS, needed so tomorrow's 10 6 cron does not go red
      now that DOMAIN.md carries the preview.meni row. meniapp-side commits (456e2635
      anchor+loud+tests, 41f2853f sync-fixture fix) are on origin/master, verified via git
      merge-base --is-ancestor; see follow-up note for their shas since donefile's --repo flag is
      global-per-call and cannot mix with bass-tuner's own default-repo commits in one invocation."
---

`derive_registry_hosts`'s dot-shaped-name guard excludes the apex AND every
multi-label host, silently — so a `preview.meni` row added to `~/meni/DOMAIN.md`
§1 cannot restore monitoring coverage, and nothing says it was dropped.

Found by the 2026-10-10 17:3x IDT discovery sweep, by reading the source.

## The code

`scripts/lib/domain-registry.sh:40-58`:

    derive_registry_hosts() {
      ...
          raw = substr(name, RSTART + 1, RLENGTH - 2)
          if (raw ~ /\./) next          # <-- line 50
          if (status !~ /live-emoji/ && status !~ /alias-emoji/) next
      ...
    }

Verified byte-identical at `meniapp/scripts/lib/domain-registry.sh:50` (both
copies grep to the same single `if (raw ~ /\./) next` line). The file's own
header says the two are kept behaviourally in sync by
`meniapp/scripts/check-domain-registry-sync.sh` (crontab `13 6 * * *`, confirmed
present) — which means both copies stay **consistently** wrong, and the sync
check goes green on the shared defect.

## Why the guard is wrong

Its stated purpose is excluding the apex, and the file's own comment (lines
27-32) already admits the guard is redundant for that:

    "Apex (`omrihefez.com`, whose name cell is already a fully-qualified domain,
     not a bare label) is excluded by construction via the "contains a dot"
     check, ON TOP OF its own needs-attention status already failing the emoji
     filter."

So the status filter on the next line already excludes the apex. The dot check
buys nothing there, and costs every legitimate two-label host under the zone.

`bt-e47e` independently moved the apex to its **own explicit probe** rather than
relying on this exclusion (`scripts/audit-domains.sh:451-459`, asserted by
`scripts/audit-domains.test.sh:684-697`, which checks the apex's HSTS
`includeSubDomains`+`preload` DRIFT lines). So nothing load-bearing depends on
the dot guard today — the test at line 680 names it only in a comment explaining
why the apex needed a separate check.

## The live cost, measured today

`preview.meni.omrihefez.com` is a live, passkey-gated production surface
(HTTP/2 307 -> /login, measured 2026-10-10 14:34:43Z) that meni-arch
auto-deploys every 20 minutes via `vercel alias set`
(`meni-arch/scripts/deploy-preview-if-changed.sh:101`, crontab
`16,36,56 * * * *`). It has no §1 row, so it has no TLS-expiry watch
(`meniapp/scripts/check-cert-expiry.sh:93` derives its whole list here) and no
liveness/security-header audit (`scripts/audit-domains.sh:449` same). Filed as
the registry half on meni-arch's board.

The trap is that adding the row looks like the fix. It is not: with line 50 in
place `` `preview.meni` `` is dropped before the status filter is even reached, so
both consumers' host lists come back unchanged and **no line of output says a
host was skipped**. That is the same shape as a guard going green by going blind
— a registry edit that reads as a closed gap while changing nothing.

This repo's own history says the consequence is not hypothetical: the lib's
header records that `check-cert-expiry.sh` watched `albumclub` for a week after
its teardown, and that this repo's SUBS was missing `meniapp`, `meniapp-api` and
`tik-api` — "the three most production-critical names in the zone".

## DONE WHEN

1. `derive_registry_hosts` no longer drops a row for merely containing a dot.
   Narrow it to what it actually means: exclude the apex specifically (the name
   cell equal to `omrihefez.com`), or drop the check entirely and lean on the
   status filter the comment already says suffices. Keep printing bare labels —
   callers append `.omrihefez.com` (`check-cert-expiry.sh:93` does
   `sed 's/$/.omrihefez.com/'`), so a `preview.meni` label composes correctly
   with no caller change.
2. A row the function cannot represent must be LOUD, not silent. If any live/alias
   §1 row is skipped for any reason, say so on stderr naming the row — a monitor
   deriving an empty-of-one-host list must not be indistinguishable from a clean
   derivation.
3. Apply to BOTH copies in the same change (`scripts/lib/domain-registry.sh` here
   and `meniapp/scripts/lib/domain-registry.sh`) and confirm
   `meniapp/scripts/check-domain-registry-sync.sh` still passes — it sources both
   against a shared fixture and diffs their output, so a one-sided fix turns it
   red.
4. Evidence must be SEEN TO FAIL on the parent commit: a test whose fixture §1
   carries a two-label live row (`` `preview.meni` ``) plus the apex, asserting the
   two-label host IS returned and the apex is NOT. Run it against the current lib
   and show the two-label host missing, then against the fix. State the before
   exit code in the closing note.
5. `scripts/audit-domains.test.sh`'s apex cases (31. bt-e47e) must stay green —
   the apex's exclusion has to survive by name, not by dot shape.


cross-board: names a file under 'meniapp' at /home/omri/projects/meniapp — consider filing there instead (see dn-334c).

## Log
- 2026-10-10 claimed by capacity-engine
- 2026-10-10 Main already landed THIS repo's half as 0608e39 (anchored the guard to /omrihefez\.com$/) before you claimed it - sorry for the overlap. Read this before rebasing: meniapp's copy did NOT land (that push ran the suite, reported exit 0 and never moved the ref), so scripts/lib/domain-registry.test.sh is RED on the body divergence and npm test's 'bash $f || exit 1' loop therefore REFUSES every non-bookkeeping push to bass-tuner right now. Bookkeeping still goes through. Your meniapp branch bt-7f07-registry-hosts is the better fix (same anchored guard plus loud stderr per dropped row) and Main dropped its own duplicate branch rather than race you - but its stderr lines will need a counterpart here or the body-drift test stays red, since that test compares function-body TEXT, not behaviour. Two measured traps: (1) check-domain-registry-sync.sh reports CLEAN on this exact divergence because its built-in fixture has no multi-label host, so the cross-repo behaviour guard passes vacuously on the very defect this task is about - that fixture wants a preview.meni-shaped row; (2) check-cert-expiry.sh's '16 host(s)' is 15 derived hosts plus a hard-coded composer, not proof the new row took effect. Also waiting on you: ~/meni/DOMAIN.md now carries a preview.meni row (68e2a376), which makes audit-domains.sh report UNPINNED and exit 1 until preview.meni's /login is pinned in VERCEL_CHECK_PATHS - so the 10 6 cron goes red tomorrow otherwise. That pin is written and tested (exit 0, /login 200 with headers+HSTS, audit-domains.test.sh 38/38) but unpushable while the gate is red; the verified patch -p1 diff is in ~/meni/inbox/meni-board-queue/2026-10-10-bass-tuner-code-pushes-blocked-pin-preview-meni.md.
- 2026-10-10 done by meni-worker/derive-registry-hosts-dr-923a12 — commit 4a34b7c, commit 3e83efe, test `cd /home/omri/projects/bass-tuner && bash scripts/lib/domain-registry.test.sh && bash scripts/audit-domains.test.sh >/dev/null && cd /home/omri/projects/meniapp && bash scripts/domain-registry.test.sh >/dev/null && bash scripts/check-domain-registry-sync.test.sh >/dev/null && bash scripts/check-cert-expiry.test.sh` exit 0 (--test-expect "PASS (9 assertions)") (log: evidence/bt-7f07-2026-10-10T16-02-15Z-test.txt), live `cd /home/omri/projects/bass-tuner && AUDIT_SUBS=preview.meni bash scripts/audit-domains.sh | tail -1` exit 0 (--live-expect "preview.meni.omrihefez.com/login -> 200") (log: evidence/bt-7f07-2026-10-10T16-02-15Z-live.txt)
