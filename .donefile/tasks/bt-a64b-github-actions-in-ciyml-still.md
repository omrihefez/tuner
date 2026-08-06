---
id: bt-a64b
title: GitHub Actions in ci.yml still use mutable version tags instead of pinned SHAs
status: open
priority: p2
tags:
  - security
created: 2026-08-06
---

ce-f48b's SHA-pinning hardening reached most of the fleet but not this repo. .github/workflows/ci.yml line 30 uses actions/checkout@v4 and line 34 uses actions/setup-node@v4 - mutable tags a compromised or retagged upstream action would silently swap under CI, which runs with repo credentials. Verified 2026-08-06 by grepping every workflow in every board repo: meniapp, iac, donefile, second-brain, capacity-engine, meni-arch and tik-api's spark_sync and auto_fetch_report are all pinned to full 40-char SHAs with a trailing version comment. bass-tuner, vidsmith, tik-next and tik-api's test.yml are the four holdouts, each filed on its own board since each needs its own commit. Note this repo already does the harder half correctly - it sets fetch-depth 0 on the same checkout step - so only the ref needs pinning. DONE WHEN: both uses in ci.yml are pinned to a full commit SHA with a trailing version comment and one CI run passes on the pinned refs. Verify with a grep over .github/workflows showing zero remaining uses of an action at a bare tag, plus the passing run.
