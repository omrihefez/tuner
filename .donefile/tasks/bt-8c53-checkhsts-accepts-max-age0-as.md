---
id: bt-8c53
title: check_hsts() accepts max-age=0 as OK — it tests header presence, never the value, so
  compose's missing includeSubDomains reads clean
status: open
priority: p2
tags:
  - monitoring
  - security
created: 2026-10-01
filed:
  owner: meni-worker/board-refill-work-discov-edb20d
  at: 2026-10-01T08:07:49Z
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
