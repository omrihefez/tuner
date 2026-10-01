---
id: bt-4164
title: Add permissions-policy to the audit-domains.sh baseline — 7 of 10 live hosts now send it, and
  it is the one header the estate has had to chase by hand twice
status: open
priority: p3
tags:
  - monitoring
  - security
created: 2026-10-01
filed:
  owner: meni-worker/board-refill-work-discov-edb20d
  at: 2026-10-01T08:07:59Z
---

`REQUIRED_HEADERS` in `scripts/audit-domains.sh` (line 54) is:

    REQUIRED_HEADERS=(x-frame-options x-content-type-options referrer-policy)

plus a CSP check in `missing_security_headers()`. `permissions-policy` is not in it.

That was CORRECT when bt-a2c2 wrote the baseline — its own comment (lines 37-38) says the list is
"what those seven siblings actually send, not an aspirational list", and at the time only four of
seven sent `Permissions-Policy`. That premise has since changed, and nobody revisited the list.

MEASURED LIVE 2026-10-01 ~11:02-11:03 IDT:

    bass       camera=(), microphone=(self), geolocation=()
    kidai      camera=(), microphone=(), geolocation=(), interest-cohort=()
    meniapp    camera=(), microphone=(self), geolocation=()
    planner    camera=(), microphone=(), geolocation=()
    tik        camera=(), microphone=(), geolocation=()
    trips      camera=(), microphone=(), geolocation=(self)
    house      camera=(), microphone=(), geolocation=()
    compose    <absent>
    meni       <absent>
    arch-preview <absent>

Seven of ten send it. It is now the estate norm, not an aspiration — which is exactly the test
bt-a2c2's comment sets for admission to the baseline.

WHY THIS IS WORTH A TASK RATHER THAN A ONE-LINE EDIT SOMEDAY: this is the single header the estate
has had to chase by hand, twice, because no monitor watched it. `df-024f` was filed 2026-09-25
after a human ran the seven-host loop by hand and found four misses; `ar-3426` was then filed
2026-09-27 after another human re-measured meni-arch the same way. Both would have been a DRIFT
line in a scheduled run if the header were in this list. The remaining two misses (compose,
meni-arch) are each already tracked on their own boards — so adding the header here is not
re-filing those, it is making sure the next regression is found by the monitor instead of by a
person.

## Done when

- `permissions-policy` is in the baseline the audit asserts, with a comment recording the
  2026-10-01 measurement above as the admission evidence (same discipline bt-a2c2 used).
- PRESENCE, not an exact value: the seven hosts that send it legitimately disagree on the value
  (`microphone=(self)` on bass/meniapp because they use the mic, `geolocation=(self)` on trips,
  `interest-cohort=()` on kidai). A single expected string would create false DRIFT on four hosts.
  Per-host exact values are `scripts/check-permissions-policy.sh`'s job and already exist for bass.
- The two hosts known to be missing it today (compose, meni-arch's `meni`/`arch-preview`) must not
  turn this into a permanently-red run while their own tasks are open. Either land this after they
  close, or carry a named, dated exemption for each pointing at `cp-`/`ar-3426` — an exemption with
  a task id and a date, never a silent skip.
- A test in `scripts/audit-domains.test.sh` feeds a stubbed 200 response with no
  `permissions-policy` and asserts DRIFT, seen to FAIL against the parent commit.

## Verify (from the main checkout, never a worktree)

    cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh

Filed by the periodic discovery sweep, 2026-10-01.
