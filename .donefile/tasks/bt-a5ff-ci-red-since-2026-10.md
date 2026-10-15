---
id: bt-a5ff
title: CI red since 2026-10-15 — install-monitoring-crons.sh exec's meniapp's canonical
  lint-crontab-logdirs.sh, unreachable by meni-ci
status: open
priority: p2
tags:
  - ci
created: 2026-10-15
filed:
  owner: meni-worker/8-of-15-repos-have-red-c-cf204d
  at: 2026-10-15T19:31:53Z
---

Static checks job fails: `install-monitoring-crons.sh: with a real crontab present, installer
exited 1 and wrote_crontab=no -- the guard must not block a normal install. stderr: bash:
/home/omri/projects/meniapp/scripts/lint-crontab-logdirs.sh: No such file or directory`.

Root cause is NOT in this repo's own logic -- it's the shared meni-ci permission gap tracked
in iac-fc0d (meni-ci, uid 996, can't traverse /home/omri/projects, which is mode 0700, to
reach meniapp's canonical scripts that bass-tuner's wrappers delegate to by absolute path).
Confirmed the same "canonical unreachable in CI" shape hit kidai and tik-next directly
(Permission denied there, vs "No such file" here -- same underlying EACCES, different surface
message depending on how each wrapper probes the path).

Closes once iac-fc0d lands (grants meni-ci access, or relocates the canonical scripts) and a
fresh CI run on this repo goes green. Re-run: gh run list -R omrihefez/tuner -b main -L 1.

## Log
- 2026-10-15 CORRECTED ROOT CAUSE (iac-fc0d, 2026-10-15) — this task's premise is wrong in a way that
matters: it says this closes once iac-fc0d's "access/relocation fix" lands. There will be no
access fix, and waiting for one blocks this task forever.

This repo's failing CI job runs on a GitHub-HOSTED runner (labels=["ubuntu-latest"]), not on
the meni-vps self-hosted one. There is no /home/omri on a hosted runner at all, so meni-ci's
uid, /home/omri's mode, and any ACL or systemd change on Omri's box are all irrelevant here.
The failure is a plain ENOENT, not the EACCES kidai and tik-next hit.

The fix is in THIS repo, and it is the convention several repos here already use: keep the
absolute canonical path as the preferred source and fall back to a committed *.vendored.sh pin
when it is not readable. See iac's docs/iac-fc0d-canonical-scripts-on-ci.md for the full
decision and why the two fixes originally proposed were both rejected, and iac's
scripts/lib/core-bare-guard.sh + scripts/install-git-hooks.sh for the shape (test the path with
-r / -x, not -f).

Pins get drift coverage automatically: meniapp's scripts/check-vendored-pin-drift.sh discovers
any *.vendored.sh from its own mandatory "verbatim copy of <repo>'s <path> below" header.
