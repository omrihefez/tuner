---
id: bt-6146
title: "audit-domains.sh: oauth.omrihefez.com/health missing x-frame-options and permissions-policy
  (live DRIFT)"
status: done
priority: p3
tags:
  - security
  - http-headers
  - monitoring
created: 2026-10-10
filed:
  owner: capacity-engine/worker
  at: 2026-10-10T16:22:08Z
done:
  at: 2026-10-10T16:44:36Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: bash scripts/audit-domains.sh | grep -qv 'DRIFT.*oauth.omrihefez.com'
    exit: 0
    at: 2026-10-10T16:44:35Z
    log: evidence/bt-6146-2026-10-10T16-44-35Z-test.txt
    sha256: 8764e02dc47c5a9b3055d64ddfdcc21886cc39f4a417f98ecef1a5ef7ae3dedd
    bytes: 73
  - type: live
    cmd: "curl -sI https://oauth.omrihefez.com/health | grep -qi 'x-frame-options: DENY' && curl -sI
      https://oauth.omrihefez.com/health | grep -qi '^permissions-policy:'"
    exit: 0
    at: 2026-10-10T16:44:35Z
    log: evidence/bt-6146-2026-10-10T16-44-35Z-live.txt
    sha256: defdff7826ee051e304222e27c22a8b4f64dbf6280d48a722eb48741c681fc79
    bytes: 163
  - type: note
    value: "Premise was live (confirmed via scripts/audit-domains.sh on origin/main before fix: DRIFT
      oauth.omrihefez.com/health missing x-frame-options,permissions-policy). Fix landed outside
      bass-tuner, in apartment's oauth-callback service (unregistered board, no remote, not in
      donefile's repo-alias list): local commit 68a1230 on apartment's master. Same pattern as
      ap-2037/bt-dc36/bt-d945 — this host's header fixes live in apartment, bass-tuner only detects.
      _security_headers() in smarthome/oauth-callback/server.py now also sends X-Frame-Options: DENY
      and Permissions-Policy: camera=(), microphone=(), geolocation=() (matching house/tik's
      no-device-API value; CSP already had frame-ancestors 'none' but audit baseline checks
      X-Frame-Options explicitly for older UAs). test_server.py's _assert_baseline extended;
      confirmed failing (4/4 red) against pre-fix server.py and passing (4/4 green) after restore --
      seen to fail, not just seen to pass. Committed in an isolated worktree
      (/home/omri/apartment-worktrees/bt-6146-oauth-headers), ff-merged to apartment master
      (68a1230), worktree removed. Service restarted 2026-10-10 19:43 IDT after confirming no active
      flow (journalctl quiet 2h, pending/ dir empty). Live curl confirms both headers present.
      bass-tuner's own audit-domains.sh re-run full: exit 0, no DRIFT anywhere;
      audit-domains.test.sh (unmodified, control) still passes 41/41 -- this task touched zero
      bass-tuner files. Cross-board pointer ce-9ab6/iac-55fe checked: unrelated (GCP SA key rotation
      decision, not HTTP headers)."
---

Discovered while closing bt-820a. Confirmed live and on unmodified origin/main (pre-existing, unrelated to bt-820a's apex-HSTS fix): `DRIFT  oauth.omrihefez.com/health -> 200 missing security headers: x-frame-options,permissions-policy`. Measured 2026-10-10 via scripts/audit-domains.sh run on both the fix branch and a control worktree at origin/main (same commit, 59a954e) — identical finding on both, so it predates and is independent of bt-820a's change.

## Log
- 2026-10-10 claimed by capacity-engine
- 2026-10-10 done by capacity-engine/worker — test `bash scripts/audit-domains.sh | grep -qv 'DRIFT.*oauth.omrihefez.com'` exit 0 (log: evidence/bt-6146-2026-10-10T16-44-35Z-test.txt), live `curl -sI https://oauth.omrihefez.com/health | grep -qi 'x-frame-options: DENY' && curl -sI https://oauth.omrihefez.com/health | grep -qi '^permissions-policy:'` exit 0 (log: evidence/bt-6146-2026-10-10T16-44-35Z-live.txt)
