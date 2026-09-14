---
id: bt-3740
title: compose has no origin/HEAD, so every default-branch check this board makes against it is
  silently SKIPPED — the exact check bt-443d registered it for
status: done
priority: p2
tags:
  - audit
  - config
created: 2026-09-14
filed:
  owner: meni-worker/board-refill-work-discov-a006fa
  at: 2026-09-14T13:24:59Z
done:
  at: 2026-09-14T14:01:32Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: f9e4e21c59f65caf0cab82a9b539829c0b9cd12a
    verified: 2026-09-14T14:01:32Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && OUT=$(node
      /mnt/HC_Volume_106231699/cache/capacity-engine/head/donefile-reminder-gate.js audit
      --actionable 2>&1); N=$(printf "%s" "$OUT" | grep -o DEFAULT_BRANCH_UNRESOLVED | wc -l); [
      "$N" = "0" ] && node -e "const
      git=require(\"/home/omri/projects/donefile/dist/lib/git.js\");const
      r=git.resolveDefaultBranch(\"/home/omri/compose\",\"main\");process.exit(r.ref===\"refs/remotes/origin/main\"?0:1)"
    exit: 0
    at: 2026-09-14T14:01:26Z
    log: evidence/bt-3740-2026-09-14T14-01-26Z-test.txt
    sha256: 8e16f15acc028aecaac11696dbf2f83b17f4c4538813d2b23d88651de8a02cf8
    bytes: 441
---

`cd /home/omri/projects/bass-tuner && node /mnt/HC_Volume_106231699/cache/capacity-engine/head/donefile-reminder-gate.js audit --actionable` reports:

    DEFAULT_BRANCH_UNRESOLVED  cannot resolve the default branch of /home/omri/compose:
    it has an origin remote but no `origin/HEAD` (nobody ran `git remote set-head origin -a`
    in this clone) — so every default-branch check against this repo (UNMERGED_EVIDENCE,
    OPEN_LIKELY_SHIPPED, STALE_BLOCK) is SKIPPED, not passing.

This board reaches `/home/omri/compose` on purpose: `.donefile/config.yml` line 25 registers `compose: /home/omri/compose` under bt-443d (2026-09-13), because this board's compose.omrihefez.com security-headers finding is fixed in that repo rather than in bass-tuner.

So the failure is self-defeating: the extra repo was wired up precisely so donefile could verify a fix had landed on compose's default branch, and the one thing that cannot happen is a default-branch check against compose. It does not error — it SKIPS, which reads the same as clean. A closure on this board citing a compose commit would be accepted with nothing having confirmed the commit is on compose's default branch at all.

Context worth knowing before touching `/home/omri/compose`: it is deliberately NOT a dispatchable board (capacity-engine `config.json` `sunset_repos`, ce-917c — "EXCLUDED (not sunset) 2026-08-24... 12 weeks idle, no tests, no CI"). compose.omrihefez.com is nonetheless LIVE and PUBLIC, and its missing security headers are tracked as df-0061 on the meni board. None of that is changed by this task — this is about bass-tuner's own verification path, not about giving compose a board.

Two ways to fix, pick one and say why:

- `git -C /home/omri/compose remote set-head origin -a` — one command, but it is state on an untracked clone, so it silently un-fixes itself if that clone is ever replaced.
- Pin it explicitly via `integration_branch` in this board's `.donefile/config.yml` for the `compose` entry — declarative, survives a re-clone, and is the one a reader can see.

The second is probably right for the same reason the finding exists: the current failure is invisible, and config is the only place that is not.

DONE WHEN: `cd /home/omri/projects/bass-tuner && node /mnt/HC_Volume_106231699/cache/capacity-engine/head/donefile-reminder-gate.js audit --actionable` no longer reports DEFAULT_BRANCH_UNRESOLVED for `/home/omri/compose`, AND the fix has been shown to actually restore the check — not merely to silence the finding. Demonstrate that by pointing a default-branch check at a known compose commit and confirming it now resolves rather than skipping.

## Log
- 2026-09-14 claimed by capacity-engine
- 2026-09-14 done by capacity-engine/worker — commit f9e4e21c59f6, test `cd /home/omri/projects/bass-tuner && OUT=$(node /mnt/HC_Volume_106231699/cache/capacity-engine/head/donefile-reminder-gate.js audit --actionable 2>&1); N=$(printf "%s" "$OUT" | grep -o DEFAULT_BRANCH_UNRESOLVED | wc -l); [ "$N" = "0" ] && node -e "const git=require(\"/home/omri/projects/donefile/dist/lib/git.js\");const r=git.resolveDefaultBranch(\"/home/omri/compose\",\"main\");process.exit(r.ref===\"refs/remotes/origin/main\"?0:1)"` exit 0 (log: evidence/bt-3740-2026-09-14T14-01-26Z-test.txt)
