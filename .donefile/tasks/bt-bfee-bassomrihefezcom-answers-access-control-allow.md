---
id: bt-bfee
title: "bass.omrihefez.com answers Access-Control-Allow-Origin: * , defeating the
  Cross-Origin-Resource-Policy vercel.json sets - and the header test only asserts headers it
  expects"
status: claimed
priority: p3
tags:
  - security
  - http-headers
created: 2026-10-05
filed:
  owner: meni-worker/board-refill-work-discov-5e7b4f
  at: 2026-10-04T22:35:30Z
claim:
  owner: capacity-engine
  at: 2026-10-04T23:31:49Z
---

Measured live 2026-10-05 01:26 IDT, `curl -sI https://bass.omrihefez.com/`:

    access-control-allow-origin: *
    cross-origin-resource-policy: same-origin
    cross-origin-opener-policy: same-origin

Those first two headers state opposite intents on the same response. `vercel.json`
deliberately sets `Cross-Origin-Resource-Policy: same-origin` to stop other origins
reading this document; `Access-Control-Allow-Origin: *` grants exactly that.

WHERE THE ACAO COMES FROM. Not from this repo. `grep -n -i access-control
vercel.json` returns nothing, and `middleware.js` sets headers only on the
tuner->bass 308 redirect path (line 27). The response also carries
`accept-ranges: bytes` and `content-disposition: inline`, which is Vercel's static
file handler, not Next — so the `*` is a platform default that lands ON TOP of this
repo's `headers` block. Confirmed by comparison against the sibling surfaces, all
probed in the same minute: planner, kidai, meni and tik send no ACAO at all, and
compose sends its own origin. bass is the only `*` in the estate.

PRICED HONESTLY — THIS IS HYGIENE, NOT A DATA LEAK. bass.omrihefez.com is a fully
public static page with no credential, no cookie and no per-user content, so there
is nothing an attacker gains by reading it cross-origin that they could not read by
fetching it directly. The reason it is still worth fixing is that the two headers
cannot both be the intent, and nobody can tell from the repo which one is: a later
reader seeing CORP in `vercel.json` will reasonably believe cross-origin reads are
refused when they are not.

THE REAL DEFECT IS THE TEST, AND IT GENERALISES. `test/vercel-headers.test.js`
asserts the headers this repo INTENDS are present (it checks for
`Cross-Origin-Resource-Policy: same-origin` at line 36). Nothing asserts that a
header the repo did not ask for is ABSENT, so a platform default can contradict a
deliberate security header and every check stays green. The same hole exists in the
fleet's header checks generally — `scripts/audit-domains.sh` and
`scripts/check-permissions-policy.sh` both look for headers that should be there,
never for headers that should not be.

DONE WHEN:
  - A decision is recorded, either way: drop CORP/COOP if cross-origin reads are
    genuinely fine for a public tuner, or suppress the ACAO (a `vercel.json` headers
    entry setting `Access-Control-Allow-Origin` to the empty value, or moving the
    document behind middleware) so the response stops contradicting itself.
  - `test/vercel-headers.test.js` gains an assertion on a LIVE response that the
    header set is consistent with whichever decision was taken — specifically an
    assertion that FAILS against today's live headers. Say so in the evidence: run
    it before the fix and show it red. A test that only passes after is not evidence
    here, because the current state already passes every existing test.
  - Do NOT close this with a grep of `vercel.json`. The `*` is not in `vercel.json`;
    that is the whole point. Evidence must read the served response.

## Log
- 2026-10-05 claimed by capacity-engine
