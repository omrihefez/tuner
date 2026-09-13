---
id: bt-443d
title: fix compose.omrihefez.com's missing security headers (CSP, X-Frame-Options,
  X-Content-Type-Options, Referrer-Policy, wildcard CORS)
status: done
priority: p3
tags:
  - security
  - cross-board — compose is boardless
  - so this needs filing to ~/inbox/meni-board-queue/ or Main's own action
  - not a bass-tuner board task
created: 2026-09-11
filed:
  owner: capacity-engine
  at: 2026-09-10T21:24:04Z
done:
  at: 2026-09-13T16:04:51Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: c2bda839a3858a1fa8bf1e842968db363c4545ec
    repo: compose
    verified: 2026-09-13T16:04:51Z
  - type: live
    cmd: 'resp=$(curl -sD - -o /dev/null --max-time 15 https://compose.omrihefez.com/) && echo "$resp" |
      grep -qi "^content-security-policy:" && echo "$resp" | grep -qi "^x-frame-options:" && echo
      "$resp" | grep -qi "^x-content-type-options:" && echo "$resp" | grep -qi "^referrer-policy:"
      && echo "$resp" | grep -qi "^access-control-allow-origin: https://compose.omrihefez.com"'
    exit: 0
    at: 2026-09-13T16:04:50Z
    log: evidence/bt-443d-2026-09-13T16-04-50Z-live.txt
    sha256: f8520ab6bc8bd994fb9e1c3d3393a628c69e5fc1d5e1592782dc7fe19146fe86
    bytes: 372
  - type: note
    value: "Verified compose.omrihefez.com live: was missing
      CSP/X-Frame-Options/X-Content-Type-Options/Referrer-Policy and served
      access-control-allow-origin:* (curl'd 2026-09-13 15:56 UTC, before fix). Fixed via compose
      repo's vercel.json (new file, this app had none) — CSP matches the fleet baseline (bt-a2c2),
      scoped to compose's actual resources (self-contained Next.js App Router app: no external
      scripts/fonts/images/CDNs); script-src/style-src keep unsafe-inline because Next's App Router
      hydration payload and this app's dynamic inline style props (music-notation layout) need it —
      nonce-based CSP was ruled out because this route prerenders as fully static and Next's
      auto-nonce injection only works for dynamically-rendered pages. Also scoped
      Access-Control-Allow-Origin from * to the site's own origin. bt-a2c2's audit-domains.sh
      (0532fc85) added detection for the 4-header baseline but does not fix hosts or check CORS --
      it did not cover this finding, contra the filing's LIKELY-ALREADY-DONE heuristic. Deployed to
      Vercel production (vercel --prod, aliased to compose.omrihefez.com) and verified live
      post-deploy."
---

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `0532fc85` 2026-09-11 "audit-domains.sh: assert security-header baseline per host (bt-a2c2)" — scripts/audit-domains.sh, scripts/audit-domains.test.sh (87% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
Priority lowered p2 -> p3 on that match alone; raise it back if the finding turns out to be real (ce-a792).
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-a2c2, session `audit-domains-sh-discard-a0a9a5`, dispatched on bass-tuner.
Reported 2026-09-11 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 0532fc85b906e85ef0f2bf6c8c4088a75494fe75).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-11 blocker bt-a2c2 closed 2026-09-10T21:20:20Z — recheck whether this can proceed now.
- 2026-09-13 claimed by capacity-engine
- 2026-09-13 done by capacity-engine/worker — commit c2bda839a385 (compose), live `resp=$(curl -sD - -o /dev/null --max-time 15 https://compose.omrihefez.com/) && echo "$resp" | grep -qi "^content-security-policy:" && echo "$resp" | grep -qi "^x-frame-options:" && echo "$resp" | grep -qi "^x-content-type-options:" && echo "$resp" | grep -qi "^referrer-policy:" && echo "$resp" | grep -qi "^access-control-allow-origin: https://compose.omrihefez.com"` exit 0 (log: evidence/bt-443d-2026-09-13T16-04-50Z-live.txt)
