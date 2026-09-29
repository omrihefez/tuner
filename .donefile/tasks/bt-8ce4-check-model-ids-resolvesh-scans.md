---
id: bt-8ce4
title: check-model-ids-resolve.sh scans only /home/omri/projects/* so every Gemini model ID in
  ~/meni/bin is invisible to the 2026-10-20 retirement guard
status: open
priority: p2
tags:
  - monitoring
  - models
  - cross-board
created: 2026-09-29
filed:
  owner: meni-worker/board-refill-work-discov-c54ec0
  at: 2026-09-29T17:38:07Z
---

`scripts/check-model-ids-resolve.sh` is the fleet's only guard that a hardcoded Gemini
model ID still resolves against the provider. It runs daily at 06:14 via
`run-monitor.sh model-ids` (crontab, installed by `scripts/install-monitoring-crons.sh:91`).

ITS SCAN ROOT IS ONE HARDCODED GLOB. `check-model-ids-resolve.sh:88`:

    for _d in /home/omri/projects/*/; do

So every model ID outside `/home/omri/projects/` is invisible to it by construction —
not under-covered, structurally unreachable. This is the same single-root defect the
board census has been widened for three times (ce-1ff6 added `~/meni`, ce-bea1 added
`~/tik-api`, ce-e7d7 added `-L` for the six symlinked subtrees).

WHAT IS ACTUALLY UNGUARDED TODAY, measured 2026-09-29 by
`grep -rn "gemini-2\.5" /home/omri/meni/bin`:

    bin/gemini_call.py:59    def tts(text, voice="Charon", model="gemini-2.5-pro-preview-tts", ...)
    bin/gemini_call.py:212   def generate(prompt, model="gemini-2.5-flash", timeout=120)
    bin/hebrew-review.py:23  MODEL = "gemini-2.5-pro"
    bin/apify_newaccount.py:97        .../models/gemini-2.5-pro:generateContent
    bin/apify_newaccount_image.py:20  def vision_pick(..., model="gemini-2.5-pro")
    bin/google_guard.py:52-53         price table keyed on gemini-2.5-pro / gemini-2.5-flash

`gemini_call.py` is the SHARED wrapper — its two function defaults are what every caller
that does not pass `model=` gets. `vidsmith/vidsmith/tts.py:5` names `gemini_call.tts()`
as its own path to TTS.

THE DEADLINE MAKES THIS TIME-BOXED, not hygiene. Google's Gemini 2.5 retirement is
**2026-10-20 — 21 days from today**. The dated-constraint scan for this sweep carries
four separate rows on that date (vs-d3ef, sb-bda7, ma-50ae, kd-3d2b), every one of them
a per-repo task that had to be filed and worked by hand. `bt-5abe` built this monitor so
the NEXT retirement would be caught automatically; the un-scanned root is where the
catch does not happen. Priced p2 on the dated constraint, not on the code shape.

NOTE ON SCOPE: this task is bass-tuner's — widening the guard's roots. It deliberately
does NOT ask anyone to change `~/meni/bin`; that repo is Main-only and a worker may not
commit to it. Fixing the guard is what makes those strings visible, and what they are
then worth doing about is a separate call for Main.

DONE WHEN
1. `SCAN_ROOTS`' default covers the roots the board census already learned it needs —
   at minimum `/home/omri/meni`, and decide explicitly (in a comment, as this script
   already does for the worktree-dir exclusions) whether `/home/omri/compose`,
   `/home/omri/tik-api`, `/home/omri/apartment` and `/home/omri/study` belong too.
   `MODEL_SCAN_ROOTS` stays overridable so the companion test stays hermetic.
2. Descending into the new roots does not reintroduce the worktree/vendored-clone noise
   the current `case` at :90-92 filters, and does not follow a symlink loop (see the
   census's own `-prune` lesson, ce-04af).
3. `scripts/check-model-ids-resolve.test.sh` gains a case that FAILS on the current
   default and passes after: point a fixture root outside `/home/omri/projects` and
   assert the model ID in it is discovered. Watch it go red against the parent commit
   before closing — a test that only ever passes cannot tell you the root was widened.
4. Run the widened guard once for real and report what it discovers, so the
   `~/meni/bin` strings above get a live resolve verdict rather than an assumption.

VERIFY (from the main checkout, never a worktree)

    cd /home/omri/projects/bass-tuner && bash scripts/check-model-ids-resolve.test.sh

Filed by the periodic discovery sweep, 2026-09-29.


cross-board: names a file under 'vidsmith' at /home/omri/projects/vidsmith — consider filing there instead (see dn-334c).
