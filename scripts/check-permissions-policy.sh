#!/usr/bin/env bash
# bt-40c5 (origin) / bt-5c8e (this version): bass.omrihefez.com calls
# getUserMedia (tuner.js:616) but sent no Permissions-Policy header, so the
# page inherited the browser default -- every policy-controlled feature
# (camera, geolocation, payment, USB, ...) allowed, not just the microphone
# this app actually uses. bt-40c5 fixed bass and this script asserted the
# exact value for bass ALONE, with the host picked via CHECK_HOST and the
# expected value a single hardcoded literal.
#
# bt-5c8e: that was a single-host check wearing an env var. Seven other
# registry hosts also send this header and only got presence-only coverage
# from audit-domains.sh (which says so in its own comment: "Per-host exact
# values are check-permissions-policy.sh's job, not this one"). A value
# WIDENED on any of those seven was invisible -- same "N of M" shape this
# estate has paid for repeatedly (check-gate-declarations.mjs 8/15 boards,
# gate-probe 8/15, derive_registry_hosts dropping hosts in bt-7f07).
#
# HOST LIST: derived at runtime from ~/meni/DOMAIN.md via
# lib/domain-registry.sh's derive_registry_hosts(), mode "all" -- NOT
# "vercel". The header is not Vercel-specific: oauth.omrihefez.com (a bare
# stdlib http.server behind a Cloudflare Tunnel, no app-level header code at
# all) sends the exact same baseline value as the Vercel hosts, measured
# live 2026-10-11. Filtering to Vercel-only would silently drop it the same
# way the old single-host shape dropped everyone but bass.
#
# PRESENCE is still someone else's job for an UNTRACKED host -- a host this
# script has no EXPECTED_PP entry for, and that does not send the header,
# is silently skipped (that is audit-domains.sh's REQUIRED_HEADERS baseline
# to enforce). But a host this script DOES track that stops sending the
# header, or a host that starts sending it with no entry recorded, is never
# silent:
#   - tracked + header absent      -> DRIFT (the control regressed)
#   - tracked + header present     -> OK or DRIFT (value match/mismatch)
#   - untracked + header present   -> UNPINNED (same idiom
#                                      check-tunnel-liveness.sh:94 and
#                                      audit-domains.sh:632 already use for
#                                      exactly this situation) -- a new
#                                      header-sending host must not get
#                                      silent presence-only coverage by
#                                      default.
#   - untracked + header absent    -> silent skip (not this script's job)
#
# Asserts the LIVE response header, not the presence of a string in
# vercel.json -- a header block can be present and still not reach the
# browser (wrong route glob, a later header block overriding it, a stale
# deploy). CURL_CMD is overridable so the companion test is hermetic; PP_HOSTS
# (space-separated bare labels, same override convention as
# check-tunnel-liveness.sh's TUNNEL_HOSTS / audit-domains.sh's AUDIT_SUBS)
# replaces the registry derivation entirely, for the same reason.
#
# The exact value matters more than presence: `microphone=()` (empty
# allowlist) would refuse getUserMedia on bass/meniapp/tuner and silently
# break them, so this checks the full value, not just that the header
# exists.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/domain-registry.sh
. "$HERE/lib/domain-registry.sh" || {
  echo "FATAL: cannot source lib/domain-registry.sh — refusing to run with no derived host list" >&2
  exit 2
}

# EXPECTED_PP[bare-label] = exact Permissions-Policy value. Measured live
# 2026-10-11. Each entry's trailing comment is the reason it differs from
# the estate baseline (camera=(), microphone=(), geolocation=()) where it
# does, so the next reader can tell a deliberate difference from drift
# (bt-5c8e DONE WHEN #3) -- a bare value with no comment here would be
# exactly as unreadable as the single literal this replaces.
declare -A EXPECTED_PP=(
  [bass]="camera=(), microphone=(self), geolocation=()"                              # tuner.js:616 calls getUserMedia
  [tuner]="camera=(), microphone=(self), geolocation=()"                             # 308-redirects to bass (bt-b806); same bass-tuner vercel.json headers block, same project
  [meniapp]="camera=(), microphone=(self), geolocation=()"                           # PWA voice-note capture (worker thread attachments) uses the mic
  [trips]="camera=(), microphone=(), geolocation=(self)"                             # trips-hub dashboard uses geolocation
  [kidai]="camera=(), microphone=(), geolocation=(), interest-cohort=()"             # extra directive opts out of FLoC/Topics; grants no feature
  [compose]="camera=(), microphone=(), geolocation=(), payment=(), usb=(), midi=()"  # explicit deny-list on top of the baseline; grants no feature
  [house]="camera=(), microphone=(), geolocation=()"                                 # estate baseline, grants nothing
  [meni]="camera=(), microphone=(), geolocation=()"                                  # estate baseline, grants nothing
  [preview.meni]="camera=(), microphone=(), geolocation=()"                          # staging alias of meni (ar-111a); same app, same baseline
  [planner]="camera=(), microphone=(), geolocation=()"                               # estate baseline, grants nothing
  [tik]="camera=(), microphone=(), geolocation=()"                                   # estate baseline, grants nothing
  [oauth]="camera=(), microphone=(), geolocation=()"                                 # estate baseline, grants nothing -- sent despite being a bare stdlib server with no app-level header code (Cloudflare Tunnel origin), measured live 2026-10-11
)

if [ -n "${PP_HOSTS:-}" ]; then
  read -r -a HOSTS <<<"$PP_HOSTS"
else
  DOMAIN_MD="${DOMAIN_MD:-$HOME/meni/DOMAIN.md}"
  [ -r "$DOMAIN_MD" ] || {
    echo "FATAL: cannot read $DOMAIN_MD — refusing to run with no registry" >&2
    exit 2
  }
  mapfile -t HOSTS < <(derive_registry_hosts "$DOMAIN_MD" all | sort -u)
fi

if [ "${#HOSTS[@]}" -eq 0 ]; then
  echo "FATAL: derived zero live/alias hosts — refusing to run an empty check" >&2
  exit 2
fi

FAIL=0
CHECKED=0

for h in "${HOSTS[@]}"; do
  host="$h.omrihefez.com"
  expected="${EXPECTED_PP[$h]:-}"
  resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$host/")
  line=$(echo "$resp" | grep -i '^permissions-policy:' | head -1)

  if [ -z "$line" ]; then
    if [ -n "$expected" ]; then
      echo "DRIFT  $host -> no Permissions-Policy header sent (expected: $expected)" >&2
      FAIL=1
    fi
    continue
  fi

  value="${line#*:}"
  value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r$//')"
  CHECKED=$((CHECKED + 1))

  if [ -z "$expected" ]; then
    echo "UNPINNED $host -> sends Permissions-Policy: $value but nobody recorded an expected value for it in this script — add EXPECTED_PP[$h]" >&2
    FAIL=1
    continue
  fi

  if [ "$value" != "$expected" ]; then
    echo "DRIFT  $host -> Permissions-Policy: $value (expected: $expected)" >&2
    FAIL=1
  else
    echo "OK     $host -> Permissions-Policy: $value"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "check-permissions-policy: $CHECKED header-sending host(s) all match their recorded value, out of ${#HOSTS[@]} derived"
  exit 0
fi
echo "check-permissions-policy: at least one host drifted or is sending an unrecorded Permissions-Policy value" >&2
exit 1
