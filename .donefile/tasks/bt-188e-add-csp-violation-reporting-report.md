---
id: bt-188e
title: Add CSP violation reporting (report-uri/report-to)
status: done
priority: p3
tags:
  - security
  - http-headers
  - observability
created: 2026-10-03
filed:
  owner: capacity-engine/worker
  at: 2026-10-03T01:19:58Z
activation: none - Vercel is git-integrated, push to origin/main auto-deploys
done:
  at: 2026-10-03T01:33:56Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: a97c6d5
    verified: 2026-10-03T01:33:56Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && node --test test/vercel-headers.test.js
    exit: 0
    at: 2026-10-03T01:33:54Z
    log: evidence/bt-188e-2026-10-03T01-33-54Z-test.txt
    sha256: 621bfe0a12356fa4fecc1f5ec8445446c165cba5be9b1b57d571fb7693a1d684
    bytes: 2538
  - type: live
    cmd: "bash /home/omri/projects/bass-tuner/deploy/activation-probes/probe-bt-188e.sh | grep -q
      '^probe-bt-188e: PASS'"
    exit: 0
    at: 2026-10-03T01:33:54Z
    log: evidence/bt-188e-2026-10-03T01-33-54Z-live.txt
    sha256: 704eaab02bbece0972071d47201e08ced520589409260222eca840639ae25835
    bytes: 114
---

Fleet scan (kd-506a, 2026-10-02) found bass-tuner's CSP ships with no report-uri/report-to, so a blocked script is invisible. Filed per kd-c97e (mis-filed on kidai's board; moving the finding here per the repo-ownership rule).

## Log
- 2026-10-03 claimed by capacity-engine/worker
- 2026-10-03 done by capacity-engine/worker — commit a97c6d5, test `cd /home/omri/projects/bass-tuner && node --test test/vercel-headers.test.js` exit 0 (log: evidence/bt-188e-2026-10-03T01-33-54Z-test.txt), live `bash /home/omri/projects/bass-tuner/deploy/activation-probes/probe-bt-188e.sh | grep -q '^probe-bt-188e: PASS'` exit 0 (log: evidence/bt-188e-2026-10-03T01-33-54Z-live.txt)
