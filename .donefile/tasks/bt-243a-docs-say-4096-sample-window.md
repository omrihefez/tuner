---
id: bt-243a
title: Docs say 4096-sample window / 22.05kHz but code uses fftSize 8192 at native sample rate
status: open
priority: p3
tags:
  - docs
created: 2026-07-14
---

README.md ('a 4096-sample window is fed to a YIN pitch detector') and about.html:30 ('a 4096-sample window is analyzed') both state 4096, but tuner.js:443 sets analyser.fftSize=8192 and reads that many samples (tuner.js:346). The header comment tuner.js:1-3 also claims sampling 'at 22.05 kHz worth of resolution' which is never applied (context runs at native 44.1/48kHz). Why wrong: misleading public-facing docs on an open-source, audit-invited project. Fix: update the three locations to the real numbers, or change the code to match the docs.
