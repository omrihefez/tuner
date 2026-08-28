---
id: bt-31a9
title: bass-tuner's 10 cron jobs run scripts out of an unsynced checkout — same silent-stale shape
  fixed in house-control, donefile and tik-api tonight
status: claimed
priority: p2
tags:
  - infra
  - cron
created: 2026-08-28
claim:
  owner: capacity-engine
  at: 2026-08-28T04:30:15Z
---

Generalising a pattern that three separate workers hit independently on 2026-08-27/28.

THE SHAPE: a repo's cron jobs execute scripts straight out of /home/omri/projects/<repo>,
and nothing fast-forwards that checkout. Work lands on origin, the checkout stays behind,
and the cron keeps running yesterday's code — silently, because the job succeeds. Every
health signal reads green; only the OUTPUT is stale.

FIXED TONIGHT, three repos, all the same fix (a dedicated */3min ff-only sync that never
forces and alerts on genuine divergence): house-control hc-498b, donefile dn-05e3,
tik-api tk-66aa. meniapp already had one.

WHY IT MATTERS RATHER THAN BEING TIDINESS: house-control's 2-hourly music build runs from
its checkout, so on 2026-08-27 every playlist fix shipped for Omri reached his Spotify ONLY
because a worker noticed the checkout was behind and pulled by hand. Without that, he would
have been told his playlists were fixed while the builder kept running the old selector.
That is the exact failure he was angry about that evening: a truthful "shipped" that never
became "live".

BASS-TUNER IS THE LARGEST REMAINING INSTANCE: 10 cron entries, all invoking
scripts/run-monitor.sh out of the checkout, and no ff-sync. It happens to be at 0 behind
origin right now, which is why nothing has broken — that is luck, not a mechanism.

ALSO UNCOVERED, smaller: trips-hub (2 entries), second-brain (2), iac (2), tik-next (1).
capacity-engine is NOT affected — it deploys from a git-archive export rebuilt at tick
start, so it self-syncs by construction. Check each rather than assuming: a repo whose cron
only touches data, or which re-clones, does not need this.

DONE WHEN: bass-tuner has the same */3min ff-sync the other four have, and the remaining
repos above are each either covered or explicitly recorded as not needing it. Copy the
pattern rather than reinventing it — tk-66aa verified three behaviours on a scratch clone
before shipping (in-sync no-op, clean fast-forward, refusal with unchanged HEAD on genuine
divergence), which is the bar.

## Log
- 2026-08-28 claimed by capacity-engine
- 2026-08-28 released by capacity-engine
- 2026-08-28 claimed by capacity-engine
- 2026-08-28 trips-hub investigated: all its cron consumers (backflow, deploy-watchdog, dev-alias-heal, bookkeeping-secret-scan, alias-drift) already maintain their OWN private mirror clones / fetch origin fresh each run (RUNNER_DIR pattern, e.g. th-8d62/ma-a1f5/th-7649) rather than reading the shared /home/omri/projects/trips-hub checkout — same self-syncing shape as capacity-engine's git-archive export. No ff-sync needed there; explicitly recorded.
