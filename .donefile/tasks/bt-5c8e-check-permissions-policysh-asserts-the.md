---
id: bt-5c8e
title: check-permissions-policy.sh asserts the exact header value for bass only, so a widened
  Permissions-Policy on the other seven senders is invisible
status: open
priority: p3
tags:
  - monitoring
  - http-headers
created: 2026-10-11
filed:
  owner: meni-worker/board-refill-work-discov-d8813b
  at: 2026-10-11T15:15:59Z
---

`scripts/check-permissions-policy.sh` is the estate's only value-level Permissions-Policy
assertion, and it is hardcoded to one host. Seven other hosts send the header and get presence-only
coverage, so a weakened value on any of them is invisible.

Found by the periodic discovery sweep, 2026-10-11.

## The split, measured

`scripts/check-permissions-policy.sh:17-18`:

    HOST="${CHECK_HOST:-bass.omrihefez.com}"
    EXPECTED="camera=(), microphone=(self), geolocation=()"

One host, one literal expected string. `CHECK_HOST` is overridable, but `EXPECTED` is not — so
pointing it at another host makes it fail by construction, because the other hosts legitimately
send different values. It is a single-host check wearing an env var.

`scripts/audit-domains.sh:110-112` is what covers everyone else, and it tests PRESENCE only:

    if [ -z "$pp_exempt" ]; then
      echo "$resp" | grep -qi '^permissions-policy:' || missing+=("permissions-policy")
    fi

That file says so in as many words at lines 72-77 — "Checked for PRESENCE only, never an exact
value ... Per-host exact values are scripts/check-permissions-policy.sh's job, not this one."
Which is correct about the division of labour and wrong about the coverage: that job is being done
for one host out of eight.

## What the eight actually send, probed 2026-10-11 ~18:06-18:10 IDT

    bass        camera=(), microphone=(self), geolocation=()                          [value-checked]
    meniapp     camera=(), microphone=(self), geolocation=()                          [presence only]
    kidai       camera=(), microphone=(), geolocation=(), interest-cohort=()          [presence only]
    trips       camera=(), microphone=(), geolocation=(self)                          [presence only]
    planner     camera=(), microphone=(), geolocation=()                              [presence only]
    meni        camera=(), microphone=(), geolocation=()                              [presence only]
    preview.meni camera=(), microphone=(), geolocation=()                             [presence only]
    compose     camera=(), microphone=(), geolocation=(), payment=(), usb=(), midi=() [presence only]

## Why presence is not enough, by the sibling script's own argument

`check-permissions-policy.sh:12-14` already makes the case and confines it to bass:

> The exact value matters more than presence: `microphone=()` (empty allowlist) would refuse
> getUserMedia in the page itself and silently break the tuner, so this checks the full value,
> not just that the header exists.

The inverse is the security direction and applies to the other seven: a value that WIDENS — a
directive dropped, or an `=()` loosened to `=*` or `=(self)` — keeps the header present and passes
every check in the estate. `meniapp` already carries `microphone=(self)` legitimately, so the
fleet has no uniform expected string to fall back on; the per-host values have to be recorded
somewhere for a comparison to exist at all.

This is the same "hardcoded N of M" shape this fleet has paid for repeatedly on adjacent files:
ce-3ee1 (check-gate-declarations.mjs, 8 of 15 boards), ce-a7f8 / ce-ca53 (gate-probe, 8 of 15),
bt-7f07 (derive_registry_hosts silently dropping hosts). In each case the check looked healthy
because the hosts it could not see produced output identical to hosts with nothing wrong.

## DONE WHEN

1. Every host that currently sends a Permissions-Policy has its exact expected value recorded and
   asserted. Prefer extending `check-permissions-policy.sh` to a host->expected map over writing
   a second script, so there stays ONE place that owns per-host values.
2. A host that sends the header but has no recorded expected value FAILS LOUDLY as unpinned —
   the `UNPINNED` idiom `audit-domains.sh:593` already uses for exactly this situation — rather
   than being skipped. A new live host must not get silent presence-only coverage by default.
3. Each recorded value carries the reason it differs where it does (bass and meniapp need the
   microphone; trips needs geolocation; kidai's `interest-cohort`; compose's payment/usb/midi), so
   the next reader can tell a deliberate difference from drift. That is what makes a mismatch
   actionable instead of noise.
4. The derivation of WHICH hosts to check comes from `~/meni/DOMAIN.md` via
   `derive_registry_hosts`, not a second hand-maintained list beside the registry — the drift
   `bt-7f07` and `df-78db` both exist to stop.
5. Tests: a stubbed response per host asserting a correct value passes, a widened value
   (`geolocation=*`) FAILS, and an unrecorded header-sending host reports UNPINNED. Demonstrate
   the widened-value case red against the parent commit.

## Evidence

    cd /home/omri/projects/bass-tuner && bash scripts/check-permissions-policy.test.sh
    cd /home/omri/projects/bass-tuner && bash scripts/check-permissions-policy.sh

The first must fail on the parent commit for the widened-value fixture; say so in the closing
note. A grep for a host name in the new map is not evidence of coverage — assert on a response,
not on the config.

## Note on scope

p3 deliberately. Nothing is currently wrong with any of the eight values — all were probed above
and all are sane. This is the absence of a control, not a live hole, and it should not be
priced as one. It becomes a real exposure the first time one of these apps starts using a gated
feature and loosens its own policy to do it.
