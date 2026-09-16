---
id: bt-8818
title: oauth, tik and tik-api-vps are live in DOMAIN.md with no liveness check in any monitor -
  audit-domains.sh derives Vercel-only hosts and skips the rest
status: done
priority: p2
tags:
  - monitoring
  - coverage
created: 2026-09-16
filed:
  owner: meni-worker/board-refill-work-discov-ee818f
  at: 2026-09-16T15:44:52Z
done:
  at: 2026-09-16T16:28:36Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: e288ade3a9f0248fc67acf47db51198dd1a2faf8
    verified: 2026-09-16T16:28:36Z
  - type: test
    cmd: bash /home/omri/projects/bass-tuner/scripts/check-tunnel-liveness.test.sh
    exit: 0
    at: 2026-09-16T16:28:34Z
    log: evidence/bt-8818-2026-09-16T16-28-34Z-test.txt
    sha256: fb9cdef5445cb052fb2c32a06a169bee3a6bd5576ae16525a722ff4288ebbf78
    bytes: 1125
  - type: live
    cmd: bash /home/omri/projects/bass-tuner/scripts/check-tunnel-liveness.sh
    exit: 0
    at: 2026-09-16T16:28:34Z
    log: evidence/bt-8818-2026-09-16T16-28-34Z-live.txt
    sha256: e444de9981d52b381ce9eacb28a846765da0526d919cab55b2fef9fe8254f4fa
    bytes: 433
---

Found by the periodic discovery sweep, 2026-09-16, measured against `~/meni/DOMAIN.md` (§1), `~/meni/config/health-registry.json`, `~/meni/bin/check-public-surfaces.sh` and `scripts/audit-domains.sh`.

Three hosts that DOMAIN.md §1 marks 🟢 live have no liveness check in ANY monitor on this box:

- **`oauth.omrihefez.com`** — the OAuth2 redirect catcher for Meni's own CLI OAuth flows. Cloudflare Tunnel `meni-oauth` to `127.0.0.1:8746` (`meni-oauth-callback.service`). Intentionally public, no auth wall; DOMAIN.md names `/health` → 200 as its liveness probe. `grep -n oauth` over health-registry.json, check-public-surfaces.sh and audit-domains.sh returns nothing in all three.
- **`tik.omrihefez.com`** — the TIK frontend, explicit CNAME, NextAuth-gated. health-registry.json watches four tik entries and every one of them targets `tik-api.omrihefez.com`; the frontend appears nowhere.
- **`tik-api-vps.omrihefez.com`** — the VPS origin that is the documented rollback pair for `tik-api` (`~/.cloudflare/tunnel-tik-api-vps/ROLLBACK-to-laptop.sh`). Not in either file.

WHY THIS IS THIS REPO'S PROBLEM. `scripts/audit-domains.sh` already derives its host list from DOMAIN.md rather than hardcoding it — `derive_registry_hosts "$DOMAIN_MD" vercel` (line 90). The `vercel` filter is correct for what that script does (Deployment-Protection drift), and it prints `SKIP ... live in the registry but not Vercel-hosted` for the rest. But nothing else in the estate picks those skipped hosts up, so "not a Vercel host" has become "not monitored". bass-tuner owns the generic monitor harness they belong in: `scripts/run-monitor.sh`, `scripts/install-monitoring-crons.sh`, and three existing monitors (fallback-cert, domain-audit, heartbeat, stale-deploy) already wired through it with crontab-drift guards.

WHY IT MATTERS MORE THAN A MISSING ROW. The `pete` row in DOMAIN.md records the exact failure this prevents: on 2026-09-04 the tunnel origin for `pete`/`pete-api` was deleted and both went 530 for about a day before anyone noticed. `oauth` is the sharper case now — it is the code-pickup endpoint for Meni's own OAuth consents, and several blocked tasks across the fleet (sb-e6fc, sb-5a06, ma-a980, iac-e7ad) are waiting on Omri to complete exactly such a consent. If that endpoint is dark on the day he finally does one, the consent fails and nothing anywhere reports why.

NOTE ON SCOPE, so this does not get built in the wrong repo. `check-public-surfaces.sh` lives in `~/meni/bin`, which a worker may not commit to, and its hand-maintained `SURFACES` array is already tracked as a separate finding (df-78db, meni board, open p2 — "derive it from the registry bass-tuner already uses"). Do NOT try to fix that file. Build the check here, in bass-tuner, as its own monitor over the registry hosts audit-domains.sh skips.

DONE WHEN: a monitor in this repo, installed through `scripts/install-monitoring-crons.sh` with a crontab-drift guard like the other four, checks that each non-Vercel-hosted 🟢 live host in DOMAIN.md answers with the status it is known to answer with — pinned per host, the same idiom check-public-surfaces.sh uses, not a blanket non-5xx rule. Host list derived from DOMAIN.md, not typed in, so the next tunnel surface is covered without anyone remembering.

EVIDENCE must fail before and pass after, in both directions: point one entry at a host that does not resolve and show the monitor exits non-zero; pin one entry to the wrong expected status and show it exits non-zero. A monitor only ever seen passing is indistinguishable from one that cannot fire.

## Log
- 2026-09-16 claimed by capacity-engine
- 2026-09-16 done by capacity-engine/worker — commit e288ade3a9f0, test `bash /home/omri/projects/bass-tuner/scripts/check-tunnel-liveness.test.sh` exit 0 (log: evidence/bt-8818-2026-09-16T16-28-34Z-test.txt), live `bash /home/omri/projects/bass-tuner/scripts/check-tunnel-liveness.sh` exit 0 (log: evidence/bt-8818-2026-09-16T16-28-34Z-live.txt)
