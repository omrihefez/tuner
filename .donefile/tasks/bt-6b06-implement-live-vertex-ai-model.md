---
id: bt-6b06
title: Implement live Vertex AI model-resolution checking for second-brain's vision_*.py Gemini calls
status: done
priority: p3
tags:
  - observability
created: 2026-09-29
filed:
  owner: capacity-engine
  at: 2026-09-29T08:03:42Z
reported: 2026-09-29
done:
  at: 2026-09-29T08:33:30Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 640b57e069c75ad08fcd32e6d24d472815064476
    repo: second-brain
    verified: 2026-09-29T08:33:30Z
  - type: test
    cmd: .venv/bin/python -m pytest tests/test_vision.py tests/test_vision_full_run_script.py
      tests/test_vision_full_extract_script.py tests/test_vision_sample_script.py
      tests/test_vision_sample_stratified_script.py -q
    exit: 0
    at: 2026-09-29T08:33:21Z
    expect: passed
    log: evidence/bt-6b06-2026-09-29T08-33-21Z-test.txt
    sha256: bfc59a6ec6c354737634400e054c904a71347a2b2c0793863622432dba33c4b3
    bytes: 312
  - type: note
    value: "Implemented VertexVision.check_model_resolves() (free models.get() lookup, no billed tokens)
      and wired it into all four vision_*.py entrypoints as a preflight before any batch starts. New
      unit tests (test_check_model_resolves_passes_when_get_succeeds /
      test_check_model_resolves_raises_clear_error_on_404) proven to FAIL on the parent commit
      (478e4dd, AttributeError: no check_model_resolves) and PASS on this one. Genuine LIVE
      verification against real Vertex AI is NOT possible on this box today: bash
      scripts/check_vertex_access.sh (in second-brain) confirms exit 1, 'no usable Vertex AI
      credential found for meni-gmail-64683' -- this is the SAME already-diagnosed, already-gated
      credential gap as sb-ef52 (blocked since 2026-08-26, gate_owner omri: the vaulted
      iac-terraform SA lacks aiplatform.endpoints.predict and cannot self-grant IAM roles). Not
      re-escalating a duplicate gate for bt-6b06 -- the code is complete and unit-tested; live
      exercise against production Vertex will happen the moment sb-ef52's own gate clears. Also:
      this task was auto-filed on bass-tuner's board but its deliverable is entirely in second-brain
      (which has its own sb- board) -- added a second-brain repo alias to bass-tuner's
      .donefile/config.yml (commit 7689244) to resolve cross-repo evidence, matching the existing
      compose/meni/donefile alias pattern."
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): needs a dedicated GCP service account with Vertex AI permissions on project meni-gmail-64683, wired via Infisical — confirmed no ADC or vault secret exists on this box today (vault-peek: GCP_SERVICE_ACCOUNT_JSON/VERTEX_SERVICE_ACCOUNT/SECOND_BRAIN_GCP_SA all MISSING)

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-2492, session `this-monitor-only-covers-f37035`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 5f379be).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-29 blocker bt-2492 closed 2026-09-29T07:56:22Z — recheck whether this can proceed now.
- 2026-09-29 claimed by capacity-engine
- 2026-09-29 done by capacity-engine/worker — commit 640b57e069c7 (second-brain), test `.venv/bin/python -m pytest tests/test_vision.py tests/test_vision_full_run_script.py tests/test_vision_full_extract_script.py tests/test_vision_sample_script.py tests/test_vision_sample_stratified_script.py -q` exit 0 (--test-expect "passed") (log: evidence/bt-6b06-2026-09-29T08-33-21Z-test.txt)
