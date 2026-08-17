---
id: bt-a428
title: "wildcard cert-renewal cron intermittently fails: `vercel: command not found`"
status: done
priority: p2
tags:
  - from-brief
created: 2026-08-03
done:
  at: 2026-08-03T06:22:55Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 56b6463
    verified: 2026-08-03T06:22:55Z
  - type: test
    cmd: env -i PATH=/usr/bin:/bin HOME=$HOME bash scripts/renew-wildcard-cert.sh --force
    exit: 0
    at: 2026-08-03T06:22:34Z
    log: evidence/bt-a428-2026-08-03T06-22-34Z-test.txt
    sha256: b8a3cfe83fcb4174d5fef1a038ccae71356aa14384855523478e68c1b3ef3cb0
    bytes: 1664
---

scripts/renew-wildcard-cert.sh (installed via install-cert-renewal-cron.sh) fails under cron with 'line 84: vercel: command not found', per /home/omri/.cache/bass-tuner-cert-renewal.log — happened 2026-07-27 and again 2026-08-03, with one clean run in between (2026-07-30, when the days-until-expiry check found enough runway and skipped the actual `vercel certs issue` call, so the missing binary never got exercised). Root cause: cron's PATH doesn't include wherever `vercel` actually lives (npm global bin dir), so the script only works when run from an interactive shell. Live cert on *.omrihefez.com is not currently at risk (valid until 2026-10-24 per direct openssl check), so this is not urgent, but it's a silent, recurring, unmonitored failure mode on the ONLY renewal path for that wildcard cert. Done when: running the script the way cron does (minimal env, e.g. `env -i PATH=/usr/bin:/bin HOME=$HOME <other required vars> bash scripts/renew-wildcard-cert.sh --force`) successfully resolves `vercel` (fix via absolute path to the vercel binary, or export the correct PATH in the crontab entry itself) and completes a real renewal end-to-end with a clean exit code, logged. Verify by re-running the exact cron invocation (check crontab -l for the entry) after the fix, not just running the script normally from a login shell.

Filed by the morning brief's intake pass.

## Log
- 2026-08-03 claimed by capacity-engine
- 2026-08-03 released by capacity-engine
- 2026-08-03 claimed by capacity-engine
- 2026-08-03 done by capacity-engine/worker — commit 56b6463, test `env -i PATH=/usr/bin:/bin HOME=$HOME bash scripts/renew-wildcard-cert.sh --force` exit 0 (log: evidence/bt-a428-2026-08-03T06-22-34Z-test.txt)
