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
- 2026-10-15 Main, 2026-10-15 23:45 IDT — carrying the diagnosis here from ce-0d9d, which was a cross-board
duplicate of this task (capacity-engine's parser filed it on the wrong board; ce-cadf fixes the
defect). The analysis was done against the real failing run, so it should live where the work is.

**The failing run is 38691612455, on a GitHub-HOSTED runner.** `ci.yml:29` has exactly one
`runs-on:` and it is `ubuntu-latest`; the run reports a Hosted Compute Agent (Azure westus3,
image ubuntu-24.04). That matters because a worker initially attributed this to iac-fc0d
("meni-ci self-hosted runner can't read /home/omri") and parked it there. **That cannot be the
cause here** — no job in this repo touches the self-hosted runner, so iac-fc0d landing (it is now
done, 0d083bd0) does not turn this green. Classify by `runs-on` before attributing a cause.

**Step conclusions — it is this repo's own tests, not infrastructure:**

    JOB: Static checks -> failure
      4. JS syntax check ................. success
      5. HTML validate ................... success
      6. Internal link + manifest check .. success
      7. sw.js cache-bump check .......... success
      8. Unit tests ...................... FAILURE

**The actual failure:**

    FAIL: install-monitoring-crons.sh: with a real crontab present, installer exited 1 and
    wrote_crontab=no -- the guard must not block a normal install.
    stderr: bash: /home/omri/projects/meniapp/scripts/lint-crontab-logdirs.sh:
            No such file or directory

So `install-monitoring-crons.sh` execs **meniapp's `scripts/lint-crontab-logdirs.sh` by absolute
path**. That path exists only on the fleet box, so on a hosted runner the installer exits 1 and
the test correctly reports that it refused a normal install. Same class as ce-d302, which was
capacity-engine's own 26-day instance of exactly this and is now green.

**The fix pattern already exists in this repo, applied to a different call site.** Two log lines
earlier, in the same job:

    gitdir-scrub lint: meniapp not checked out at
    /home/omri/projects/meniapp/scripts/lint-testsh-gitdir-scrub.sh
    -- skipping (expected off the meni VPS, e.g. in CI)

That cross-repo call degrades to a visible skip; `lint-crontab-logdirs.sh` does not. The work is
to apply the guard this repo already owns to the call site that lacks it. Prefer the
INCONCLUSIVE convention where the harness counts it over a bare SKIP (ce-d160) — a skip nothing
tallies is its own blind spot, and that is the residual ce-d302 left behind.

**Do not be misled by `# fail 0` in the log.** The node TAP summary prints
`# tests 126 / # pass 126 / # fail 0` at 06:18:30, and the shell-harness FAIL above appears at
06:18:38 — eight seconds later, from a different harness inside the same `npm test`. The TAP
counts are true and the job still exits 1.

Cross-refs: ce-5e41 holds the fleet-wide triage (8 of 15 repos red, now classified into three
failure modes — hosted ENOENT, self-hosted EACCES from `ProtectHome=yes`, and account-wide
Actions-minutes exhaustion identifiable by `runner_id:0`). kidai (kd-e0cc) and tik-next
(tkn-7fa3) are the same hosted-sibling-path shape as this one and were deduped against each
other by the dispatcher at score 1, so a fix here is likely portable to both.
