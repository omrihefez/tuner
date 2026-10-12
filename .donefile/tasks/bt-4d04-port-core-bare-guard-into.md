---
id: bt-4d04
title: Port core-bare-guard into donefile's canonical hooks/pre-push.sh template (dn-979a already
  covers this — sequence it AFTER dn-21df-identity-guard-propagation lands, since both touch the
  same shared template/propagation machinery)
status: done
priority: p3
tags:
  - infra
  - git
  - reliability
created: 2026-10-12
filed:
  owner: capacity-engine
  at: 2026-10-12T11:04:26Z
reported: 2026-10-12
done:
  at: 2026-10-12T13:42:44Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 98ee1b335c69318af46b84c043574c662c295f1e
    repo: donefile
    verified: 2026-10-12T13:42:44Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && N=$(grep -c core_bare_guard_check .git/hooks/pre-push);
      echo N=$N; [ "$N" = "2" ]
    exit: 0
    at: 2026-10-12T13:42:44Z
    log: evidence/bt-4d04-2026-10-12T13-42-44Z-test.txt
    sha256: f2e3112a303734680106de51ab17e9c85715292c0b757c73084a5a18e15ba054
    bytes: 126
  - type: note
    value: "not real / already fixed: dn-21df (donefile, done 2026-10-12) was widened mid-task by Main
      to install the core.bare guard alongside the identity guard into donefile's canonical
      hooks/pre-push.sh template, then propagated it via the already-scheduled hooks-check --all
      --fix tick to all 5 PER_CLONE boards including bass-tuner. Verified fresh: bass-tuner's live
      .git/hooks/pre-push is byte-identical (diff, exit 0) to donefile's hooks/pre-push.sh template
      and carries core_bare_guard_check wired at both entry (line 189) and exit (line 502), plus the
      ambient GIT_DIR/GIT_WORK_TREE/GIT_COMMON_DIR scrub (line 151). This is PER_CLONE (not tracked
      in bass-tuner's own .git) so a fresh clone needs the installer/hooks-check re-run to pick it
      up again -- durability caveat already recorded on dn-21df, not re-filing it here."
---

Named in the finding: hooks/pre-push.sh, template/propagation

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): live-hook-only edits on meni-arch (and presumably donefile/kidai/bass-tuner/zn-tournaments, all PER_CLONE) get resynced back to the unfixed template by a fleet hook-hygiene process even within one session — only a template-level fix in donefile is durable.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working ar-d9f9, session `port-th-0dd5-ambient-git-87a059`, dispatched on meni-arch.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on donefile, kidai (ce-71de). Scope this task to the part that is actually about meni-arch; the siblings cover the rest.
That task's report closed DONE (commit d6e245548b18864919949f8751208d5a99607541 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `d6e245548b18864919949f8751208d5a99607541` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-12 claimed by capacity-engine
- 2026-10-12 done by capacity-engine/worker — commit 98ee1b335c69 (donefile), test `cd /home/omri/projects/bass-tuner && N=$(grep -c core_bare_guard_check .git/hooks/pre-push); echo N=$N; [ "$N" = "2" ]` exit 0 (log: evidence/bt-4d04-2026-10-12T13-42-44Z-test.txt)
