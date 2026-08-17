---
id: bt-4e51
title: Restore pinch-zoom — drop maximum-scale=1 / user-scalable=no (a11y/WCAG)
status: done
priority: p2
tags:
  - a11y
created: 2026-07-02
done:
  at: 2026-07-02T07:37:58Z
  by: meni@vps/bass-tuner-dev
evidence:
  - type: commit
    value: 05cd0782194fac4a3214b6ec44085dd0999d9291
    verified: 2026-07-02T07:37:58Z
  - type: note
    value: viewport now width=device-width,initial-scale=1 only; pinch-zoom allowed. SW bumped v7 so it
      ships.
---

`index.html:5` — the viewport meta is
`width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no`.
`maximum-scale=1` + `user-scalable=no` block pinch-zoom, a WCAG 1.4.4 (Resize
Text) failure — low-vision users can't magnify the note/cents readout. Fix: keep
`width=device-width, initial-scale=1`, drop the other two. Same bug class as the
tik MUX-01 audit finding.

## Log
- 2026-07-02 claimed by meni@vps/bass-tuner-dev
- 2026-07-02 done by meni@vps/bass-tuner-dev — commit 05cd0782194f
