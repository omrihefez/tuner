---
id: bt-41b2
title: Confirm bass-tuner renew-wildcard-cert.sh (vercel certs issue) still works on Hobby at the
  next renewal
status: blocked
priority: p3
tags:
  - vercel
  - dns
created: 2026-10-22
filed:
  owner: capacity-engine
  at: 2026-10-22T10:35:05Z
reported: 2026-10-22
blocked:
  reason: "Waits on the Vercel downgrade Omri was already told about via iac-1467 (hub msg 73949, the
    iac-1467 told pin). Not a new ask: the probe flips when billing.plan=hobby, then Main/fleet
    verifies renew-wildcard-cert.sh. No needs-you card needed."
  since: 2026-10-22
  probe:
    cmd: python3 -c "import json,os,urllib.request as
      u;t=json.load(open(os.path.expanduser('~/.local/share/com.vercel.cli/auth.json')))['token'];d=json.load(u.urlopen(u.Request('https://api.vercel.com/v2/teams/team_1JqV1IChqxsh933CUDYmVvGQ',headers={'Authorization':'Bearer
      '+t})));assert d['billing']['plan']=='hobby',d['billing']['plan']"
    exit: 1
    at: 2026-10-23T12:14:07Z
    log: evidence/bt-41b2-2026-10-22T10-56-48Z-probe.txt
    sha256: 990cabe2fa9e538d2e1f314c4c21efca73e0f3898ac5fd98fdd221bac8f5b43a
    bytes: 430
  gate_owner: main
  parked_claim:
    owner: capacity-engine
    at: 2026-10-22T10:54:49Z
---

Named in the finding: renew-wildcard-cert.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): untested on Hobby; the newest *.omrihefez.com cert expires in ~89d

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working iac-1467, session `sunset-the-vercel-pro-te-295e6c`, dispatched on iac.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed PARTIAL.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: python3 -c "import json,os,urllib.request as u;t=json.load(open(os.path.expanduser('~/.local/share/com.vercel.cli/auth.json')))['token'];d=json.load(u.urlopen(u.Request('https://api.vercel.com/v2/teams/team_1JqV1IChqxsh933CUDYmVvGQ',headers={'Authorization':'Bearer '+t})));assert d['billing']['plan']=='hobby',d['billing']['plan']"
GATE-OWNER: main

## Log
- 2026-10-22 claimed by capacity-engine
- 2026-10-22 claim by capacity-engine parked (blocked)
- 2026-10-22 blocked: Premise live but untestable on Hobby: team omris-projects-b1cad393 is still billing.plan=pro (iac-1467 done; Omri presses Downgrade himself). Personal scope rejected by CLI ('cannot set Personal Account as scope'), so no Hobby team to test against. Newest *.omrihefez.com cert has 59d left (not 89d); script threshold is 45d, so first real renewal ~2026-11-05. After downgrade, run: scripts/renew-wildcard-cert.sh --force --i-mean-it (attended) or wait for the cron and check log. [probe `python3 -c "import json,os,urllib.request as u;t=json.load(open(os.path.expanduser('~/.local/share/com.vercel.cli/auth.json')))['token'];d=json.load(u.urlopen(u.Request('https://api.vercel.com/v2/teams/team_1JqV1IChqxsh933CUDYmVvGQ',headers={'Authorization':'Bearer '+t})));assert d['billing']['plan']=='hobby',d['billing']['plan']"` exit 1, owner omri]
- 2026-10-22 blocked reason updated: "Premise live but untestable on Hobby: team omris-projects-b1cad393 is still billing.plan=pro (iac-1467 done; Omri presses Downgrade himself). Personal scope rejected by CLI ('cannot set Personal Account as scope'), so no Hobby team to test against. Newest *.omrihefez.com cert has 59d left (not 89d); script threshold is 45d, so first real renewal ~2026-11-05. After downgrade, run: scripts/renew-wildcard-cert.sh --force --i-mean-it (attended) or wait for the cron and check log." -> "Waits on the Vercel downgrade Omri was already told about via iac-1467 (hub msg 73949, the iac-1467 told pin). Not a new ask: the probe flips when billing.plan=hobby, then Main/fleet verifies renew-wildcard-cert.sh. No needs-you card needed."
- 2026-10-22 blocker iac-1467 closed 2026-10-22T10:30:45Z — recheck whether this can proceed now.
