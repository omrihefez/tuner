---
id: bt-11d5
title: "Confirm live trips CSP img-src has no bare https: after dev->main promotion, then run
  bass-tuner check-csp-strength.sh"
status: done
priority: p3
tags:
  - csp
  - verify
created: 2026-10-29
filed:
  owner: capacity-engine
  at: 2026-10-29T07:47:13Z
reported: 2026-10-29
done:
  at: 2026-10-29T10:32:04Z
  by: capacity-engine
evidence:
  - type: live
    cmd: "curl -sfI https://trips.omrihefez.com/ | grep -iq \"img-src 'self' data: blob:
      https://upload.wikimedia.org\" && bash
      /home/omri/projects/bass-tuner/scripts/check-csp-strength.sh"
    exit: 0
    at: 2026-10-29T10:31:57Z
    log: evidence/bt-11d5-2026-10-29T10-31-57Z-live.txt
    sha256: b5e7feb19b5cf5197572fe8dff949fd63751a1870215c2263319217db7577494
    bytes: 2553
  - type: note
    value: "Gate truly cleared, verified independently of the probe: trips-hub th-c4c1 dd9c4f0e is on
      origin/main, live trips.omrihefez.com img-src = 'self' data: blob: + 4 named hosts (no bare
      https:), and check-csp-strength.sh (which flags bare https: in img-src and was red on trips at
      09:50 IST) exits 0, 13/16 hosts clean. Verified 2026-10-29 ~12:35 IST by ce-5bc0."
---

Named in the finding: check-csp-strength.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): live header still shows 'https:' at 09:45 IST, dd9c4f0e not on origin/main yet

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working th-c4c1, session `trips-omrihefez-com-csp--c11bf7`, dispatched on trips-hub.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit dd9c4f0e — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `dd9c4f0e` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: git -C /home/omri/projects/trips-hub fetch -q origin main && git -C /home/omri/projects/trips-hub grep -q 'IMG_HOSTS.join' origin/main -- lib/csp.ts

## Log
- 2026-10-29 claimed by capacity-engine
- 2026-10-29 PREMISE-PROBE: ! git -C /home/omri/projects/trips-hub grep -q 'data: https: blob:' origin/main -- lib/csp.ts && bash /home/omri/projects/bass-tuner/scripts/check-csp-strength.sh
- 2026-10-29 claim by capacity-engine parked (blocked)
- 2026-10-29 blocked: Live trips CSP still has bare https: in img-src (checked 09:50 IST). Fix th-c4c1 is on trips-hub dev only, not on main; dev->main promotion is attended. Re-run check-csp-strength.sh after promotion. [probe `git -C /home/omri/projects/trips-hub grep -q 'IMG_HOSTS.join' origin/main -- lib/csp.ts` exit 1, owner main]
- 2026-10-29 blocked reason updated: "Live trips CSP still has bare https: in img-src (checked 09:50 IST). Fix th-c4c1 is on trips-hub dev only, not on main; dev->main promotion is attended. Re-run check-csp-strength.sh after promotion." -> "Waits on trips-hub's own 15-min promote cron (scripts/promote.mjs, load-gated) carrying th-c4c1 dd9c4f0e dev->main; not an attended merge. Then re-run check-csp-strength.sh once the deploy watchdog ships main (~16min)."
- 2026-10-29 blocker th-c4c1 closed 2026-10-29T07:42:47Z — recheck whether this can proceed now.
- 2026-10-29 unblocked
- 2026-10-29 done by capacity-engine — live `curl -sfI https://trips.omrihefez.com/ | grep -iq "img-src 'self' data: blob: https://upload.wikimedia.org" && bash /home/omri/projects/bass-tuner/scripts/check-csp-strength.sh` exit 0 (log: evidence/bt-11d5-2026-10-29T10-31-57Z-live.txt)
