---
id: bt-5c88
title: Port th-0dd5 ambient-GIT_* scrub + core.bare guard to this repo's pre-push hook (per-clone
  hook caveat)
status: done
priority: p3
tags:
  - infra
  - git
  - reliability
created: 2026-10-12
filed:
  owner: meni-worker/port-the-pre-push-ambien-9a509c
  at: 2026-10-12T09:16:05Z
reported: 2026-10-12
done:
  at: 2026-10-12T14:37:50Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 98ee1b335c69318af46b84c043574c662c295f1e
    repo: donefile
    verified: 2026-10-12T14:37:50Z
  - type: test
    cmd: diff /home/omri/projects/donefile/hooks/pre-push.sh
      /home/omri/projects/bass-tuner/.git/hooks/pre-push && echo NO_DRIFT
    exit: 0
    at: 2026-10-12T14:37:50Z
    log: evidence/bt-5c88-2026-10-12T14-37-50Z-test.txt
    sha256: 8613ec24af025a13f856014ffec10cdae14677d5157eafcbfad63b11064906bd
    bytes: 132
  - type: note
    value: "not real / already fixed: dn-21df (done 2026-10-12T11:25:24Z, commits bb7eef40+98ee1b33 in
      donefile) ported the th-0dd5 ambient-GIT_* scrub + core.bare guard into donefile's pre-push
      TEMPLATE (hooks/pre-push.sh) and the hooks-check--fix propagation already carried it to
      bass-tuner's installed .git/hooks/pre-push (one of the 5 PER_CLONE boards named in dn-21df's
      own evidence). Read of the installed hook confirms: top-level GIT_* prefix scrub (broader than
      the literal list -- every ${!GIT_@} var), entry-time core_bare_guard_check sourcing meniapp's
      canonical lib by absolute path with WARN-not-fail-loud fallback, and an exit-time check folded
      into the hook's existing run_log EXIT trap (_dn_prepush_on_exit) rather than a second trap.
      diff against the template shows zero drift. Fresh verification today (2026-10-12): (1)
      donefile's own vitest suite test/pre-push-hook.test.ts run fresh, 29/29 passing including
      'repairs a pre-existing core.bare=true on entry (dn-21df, th-0dd5)'; (2) hooks-check reports
      bass-tuner gated, 0 findings; (3) hand-built hermetic test against a real throwaway repo using
      bass-tuner's actual installed hook file: a clean push succeeds normally; a push whose own test
      script corrupts the shared checkout via an explicit GIT_DIR=<worktree-gitdir> git init is
      caught, repaired (core.bare unset), and REFUSED by git (stderr: 'core-bare-guard: REFUSED ...
      (th-0dd5/th-5dbe/dn-21df)', 'error: failed to push some refs'). No code changes needed here;
      closing as already-fixed."
---

Port the ambient-GIT_* scrub + shared-checkout core.bare guard (th-0dd5, originated in trips-hub's th-5dbe) to this repo's pre-push hook.

Why: git's guess_repository_type() decides a `git init`'s core.bare from the basename of the GIT_DIR it is handed. Git exports GIT_DIR into every hook, and for a push from a linked worktree (the mandated fleet workflow) that value is <repo>/.git/worktrees/<name> -- so any `git init`/clone/scratch-repo fixture this hook runs without its own scrub flips core.bare=true on the SHARED checkout, breaking every work-tree command there. Not trips-hub-specific; any repo's gate has the identical exposure.

The canonical implementation now lives in meniapp: scripts/lib/core-bare-guard.sh (/home/omri/projects/meniapp/scripts/lib/core-bare-guard.sh), already wired into meniapp's own deploy/git-hooks/pre-push, and ported into capacity-engine's .githooks/pre-push (parked for attended merge on branch th-0dd5-core-bare-guard-port, not yet on main) -- both are worked examples.

DURABILITY CAVEAT SPECIFIC TO THIS REPO: this repo's pre-push hook lives at .git/hooks/pre-push, which git does NOT track and a fresh `git clone` does NOT copy (per child-CLAUDE.md's pre-push-guard-table: this repo is in the PER_CLONE bucket, not VERSIONED). A plain edit to the live hook file protects THIS clone only -- the next fresh clone gets no guard at all, silently. Before editing the live hook file: check whether this repo already has a tracked installer script (install-*-hooks.sh or similar) that writes/symlinks .git/hooks/pre-push on setup. If one exists, port the change into that installer's TEMPLATE so every future install carries it, then re-run the installer here to pick it up. If no such installer exists, still make the live-hook edit (protects this clone now), but say explicitly in the closing evidence that the fix does not survive a re-clone, and consider filing a second, separate task for "give this repo a tracked hook installer" rather than silently treating the live edit as a complete fix.

What to add to the hook itself:
1. A top-level `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_PREFIX`, before anything else runs.
2. Source meniapp's canonical lib by absolute path (WARN, don't fail loud, if missing), then an entry-time core_bare_guard_check call: repair-and-warn, never refuse.
3. An exit-time core_bare_guard_check call that DOES refuse if the checkout was corrupted during this run -- check first whether this hook already sets its own `trap ... EXIT` (bash traps are single-slot per signal); if so, fold the check into that existing handler rather than registering a second one. See capacity-engine's or meniapp's version (branch th-0dd5-core-bare-guard-port / already on meniapp main) for both shapes of this.

DONE WHEN: a real push from a linked worktree still succeeds, and a manual `git --git-dir=<shared .git> config core.bare true` injected before a push is repaired-and-warned-about (entry case) while the same corruption injected BY a gate step during the run IS refused (exit case). Verify both with a hermetic test against a real throwaway repo (copy meniapp's/trips-hub's scripts/lib/core-bare-guard.test.sh, it needs no repo-specific changes beyond the LIB path).

## Log
- 2026-10-12 claimed by capacity-engine
- 2026-10-12 done by capacity-engine/worker — commit 98ee1b335c69 (donefile), test `diff /home/omri/projects/donefile/hooks/pre-push.sh /home/omri/projects/bass-tuner/.git/hooks/pre-push && echo NO_DRIFT` exit 0 (log: evidence/bt-5c88-2026-10-12T14-37-50Z-test.txt)
