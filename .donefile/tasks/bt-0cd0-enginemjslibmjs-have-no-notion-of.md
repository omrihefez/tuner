---
id: bt-0cd0
title: engine.mjs/lib.mjs have no notion of bass-tuner having two live auth hosts (preview.meni
  appears nowhere outside this one text entry) — worth a structured second-host field if another
  repo grows the same shape
status: open
priority: p3
tags:
  - fleet
  - auth
created: 2026-10-19
filed:
  owner: capacity-engine
  at: 2026-10-19T01:12:24Z
reported: 2026-10-19
---

Named in the finding: engine.mjs/lib.mjs

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): check-public-surfaces.sh and bass-tuner/audit-domains.sh already name preview.meni.omrihefez.com explicitly, so the data exists elsewhere, just not cross-referenced here

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working ce-e7ec, session `meni-arch-s-auth-recover-63f54d`, dispatched on capacity-engine.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on meni-arch (ce-71de). Scope this task to the part that is actually about capacity-engine; the siblings cover the rest.
That task's report closed PARTIAL (commit ff3d5b2b — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `ff3d5b2b` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

INHERITED RESTRICTION — the parent this was raised on, ce-e7ec, was BLOCKED (gate-owner main) when this was auto-filed, so this task is parked with it rather than becoming a way around it (ce-ce4f). It unblocks when ce-e7ec does; re-scope it then, since the parent's own work may already cover it.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: s=$(cd /home/omri/projects/capacity-engine && node /home/omri/projects/donefile/dist/cli.js show ce-e7ec --json) && printf '%s' "$s" | node -e "const s=JSON.parse(require('fs').readFileSync(0,'utf8'));const ok=['open','claimed','merged','done'];if(!ok.includes(s.status)){process.exit(1)}if(s.status!=='merged'&&s.status!=='done'){process.exit(0)}const ev=(s.evidence||[]).slice().reverse();const c=ev.find(e=>e&&e.type==='live'&&e.cmd)||ev.find(e=>e&&e.type==='test'&&e.cmd);if(!c){process.exit(0)}try{require('child_process').execSync(c.cmd,{stdio:'ignore',shell:'/bin/bash'});process.exit(0)}catch(e){process.exit(1)}"

## Log
- 2026-10-19 blocked: INHERITED PARK — auto-filed by the capacity engine from a FOLLOW-UP line raised on ce-e7ec, which was blocked (gate-owner main) at filing time. A child task must not become a copy button around its parent's gate: on 2026-08-09 ma-5ec5 cloned parked ma-1436 this way and re-armed an unattended meni-hub restart 71 minutes later (ce-ce4f). UNBLOCK PREDICATE: ce-e7ec is unblocked — then re-scope this finding on its own merits (the parent's own work may already cover it) and unblock it too. Parent's reason: DONE on branch ce-e7ec-preview-passkey-entry ff3d5b2b, NOT yet on main, awaiting Main merge: this repo is the fleet's own dispatcher, config.json is read live and auth-recovery-staleness.mjs is library code, so this diff is outside the test/docs-only safe-diff exception (ATTENDED-ONLY) and needs an attended merge [probe `s=$(cd /home/omri/projects/capacity-engine && node /home/omri/projects/donefile/dist/cli.js show ce-e7ec --json) && printf '%s' "$s" | node -e "const s=JSON.parse(require('fs').readFileSync(0,'utf8'));const ok=['open','claimed','merged','done'];if(!ok.includes(s.status)){process.exit(1)}if(s.status!=='merged'&&s.status!=='done'){process.exit(0)}const ev=(s.evidence||[]).slice().reverse();const c=ev.find(e=>e&&e.type==='live'&&e.cmd)||ev.find(e=>e&&e.type==='test'&&e.cmd);if(!c){process.exit(0)}try{require('child_process').execSync(c.cmd,{stdio:'ignore',shell:'/bin/bash'});process.exit(0)}catch(e){process.exit(1)}"` exit 1, owner main]
- 2026-10-19 unblocked
