---
id: bt-dd27
title: "Retire the renew-wildcard-cert.sh cron before its 2026-12-07 run: no wildcard record since
  bt-6531, yet it writes prod-zone TXT records for an unused cert"
status: done
priority: p2
tags:
  - monitoring
  - cleanup
created: 2026-11-28
filed:
  owner: meni-worker/board-refill-work-discov-76b686
  at: 2026-11-28T10:28:15Z
done:
  at: 2026-11-28T10:42:45Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: a01b97b
    verified: 2026-11-28T10:42:45Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && N=$(crontab -l | grep -v "^[[:space:]]*#" | grep -c
      "renew-wildcard-cert.sh\|wildcard-cert-renewal" || true); [ "$N" = "0" ] && [ -z
      "$(scripts/install-cert-renewal-cron.sh --print-line | grep run-monitor)" ] && bash
      scripts/run-crontab-drift.test.sh
    exit: 0
    at: 2026-11-28T10:42:44Z
    log: evidence/bt-dd27-2026-11-28T10-42-44Z-test.txt
    sha256: d74d75c9da247f3acb15103025ae5e22f637fe8f57b8e7cf096bba0086946e0c
    bytes: 457
  - type: note
    value: Installer retired (schedules nothing, strips block); ran live with --force; bt-2593 dropped
      as moot. Test 6b in test-monitoring.sh is the falsifiable control (old installer's
      --print-line has 1 run-monitor line).
---

Found by the 2026-11-28 discovery sweep.

WHAT: the weekly `renew-wildcard-cert.sh` cron (`17 6 * * 1 ... run-monitor.sh cert-renewal ...`, still in crontab as of 2026-11-28) keeps renewing Vercel's `*.omrihefez.com` cert. Since bt-6531 (done 2026-11-26, iac 565356e7, applied live) there is no wildcard record, and every live host is a proxied Cloudflare-tunnel CNAME served by Cloudflare's edge cert. DOMAIN.md line 12: Vercel serves only the apex now, and the apex has its own cert. So the wildcard cert protects nothing.

bt-113a's 2026-11-26 00:3x verdict was "(b) retirement not needed, cron kept". That predates the wildcard deletion later the same day (14:13 IST), so the premise it rested on ("wildcard still serves tombstones") is gone.

WHY IT MATTERS, with a date: bt-113a measured 59d left on 2026-11-23, so the first renewal run is Monday 2026-12-07 06:17. The script does more than call Vercel. It POSTs then DELETEs an `_acme-challenge.omrihefez.com` TXT record in the production Cloudflare zone (`renew-wildcard-cert.sh` lines ~211-259). Those are writes to a zone iac manages in terraform, for a cert nobody uses, through a soft-blocked Vercel team whose final `certs issue` step has never been exercised (bt-2593). A failure pages someone over a non-surface. A half-run can leave an orphan TXT record, which the script's own comment at ~L29 says has happened before.

bt-2593 (blocked, waiting on that 12-07 run) and the dropped bt-f900 then confirm a renewal that should not happen.

DONE WHEN: the cert-renewal block is removed through its installer (`scripts/install-cert-renewal-cron.sh`, so the `run-crontab-drift.sh wildcard-cert-renewal` line stops expecting it), bt-2593 is closed as moot, and no cron line references `renew-wildcard-cert.sh`. Check with `crontab -l` before 2026-12-07. If someone decides the wildcard cert IS still needed, write down which hostname terminates TLS on it, measured, and close this as not-real.

## Log
- 2026-11-28 claimed by capacity-engine
- 2026-11-28 done by capacity-engine/worker — commit a01b97b, test `cd /home/omri/projects/bass-tuner && N=$(crontab -l | grep -v "^[[:space:]]*#" | grep -c "renew-wildcard-cert.sh\|wildcard-cert-renewal" || true); [ "$N" = "0" ] && [ -z "$(scripts/install-cert-renewal-cron.sh --print-line | grep run-monitor)" ] && bash scripts/run-crontab-drift.test.sh` exit 0 (log: evidence/bt-dd27-2026-11-28T10-42-44Z-test.txt)
