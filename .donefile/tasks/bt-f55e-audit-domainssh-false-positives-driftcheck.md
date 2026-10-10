---
id: bt-f55e
title: audit-domains.sh false-positives DRIFT/CHECK on arch-preview.omrihefez.com, retired by ar-1fde
status: done
priority: p3
tags:
  - from-brief
  - cross-board
created: 2026-10-10
filed:
  owner: morning-brief
  at: 2026-10-10T08:03:02Z
done:
  at: 2026-10-10T08:15:53Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 81dc7e1e118511521ee92297bbd25bf6d5f98348
    verified: 2026-10-10T08:15:53Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh
    exit: 0
    at: 2026-10-10T08:15:30Z
    log: evidence/bt-f55e-2026-10-10T08-15-30Z-test.txt
    sha256: eaa720686fcf0fd235333088cfb17c0397b206501cb588849eca638a19739db6
    bytes: 11895
  - type: live
    cmd: bash -c "cd /home/omri/projects/bass-tuner; OUT=\$(bash scripts/audit-domains.sh 2>&1); echo
      \"\$OUT\" | grep -qF \"SKIP   arch-preview.omrihefez.com -> 404 retired, not drift\" || exit
      1; N=\$(echo \"\$OUT\" | grep -cE \"^(DRIFT|CHECK)[[:space:]]+arch-preview\.omrihefez\.com\");
      [ \"\$N\" = \"0\" ]"
    exit: 0
    at: 2026-10-10T08:15:30Z
    log: evidence/bt-f55e-2026-10-10T08-15-30Z-live.txt
    sha256: b13c9470634f694ca776e4db7553011438c70cb002d372131775af886bbc523a
    bytes: 305
---

scripts/audit-domains.sh still treats arch-preview.omrihefez.com as a live passkey-protected host expecting 307 -> /login (SUBS map entry + an ar-3426-dated exemption). meni-arch's ar-1fde (closed 2026-10-09 04:12) intentionally retired this host via `vercel alias rm` -- it now 404s by design, and check-promotion-drift.sh's preview target moved to preview.meni.omrihefez.com. The 2026-10-10 06:10 domain-audit run is the first to show the 404 and flags it as DRIFT, which will refire daily forever. Done when: audit-domains.sh no longer emits a DRIFT/CHECK line for arch-preview.omrihefez.com -- either drop it from the SUBS list (same pattern as the albumclub/apartments teardowns in ~/meni/DOMAIN.md) or add an explicit "retired, expect 404" exemption citing ar-1fde -- and a live run of the script shows no arch-preview line in its output.

Filed by the morning brief's intake pass.

cross-board: names a file under 'meni' at /home/omri/meni — ~/meni is undispatched — route it via ~/inbox/meni-board-queue/ instead (see dn-334c).

## Log
- 2026-10-10 claimed by capacity-engine
- 2026-10-10 done by capacity-engine/worker — commit 81dc7e1e1185, test `cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh` exit 0 (log: evidence/bt-f55e-2026-10-10T08-15-30Z-test.txt), live `bash -c "cd /home/omri/projects/bass-tuner; OUT=\$(bash scripts/audit-domains.sh 2>&1); echo \"\$OUT\" | grep -qF \"SKIP   arch-preview.omrihefez.com -> 404 retired, not drift\" || exit 1; N=\$(echo \"\$OUT\" | grep -cE \"^(DRIFT|CHECK)[[:space:]]+arch-preview\.omrihefez\.com\"); [ \"\$N\" = \"0\" ]"` exit 0 (log: evidence/bt-f55e-2026-10-10T08-15-30Z-live.txt)
