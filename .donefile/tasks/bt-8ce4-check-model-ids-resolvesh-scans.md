---
id: bt-8ce4
title: check-model-ids-resolve.sh scans only /home/omri/projects/* so every Gemini model ID in
  ~/meni/bin is invisible to the 2026-10-20 retirement guard
status: open
priority: p3
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

## Log
- 2026-09-29 claimed by capacity-engine
- 2026-09-29 Main, 2026-09-29 evening: the STRUCTURAL claim is confirmed -- SCAN_ROOTS is
`/home/omri/projects/*/` and nothing else (check-model-ids-resolve.sh:87), so
~/meni/bin is genuinely outside the guard. Fix that.

But I ran the guard against ~/meni for live evidence before touching it, and
the exposure list in this task does not survive the probe. Do NOT just widen
SCAN_ROOTS -- as written it would ship two FALSE alarms and zero true findings:

  MODEL_SCAN_ROOTS="/home/omri/meni/" bash scripts/check-model-ids-resolve.sh
  -> DRIFT 2: gemini-2.5-flash-preview-image:404, gemini-25-model-strings:404

1. `gemini-25-model-strings` is not a model ID at all. It is a WORKER SESSION
   NAME in state/children.json:2802. The ID-extraction regex over-matches any
   `gemini-*` token in any file.
2. `gemini-2.5-flash-preview-image` 404s BY DESIGN. It appears only as a price
   table KEY in bin/billing_killswitch.py:133-134, and the ⚠️ comment directly
   above it (:96-100, "THE NAME TRAP, measured 2026-09-02") says why: calls go
   to `models/gemini-2.5-flash-image`, but Cloud Monitoring labels that same
   traffic `model = gemini-2.5-flash-preview-image`, and keying on the API name
   "matches nothing and prices the month at 0.00 -- the August failure shape
   exactly". It is a METRIC label. It will never resolve against the
   Generative Language API, and it must not be "fixed" to a name that does.

Also: the two defaults this task names as the headline risk -- gemini_call.py:59
`model="gemini-2.5-pro-preview-tts"` and :212 `model="gemini-2.5-flash"` -- both
still RESOLVE today. They are real defaults and the line numbers are right, but
they are not currently broken, so the 21-days-to-2026-10-20 urgency is a
forecast, not a measurement. I did not find the retirement notice itself; this
script has no hardcoded date and works purely by live probe.

So the real work is two things, and the second is the harder one:
  a. widen the roots to cover ~/meni (and say why ~/meni was ever excluded).
  b. give the extractor a way to tell an API model name from a metric label and
     from an arbitrary `gemini-*` string, or the widened guard cries wolf on its
     first run and gets ignored -- which is the failure mode this whole class of
     monitor keeps hitting. An allowlist keyed on the billing_killswitch comment
     would do it, but it needs to be a deliberate "this string is not an API
     name" marker, not a suppression file nobody reads.
- 2026-09-29 Main, 2026-09-29 20:5x IDT: DEADLINE FRAMING STRUCK, dropping p2 -> p3. The
filing worker traced its own 2026-10-20 date to source and it refutes the
urgency; I verified both halves independently rather than taking the retraction
on trust.

1. Scope of the notice. ma-50ae (lines 88-97, same block on kd-3d2b) quotes it
   verbatim out of Omri's mail via the second-brain index (mail, 2026-07-29):
   "Migrate your Gemini Enterprise Agent Platform workflows to generally
   available models before October 20, 2026". Scoped to GEMINI ENTERPRISE AGENT
   PLATFORM -- the Vertex side. Silent on generativelanguage.googleapis.com.
   Independently corroborated by vs-d3ef (vidsmith) and sb-bda7 (second-brain),
   both closed 2026-08-05 by workers who read the notice via Gmail REST.

2. Which endpoint ~/meni/bin actually calls. Read the code, did not assume:
   gemini_call.py:20 API, :24 VEO_START, :25 VEO_OP and apify_newaccount.py:97
   are all https://generativelanguage.googleapis.com/v1beta/... -- the PUBLIC
   endpoint. So the exact files cited to justify p2 are precisely the set the
   notice does not cover.

Net: there is no October deadline on this task. Combined with the two false
positives already noted above, the live probe against ~/meni returns ZERO true
findings today.

What survives, and it is still worth doing at p3: SCAN_ROOTS is
`/home/omri/projects/*/` (check-model-ids-resolve.sh:87) and ~/meni is outside
it, which is a real structural blind spot in the fleet's only model-retirement
guard. Fix it together with part (b) from the note above -- teach the extractor
to distinguish an API model name from a Cloud Monitoring metric label and from
an arbitrary gemini-* token -- because widening the root alone makes the guard
cry wolf on its first run.

Provenance of the error, worth keeping because it is reusable: the date came
from the brief's DATED CONSTRAINTS rows, which quote vs-d3ef and sb-bda7 BODIES
written before the scope correction landed. vs-d3ef's own DONE WHEN says "the
actual GCP sunset notice has been read to confirm exact scope/date" -- the task
named scope as the thing to verify, and a date was quoted instead. A dated
constraint inherited from a brief is a pointer to a source, not the source.
- 2026-09-29 priority: 'p2' -> 'p3'
- 2026-09-29 released by capacity-engine
