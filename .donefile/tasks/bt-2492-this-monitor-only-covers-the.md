---
id: bt-2492
title: this monitor only covers the public generativelanguage.googleapis.com surface; second-brain's
  vision_*.py scripts call Vertex AI's Gemini surface (GCP SA auth, not an API key) and are not
  checked
status: done
priority: p3
tags:
  - observability
created: 2026-09-29
filed:
  owner: capacity-engine
  at: 2026-09-29T06:40:41Z
reported: 2026-09-29
done:
  at: 2026-09-29T07:56:22Z
  by: capacity-engine/worker
  waived: 5f379be is bt-5abe's own commit; it already introduced the SCOPE NOTE that resolves
    bt-2492's finding before bt-2492 was filed (bt-2492 was auto-filed FROM that same commit's own
    follow-up line) -- no separate commit exists because nothing needed to change
evidence:
  - type: commit
    value: 5f379be
    verified: 2026-09-29T07:56:22Z
  - type: test
    cmd: grep -q "second-brain's vision_\*.py scripts call Vertex AI" scripts/check-model-ids-resolve.sh
      && grep -q "Vertex-only name -- see this script's SCOPE NOTE"
      scripts/check-model-ids-resolve.sh && bash scripts/check-model-ids-resolve.test.sh
    exit: 0
    at: 2026-09-29T07:56:20Z
    log: evidence/bt-2492-2026-09-29T07-56-20Z-test.txt
    sha256: 0707b0a79e6436485e92aa2dbcf7b2351fd7e0b20c2b348f896764a45e1d6d5c
    bytes: 1651
  - type: note
    value: "Premise verified true (second-brain's Vertex-auth vision_*.py models genuinely aren't
      checked by this public-API monitor) but the actual harm cited -- a Vertex-only model
      false-DRIFTing and misleading a human into chasing the wrong repo -- was already fixed in the
      SAME original commit (5f379be, on origin/main before this follow-up task was even filed): the
      SCOPE NOTE documents the gap and the DRIFT line says 'or a Vertex-only name -- see this
      script's SCOPE NOTE'. Live-verified today: scoping to second-brain alone returns 'OK 3 model
      ID(s) resolve: gemini-2.5-flash gemini-2.5-flash-lite gemini-3.1-flash-lite' -- no live
      false-DRIFT occurring. Full active Vertex-side checking needs a dedicated GCP service account
      for project meni-gmail-64683, confirmed unavailable on this box (no ADC file, no matching
      vault secret) -- the 'separate GCP credential wiring, larger change' bt-5abe already flagged
      as future work; filed as follow-up rather than improvised without credentials to test
      against."
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): vision_sample_stratified.py:20 says gemini-3.1-flash-lite "only resolves via locations/global" — a Vertex-only model discovered by this monitor would false-DRIFT against the public API

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-5abe, session `no-monitor-anywhere-chec-5a1a68`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 5c4246c6f26f46d21211e936ab2716a4607f07f1).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-29 claimed by capacity-engine
- 2026-09-29 done by capacity-engine/worker — commit 5f379be, test `grep -q "second-brain's vision_\*.py scripts call Vertex AI" scripts/check-model-ids-resolve.sh && grep -q "Vertex-only name -- see this script's SCOPE NOTE" scripts/check-model-ids-resolve.sh && bash scripts/check-model-ids-resolve.test.sh` exit 0 (log: evidence/bt-2492-2026-09-29T07-56-20Z-test.txt) (evidence waived: 5f379be is bt-5abe's own commit; it already introduced the SCOPE NOTE that resolves bt-2492's finding before bt-2492 was filed (bt-2492 was auto-filed FROM that same commit's own follow-up line) -- no separate commit exists because nothing needed to change)
