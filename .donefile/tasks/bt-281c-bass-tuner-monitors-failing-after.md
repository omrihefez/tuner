---
id: bt-281c
title: "bass-tuner monitors failing after VPS self-host move: unregistered-live-hosts, csp-strength,
  permissions-policy, stale-deploy"
status: done
priority: p2
tags:
  - from-brief
created: 2026-11-25
filed:
  owner: morning-brief
  at: 2026-11-25T07:07:04Z
done:
  at: 2026-11-25T07:31:49Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: a8a0f70
    verified: 2026-11-25T07:31:49Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-unregistered-live-hosts.sh >/dev/null
      && bash scripts/check-csp-strength.sh >/dev/null && bash scripts/check-permissions-policy.sh
      >/dev/null && bash deploy/activation-probes/probe-bt-5fb7.sh
    exit: 0
    at: 2026-11-25T07:31:21Z
    log: evidence/bt-281c-2026-11-25T07-31-21Z-test.txt
    sha256: 8275740d738682840aa6933970e7df3f9e9f580b1e5aa6ffba39c2102cc47fc4
    bytes: 321
  - type: note
    value: "Root cause: after the VPS move tuner (308 alias) sends no headers, and stale Vercel aliases
      kidai/preview.meni still list. Exempted explicitly, only while not serving; falsified with a
      stub 200."
---

Inbox notes 2026-11-24/25 show four bass-tuner monitors failed (unregistered-live-hosts, csp-strength, permissions-policy, stale-deploy) after bass moved off paused Vercel to the VPS. Find root cause (likely missing headers/host registry on the self-hosted origin), fix, and done-when all four monitors pass against https://bass.omrihefez.com. Check board first for existing oncall tasks.

Filed by the morning brief's intake pass.

## Log
- 2026-11-25 claimed by capacity-engine
- 2026-11-25 done by capacity-engine/worker — commit a8a0f70, test `cd /home/omri/projects/bass-tuner && bash scripts/check-unregistered-live-hosts.sh >/dev/null && bash scripts/check-csp-strength.sh >/dev/null && bash scripts/check-permissions-policy.sh >/dev/null && bash deploy/activation-probes/probe-bt-5fb7.sh` exit 0 (log: evidence/bt-281c-2026-11-25T07-31-21Z-test.txt)
