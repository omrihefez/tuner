---
id: bt-bfee
title: "bass.omrihefez.com answers Access-Control-Allow-Origin: * , defeating the
  Cross-Origin-Resource-Policy vercel.json sets - and the header test only asserts headers it
  expects"
status: done
priority: p3
tags:
  - security
  - http-headers
created: 2026-10-05
filed:
  owner: meni-worker/board-refill-work-discov-5e7b4f
  at: 2026-10-04T22:35:30Z
done:
  at: 2026-10-04T23:56:23Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 925d494
    verified: 2026-10-04T23:56:23Z
  - type: test
    cmd: bash scripts/check-cors-corp-consistency.test.sh
    exit: 0
    at: 2026-10-04T23:56:22Z
    log: evidence/bt-bfee-2026-10-04T23-56-22Z-test.txt
    sha256: 0d1f77e8c7010fdb710b385d53f890e23dc2859f83921c77324646f0b44408e4
    bytes: 908
  - type: live
    cmd: bash deploy/activation-probes/probe-bt-bfee.sh
    exit: 0
    at: 2026-10-04T23:56:22Z
    expect: PASS
    log: evidence/bt-bfee-2026-10-04T23-56-22Z-live.txt
    sha256: 88e7a5d1c57766fae75525982c418d188f4e20562285658f7bced1d3afea7e03
    bytes: 284
  - type: note
    value: "Branch spans a86d8b2..925d494 (two commits: the fix itself, then a doc-only README update
      recording the live probe's post-deploy PASS). ACAO:* was a Vercel platform default never
      present in vercel.json, not catchable by the old config-reading test. Fix: explicit
      ACAO=https://bass.omrihefez.com in vercel.json (confirmed via live preview deploy that an
      empty-string value does NOT override the platform default, only a concrete value does); kept
      CORP/COOP same-origin per bt-d517's deliberate posture. New
      scripts/check-cors-corp-consistency.sh (+hermetic test) and
      deploy/activation-probes/probe-bt-bfee.sh read the live response; probe confirmed FAIL against
      the still-unpatched site pre-deploy and PASS against production post-deploy."
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
- 2026-10-05 done by capacity-engine/worker — commit 925d494, test `bash scripts/check-cors-corp-consistency.test.sh` exit 0 (log: evidence/bt-bfee-2026-10-04T23-56-22Z-test.txt), live `bash deploy/activation-probes/probe-bt-bfee.sh` exit 0 (--live-expect "PASS") (log: evidence/bt-bfee-2026-10-04T23-56-22Z-live.txt)
