---
id: bt-8c53
title: check_hsts() accepts max-age=0 as OK — it tests header presence, never the value, so
  compose's missing includeSubDomains reads clean
status: done
priority: p2
tags:
  - monitoring
  - security
created: 2026-10-01
filed:
  owner: meni-worker/board-refill-work-discov-edb20d
  at: 2026-10-01T08:07:49Z
done:
  at: 2026-10-01T08:54:31Z
  by: capacity-engine/worker
  waived: tagged 'security' (an activation.tag) but the change is entirely scripts/audit-domains.sh +
    its test suite -- an ops/monitoring script never referenced by vercel.json and not part of the
    served PWA bundle. No deploy/activation step applies; nothing for a --live probe to hit.
evidence:
  - type: commit
    value: 945da78ff49cc72ad9d0727806bcc69196390c6b
    verified: 2026-10-01T08:54:31Z
  - type: test
    cmd: bash scripts/audit-domains.test.sh
    exit: 0
    at: 2026-10-01T08:54:19Z
    log: evidence/bt-8c53-2026-10-01T08-54-19Z-test.txt
    sha256: 4e8dae43e0ea3fb0a5582e9d7275d01be8a0ea9ed4d52c5b42c8cf8ae66f99e0
    bytes: 8499
  - type: note
    value: "Hardened check_hsts() to parse max-age (floor 31536000, the lowest live value today) and
      require includeSubDomains; preload deliberately left as a per-host human call, documented in
      the comment. Added tests 24-26 (max-age=0 DRIFT, missing-includeSubDomains DRIFT, passing
      shape) and fixed 8 existing fixtures that had max-age without includeSubDomains (would have
      gone DRIFT under the new stricter check). Confirmed test 24's exact fixture prints OK pre-fix
      against parent commit 79a00b3 (verified via a detached control worktree, not stash -- per this
      repo's own shared-stash ban). Sibling note in the task body claiming the SUBS loop never calls
      check_hsts() is STALE: bt-3ba1 (same commit 79a00b3) already fixed that earlier the same
      sweep."
---

`check_hsts()` in `scripts/audit-domains.sh` (lines 158-166) tests only that the header NAME is
present:

    if echo "$resp" | grep -qi '^strict-transport-security:'; then
      echo "OK     $label -> $code (Strict-Transport-Security present)"

It never reads `max-age`, `includeSubDomains` or `preload`. So `max-age=0` — which actively
INSTRUCTS the browser to forget the HSTS pin — passes this check as OK, and so does any value that
has quietly lost `includeSubDomains`.

That is not a theoretical gap. MEASURED LIVE 2026-10-01 ~11:02 IDT:

    compose    strict-transport-security: max-age=63072000
    bass       strict-transport-security: max-age=31536000; includeSubDomains
    planner    strict-transport-security: max-age=63072000; includeSubDomains; preload
    meniapp    strict-transport-security: max-age=63072000; includeSubDomains; preload
    kidai      strict-transport-security: max-age=63072000; includeSubDomains; preload
    trips      strict-transport-security: max-age=63072000; includeSubDomains; preload
    tik        strict-transport-security: max-age=63072000; includeSubDomains; preload
    meni       strict-transport-security: max-age=31536000; includeSubDomains
    house      strict-transport-security: max-age=31536000; includeSubDomains

compose is the lone host with no `includeSubDomains`, and three distinct `max-age` values are in
use across nine hosts. A presence-only check reports every one of those as OK and cannot
distinguish any of them.

THE ARGUMENT THIS REPO ALREADY MADE, ONE FILE OVER. `scripts/check-permissions-policy.sh` lines
11-14 say it outright: "The exact value matters more than presence: `microphone=()` (empty
allowlist) would refuse getUserMedia in the page itself and silently break the tuner, so this
checks the full value, not just that the header exists." Same repo, same author's reasoning, and
the weaker discipline is the one applied to the header that is strictly transport security.

## Done when

- `check_hsts()` parses `max-age` and refuses a value below a named floor (pick one and say why in
  the comment — `31536000` is what three live hosts use today, so that is the honest floor, not
  `63072000`), and reports DRIFT when `includeSubDomains` is absent.
- Whether `preload` is required is a decision, not a default: six hosts send it and three do not,
  and adding `preload` to a host is effectively irreversible on the browser preload list. Record
  the call in the comment rather than silently asserting it.
- A test in `scripts/audit-domains.test.sh` feeds `CURL_CMD` a stubbed
  `strict-transport-security: max-age=0` response and asserts DRIFT. It must be seen to FAIL
  against the parent commit, where that input prints OK.

## Note on ordering

Sibling finding filed the same sweep: the `SUBS` (Vercel) loop never calls `check_hsts` at all, so
strengthening this function does nothing for the nine Vercel hosts until that is fixed too. These
are separate defects — WHAT the function asserts vs WHERE it is called — and either can land first,
but closing only this one leaves compose's value still unchecked in practice.

## Verify (from the main checkout, never a worktree)

    cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh

Filed by the periodic discovery sweep, 2026-10-01.

## Log
- 2026-10-01 claimed by capacity-engine
- 2026-10-01 done by capacity-engine/worker — commit 945da78ff49c, test `bash scripts/audit-domains.test.sh` exit 0 (log: evidence/bt-8c53-2026-10-01T08-54-19Z-test.txt) (evidence waived: tagged 'security' (an activation.tag) but the change is entirely scripts/audit-domains.sh + its test suite -- an ops/monitoring script never referenced by vercel.json and not part of the served PWA bundle. No deploy/activation step applies; nothing for a --live probe to hit.)
