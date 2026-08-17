---
id: bt-07f2
title: Vercel project has no GitHub auto-deploy wired up — pushes to main don't ship; every deploy
  needs a manual `vercel --prod`
status: done
priority: p3
tags:
  - infra
  - vercel
created: 2026-07-23
done:
  at: 2026-07-25T03:10:25Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: e64f56afaf0432c2a7ffd2f0bd7cbaac86b451af
    verified: 2026-07-25T03:10:25Z
  - type: test
    cmd: "curl -sf
      'https://api.vercel.com/v9/projects/prj_Se9EWsbcw9VUJKDVNuWh7tw65nPR?teamId=team_1JqV1IChqxsh\
      933CUDYmVvGQ' -H \"Authorization: Bearer $(node -e
      \\\"console.log(require('/home/omri/.local/share/com.vercel.cli/auth.json').token)\\\")\" |
      grep -q '\"type\":\"github\"'"
    exit: 2
    at: 2026-07-25T03:10:25Z
    log: evidence/bt-07f2-2026-07-25T03-10-25Z-test.txt
    sha256: 8449f186cb74aa40e249bc28484f8787eed12f9775dae43d907e3cf8aa2dfce7
    bytes: 325
  - type: test
    cmd: bash .donefile/evidence/verify-bt-07f2.sh
    exit: 0
    at: 2026-07-25T03:11:50Z
    log: evidence/bt-07f2-2026-07-25T03-11-50Z-test.txt
    sha256: 8ee0f9487710d7b9586a4b29a6bff38232a81345527e5e8fbd5e9c3587db09fd
    bytes: 45
  - type: note
    value: fixes the shell-quoting failure in the earlier --test run; underlying check (Vercel project
      link.type==github) passes
---

## Log
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 done by capacity-engine/worker — commit e64f56afaf04
- 2026-07-25 amended by capacity-engine/worker — test `bash .donefile/evidence/verify-bt-07f2.sh` exit 0 (log: evidence/bt-07f2-2026-07-25T03-11-50Z-test.txt)
