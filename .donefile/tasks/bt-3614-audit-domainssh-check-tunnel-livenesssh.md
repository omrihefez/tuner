---
id: bt-3614
title: audit-domains.sh, check-tunnel-liveness.sh, check-permissions-policy.sh,
  check-cors-corp-consistency.sh mention vercel in comments only (no runtime call), so none of them
  share this bug — confirmed, no action needed
status: done
priority: p3
tags:
  - bass-tuner
created: 2026-10-15
filed:
  owner: capacity-engine
  at: 2026-10-15T06:22:02Z
reported: 2026-10-15
done:
  at: 2026-10-15T06:27:55Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && N=$(grep -ohE
      '(\$\(vercel\b|=\(vercel\b|^[[:space:]]*vercel\b)' scripts/audit-domains.sh
      scripts/check-tunnel-liveness.sh scripts/check-permissions-policy.sh
      scripts/check-cors-corp-consistency.sh | wc -l) || true; [ "$N" = "0" ]
    exit: 0
    at: 2026-10-15T06:27:55Z
    log: evidence/bt-3614-2026-10-15T06-27-55Z-test.txt
    sha256: e17fa02df423e454d467cb7c2b658e7533d289a15df8b53a04bac87270b5cd49
    bytes: 271
  - type: note
    value: "Verified by manual review + a shape-based probe: searched the four named files for any
      syntactic shape a vercel CLI invocation actually takes (bare command at line start, inside
      $(...) command substitution, inside an array assignment cmd=(...)) — the same shapes present
      in the two scripts that DO have the PATH bug (check-unregistered-live-hosts.sh,
      renew-wildcard-cert.sh, fixed in bt-e452/bt-a428). Sanity-checked the regex against
      renew-wildcard-cert.sh first (3 hits, confirming the probe can detect the bug), then ran it
      against the four target files (0 hits). Every 'vercel' occurrence in the four files is a
      comment, a variable name (NONVERCEL_/VERCEL_), a string literal (vercel.com, x-vercel-error,
      vercel.json, a historical note like 'vercel alias rm, 2026-10-09'), or the vercel/non-vercel
      filter keyword passed as a plain string argument to the local derive_registry_hosts() shell
      function (scripts/lib/domain-registry.sh:53) -- never the vercel binary itself. Premise
      confirmed true, no code change needed."
---

Named in the finding: audit-domains.sh, check-tunnel-liveness.sh, check-permissions-policy.sh, check-cors-corp-consistency.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): grepped for actual (non-comment) vercel invocations, found none

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-e452, session `unregistered-live-hosts--de2930`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 48c50f13d179c6ec78e0e8efa2486fcaebff448c).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-15 claimed by capacity-engine
- 2026-10-15 done by capacity-engine/worker — test `cd /home/omri/projects/bass-tuner && N=$(grep -ohE '(\$\(vercel\b|=\(vercel\b|^[[:space:]]*vercel\b)' scripts/audit-domains.sh scripts/check-tunnel-liveness.sh scripts/check-permissions-policy.sh scripts/check-cors-corp-consistency.sh | wc -l) || true; [ "$N" = "0" ]` exit 0 (log: evidence/bt-3614-2026-10-15T06-27-55Z-test.txt)
