---
id: bt-c8b4
title: mic-blocked recovery instructions name the pre-redirect domain, so they send the user to look
  for a permission entry that is not the one blocking them
status: done
priority: p3
tags:
  - ux
  - correctness
created: 2026-07-30
done:
  at: 2026-08-01T09:16:15Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: "3937238"
    verified: 2026-08-01T09:16:15Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-08-01T09:16:14Z
    log: evidence/bt-c8b4-2026-08-01T09-16-14Z-test.txt
    sha256: 931ef530807dbf81735e7fc11a56c7df4e2bb58dd8df88bbf46d40bd62afb127
    bytes: 18025
---

tuner.js lines 547 and 702 both render the microphone-blocked help text. They tell the user to find tuner.omrihefez.com under Chrome Site settings then Microphone, and to visit https://bass.omrihefez.com for a fresh prompt. vercel.json lines 2-9 permanently 301 tuner.omrihefez.com to bass.omrihefez.com, so by the time anyone sees this message they are already ON bass.omrihefez.com: the permission entry they are told to hunt for is the wrong origin, and the page they are told to visit is the one they are looking at. Chrome keys mic permission per origin, so following these instructions exactly cannot unblock the app. This is user-facing text on the primary error path of a tuner whose entire function needs the microphone - a user who hits it has no working product and no correct way out. DONE WHEN: both strings name bass.omrihefez.com as the site to find in Site settings, drop the redundant visit-the-other-domain step, and the flow is confirmed against a real mic-denied browser session.

## Log
- 2026-08-01 claimed by capacity-engine
- 2026-08-01 done by capacity-engine/worker — commit 3937238, test `npm test` exit 0 (log: evidence/bt-c8b4-2026-08-01T09-16-14Z-test.txt)
