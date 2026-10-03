---
id: bt-188e
title: Add CSP violation reporting (report-uri/report-to)
status: open
priority: p3
tags:
  - security
  - http-headers
  - observability
created: 2026-10-03
filed:
  owner: capacity-engine/worker
  at: 2026-10-03T01:19:58Z
---

Fleet scan (kd-506a, 2026-10-02) found bass-tuner's CSP ships with no report-uri/report-to, so a blocked script is invisible. Filed per kd-c97e (mis-filed on kidai's board; moving the finding here per the repo-ownership rule).
