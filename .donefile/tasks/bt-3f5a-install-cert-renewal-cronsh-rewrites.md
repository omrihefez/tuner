---
id: bt-3f5a
title: install-cert-renewal-cron.sh rewrites its managed block wholesale with no drop guard — same
  defect class as bt-34af, currently consistent so no live bug
status: done
priority: p3
tags:
  - ops
  - monitoring
created: 2026-07-31
done:
  at: 2026-08-01T10:04:58Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 2c32281
    verified: 2026-08-01T10:04:58Z
  - type: test
    cmd: bash scripts/test-monitoring.sh
    exit: 0
    at: 2026-08-01T10:04:57Z
    log: evidence/bt-3f5a-2026-08-01T10-04-57Z-test.txt
    sha256: bb1680725f05dcb5de28c588b6b9575929f86e93520e7327e2e7d41672f30b70
    bytes: 1560
---

scripts/install-cert-renewal-cron.sh replaces everything between its BEGIN/END markers wholesale from $CRON_LINE, exactly as install-monitoring-crons.sh did before bt-34af. Any entry live inside those markers but absent from $CRON_LINE is deleted on the next run, silently — and an unscheduled monitor is indistinguishable from a passing one.

No live bug today: the block holds exactly one line (cert-renewal) and $CRON_LINE produces exactly that line. Confirmed during bt-34af by dry-run cross-check, which also showed the two installers do not clobber each other's blocks (install-cert-renewal-cron.sh keeps all 4 run-monitor lines; install-monitoring-crons.sh keeps the 1 cert-renewal line). That consistency is exactly why this is cheap to fix now, rather than after someone hand-edits the block or installs from a worktree — which is precisely how the bt-34af heartbeat line came to exist.

Note install-cert-renewal-cron.sh also strips any line containing 'renew-wildcard-cert.sh' anywhere in the crontab (line 36, grep -vF on the basename), not just inside its own block — broader than the monitoring installer's name-scoped cleanup. Worth a look while in here.

FIX: port the drop guard from install-monitoring-crons.sh (commit cb830db) — the monitor_names() helper, the comm -23 DROPPED comparison, and the --force escape hatch. It compares by monitor NAME rather than whole line, so an ordinary schedule change does not trip it and get --force'd into meaninglessness.

DONE WHEN: removing the cert-renewal entry from $CRON_LINE and running --dry-run exits non-zero naming 'cert-renewal', with the live crontab untouched. VERIFY with that negative control, not by reading the code.

## Log
- 2026-08-01 claimed by capacity-engine
- 2026-08-01 done by capacity-engine/worker — commit 2c32281, test `bash scripts/test-monitoring.sh` exit 0 (log: evidence/bt-3f5a-2026-08-01T10-04-57Z-test.txt)
