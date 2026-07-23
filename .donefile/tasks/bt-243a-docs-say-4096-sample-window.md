---
id: bt-243a
title: Docs say 4096-sample window / 22.05kHz but code uses fftSize 8192 at native sample rate
status: done
priority: p3
tags:
  - docs
created: 2026-07-14
done:
  at: 2026-07-23T05:34:05Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 396a38c
    verified: 2026-07-23T05:34:05Z
  - type: test
    cmd: sh -c "grep -q \"8192-sample window\" README.md && grep -q \"8192-sample window\" about.html &&
      grep -q \"analyser.fftSize = 8192\" tuner.js"
    exit: 0
    at: 2026-07-23T05:34:05Z
    log: evidence/bt-243a-2026-07-23T05-34-05Z-test.txt
    sha256: 5314004b5329f39962363c0d8cc747401e11ae43690b1e5151746b1f4b23aff5
    bytes: 145
---

README.md ('a 4096-sample window is fed to a YIN pitch detector') and about.html:30 ('a 4096-sample window is analyzed') both state 4096, but tuner.js:443 sets analyser.fftSize=8192 and reads that many samples (tuner.js:346). The header comment tuner.js:1-3 also claims sampling 'at 22.05 kHz worth of resolution' which is never applied (context runs at native 44.1/48kHz). Why wrong: misleading public-facing docs on an open-source, audit-invited project. Fix: update the three locations to the real numbers, or change the code to match the docs.

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit 396a38c, test `sh -c "grep -q \"8192-sample window\" README.md && grep -q \"8192-sample window\" about.html && grep -q \"analyser.fftSize = 8192\" tuner.js"` exit 0 (log: evidence/bt-243a-2026-07-23T05-34-05Z-test.txt)
