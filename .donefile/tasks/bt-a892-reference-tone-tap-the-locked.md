---
id: bt-a892
title: "Reference tone: tap the locked string to hear its target pitch (Web Audio osc)"
status: done
priority: p2
tags:
  - feature
created: 2026-07-02
done:
  at: 2026-07-06T06:35:56Z
  by: meni-autoworker
evidence:
  - type: commit
    value: 0c9342d
    verified: 2026-07-06T06:35:56Z
---

playReferenceTone() creates a sine-wave oscillator at the target frequency
(1.2s exponential fade). Tap inactive string → lock + play. Tap locked string
→ play again (stay locked). "Auto" inline button releases lock. SW cache
bumped v7→v8. Deployed to Vercel.

## Log
- 2026-07-31 dn-f920: this board's pre-commit hook was running a pre-dn-7615 template, so three suppressions for this task (BAD_TIMESTAMP/DEGRADED/NO_EVIDENCE) outlived their findings in audit-baseline.txt; the reinstalled hook prunes them on this commit
