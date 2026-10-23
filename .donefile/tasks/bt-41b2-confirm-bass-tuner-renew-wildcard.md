---
id: bt-41b2
title: Confirm bass-tuner renew-wildcard-cert.sh (vercel certs issue) still works on Hobby at the
  next renewal
status: done
priority: p3
tags:
  - vercel
  - dns
created: 2026-10-22
filed:
  owner: capacity-engine
  at: 2026-10-22T10:35:05Z
reported: 2026-10-22
done:
  at: 2026-10-23T15:37:21Z
  by: meni-worker/confirm-bass-tuner-renew-aaac60
  waived: no code change; verification-only, nothing to activate
evidence:
  - type: commit
    value: 793ea64e9d1782c0160431a8fc6fc22f92c55802
    verified: 2026-10-23T15:37:21Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && export PATH="$HOME/.bun/bin:$PATH" && vercel certs ls
      --non-interactive 2>&1 | grep -E "\*\.omrihefez\.com" | grep -E "in (8[5-9]|9[0-9])d" | grep
      -c omrihefez
    exit: 0
    at: 2026-10-23T15:37:19Z
    log: evidence/bt-41b2-2026-10-23T15-37-19Z-test.txt
    sha256: 89178142a608e9f6146d66411dda2a5d1dde90d39c04d01e862d88284cc65eea
    bytes: 202
  - type: note
    value: "Verified 2026-10-23 18:37 IDT: scripts/renew-wildcard-cert.sh --force --i-mean-it on Hobby
      team ran end to end rc=0 (ACME challenge, Cloudflare TXT, propagation, 'vercel certs issue'
      Success, TXT cleaned up). New cert_JTyU8Xf5... *.omrihefez.com in 90d. No code change. Test is
      time-bound: passes only while a ~90d wildcard exists (until ~Oct 28)."
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

## Log
- 2026-10-22 claimed by capacity-engine
- 2026-10-22 claim by capacity-engine parked (blocked)
- 2026-10-22 blocked: Premise live but untestable on Hobby: team omris-projects-b1cad393 is still billing.plan=pro (iac-1467 done; Omri presses Downgrade himself). Personal scope rejected by CLI ('cannot set Personal Account as scope'), so no Hobby team to test against. Newest *.omrihefez.com cert has 59d left (not 89d); script threshold is 45d, so first real renewal ~2026-11-05. After downgrade, run: scripts/renew-wildcard-cert.sh --force --i-mean-it (attended) or wait for the cron and check log. [probe `python3 -c "import json,os,urllib.request as u;t=json.load(open(os.path.expanduser('~/.local/share/com.vercel.cli/auth.json')))['token'];d=json.load(u.urlopen(u.Request('https://api.vercel.com/v2/teams/team_1JqV1IChqxsh933CUDYmVvGQ',headers={'Authorization':'Bearer '+t})));assert d['billing']['plan']=='hobby',d['billing']['plan']"` exit 1, owner omri]
- 2026-10-22 blocked reason updated: "Premise live but untestable on Hobby: team omris-projects-b1cad393 is still billing.plan=pro (iac-1467 done; Omri presses Downgrade himself). Personal scope rejected by CLI ('cannot set Personal Account as scope'), so no Hobby team to test against. Newest *.omrihefez.com cert has 59d left (not 89d); script threshold is 45d, so first real renewal ~2026-11-05. After downgrade, run: scripts/renew-wildcard-cert.sh --force --i-mean-it (attended) or wait for the cron and check log." -> "Waits on the Vercel downgrade Omri was already told about via iac-1467 (hub msg 73949, the iac-1467 told pin). Not a new ask: the probe flips when billing.plan=hobby, then Main/fleet verifies renew-wildcard-cert.sh. No needs-you card needed."
- 2026-10-22 blocker iac-1467 closed 2026-10-22T10:30:45Z — recheck whether this can proceed now.
- 2026-10-23 Gate verified cleared 2026-10-23 18:27 IDT (ce-ff25): team omris-projects-b1cad393 billing.plan=hobby, status=active, period=None. renew-wildcard-cert.sh default run on Hobby exits 0 ('57d left > 45d threshold') so the vercel certs read path works; --force dry-run ok. ISSUANCE ('vercel certs issue') still unproven on Hobby: first real cron renewal crosses 45d around 2026-11-04 -- verify from the cron log then, or run --force --i-mean-it attended.
- 2026-10-23 unblocked
- 2026-10-23 claimed by capacity-engine
- 2026-10-23 done by meni-worker/confirm-bass-tuner-renew-aaac60 — commit 793ea64e9d17, test `cd /home/omri/projects/bass-tuner && export PATH="$HOME/.bun/bin:$PATH" && vercel certs ls --non-interactive 2>&1 | grep -E "\*\.omrihefez\.com" | grep -E "in (8[5-9]|9[0-9])d" | grep -c omrihefez` exit 0 (log: evidence/bt-41b2-2026-10-23T15-37-19Z-test.txt) (evidence waived: no code change; verification-only, nothing to activate)
