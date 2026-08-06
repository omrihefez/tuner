---
id: bt-4923
title: renew-wildcard-cert.sh --force performs live ACME issuance with no confirmation guard
status: open
priority: p2
tags:
  - from-brief
created: 2026-08-06
---

scripts/renew-wildcard-cert.sh's --force flag skips the 'is this actually due' check and immediately performs a real production action: it creates/deletes live _acme-challenge.omrihefez.com TXT records via the Cloudflare API and calls `vercel certs issue` for *.omrihefez.com. This bit a read-only investigation on 2026-08-06 — a debugging session used --force to test a PATH fix and it silently issued a real live cert (harmless but unintended) and left an orphaned DNS TXT record on a killed second run. Add a confirmation prompt (or a separate --dry-run default, with --force requiring an explicit --i-mean-it or similar) so invoking the script during investigation/testing cannot trigger a live cert issuance or DNS write without an explicit, unambiguous opt-in. Done when: running --force without the new explicit flag prints what it would do and exits without touching Cloudflare/Vercel APIs.

Filed by the morning brief's intake pass.

## Log
- 2026-08-06 claimed by capacity-engine
- 2026-08-06 released by capacity-engine
