---
id: bt-6b06
title: Implement live Vertex AI model-resolution checking for second-brain's vision_*.py Gemini calls
status: open
priority: p3
tags:
  - observability
created: 2026-09-29
filed:
  owner: capacity-engine
  at: 2026-09-29T08:03:42Z
reported: 2026-09-29
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): needs a dedicated GCP service account with Vertex AI permissions on project meni-gmail-64683, wired via Infisical — confirmed no ADC or vault secret exists on this box today (vault-peek: GCP_SERVICE_ACCOUNT_JSON/VERTEX_SERVICE_ACCOUNT/SECOND_BRAIN_GCP_SA all MISSING)

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-2492, session `this-monitor-only-covers-f37035`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 5f379be).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
