#!/usr/bin/env bash
# bt-5059: nothing in the fleet checked CSP DIRECTIVE STRENGTH on any live
# host -- the only existing CSP coverage was the REPORT-CONSUMER side
# (meniapp/scripts/csp-report-digest.sh and friends), which can only ever
# show what a browser decided to tell us about a policy already in force.
# A live-header sweep on 2026-10-12 found trips.omrihefez.com serving
# `script-src 'self' 'unsafe-inline' ...` on a login-gated surface holding
# live trip/money data, with no nonce -- nothing flagged it, a human read
# the header by hand. This script is the missing mechanism: it fetches the
# LIVE content-security-policy header per host and asserts the directive
# VALUES, the same "live header, not a config file" shape as
# check-permissions-policy.sh (bt-40c5/bt-5c8e) and check-cors-corp-
# consistency.sh, not the presence-only baseline in audit-domains.sh.
#
# HOST LIST: derived at runtime from ~/meni/DOMAIN.md via
# lib/domain-registry.sh's derive_registry_hosts(), mode "all" -- not a
# hand-maintained list (df-78db / bt-7f07: a hand-kept host list drifts from
# the registry, and silently, since nothing re-checks it). Non-Vercel hosts
# are included on purpose: house and oauth both send a live CSP header
# despite neither being on Vercel, measured 2026-10-12.
#
# WHAT IS CHECKED, per host, against the live header:
#   - script-src (falling back to default-src when script-src is absent,
#     per the browser's own CSP fallback rule) must not contain
#     'unsafe-inline' or 'unsafe-eval', and must not carry a bare
#     https:/http:/* wildcard origin.
#   - img-src (same default-src fallback) must not carry a bare
#     https:/http:/* wildcard origin.
#   - style-src (same fallback) must not carry 'unsafe-eval' or a bare
#     wildcard. style-src 'unsafe-inline' is NOT checked here -- see the
#     EXEMPT block below.
#   - object-src (same default-src fallback -- it IS a fetch directive, so
#     the browser applies the same inheritance rule) must contain 'none'.
#     bt-2c67: this is the gap that let four of six sampled hosts past the
#     monitor with no object-src at all, which falls back to whatever
#     default-src allows -- usually 'self', which still permits a same-
#     origin <object>/<embed>: a scriptable context a nonce-based
#     script-src never gates, because the nonce rule does not apply to it.
#   - base-uri and frame-ancestors have NO default-src fallback at all --
#     they are document/navigation directives, not fetch directives, so the
#     browser never inherits either from default-src -- so each is read
#     directly, and an ABSENT value is drift on its own rather than
#     something a strict default-src quietly covers.
#     frame-ancestors must contain 'none'.
#     base-uri must contain 'self' OR 'none' -- both close the <base>-tag
#     hijack ('none' is strictly stronger, since it refuses the tag
#     outright). Measured live 2026-10-12: oauth.omrihefez.com genuinely
#     ships `base-uri 'none'` (paired with `default-src 'none'`), which is a
#     safe, deliberate config, not drift -- a check that only accepted
#     'self' would flag a real host's stricter-than-required policy as a
#     finding, which is its own false-positive bug.
#   - a missing Content-Security-Policy header entirely is DRIFT, unless the
#     host is a declared NO_CSP_REASON exemption (an API/tunnel backend or a
#     by-design-404 auth wall that never serves an HTML page for a
#     script/img directive to apply to -- same class of exemption
#     audit-domains.sh's REQUIRED_HEADERS already draws around a 200-page
#     response, just named explicitly here instead of inferred from status
#     code, since this script never fetches a status code at all).
#
# A "bare wildcard" means the literal token `https:`, `http:` or `*` on its
# own -- NOT a real origin like `https://challenges.cloudflare.com`. The
# fleet's live img-src values genuinely contain that distinction side by
# side: trips and tik both carry a bare `https:` token (every image origin
# allowed) while every other host enumerates its actual image origins.
#
# EXEMPT: style-src 'unsafe-inline' is a DELIBERATE, ESTATE-WIDE exemption,
# not a per-host one. Measured 2026-10-12: 9 of the derived hosts send it
# (compose, kidai, meni, meniapp, oauth, planner, preview.meni, tik, trips)
# and it is effectively unavoidable with Next.js's inlined critical CSS --
# the framework emits a per-page <style> block with no nonce hook in the
# App Router today. Checking it would make this monitor permanently red on
# 9 of its hosts from day one, which is exactly how a monitor gets ignored
# (bt-5059 DONE WHEN #3). script-src is NOT given the same exemption: it
# governs code execution, not paint, and only one host (trips) carries
# 'unsafe-inline' there -- it is the live finding this script exists to
# catch, not the norm.
#
# CSP_HOSTS (space-separated bare labels, same override convention as
# check-permissions-policy.sh's PP_HOSTS / check-tunnel-liveness.sh's
# TUNNEL_HOSTS) replaces the registry derivation entirely, for a hermetic
# companion test. CURL_CMD is overridable for the same reason.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/domain-registry.sh
. "$HERE/lib/domain-registry.sh" || {
  echo "FATAL: cannot source lib/domain-registry.sh — refusing to run with no derived host list" >&2
  exit 2
}

# NO_CSP_REASON[bare-label] = why this host is allowed to send NO
# Content-Security-Policy header at all. Explicit and dated, same
# convention as VERCEL_CHECK_PATHS in audit-domains.sh -- a silent skip list
# would be exactly the kind of drift this task exists to stop.
declare -A NO_CSP_REASON=(
  [brain]="second-brain's auth_wall middleware answers a bare 404 to every unauthenticated request by design -- no HTML page is ever served for a script/img directive to protect, measured live 2026-10-12"
  [meniapp-api]="meni-hub API backend, JSON-only, no HTML page -- never serves a body a CSP header would apply to, measured live 2026-10-12"
  [tik-api]="TIK API backend, JSON-only, same as meniapp-api, measured live 2026-10-12"
  [tik-api-vps]="TIK API VPS cutover/rollback origin, JSON-only, same as meniapp-api, measured live 2026-10-12"
)

if [ -n "${CSP_HOSTS:-}" ]; then
  read -r -a HOSTS <<<"$CSP_HOSTS"
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

# extract_directive <csp> <name> -> prints <name>'s raw value (everything up
# to the next ';' or end of string), or nothing if <name> is absent.
# Anchored on a trailing space/tab so "script-src" never matches a prefix of
# a different directive like a hypothetical "script-src-elem".
extract_directive() {
  local csp="$1" name="$2"
  echo "$csp" | grep -oE "(^|;)[[:space:]]*${name}[[:space:]]+[^;]*" | sed -E "s/^(;)?[[:space:]]*${name}[[:space:]]+//" | head -1
}

# effective_directive <csp> <name> -> <name>'s own value if the directive is
# present, else default-src's value (the browser's own CSP fallback rule) --
# so a host that only sets default-src (oauth) isn't read as having no
# restriction at all on script-src/img-src/style-src.
effective_directive() {
  local csp="$1" name="$2" val
  val="$(extract_directive "$csp" "$name")"
  if [ -z "$val" ]; then
    val="$(extract_directive "$csp" "default-src")"
  fi
  printf '%s' "$val"
}

has_keyword() {
  case "$1" in
    *"'$2'"*) return 0 ;;
    *) return 1 ;;
  esac
}

has_bare_wildcard() {
  echo "$1" | grep -qE '(^|[[:space:]])(https:|http:|\*)([[:space:]]|$)'
}

FAIL=0
CHECKED=0

for h in "${HOSTS[@]}"; do
  host="$h.omrihefez.com"
  resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$host/")
  line=$(echo "$resp" | grep -i '^content-security-policy:' | head -1)

  if [ -z "$line" ]; then
    reason="${NO_CSP_REASON[$h]:-}"
    if [ -n "$reason" ]; then
      echo "OK     $host -> no Content-Security-Policy header, exempt: $reason"
    else
      echo "DRIFT  $host -> no Content-Security-Policy header sent" >&2
      FAIL=1
    fi
    continue
  fi

  csp="${line#*:}"
  csp="$(echo "$csp" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r$//')"
  CHECKED=$((CHECKED + 1))

  reasons=()

  script_src="$(effective_directive "$csp" "script-src")"
  has_keyword "$script_src" "unsafe-inline" && reasons+=("script-src has 'unsafe-inline'")
  has_keyword "$script_src" "unsafe-eval" && reasons+=("script-src has 'unsafe-eval'")
  has_bare_wildcard "$script_src" && reasons+=("script-src has a bare wildcard origin")

  img_src="$(effective_directive "$csp" "img-src")"
  has_bare_wildcard "$img_src" && reasons+=("img-src has a bare wildcard origin")

  style_src="$(effective_directive "$csp" "style-src")"
  has_keyword "$style_src" "unsafe-eval" && reasons+=("style-src has 'unsafe-eval'")
  has_bare_wildcard "$style_src" && reasons+=("style-src has a bare wildcard origin")
  # style-src 'unsafe-inline' deliberately NOT checked -- see EXEMPT comment above.

  object_src="$(effective_directive "$csp" "object-src")"
  has_keyword "$object_src" "none" || reasons+=("object-src missing 'none' (effective value: ${object_src:-<absent>})")

  # base-uri/frame-ancestors: NO default-src fallback, read directly (bt-2c67).
  base_uri="$(extract_directive "$csp" "base-uri")"
  if ! has_keyword "$base_uri" "self" && ! has_keyword "$base_uri" "none"; then
    reasons+=("base-uri missing 'self' or 'none' (value: ${base_uri:-<absent -- no fallback, any origin may set <base>>})")
  fi

  frame_ancestors="$(extract_directive "$csp" "frame-ancestors")"
  has_keyword "$frame_ancestors" "none" || reasons+=("frame-ancestors missing 'none' (value: ${frame_ancestors:-<absent -- no fallback, any origin may frame this page>})")

  if [ "${#reasons[@]}" -gt 0 ]; then
    joined="$(printf '%s; ' "${reasons[@]}")"
    joined="${joined%; }"
    echo "DRIFT  $host -> $joined -- csp: $csp" >&2
    FAIL=1
  else
    echo "OK     $host -> script-src/img-src/style-src/object-src/base-uri/frame-ancestors clean (style-src 'unsafe-inline' exempt)"
  fi
done

if [ "$FAIL" -eq 0 ]; then
  echo "check-csp-strength: $CHECKED CSP-sending host(s) all clean, out of ${#HOSTS[@]} derived"
  exit 0
fi
echo "check-csp-strength: at least one host has a weak CSP directive or sends no CSP at all" >&2
exit 1
