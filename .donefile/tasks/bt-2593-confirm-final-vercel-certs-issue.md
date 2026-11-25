---
id: bt-2593
title: Confirm final `vercel certs issue` step works under soft-block on first real renewal (~2026-12-07)
status: blocked
priority: p3
tags:
  - tls
  - vercel
  - monitoring
created: 2026-11-26
filed:
  owner: capacity-engine
  at: 2026-11-25T22:28:52Z
reported: 2026-11-26
blocked:
  reason: "Wait for the 2026-12-07 06:17 IST renewal cron run (cert has ~57d left, so a failure still
    leaves ~45d). Probe flips on either outcome; then: success -> close, FATAL -> retire the
    wildcard cert or move issuance off Vercel."
  since: 2026-11-26
  probe:
    cmd: grep -qE "^\[2026-12-[0-9]{2}T[^]]*\] (issuance succeeded|FATAL)"
      "$HOME/.cache/bass-tuner-cert-renewal.log"
    exit: 1
    at: 2026-11-25T22:32:57Z
    log: evidence/bt-2593-2026-11-25T22-32-57Z-probe.txt
    sha256: a25b0e1a8cdbaa26488fa250ed52a321de7de45d042752d155f5cb9016d4052f
    bytes: 112
  gate_owner: time
  parked_claim:
    owner: capacity-engine
    at: 2026-11-25T22:31:20Z
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): only ls and --challenge-only were exercised; a real issue writes

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-113a, session `wildcard-cert-renewal-cr-0f6016`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: grep -qE "^\[2026-12-[0-9]{2}T[^]]*\] (issuance succeeded|FATAL)" "$HOME/.cache/bass-tuner-cert-renewal.log"
GATE-OWNER: time

## Log
- 2026-11-26 claimed by capacity-engine
- 2026-11-26 PREMISE-PROBE: grep -qE "^\[2026-12-[0-9]{2}T[^]]*\] issuance succeeded" "$HOME/.cache/bass-tuner-cert-renewal.log"
- 2026-11-26 Checked 2026-11-26: final non-challenge issue step last ran for real 2026-09-21 (log line 69 'issuance succeeded'), pre-soft-block. Soft-block since 2026-11-24 only verified for certs ls + --challenge-only (bt-113a). Forcing a real issuance now was NOT done: writes prod Cloudflare TXT + ACME issuance on a cert with 57d left. Cron fires Mon 2026-12-07 06:17 IST; probe above passes once that run logs success.
- 2026-11-26 claim by capacity-engine parked (blocked)
- 2026-11-26 blocked: Wait for the 2026-12-07 06:17 IST renewal cron run (cert has ~57d left, so a failure still leaves ~45d). Probe flips on either outcome; then: success -> close, FATAL -> retire the wildcard cert or move issuance off Vercel. [probe `grep -qE "^\[2026-12-[0-9]{2}T[^]]*\] (issuance succeeded|FATAL)" "$HOME/.cache/bass-tuner-cert-renewal.log"` exit 1, owner time]
