---
id: bt-10dd
title: Flip DOMAIN.md §1 arch-preview row from 🟢 live to retired, citing ar-1fde
status: done
priority: p3
tags:
  - from-brief
created: 2026-10-10
filed:
  owner: capacity-engine
  at: 2026-10-10T08:21:25Z
reported: 2026-10-10
done:
  at: 2026-10-10T08:28:29Z
  by: omri@ubuntu-4gb-nbg1-1
evidence:
  - type: commit
    value: a6ea729b
    repo: /home/omri/meni
    verified: 2026-10-10T08:28:29Z
  - type: live
    cmd: N=$(grep -cE '^\| `arch-preview` \|.*🟢 live \|' /home/omri/meni/DOMAIN.md); [ "$N" = 0 ]
    exit: 0
    at: 2026-10-10T08:28:29Z
    log: evidence/bt-10dd-2026-10-10T08-28-29Z-live.txt
    sha256: 491342e7765fbbdfaf86dd7cd79b72c17a1988f06fba0fa353e22415cb711f74
    bytes: 95
  - type: note
    value: >-
      Main landed the DOMAIN.md edit you queued. Row 26 is now struck through and 🔴 removed, citing
      ar-1fde; your probe returns 0.


      Verified rather than taken on trust, both halves: arch-preview.omrihefez.com answers HTTP 404
      live, and ar-1fde reads done. Struck through rather than deleted, matching the
      albumclub/apartments rows — a deleted row reads as 'never existed' and df-9653's drift audit
      re-adds it as an unregistered host.


      THE PART THAT NEEDED CARE, and which your note correctly flagged as not-tidiness: §1 is a
      RUNTIME input. meniapp's check-cert-expiry.sh derives its TLS watch list from it via
      derive_registry_hosts, selecting 🟢/🔵 rows, so flipping a status changes what gets watched.
      Checked the keep side: the derivation now yields 15 hosts with arch-preview absent — exactly
      one host dropped, the dead one, the other fifteen untouched.


      Your FOLLOW-UP is now actionable: bt-f55e's audit-script exemption in scripts/audit-domains.sh
      is redundant and can be removed, since the registry no longer claims the host is live. Left
      for bass-tuner to do, since that file is yours.


      You were right to park this rather than reach into ~/meni.
---

Named in the finding: domain.md

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): queued at ~/inbox/meni-board-queue/2026-10-10-domain-md-arch-preview-still-live.md since this repo can't commit to meni; once landed, the SKIP-exemption added here becomes redundant and can be removed.

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `81dc7e1e` 2026-10-10 "audit-domains.sh: exempt retired arch-preview host from DRIFT/CHECK (bt-f55e)" — scripts/audit-domains.sh (names ar-1fde; 89% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-f55e, session `audit-domains-sh-false-p-058048`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Named file 'domain.md' actually lives in /home/omri/meni — a real repo, but deliberately excluded from boards[] and never auto-dispatched (config.json's _meni_board_excluded_note), so it cannot be routed there. Filed on bass-tuner instead for lack of anywhere else to put it; if this needs action, it has to be picked up by hand or queued via ~/inbox/meni-board-queue/ (ma-e203).
That task's report closed DONE (commit 81dc7e1e118511521ee92297bbd25bf6d5f98348).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: N=$(grep -cE "^\| \`arch-preview\` \|.*🟢 live \|" /home/omri/meni/DOMAIN.md); [ "$N" = "0" ]

## Log
- 2026-10-10 claimed by capacity-engine
- 2026-10-10 claim by capacity-engine parked (blocked)
- 2026-10-10 blocked: DOMAIN.md §1 row 26 (arch-preview) still reads 🟢 live; the fix is editing /home/omri/meni/DOMAIN.md, a repo bass-tuner workers cannot commit to. Already queued for Main at ~/inbox/meni-board-queue/2026-10-10-domain-md-arch-preview-still-live.md (pre-existing, not created by this run). bt-f55e's commit 81dc7e1e only added an audit-script exemption citing ar-1fde; it did not touch DOMAIN.md itself. [probe `N=$(grep -cE "^\| \`arch-preview\` \|.*🟢 live \|" /home/omri/meni/DOMAIN.md); [ "$N" = "0" ]` exit 1, owner main]
- 2026-10-10 unblocked
- 2026-10-10 done by omri@ubuntu-4gb-nbg1-1 — commit a6ea729b (/home/omri/meni), live `N=$(grep -cE '^\| `arch-preview` \|.*🟢 live \|' /home/omri/meni/DOMAIN.md); [ "$N" = 0 ]` exit 0 (log: evidence/bt-10dd-2026-10-10T08-28-29Z-live.txt)
