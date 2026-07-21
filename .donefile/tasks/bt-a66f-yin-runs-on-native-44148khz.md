---
id: bt-a66f
title: YIN runs on native 44.1/48kHz at fftSize 8192 — ~11M float ops/detection, heavy on mobile
status: claimed
priority: p2
tags:
  - perf
created: 2026-07-14
claim:
  owner: capacity-engine
  at: 2026-07-21T21:52:52Z
---

tuner.js:443 sets analyser.fftSize=8192 and :349 runs detectPitchYIN at state.audioCtx.sampleRate (native 44.1/48kHz). Diff loop (tuner.js:278-285) is O((tauMax-tauMin)*(SIZE-tauMax)) ~ 1800*6360 ~ 11M mult-add per detection, x22/s (DETECT_INTERVAL_MS=45) ~ 250M ops/s of tight float math => battery drain / thermal / jank on low-end phones. The header comment tuner.js:1-3 claims 'we sample at 22.05 kHz worth of resolution' but the code never downsamples or sets sampleRate, so it does 2x the work described. Fix: create AudioContext({sampleRate:22050}) or decimate the buffer before YIN; halves cost and matches the stated design.

## Log
- 2026-07-21 claimed by capacity-engine
