---
id: bt-0611
title: audit-domains.sh exempts oauth from the security-header baseline as 'no auth wall by design'
  — which is why ap-2037's missing CSP/nosniff on our one public surface went unseen
status: done
priority: p2
tags:
  - monitoring
  - security
created: 2026-10-08
filed:
  owner: meni-worker/board-refill-work-discov-b483dc
  at: 2026-10-08T00:34:31Z
done:
  at: 2026-10-08T01:08:53Z
  by: capacity-engine/worker
  waived: "security tag is a false positive for activation-gating here: this change touches only
    scripts/audit-domains.sh and its test (a repo/process monitoring script per
    .donefile/config.yml's own 'tags NOT listed' note), not the Vercel-served PWA surface
    (manifest.json/sw.js/vercel.json/static HTML-CSS-JS). Nothing to deploy or activate."
evidence:
  - type: commit
    value: f5c1942
    verified: 2026-10-08T01:08:53Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh
    exit: 0
    at: 2026-10-08T01:08:24Z
    log: evidence/bt-0611-2026-10-08T01-08-24Z-test.txt
    sha256: eaa720686fcf0fd235333088cfb17c0397b206501cb588849eca638a19739db6
    bytes: 11895
  - type: note
    value: oauth moved from a blanket NONVERCEL_HEADER_SKIP_REASON exemption into
      NONVERCEL_CHECK_PATHS[oauth]=/health (same per-path baseline class as tik-api/meniapp-api);
      brain's exemption reviewed and kept, now dated/tagged bt-0611 so a reviewed exemption no
      longer looks identical to an unreviewed one. New tests 11c/11d assert oauth missing
      x-content-type-options is DRIFT, confirmed to fail against the parent commit (fbf5e62) and
      pass after the fix. /clips/<name>.mp3 on the same host (server.py) also bypasses headers but
      has no stable registry-known path to pin — filed as follow-up, not guessed at.
---

`scripts/audit-domains.sh` exempts `oauth` from the body-shaped security-header
baseline (CSP / X-Frame-Options / nosniff / Cache-Control) on this stated
rationale:

    audit-domains.sh:140
    [oauth]="intentionally public with no auth wall by design; correct
             behaviour, not drift"

    audit-domains.sh:147-149
    `brain`/`oauth` stay OUT of NONVERCEL_CHECK_PATHS (their 404/public
    bodies must never be scored against the CSP/XFO/nosniff/Cache-Control
    baseline meant for a real app response)

The exemption conflates "has no AUTH wall" with "serves no real app response".
For `oauth` the second half is false, and the host's own code disagrees with the
exemption: `smarthome/oauth-callback/server.py`'s `_html()` helper (line 65)
sets `Content-Security-Policy`, `Referrer-Policy` and
`X-Content-Type-Options: nosniff` on every response that goes through it. That
IS a real app response carrying the baseline. The exemption says such a response
cannot exist here.

## What the exemption let through

The two response paths that bypass `_html()` ship none of those headers, and
nothing noticed for months because this script is the one place that would have:

- `do_HEAD` (server.py:135) hand-rolls four headers of its own.
- the `/clips/` hit branch of `do_GET` (server.py:86-99) writes its own response
  with only Content-Type / Content-Length / HSTS. `/clips/<name>.mp3` serves file
  CONTENT from a public path with no `nosniff` and no CSP, and the only
  validation is `name.endswith(".mp3")` plus `f.is_file()` — the bytes are never
  checked.

RE-MEASURED LIVE 2026-10-08 03:2x IDT, still true:

    curl -sI https://oauth.omrihefez.com/health
    HTTP/2 200
    content-type: text/html; charset=utf-8
    cache-control: no-store
    strict-transport-security: max-age=63072000; includeSubDomains; preload
    (no content-security-policy, no referrer-policy, no x-content-type-options)

The header fix itself is apartment's ap-2037 (open p2, filed 2026-10-07). This
task is the OTHER half: why the estate's own header auditor was structurally
incapable of reporting it, on the one intentionally-public unauthenticated
surface we run.

## The precedent is already in this file

`tik-api`/`tik-api-vps` were in exactly this position and were reassessed
(bt-135b, audit-domains.sh:120-131). The reasoning recorded there applies
verbatim to `oauth`:

    nosniff still matters on a bare JSON body, so they get the per-path
    baseline rather than a by-design exemption
    ... Confirmed live and fixed in the tik-api repo: nosniff was entirely
    absent before this task.

So the reassessment pattern exists, has been done once, and found a real missing
header the first time it ran. It has never been applied to `oauth` — the host
where it matters most, because it is the only one with no auth wall in front of
it at all.

The same comment block also records why root-only probing is not enough
(hc-d30f: house-control's `/` WAS the redirect that skipped the headers), which
is the same per-path lesson `oauth` needs: `/health` and `/clips/<x>.mp3` are
different response paths with different header sets.

## DONE WHEN

- `oauth` is assessed per-path rather than exempted wholesale: a
  `NONVERCEL_CHECK_PATHS[oauth]` entry covering the paths that serve a real
  response, and the `NONVERCEL_HEADER_SKIP_REASON[oauth]` exemption removed or
  narrowed to only what genuinely cannot carry the baseline. The existing
  `NONVERCEL_HSTS_ONLY_PATH[oauth]="/health"` was the right instinct (bt-b75b
  narrowed the skip once already) — this finishes that narrowing.
- `brain` is assessed in the same pass and a verdict recorded either way. Its
  exemption is more defensible (a bare 404 to every unauthenticated request), but
  "more defensible" should be written down as a decision, not left as the same
  one-line reason that turned out wrong for `oauth`. Per
  `_excluded_boards_note`-style convention: an unreviewed exemption and a
  reviewed one must not look identical.
- The script's own tests are updated to match. `audit-domains.test.sh:232` and
  `:335` currently ASSERT the HSTS-only scope and the SKIP line for `oauth`, so
  they will fail on this change — that is correct and is the signal, not a
  problem to route around. Replace them with fixtures asserting the per-path
  baseline runs for `oauth`, including a fixture where a header is MISSING and
  the script reports it.
- SEEN TO FAIL, explicitly: feed the script a fixture for `oauth` with no
  `x-content-type-options` and confirm it reports a failure. An exemption removed
  without that check just moves the host from "never checked" to "checked by
  something nobody has watched fail".
- Evidence: a run of `bash scripts/audit-domains.test.sh` exiting 0 with the new
  fixtures, plus the script's own output line for `oauth` showing the baseline
  being evaluated rather than skipped. Do NOT make the evidence a live
  `curl -sI` against oauth.omrihefez.com — that asserts ap-2037's fix, not this
  one, and this task must be closeable before or after that one lands.

## Log
- 2026-10-08 claimed by capacity-engine
- 2026-10-08 done by capacity-engine/worker — commit f5c1942, test `cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh` exit 0 (log: evidence/bt-0611-2026-10-08T01-08-24Z-test.txt) (evidence waived: security tag is a false positive for activation-gating here: this change touches only scripts/audit-domains.sh and its test (a repo/process monitoring script per .donefile/config.yml's own 'tags NOT listed' note), not the Vercel-served PWA surface (manifest.json/sw.js/vercel.json/static HTML-CSS-JS). Nothing to deploy or activate.)
