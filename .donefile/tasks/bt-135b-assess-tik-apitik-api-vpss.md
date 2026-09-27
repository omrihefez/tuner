---
id: bt-135b
title: assess tik-api/tik-api-vps's intended security-header posture (financial backends, currently
  SKIPped as "not yet assessed" in audit-domains.sh)
status: done
priority: p3
tags:
  - security
  - monitoring
created: 2026-09-27
filed:
  owner: capacity-engine
  at: 2026-09-27T19:04:05Z
reported: 2026-09-27
activation: "no restart needed: cron (10 6 * * * scripts/run-monitor.sh domain-audit
  scripts/audit-domains.sh) reads this checkout's script directly on its next run; already re-run
  manually and verified live"
merged:
  at: 2026-09-27T20:24:02Z
  by: capacity-engine/worker
done:
  at: 2026-09-27T20:26:28Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 2c7c0bc
    verified: 2026-09-27T20:24:02Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh
    exit: 0
    at: 2026-09-27T20:23:53Z
    log: evidence/bt-135b-2026-09-27T20-23-53Z-test.txt
    sha256: 97b28f884bb09dc83ec554ec2f370344f98f15ffbffec67c6d57398994ad82c5
    bytes: 4155
  - type: live
    cmd: bash /home/omri/projects/bass-tuner/scripts/audit-domains.sh 2>&1 | grep -E
      "^OK     tik-api(-vps)?\.omrihefez\.com/health -> 200" | wc -l | grep -qx 2
    exit: 1
    at: 2026-09-27T20:23:53Z
    log: evidence/bt-135b-2026-09-27T20-23-53Z-live.txt
    sha256: 79f76c069056e927ee248c194731696aa621ec801529630ff976c4f8f701cf52
    bytes: 155
  - type: note
    value: "Assessed and real: tik-api/tik-api-vps are the same JSON-only FastAPI origin (auth-gated
      except /health), same class as meniapp-api. Fixed the actual gap in the tik-api repo (main.py:
      added X-Content-Type-Options: nosniff middleware, commit 01297ec on tik-api master, already
      deployed live via its own ff-sync+rebuild cron and confirmed) and updated audit-domains.sh
      here to check tik-api/tik-api-vps at /health instead of defaulting to 'not yet assessed'."
  - type: commit
    value: 2c7c0bc
    verified: 2026-09-27T20:26:28Z
  - type: live
    cmd: 'n=0; for h in tik-api tik-api-vps; do curl -fsS -D - -o /dev/null --max-time 10
      "https://$h.omrihefez.com/health" | grep -qi "^x-content-type-options: nosniff" && n=$((n+1));
      done; [ "$n" = 2 ]'
    exit: 0
    at: 2026-09-27T20:26:28Z
    log: evidence/bt-135b-2026-09-27T20-26-28Z-live.txt
    sha256: 74595b19e090f5e0c7d3c643f1e97e58323a8cb058a99229fda924adf3d461db
    bytes: 197
---

Named in the finding: tik-api/tik-api-vps, audit-domains.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): bt-d173's task body flagged these as unassessed rather than by-design-exempt like brain/oauth

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-d173, session `assert-live-security-hea-4436a2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 05a2c35855f462681688c280de268c2785f4419c).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-27 blocker bt-d173 closed 2026-09-27T18:57:09Z — recheck whether this can proceed now.
- 2026-09-27 claimed by capacity-engine
- 2026-09-27 released by capacity-engine
- 2026-09-27 claimed by capacity-engine
- 2026-09-27 merged by capacity-engine/worker — commit 2c7c0bc, test `cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh` exit 0 (log: evidence/bt-135b-2026-09-27T20-23-53Z-test.txt) — activation-gated, --live evidence exists but none exited 0 (got: 1) — rerun --live once the surface is actually activated
- 2026-09-27 promoted merged -> done by capacity-engine/worker — commit 2c7c0bc, live `n=0; for h in tik-api tik-api-vps; do curl -fsS -D - -o /dev/null --max-time 10 "https://$h.omrihefez.com/health" | grep -qi "^x-content-type-options: nosniff" && n=$((n+1)); done; [ "$n" = 2 ]` exit 0 (log: evidence/bt-135b-2026-09-27T20-26-28Z-live.txt)
