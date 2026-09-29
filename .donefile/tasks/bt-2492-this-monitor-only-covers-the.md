---
id: bt-2492
title: this monitor only covers the public generativelanguage.googleapis.com surface; second-brain's
  vision_*.py scripts call Vertex AI's Gemini surface (GCP SA auth, not an API key) and are not
  checked
status: open
priority: p3
tags:
  - observability
created: 2026-09-29
filed:
  owner: capacity-engine
  at: 2026-09-29T06:40:41Z
reported: 2026-09-29
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): vision_sample_stratified.py:20 says gemini-3.1-flash-lite "only resolves via locations/global" — a Vertex-only model discovered by this monitor would false-DRIFT against the public API

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-5abe, session `no-monitor-anywhere-chec-5a1a68`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 5c4246c6f26f46d21211e936ab2716a4607f07f1).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
