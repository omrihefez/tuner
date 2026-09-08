---
id: bt-6773
title: "pre-push gate 'hub-auto-restart: node_modules lock' fails on every real push, passes
  standalone (ma-cf06 regression)"
status: done
priority: p1
tags:
  - hub
  - bug (filed as ma-b35d on meniapp)
created: 2026-09-08
filed:
  owner: capacity-engine
  at: 2026-09-08T17:31:52Z
done:
  at: 2026-09-08T18:15:59Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: "git -C /home/omri/projects/meniapp ls-files | grep -q
      '^hub/scripts/test-hub-node-modules-lock-race\\.sh$' && [ \"$(git -C
      /home/omri/projects/bass-tuner ls-files | grep -cE '^hub/|lock-race' || true)\" = \"0\" ] &&
      cd /home/omri/projects/meniapp && node /home/omri/projects/donefile/dist/cli.js show ma-b35d
      2>&1 | grep -q 'OOM-kills under the 1536M worker cgroup cap' && node
      /home/omri/projects/donefile/dist/cli.js show ma-b35d 2>&1 | grep -qE '^status:
      (open|claimed|blocked)' && grep -q '^MemoryMax=1536M'
      /home/omri/.config/systemd/user/meni-child@.service && grep -q '^MemorySwapMax=0'
      /home/omri/.config/systemd/user/meni-child@.service.d/50-memoryswapmax.conf"
    exit: 0
    at: 2026-09-08T18:15:56Z
    log: evidence/bt-6773-2026-09-08T18-15-56Z-test.txt
    sha256: 746b59724f6a31d4d5d04ccefd6abc298032e2d65748e9c01c76fafa8f9bd83f
    bytes: 668
  - type: note
    value: >-
      CLOSED AS CONFIRMED CROSS-BOARD DUPLICATE + DEAD PREMISE. No code change; nothing to fix in
      bass-tuner.


      The task body's own instruction ("START HERE: read ma-b35d before doing any work") resolved
      it. ma-b35d is the same finding, on the board that owns it, and is still live.


      1) THE TITLE'S ROOT CAUSE IS PROVEN WRONG. bt-6773 is titled "(ma-cf06 regression)". ma-b35d
      was retitled 2026-09-08 to "workers cannot push meniapp: pre-push gate OOM-kills under the
      1536M worker cgroup cap (not a hub-lock bug)" after the same worker
      (ff-sync-main-checkout-sh-f8fde6, who wrote the FOLLOW-UP line this task was auto-filed from)
      tested main's competing hypothesis and retracted its own framing. Its evidence: 6 OOM-kill
      events in `journalctl --user -u meni-child@ff-sync-main-checkout-sh-f8fde6`, one per real push
      attempt, peaks at the 1.5G ceiling. "hub-auto-restart: node_modules lock" was the step running
      when the worker was killed, not a failing check. So implementing bt-6773 as written would be
      fixing a lock bug that does not exist.


      2) IT IS NOT BASS-TUNER'S WORK. This board was chosen only because the discovering session
      happened to be dispatched here. bass-tuner tracks no `hub/` path and no lock-race script: `git
      -C /home/omri/projects/bass-tuner ls-files | grep -E '^hub/|lock-race'` matches nothing. The
      implicated file is /home/omri/projects/meniapp/hub/scripts/test-hub-node-modules-lock-race.sh.


      3) THE REAL ROOT CAUSE IS LIVE AND IS CONFIGURATION, NOT A DEFECT. Confirmed fresh from this
      worker's own cgroup rather than re-quoting ma-b35d:
           memory.max       1610612736   (1536 MiB)
           memory.high      max
           memory.swap.max  0
         Both non-obvious values are DELIBERATE and documented drop-ins, so do not "fix" them as a misconfiguration:
           50-memoryswapmax.conf (ma-37f5) sets MemorySwapMax=0 so MemoryHigh can terminate a runaway instead of funding it from swap forever.
           51-memoryhigh-no-throttle-band.conf (ma-0bf1) sets MemoryHigh=infinity so a render cannot livelock inside the throttle band; measured 34/80 frames in 180s with the band vs 80/80 in 29s without.
         Net: a worker gets a hard 1536M wall, no swap, and no reclaim band before it. meniapp's full pre-push gate peaks ~2.55G (main's measurement). That is why the failure is deterministic and content-independent. ma-b35d's recorded root cause stands unchanged; I found nothing to add to it.

      WHAT REMAINS, AND WHERE: both sub-problems are already recorded on ma-b35d (open, p1, meniapp)
      with fix owners named — (a) worker cgroup sizing vs the gate's memory footprint, (b)
      test-hub-node-modules-lock-race.sh's race-window timing being too tight to survive box
      contention even without an OOM kill. Deliberately filing NO follow-up here: a third copy on a
      third board is how this became two tasks in the first place.


      EVIDENCE NOTE ON WHAT THIS CLOSURE DOES AND DOES NOT REST ON. The --test command asserts five
      independent properties, and each was verified to FAIL when negated (five negative controls
      run, all exit 1): the implicated script is tracked in meniapp; bass-tuner tracks zero matching
      paths; ma-b35d carries the corrected root-cause title; ma-b35d is still open/claimed/blocked
      rather than closed out from under this; and the 1536M cap plus MemorySwapMax=0 are still the
      live configuration. Every clause is a positive assertion on captured state - an earlier draft
      used `! ... | grep -q` for the bass-tuner clause and donefile correctly refused it, since a
      negated pipeline passes identically whether the thing is absent or the command was mistyped.


      Four of the five clauses are greps over donefile task text and systemd unit text. That is the
      right instrument for "is this tracked elsewhere" and "is this still the configured cap", but
      it is text, not behaviour, and it is said plainly here rather than left for the next reader to
      work out. What this closure does NOT do is reproduce the OOM: doing so means pushing meniapp,
      which is the broken thing itself, and ma-b35d already holds six measured instances.
---

POSSIBLE CROSS-BOARD DUPLICATE — ma-b35d on meniapp (open, 90% title match) looks like the same finding. This filed anyway because that match is scored WITHOUT the repo-identity check same-board dedupe relies on (ce-916b: routing had no signal for either finding to place it confidently), so it's a pointer to check, not a confirmed dup. START HERE: read ma-b35d before doing any work — if it already covers this, close with a note saying so instead of redoing it.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-ea85, session `ff-sync-main-checkout-sh-f8fde6`, dispatched on bass-tuner.
Reported 2026-09-08 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit b54d8816ad19f4fc86a9a68918e7e2a1b7b1af07).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-08 claimed by capacity-engine
- 2026-09-08 done by capacity-engine/worker — test `git -C /home/omri/projects/meniapp ls-files | grep -q '^hub/scripts/test-hub-node-modules-lock-race\.sh$' && [ "$(git -C /home/omri/projects/bass-tuner ls-files | grep -cE '^hub/|lock-race' || true)" = "0" ] && cd /home/omri/projects/meniapp && node /home/omri/projects/donefile/dist/cli.js show ma-b35d 2>&1 | grep -q 'OOM-kills under the 1536M worker cgroup cap' && node /home/omri/projects/donefile/dist/cli.js show ma-b35d 2>&1 | grep -qE '^status: (open|claimed|blocked)' && grep -q '^MemoryMax=1536M' /home/omri/.config/systemd/user/meni-child@.service && grep -q '^MemorySwapMax=0' /home/omri/.config/systemd/user/meni-child@.service.d/50-memoryswapmax.conf` exit 0 (log: evidence/bt-6773-2026-09-08T18-15-56Z-test.txt)
