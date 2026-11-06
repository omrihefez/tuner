---
id: bt-c532
title: Move remaining GitHub-hosted (ubuntu-latest) workflows to [self-hosted, meni-vps] fleet-wide
  to stay inside free minutes — bass-tuner
status: open
priority: p1
tags:
  - ci
  - infra
  - fleet-gate
created: 2026-11-06
filed:
  owner: capacity-engine
  at: 2026-11-06T09:57:03Z
reported: 2026-11-06
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): 17 runs-on: ubuntu-latest remain (meniapp visual-check/external-probe/ci-app/ci-hub/ci-plugin/dependency-audit, donefile test+audit, capacity-engine test+ci-health-watch, tik-api x4, bass-tuner, apartment-planner, zn-tournaments, meni-arch, pete); trips-hub is already 100% self-hosted

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working th-1dc1, session `trips-hub-ci-not-startin-9c39c7`, dispatched on trips-hub.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on meni-arch, tik-api, donefile, meniapp, capacity-engine, apartment-planner (ce-71de). Scope this task to the part that is actually about trips-hub; the siblings cover the rest.
That task's report closed BLOCKED.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
