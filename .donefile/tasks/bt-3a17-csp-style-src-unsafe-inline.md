---
id: bt-3a17
title: CSP style-src 'unsafe-inline' appears unnecessary — tighten it
status: done
priority: p3
tags:
  - security
created: 2026-07-14
done:
  at: 2026-07-23T05:40:01Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: b0803fd
    verified: 2026-07-23T05:40:01Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-23T05:40:00Z
    log: evidence/bt-3a17-2026-07-23T05-40-00Z-test.txt
    sha256: fa4c0e4a3e904bc1d716168d4dd9615c8c2dc64693d16b8c31b62dba62103fac
    bytes: 10843
  - type: live
    cmd: curl -sD - -o /dev/null https://tuner.omrihefez.com/ | grep -i content-security-policy
    exit: 0
    at: 2026-07-23T05:40:00Z
    log: evidence/bt-3a17-2026-07-23T05-40-00Z-live.txt
    sha256: 7ef4e3ee5ca440156754ded12812a894dbbffd026b452bb61e622f5ed47c8623
    bytes: 383
---

vercel.json CSP has style-src 'self' 'unsafe-inline'. Verified there are NO inline <style> blocks or style= attributes in index.html/about.html/privacy.html (grep clean). The needle animation uses CSSOM ($needle.style.left, tuner.js:418) which CSP does NOT gate. So 'unsafe-inline' for styles is very likely removable, tightening the policy at zero functional cost. Fix: drop 'unsafe-inline' from style-src and smoke-test the needle/layout; re-add only if something breaks.

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit b0803fd, test `npm test` exit 0 (log: evidence/bt-3a17-2026-07-23T05-40-00Z-test.txt), live `curl -sD - -o /dev/null https://tuner.omrihefez.com/ | grep -i content-security-policy` exit 0 (log: evidence/bt-3a17-2026-07-23T05-40-00Z-live.txt)
