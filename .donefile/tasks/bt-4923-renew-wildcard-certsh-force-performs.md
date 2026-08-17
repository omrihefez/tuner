---
id: bt-4923
title: renew-wildcard-cert.sh --force performs live ACME issuance with no confirmation guard
status: done
priority: p2
tags:
  - from-brief
created: 2026-08-06
done:
  at: 2026-08-06T06:44:05Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 69f0576
    verified: 2026-08-06T06:44:05Z
  - type: test
    cmd: bash -c "cd /home/omri/projects/bass-tuner && out=\$(bash scripts/renew-wildcard-cert.sh
      --force 2>&1); ec=\$?; echo \"\$out\" | grep -q \"Not touching Cloudflare or Vercel\" && [
      \$ec -eq 0 ]"
    exit: 0
    at: 2026-08-06T06:44:05Z
    log: evidence/bt-4923-2026-08-06T06-44-05Z-test.txt
    sha256: 23f5dfe710e7f919835080e0e931dd1f529cdacb371110b2ad1cd7306a9abb56
    bytes: 197
---

scripts/renew-wildcard-cert.sh's --force flag skips the 'is this actually due' check and immediately performs a real production action: it creates/deletes live _acme-challenge.omrihefez.com TXT records via the Cloudflare API and calls `vercel certs issue` for *.omrihefez.com. This bit a read-only investigation on 2026-08-06 — a debugging session used --force to test a PATH fix and it silently issued a real live cert (harmless but unintended) and left an orphaned DNS TXT record on a killed second run. Add a confirmation prompt (or a separate --dry-run default, with --force requiring an explicit --i-mean-it or similar) so invoking the script during investigation/testing cannot trigger a live cert issuance or DNS write without an explicit, unambiguous opt-in. Done when: running --force without the new explicit flag prints what it would do and exits without touching Cloudflare/Vercel APIs.

Filed by the morning brief's intake pass.

## Log
- 2026-08-06 claimed by capacity-engine
- 2026-08-06 released by capacity-engine
- 2026-08-06 claimed by capacity-engine
- 2026-08-06 done by capacity-engine/worker — commit 69f0576, test `bash -c "cd /home/omri/projects/bass-tuner && out=\$(bash scripts/renew-wildcard-cert.sh --force 2>&1); ec=\$?; echo \"\$out\" | grep -q \"Not touching Cloudflare or Vercel\" && [ \$ec -eq 0 ]"` exit 0 (log: evidence/bt-4923-2026-08-06T06-44-05Z-test.txt)
- 2026-08-06 Naming caveat flagged by main's review: --force now means 'don't act' (dry-run) unless paired with --i-mean-it, inverting the usual --force convention (proceed past a safety check). Someone reaching for --force under time pressure (cert expired, site down) will expect it to renew and instead get a dry run -- safe failure direction, but only if they read stdout. If flag names are ever revisited: --dry-run (opt-in to inspect) + bare invocation acting on it would give the same protection without the inversion. Not reworked here since --force/--i-mean-it matches what the task specified.
