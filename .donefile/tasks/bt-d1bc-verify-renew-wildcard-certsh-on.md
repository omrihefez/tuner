---
id: bt-d1bc
title: Verify renew-wildcard-cert.sh on Hobby after downgrade (cron log ~2026-11-05 or attended
  --force --i-mean-it)
status: done
priority: p3
tags:
  - vercel
  - dns
created: 2026-10-23
filed:
  owner: capacity-engine/backfill
  at: 2026-10-23T00:40:23Z
reported: 2026-10-22
done:
  at: 2026-10-23T18:28:40Z
  by: capacity-engine/worker
  waived: verification-only; bt-41b2 already ran the script on Hobby, nothing to activate
evidence:
  - type: commit
    value: 793ea64e9d1782c0160431a8fc6fc22f92c55802
    verified: 2026-10-23T18:28:40Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && export PATH="$HOME/.bun/bin:$PATH" && python3 -c "import
      json,os,urllib.request as
      u;t=json.load(open(os.path.expanduser(\"~/.local/share/com.vercel.cli/auth.json\")))[\"token\"];d=json.load(u.urlopen(u.Request(\"https://api.vercel.com/v2/teams/team_1JqV1IChqxsh933CUDYmVvGQ\",headers={\"Authorization\":\"Bearer
      \"+t})));assert d[\"billing\"][\"plan\"]==\"hobby\",d[\"billing\"][\"plan\"]" && vercel certs
      ls --non-interactive 2>&1 | grep -E "\*\.omrihefez\.com" | grep -cE "in (6[0-9]|[7-9][0-9])d"
    exit: 0
    at: 2026-10-23T18:28:37Z
    log: evidence/bt-d1bc-2026-10-23T18-28-37Z-test.txt
    sha256: 2c6a7ae6c168caac92f911f1882b5b57c3d499f0f64b99f1367260512bc1ae05
    bytes: 543
  - type: note
    value: "premise already dead: bt-41b2 ran scripts/renew-wildcard-cert.sh --force --i-mean-it on the
      Hobby team, rc=0, new cert in 90d. Rechecked 2026-10-23 21:30 IDT: billing.plan=hobby,
      cert_JTyU8Xf5 *.omrihefez.com in 90d. Test is time-bound (needs >=60d wildcard cert, true
      until ~Nov 22)."
---

Named in the finding: renew-wildcard-cert.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): team billing.plan still 'pro' on 2026-10-22; newest wildcard cert 59d left

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-41b2, session `confirm-bass-tuner-renew-635b63`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.

INHERITED RESTRICTION — the parent this was raised on, bt-41b2, was BLOCKED (gate-owner main) when this was auto-filed, so this task is parked with it rather than becoming a way around it (ce-ce4f). It unblocks when bt-41b2 does; re-scope it then, since the parent's own work may already cover it.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: s=$(cd /home/omri/projects/bass-tuner && node /home/omri/projects/donefile/dist/cli.js show bt-41b2 --json) && printf '%s' "$s" | node -e "const s=JSON.parse(require('fs').readFileSync(0,'utf8'));const ok=['open','claimed','merged','done'];if(!ok.includes(s.status)){process.exit(1)}if(s.status!=='merged'&&s.status!=='done'){process.exit(0)}const ev=(s.evidence||[]).slice().reverse();const c=ev.find(e=>e&&e.type==='live'&&e.cmd)||ev.find(e=>e&&e.type==='test'&&e.cmd);if(!c){process.exit(0)}try{require('child_process').execSync(c.cmd,{stdio:'ignore',shell:'/bin/bash'});process.exit(0)}catch(e){process.exit(1)}"

## Log
- 2026-10-23 blocked: INHERITED PARK — auto-filed by the capacity engine from a FOLLOW-UP line raised on bt-41b2, which was blocked (gate-owner main) at filing time. A child task must not become a copy button around its parent's gate: on 2026-08-09 ma-5ec5 cloned parked ma-1436 this way and re-armed an unattended meni-hub restart 71 minutes later (ce-ce4f). UNBLOCK PREDICATE: bt-41b2 is unblocked — then re-scope this finding on its own merits (the parent's own work may already cover it) and unblock it too. Parent's reason: Waits on the Vercel downgrade Omri was already told about via iac-1467 (hub msg 73949, the iac-1467 told pin). Not a new ask: the probe flips when billing.plan=hobby, then Main/fleet verifies renew-wildcard-cert.sh. No needs-you card needed. [probe `s=$(cd /home/omri/projects/bass-tuner && node /home/omri/projects/donefile/dist/cli.js show bt-41b2 --json) && printf '%s' "$s" | node -e "const s=JSON.parse(require('fs').readFileSync(0,'utf8'));const ok=['open','claimed','merged','done'];if(!ok.includes(s.status)){process.exit(1)}if(s.status!=='merged'&&s.status!=='done'){process.exit(0)}const ev=(s.evidence||[]).slice().reverse();const c=ev.find(e=>e&&e.type==='live'&&e.cmd)||ev.find(e=>e&&e.type==='test'&&e.cmd);if(!c){process.exit(0)}try{require('child_process').execSync(c.cmd,{stdio:'ignore',shell:'/bin/bash'});process.exit(0)}catch(e){process.exit(1)}"` exit 1, owner main]
- 2026-10-23 blocker bt-41b2 closed 2026-10-23T15:37:21Z — recheck whether this can proceed now.
- 2026-10-23 unblocked
- 2026-10-23 AUTO-UNBLOCKED by gate-probe-monitor.mjs (ce-9279): this park's own UNBLOCK PREDICATE — "bt-41b2 is unblocked" — is now satisfied (donefile show bt-41b2 reads status "done"). Re-scope this finding on its own merits per the park's original instruction: the parent's own work may already cover it.
- 2026-10-23 claimed by capacity-engine
- 2026-10-23 done by capacity-engine/worker — commit 793ea64e9d17, test `cd /home/omri/projects/bass-tuner && export PATH="$HOME/.bun/bin:$PATH" && python3 -c "import json,os,urllib.request as u;t=json.load(open(os.path.expanduser(\"~/.local/share/com.vercel.cli/auth.json\")))[\"token\"];d=json.load(u.urlopen(u.Request(\"https://api.vercel.com/v2/teams/team_1JqV1IChqxsh933CUDYmVvGQ\",headers={\"Authorization\":\"Bearer \"+t})));assert d[\"billing\"][\"plan\"]==\"hobby\",d[\"billing\"][\"plan\"]" && vercel certs ls --non-interactive 2>&1 | grep -E "\*\.omrihefez\.com" | grep -cE "in (6[0-9]|[7-9][0-9])d"` exit 0 (log: evidence/bt-d1bc-2026-10-23T18-28-37Z-test.txt) (evidence waived: verification-only; bt-41b2 already ran the script on Hobby, nothing to activate)
