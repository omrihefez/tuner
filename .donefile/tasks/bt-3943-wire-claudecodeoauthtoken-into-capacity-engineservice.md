---
id: bt-3943
title: Wire CLAUDE_CODE_OAUTH_TOKEN into capacity-engine.service (Infisical, same self-heal pattern
  as ~/bin/claude-hl) so judge()/judgeDuplicate()/judgeGate() headless calls actually authenticate —
  currently 100% silently fail-open
status: done
priority: p1
tags:
  - capacity-engine
  - infra
  - auth
created: 2026-07-25
done:
  at: 2026-07-25T10:43:34Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 49fb294
    repo: capacity-engine
    verified: 2026-07-25T10:43:34Z
  - type: test
    cmd: cd /home/omri/projects/capacity-engine && node test.mjs
    exit: 0
    at: 2026-07-25T10:43:24Z
    log: evidence/bt-3943-2026-07-25T10-43-24Z-test.txt
    sha256: 39b9f2e9a129b109135885ed35b375e484b160de56a7205bccd53fb0ffdbffbe
    bytes: 79
  - type: live
    cmd: cd /home/omri/projects/capacity-engine && node engine.mjs judge-probe
    exit: 0
    at: 2026-07-25T10:43:24Z
    log: evidence/bt-3943-2026-07-25T10-43-24Z-live.txt
    sha256: cf5f13ab28acd56614e612a748bc9e7403f08d6e1ac46ce5932a6de214be0c9b
    bytes: 188
---

## Log
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 released by capacity-engine
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 done by capacity-engine/worker — commit 49fb294 (capacity-engine), test `cd /home/omri/projects/capacity-engine && node test.mjs` exit 0 (log: evidence/bt-3943-2026-07-25T10-43-24Z-test.txt), live `cd /home/omri/projects/capacity-engine && node engine.mjs judge-probe` exit 0 (log: evidence/bt-3943-2026-07-25T10-43-24Z-live.txt)
