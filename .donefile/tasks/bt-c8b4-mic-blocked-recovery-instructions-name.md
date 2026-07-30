---
id: bt-c8b4
title: mic-blocked recovery instructions name the pre-redirect domain, so they send the user to look
  for a permission entry that is not the one blocking them
status: open
priority: p3
tags:
  - ux
  - correctness
created: 2026-07-30
---

tuner.js lines 547 and 702 both render the microphone-blocked help text. They tell the user to find tuner.omrihefez.com under Chrome Site settings then Microphone, and to visit https://bass.omrihefez.com for a fresh prompt. vercel.json lines 2-9 permanently 301 tuner.omrihefez.com to bass.omrihefez.com, so by the time anyone sees this message they are already ON bass.omrihefez.com: the permission entry they are told to hunt for is the wrong origin, and the page they are told to visit is the one they are looking at. Chrome keys mic permission per origin, so following these instructions exactly cannot unblock the app. This is user-facing text on the primary error path of a tuner whose entire function needs the microphone - a user who hits it has no working product and no correct way out. DONE WHEN: both strings name bass.omrihefez.com as the site to find in Site settings, drop the redundant visit-the-other-domain step, and the flow is confirmed against a real mic-denied browser session.
