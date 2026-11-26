---
id: bt-f900
title: Check cert-renewal log after Mon 2026-12-07 06:17 IST run
status: dropped
priority: p3
tags:
  - tls
  - vercel
created: 2026-11-26
filed:
  owner: capacity-engine
  at: 2026-11-25T22:35:29Z
reported: 2026-11-26
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): the PREMISE-PROBE on bt-2593 passes only if a 2026-12 'issuance succeeded' line exists; a FATAL there means the soft-block breaks the final step

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-2593, session `confirm-final-vercel-cer-89ca60`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed PARTIAL.

INHERITED RESTRICTION — the parent this was raised on, bt-2593, was BLOCKED (gate-owner time) when this was auto-filed, so this task is parked with it rather than becoming a way around it (ce-ce4f). It unblocks when bt-2593 does; re-scope it then, since the parent's own work may already cover it.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: s=$(cd /home/omri/projects/bass-tuner && node /home/omri/projects/donefile/dist/cli.js show bt-2593 --json) && printf '%s' "$s" | node -e "const s=JSON.parse(require('fs').readFileSync(0,'utf8'));const ok=['open','claimed','merged','done'];if(!ok.includes(s.status)){process.exit(1)}if(s.status!=='merged'&&s.status!=='done'){process.exit(0)}const ev=(s.evidence||[]).slice().reverse();const c=ev.find(e=>e&&e.type==='live'&&e.cmd)||ev.find(e=>e&&e.type==='test'&&e.cmd);if(!c){process.exit(0)}try{require('child_process').execSync(c.cmd,{stdio:'ignore',shell:'/bin/bash'});process.exit(0)}catch(e){process.exit(1)}"

## Log
- 2026-11-26 blocked: INHERITED PARK — auto-filed by the capacity engine from a FOLLOW-UP line raised on bt-2593, which was blocked (gate-owner time) at filing time. A child task must not become a copy button around its parent's gate: on 2026-08-09 ma-5ec5 cloned parked ma-1436 this way and re-armed an unattended meni-hub restart 71 minutes later (ce-ce4f). UNBLOCK PREDICATE: bt-2593 is unblocked — then re-scope this finding on its own merits (the parent's own work may already cover it) and unblock it too. Parent's reason: Wait for the 2026-12-07 06:17 IST renewal cron run (cert has ~57d left, so a failure still leaves ~45d). Probe flips on either outcome; then: success -> close, FATAL -> retire the wildcard cert or move issuance off Vercel. [probe `s=$(cd /home/omri/projects/bass-tuner && node /home/omri/projects/donefile/dist/cli.js show bt-2593 --json) && printf '%s' "$s" | node -e "const s=JSON.parse(require('fs').readFileSync(0,'utf8'));const ok=['open','claimed','merged','done'];if(!ok.includes(s.status)){process.exit(1)}if(s.status!=='merged'&&s.status!=='done'){process.exit(0)}const ev=(s.evidence||[]).slice().reverse();const c=ev.find(e=>e&&e.type==='live'&&e.cmd)||ev.find(e=>e&&e.type==='test'&&e.cmd);if(!c){process.exit(0)}try{require('child_process').execSync(c.cmd,{stdio:'ignore',shell:'/bin/bash'});process.exit(0)}catch(e){process.exit(1)}"` exit 1, owner time]
- 2026-11-26 unblocked
- 2026-11-26 dropped: duplicate of bt-2593, which is parked on the same 2026-12-07 renewal-log probe
