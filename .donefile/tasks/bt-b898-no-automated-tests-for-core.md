---
id: bt-b898
title: No automated tests for core pitch/note math
status: claimed
priority: p1
tags:
  - tests
created: 2026-07-14
claim:
  owner: capacity-engine
  at: 2026-07-14T05:50:58Z
---

tuner.js:76-87 (midiToFreq/freqToMidi/noteLabel), :57-61 (medianPitch), :219-228 (closestString), :263-322 (detectPitchYIN) are pure, deterministic, and safety-critical (wrong Hz = wrong tuning) yet have ZERO tests. No package.json, no test runner, no fixtures. Why wrong: a regression in the note math silently mistunes every user with no guard. Fix: add a minimal test setup (node --test or vitest) with known-answer cases (A4=440 -> 69; E1=28 -> 41.20Hz; noteLabel(28)=E1; closestString and YIN on a synthesized sine).

## Log
- 2026-07-14 claimed by capacity-engine
