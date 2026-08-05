---
id: bt-a60b
title: bass-tuner board has no activation gate, so a task on a live Vercel PWA closes done on a
  commit alone
status: done
priority: p2
tags:
  - donefile
  - deploy
  - coverage
created: 2026-08-05
done:
  at: 2026-08-05T06:21:35Z
  by: capacity-engine/worker
  waived: config.yml + deploy/activation-probes/README.md is a governance/tooling change with no
    served-content surface of its own (same class as meniapp's ma-270c/ma-7ee7); bt-5fb7
    demonstrates the gate live via probe-bt-5fb7.sh against bass.omrihefez.com, both PASS (HEAD) and
    FAIL (stale ref e53825c) confirmed
evidence:
  - type: commit
    value: 7970cfd206bd666f5081176d21ee5de27e863360
    verified: 2026-08-05T06:21:35Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-08-05T06:21:33Z
    log: evidence/bt-a60b-2026-08-05T06-21-33Z-test.txt
    sha256: 3b301ab59f4e8cf30ad182d30a77a727bceea12c54e260f8c90eca3613c19971
    bytes: 19542
---

bass-tuner/.donefile/config.yml has prefix, claim_ttl_hours, blocked_nag_days, board_path, repos and worktree_guard, but NO activation block. Nine of the eleven registered boards have one: meniapp, trips-hub, tik-next, tik-api, second-brain, vidsmith, iac, meni-arch and capacity-engine. The only other board without one is donefile, which is a CLI library with no deploy surface and is legitimately exempt. bass-tuner is NOT exempt - it is a deployed site with vercel.json, a .vercel project link, manifest.json and a sw.js service worker, and its own CI already reasons about the deploy surface with scripts/check-sw-cache-bump.js and test/vercel-headers.test.js. Consequence: donefile done on a bass-tuner task closes it fully on a commit, with no --live probe required, so done never means deployed on this board. That matters more here than on most boards because a service-worker app has two distinct ways to be committed-but-not-live: the deploy never happened, or it happened and clients are still served the old cached shell because the sw cache key did not move - which is exactly what check-sw-cache-bump.js exists to catch at commit time but nothing checks after deploy. Same class the meni-arch board fixed for itself, where its config.yml records that activation.tags was empty so done on ANY ar task closed without a live probe. DONE WHEN: bass-tuner's config.yml carries an activation block whose tags cover the deployable surface, with the activation command and a live probe documented the way meni-arch's config does it, and one real bass-tuner task is closed through it with a passing --live probe against the served site as proof the gate works.

## Log
- 2026-08-05 claimed by capacity-engine
- 2026-08-05 done by capacity-engine/worker — commit 7970cfd206bd, test `npm test` exit 0 (log: evidence/bt-a60b-2026-08-05T06-21-33Z-test.txt) (evidence waived: config.yml + deploy/activation-probes/README.md is a governance/tooling change with no served-content surface of its own (same class as meniapp's ma-270c/ma-7ee7); bt-5fb7 demonstrates the gate live via probe-bt-5fb7.sh against bass.omrihefez.com, both PASS (HEAD) and FAIL (stale ref e53825c) confirmed)
