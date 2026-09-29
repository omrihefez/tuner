---
id: bt-5abe
title: No monitor anywhere checks that a hardcoded AI model ID still resolves — four repos carried
  live gemini-2.5 strings past a 2026-10-20 cutoff for seven weeks with nothing watching
status: open
priority: p2
tags:
  - observability
  - monitoring
created: 2026-09-29
filed:
  owner: meni-worker/board-refill-work-discov-7a770f
  at: 2026-09-29T05:39:25Z
---

Nothing in the fleet asserts that a hardcoded AI model ID still resolves. Swept 2026-09-29 across meniapp/scripts, iac/scripts, bass-tuner/scripts, kidai/src and second-brain/scripts: no script calls the `v1beta/models` list endpoint, and no test or monitor anywhere checks a configured model ID against the provider. So a model retirement is invisible until a user-visible failure.

This is being filed here because `scripts/` is where the fleet's cross-repo monitors already live (audit-domains.sh, check-fallback-cert.sh, check-permissions-policy.sh, check-tunnel-liveness.sh, check-monitor-heartbeats.sh), not because the defect is bass-tuner's own code.

WHY NOW, AND WHY IT IS NOT JUST ABOUT ONE DEADLINE. Google's notice "[Action Required] Migrate Gemini 2.5 traffic before Oct 20, 2026" is 21 days from filing, and this sweep found live `gemini-2.5-*` strings in FOUR repos that no task had ever covered — now kd-3d2b (kidai), ma-50ae (meniapp), mm-1a93 (meni-music), iac-7254 (iac). The 2026-08-05 pass caught only two repos (vs-d3ef vidsmith, sb-bda7 second-brain) because it worked from df-a928, which scoped `~/meni/bin/*` alone. Four repos were missed for seven weeks by a hand-maintained list, which is the standing failure mode a monitor exists to replace. The point of this task is that the NEXT sunset does not need a lucky sweep — and there will be one, since several of these strings are now pointed at `gemini-3-flash-preview`, a preview ID with the same fate ahead of it.

DONE WHEN a monitor exists that:
1. DISCOVERS the model IDs rather than carrying its own copy of the list. A hardcoded list in the monitor reproduces exactly the drift that caused this — it would need editing every time a repo changes a model, and nothing would tell you it had gone stale. Grep the registered repos for the provider's model-ID shape and check what you find. (The same reasoning is already recorded in `_sunset_repos_note`'s compose entry about hand-maintained numbers, and in check-cert-expiry.sh / audit-domains.sh deriving their host lists from DOMAIN.md rather than restating them.)
2. Asserts each discovered ID RESOLVES against the provider — a live call, not a string comparison against a list of known-good names. `check-permissions-policy.sh:7-14` is the shape to copy and says why in its own header: assert the live response, not the presence of a string in a config file, and check the VALUE not just presence.
3. Is hermetically testable, with a `<name>.test.sh` companion like every other monitor here. `check-permissions-policy.sh` makes `CURL_CMD` overridable for exactly this; do the same so the test needs no API key and no network.
4. Runs under `scripts/run-monitor.sh <name> <script>` so a failure reaches the morning brief through the existing latch, and is installed by `install-monitoring-crons.sh`. Read run-monitor.sh:2-25 first — it already handles the "a silent monitor is a broken monitor" problem and the persistent-failure latch, so do not re-invent either.
5. FAILS CLOSED and distinguishes cannot-run from fail. An unset or invalid API key must not read as "all models resolve". This is the specific trap that iac-7254 was filed for and that iac-da6a's block reason was rewritten to fix; both are in-repo precedent worth reading before writing the exit-code logic.

EVIDENCE REQUIRED: the monitor must be SEEN RED. Point it at a model ID that does not exist and confirm it alerts; point it at a valid one and confirm it clears. Paste both runs. A monitor only ever observed passing is indistinguishable from one that cannot fire — and that is not hypothetical here: bt-b130 and the `renew-wildcard-cert.sh` history in run-monitor.sh:5-8 are both cases on this exact board where a check ran green while the thing it watched was broken.
