---
id: bt-e47e
title: audit-domains.sh declines to assert HSTS preload on a false per-host premise, and the apex it
  actually depends on is skipped by derive_registry_hosts
status: done
priority: p2
tags:
  - security
  - http-headers
created: 2026-10-07
filed:
  owner: meni-worker/board-refill-work-discov-0dfdcd
  at: 2026-10-07T12:31:34Z
done:
  at: 2026-10-07T12:51:51Z
  by: capacity-engine/worker
  waived: "not app-surface work: audit-domains.sh is a monitoring/cron script invoked directly from
    the main checkout path (crontab: /home/omri/projects/bass-tuner/scripts/audit-domains.sh, see
    scripts/install-monitoring-crons.sh:53), not part of the Vercel-deployed bass-tuner PWA this
    board's activation gate (pwa/ux/correctness/security/deploy/feature/perf/a11y/vercel) exists
    for. Already live on disk the moment the commit landed on main -- no deploy/restart step exists
    for it."
evidence:
  - type: commit
    value: 96c6267c38baf4fd01b650bca512619d328c91d7
    verified: 2026-10-07T12:51:51Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh
    exit: 0
    at: 2026-10-07T12:51:38Z
    log: evidence/bt-e47e-2026-10-07T12-51-38Z-test.txt
    sha256: dda427f7a0813d3c0bc55027e8bb255dfbde286e08cd736ff7562315786928cc
    bytes: 11081
  - type: note
    value: "Fixed check_hsts()'s comment (preload is apex-keyed, not per-host) and added an explicit
      apex probe (check_apex_hsts, requiring includeSubDomains+preload) since
      derive_registry_hosts() excludes the apex by construction. Seen red live before closing: curl
      -sI https://omrihefez.com/ returns only max-age=63072000 (no includeSubDomains, no preload),
      and running scripts/audit-domains.sh against the real ~/meni/DOMAIN.md produced two DRIFT
      lines for omrihefez.com confirming the check actually fires. domain-registry.sh untouched; its
      cross-repo byte-identity test (lib/domain-registry.test.sh) still passes. test-monitoring.sh
      and check-tunnel-liveness.test.sh unaffected (checked against both the worktree and a control
      run on unmodified origin/main -- the only control-run differences were pre-existing
      crontab-drift FAILs unrelated to this change)."
---

Two joined problems: the domain audit's HSTS check declines to assert `preload` for a
reason that is factually wrong, and the one host where `preload` actually does anything —
the apex — is structurally unreachable by that audit and by every other consumer of the
shared registry helper.

## 1. The comment's model of `preload` is wrong

`scripts/audit-domains.sh:243-246`:

    #   preload is deliberately NOT asserted: six live hosts send it and three
    #   don't, and adding it to a host is a one-way trip onto the browser
    #   preload list — that's a call for a human to make per host, not a
    #   default this audit should silently require or silently ignore.

`preload` is not per-host. The HSTS preload list is keyed on the **registrable domain**:
qualifying requires `includeSubDomains` AND `preload` served **at the apex**, and the
submission then covers the whole tree. A `preload` token on `kidai.omrihefez.com` cannot
put that host — or anything — on the list. It is inert.

So the "one-way trip" the comment is protecting against is not a risk those six hosts can
take, and the per-host judgement it defers to a human is not a judgement that exists. The
decision not to check is defensible; the stated reason for it is not, and the comment is
what tells the next reader there is nothing here to look at.

## 2. The apex does not qualify, and nothing checks it

MEASURED LIVE 2026-10-07 12:29:51Z:

    curl -sI https://omrihefez.com/
    HTTP/2 404
    strict-transport-security: max-age=63072000
    x-vercel-error: DEPLOYMENT_NOT_FOUND

`max-age` only. **No `includeSubDomains`, no `preload`** — neither of the two directives
preloading requires. Compare the same probe run across the estate the same minute: kidai,
compose, planner, trips, tik, oauth, brain, meniapp and meniapp-api all send
`max-age=63072000; includeSubDomains; preload`.

Six-plus hosts are therefore advertising a `preload` that cannot take effect, because the
apex does not meet the precondition. (Whether `omrihefez.com` was ever actually submitted
to hstspreload.org I did NOT check — a discovery worker's curl is restricted to HEAD, so I
could not query the list. The necessary condition is measurably absent today, which is
enough for this task; treat the submission status as unverified.)

Second-order consequence worth stating plainly: without `includeSubDomains` at the apex,
a browser's first-ever visit to any `*.omrihefez.com` host is unprotected until that
specific host has been reached over HTTPS once and set its own HSTS. Closing that
trust-on-first-use window is the entire purpose of preloading, and the estate is a
wildcard tree carrying passkey and session surfaces (meni, house, brain, trips, tik).

## 3. Why no audit was ever going to catch this — the structural half

`scripts/lib/domain-registry.sh:39`, inside `derive_registry_hosts()`:

    if (raw ~ /\./) next

The apex's DOMAIN.md name cell is `` `omrihefez.com` (apex) ``, so `raw` is
`omrihefez.com` — it contains a dot and is skipped unconditionally, in every mode
(`all`, `vercel`, `non-vercel`). The filter is correct for its purpose: consumers append
`.omrihefez.com` to a bare label, so FQDN-shaped rows must be dropped. But the apex is
the one real, live host that is legitimately dot-shaped, and nothing picks it up
afterwards — not `audit-domains.sh`, not `check-tunnel-liveness.sh`, and not meniapp's
copy of the same helper.

This is exactly the shape `check-tunnel-liveness.sh`'s own header describes for the
non-Vercel hosts: *"nothing else in the estate picked up the hosts it SKIPs, so 'not a
Vercel host' had quietly become 'not monitored'."* Here, "not a subdomain" has quietly
become "not monitored", and the apex is the only host in that category.

## DONE WHEN

- `check_hsts`'s comment no longer claims `preload` is per-host. Replace the reasoning,
  do not just delete the paragraph — the next reader needs to know WHY the check is or
  is not asserted, and the current text would otherwise be re-derived.
- The apex is audited. Either extend `derive_registry_hosts()` with a mode (or a separate
  helper) that returns the apex row, or audit it explicitly in `audit-domains.sh` — but
  do NOT simply drop the `raw ~ /\./` guard, which would feed FQDN-shaped rows into the
  `$h.omrihefez.com` concatenation in both consumers and in meniapp's copy. Note
  `lib/domain-registry.test.sh` asserts this repo's copy of the function body is
  byte-identical to meniapp's, so any change to the helper must land in BOTH repos or
  that test goes red and refuses every push here — check it before choosing the approach.
- The apex's HSTS is asserted with whatever directives the estate decides it should carry,
  and a DRIFT line fires if they go missing. Seen to fail first: the check must go red
  against the apex as it is served today (no `includeSubDomains`, no `preload`), which is
  a free falsifiability test — run it before the fix and say in the closing note that you
  saw it red.
- Evidence must be a live probe of the apex, not a grep of the script. A check added to a
  file that is not wired into the cron/brief path proves nothing.

## FOLLOW-UP, not this task

Actually ADDING `includeSubDomains; preload` at the apex is a different repo's work and a
real decision, not cleanup. `omrihefez.com` currently serves Vercel's account-wide
wildcard 404 with no project behind it (DOMAIN.md §1 row 23, 🟠 blank, "design in §6"), so
the header has to come from Cloudflare or from whatever eventually gets deployed there —
iac owns `cloudflare/generated.tf`. And preload submission genuinely IS close to one-way
(removal is slow and ships with browser releases), so it needs a deliberate call once the
apex is no longer a 404. File that against iac, with the measurement above; this task is
about the audit being blind and the comment being wrong, which is workable now and
independent of that decision.

Filed by the periodic discovery sweep, 2026-10-07.

## Log
- 2026-10-07 claimed by capacity-engine
- 2026-10-07 done by capacity-engine/worker — commit 96c6267c38ba, test `cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh` exit 0 (log: evidence/bt-e47e-2026-10-07T12-51-38Z-test.txt) (evidence waived: not app-surface work: audit-domains.sh is a monitoring/cron script invoked directly from the main checkout path (crontab: /home/omri/projects/bass-tuner/scripts/audit-domains.sh, see scripts/install-monitoring-crons.sh:53), not part of the Vercel-deployed bass-tuner PWA this board's activation gate (pwa/ux/correctness/security/deploy/feature/perf/a11y/vercel) exists for. Already live on disk the moment the commit landed on main -- no deploy/restart step exists for it.)
