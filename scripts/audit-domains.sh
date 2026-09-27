#!/usr/bin/env bash
# Audit real omrihefez.com app subdomains for the bt-417b class of drift:
# DNS/wildcard resolves to Vercel, but the domain was never added to any
# Vercel project -> Deployment Protection gates it, redirecting to
# vercel.com/login instead of serving the app.
#
# HOST LIST (ma-20c5): derived at RUNTIME from ~/meni/DOMAIN.md §1 via
# scripts/lib/domain-registry.sh, not a hand-copied array — the array
# previously drifted to 8 hosts against a registry of 11 live/alias rows,
# missing `meniapp` entirely (a real gap: it IS Vercel + live, so it should
# always have been checked here).
#
# Only §1 rows with Status 🟢 live / 🔵 alias AND Host containing "Vercel"
# enter the Deployment-Protection check below — that check is meaningless
# for a Cloudflare-Tunnel-fronted host (`meniapp-api`, `tik-api`: their
# normal `/` response is a bare 404, not a Vercel app page or a redirect;
# verified live 2026-08-18). Those are printed as an explicit SKIP line, not
# silently dropped — and because the split is derived from the registry's
# own Host column rather than a hardcoded exclusion list, a *new*
# non-Vercel live host is automatically SKIPped and named too, instead of
# either crashing this script or silently vanishing the way the old
# 8-vs-11 gap did.
#
# AUDIT_SUBS (space-separated bare labels, no .omrihefez.com suffix) skips
# the DOMAIN.md derivation entirely and checks exactly that list instead —
# same env-override convention as check-cert-expiry.sh's CERT_HOSTS. Used by
# audit-domains.test.sh and by scripts/test-monitoring.sh's bt-a942 self-test
# (which forces a failure by pointing this at a nonexistent host, in place
# of the old sed-patch against a literal `SUBS=` line this script no longer
# has).
#
# SECURITY-HEADER BASELINE (bt-a2c2): `resp` below already contains the full
# response header block for every host — this script used to fetch it and
# then look only at the status line, so a host with NO security headers at
# all (compose.omrihefez.com: no CSP, no X-Frame-Options, no
# X-Content-Type-Options, no Referrer-Policy, measured live 2026-09-10) went
# unnoticed while its seven siblings all set every one of these. The baseline
# below is what those seven siblings actually send, not an aspirational list:
#   - content-security-policy (report-only counts — `trips` enforces
#     report-only rather than blocking, and still meaningfully opted in)
#   - x-frame-options
#   - x-content-type-options
#   - referrer-policy
# Applied ONLY to a host that actually served a 200 page (REQUIRED_HEADERS
# check below). A 401 (`planner`) is exempt: an auth challenge has no page
# body for a header like X-Frame-Options to protect, and none of the sibling
# 401 responses carry any of these headers either — so a 401 with no security
# headers is the norm, not drift. A 307/308 redirect is exempt for the same
# reason one hop earlier: the browser will re-request and it is the eventual
# 200's headers that matter, not the redirect's. Missing headers on a 200 are
# reported as DRIFT (same severity/verb as the existing Deployment-Protection
# drift line above), not a separate category, because both mean "this host's
# posture silently diverged from its siblings."
REQUIRED_HEADERS=(x-frame-options x-content-type-options referrer-policy)

# missing_security_headers <raw response headers>
#   Prints a comma-separated list of missing baseline header names (empty if
#   none are missing).
missing_security_headers() {
  local resp="$1" missing=()
  echo "$resp" | grep -qi '^content-security-policy:' \
    || echo "$resp" | grep -qi '^content-security-policy-report-only:' \
    || missing+=("content-security-policy")
  local h
  for h in "${REQUIRED_HEADERS[@]}"; do
    echo "$resp" | grep -qi "^${h}:" || missing+=("$h")
  done
  local IFS=,
  echo "${missing[*]}"
}

# NON-VERCEL PER-(HOST,PATH) BASELINE (bt-d173).
#
# Layer this task's own log corrected: missing_security_headers() above is
# called from exactly ONE site, the SUBS (Vercel) loop below. The OTHER_LIVE
# loop's entire body used to be a single SKIP echo — no header check of any
# kind ever ran against a non-Vercel host. That is the real reason hc-d30f
# (house-control shipping zero security headers on its auth-redirect) had no
# cross-repo coverage from either direction: house-control's own tests assert
# no header, and this script — the one place that could have — was
# structurally out of scope for it. Root-only probing would ALSO have missed
# it even if in scope: house-control's `/` IS the 307 that (before the fix)
# skipped the headers, so a per-host check needs a per-PATH check too.
#
# NONVERCEL_CHECK_PATHS is a deliberate opt-in list, not "check every
# non-Vercel host" — the registry (~/meni/DOMAIN.md §1) has two hosts whose
# CORRECT behaviour would misread as drift under this baseline: `brain`
# answers a bare 404 to every unauthenticated request by design (its auth
# wall), and `oauth` is intentionally public with no auth wall at all.
#
# `tik-api`/`tik-api-vps` (bt-135b): assessed — both are the SAME FastAPI
# origin (tik-api-tunnel.service on the VPS answers both hostnames; the
# `-vps` name is the cutover/rollback pair for `tik-api`, not a separate
# app), a pure JSON API with no HTML page ever served (docs disabled in
# prod) and every route auth-gated except `/health`. That puts them in the
# SAME class as `meniapp-api`, not `brain`/`oauth`: nosniff still matters on
# a bare JSON body, so they get the per-path baseline rather than a
# by-design exemption. Root ("/") is a bare 404 with no baseline applicable
# (same as the check-domains layer above) so it is deliberately NOT in the
# path list — only `/health`, the one 200 either host ever serves
# unauthenticated. Confirmed live and fixed in the tik-api repo: nosniff was
# entirely absent before this task.
declare -A NONVERCEL_CHECK_PATHS=(
  [house]="/ /login"
  [meniapp-api]="/health"
  [tik-api]="/health"
  [tik-api-vps]="/health"
)
declare -A NONVERCEL_HEADER_SKIP_REASON=(
  [brain]="by-design auth wall answers a bare 404 to every unauthenticated request; correct behaviour, not drift"
  [oauth]="intentionally public with no auth wall by design; correct behaviour, not drift"
)

# is_refusal_or_redirect_code <status code>
#   401/403 (auth refusal) or 307/308 (auth redirect, e.g. house-control's
#   `/` -> `/login`): a body here is either absent or a refusal, so the
#   FRAMING/SNIFFING headers stay exempt (nothing to protect from framing —
#   same reasoning as the SUBS loop's 401/307/308 exemption above) but
#   Cache-Control: no-store is checked instead, because that exemption runs
#   BACKWARDS for cache headers: a cacheable refusal body can be replayed to
#   a different viewer or outlive the auth decision that produced it
#   (hc-d30f's sharper half) — the absence matters MORE on a refusal, not
#   less.
is_refusal_or_redirect_code() {
  case "$1" in
    401 | 403 | 307 | 308) return 0 ;;
    *) return 1 ;;
  esac
}

# check_nonvercel_path <host incl. .omrihefez.com> <path>
#   Fetches <host><path> and asserts the baseline appropriate to what came
#   back, updating the shared FAIL flag. Never touches missing_security_
#   headers()/REQUIRED_HEADERS — those stay scoped to the SUBS loop so its
#   existing behaviour and tests are untouched.
check_nonvercel_path() {
  local host="$1" path="$2"
  local resp code ctype label="$host$path"
  resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$host$path")
  code=$(echo "$resp" | head -1 | awk '{print $2}')
  ctype=$(echo "$resp" | grep -i '^content-type:' | head -1 | tr -d '\r')

  if is_refusal_or_redirect_code "$code"; then
    if echo "$resp" | grep -qi '^cache-control:.*no-store'; then
      echo "OK     $label -> $code (Cache-Control: no-store present on refusal/redirect)"
    else
      echo "DRIFT  $label -> $code missing Cache-Control: no-store on a refusal/redirect body (replayable/cacheable refusal, hc-d30f class)"
      FAIL=1
    fi
    return
  fi

  if [[ "$code" == "200" ]]; then
    local missing=()
    # nosniff protects against MIME-sniffing on ANY 200 body, JSON API
    # included — checked regardless of content-type.
    echo "$resp" | grep -qi '^x-content-type-options:' || missing+=("x-content-type-options")
    # CSP/X-Frame-Options/Referrer-Policy protect a DOCUMENT from being
    # framed/leaked on navigation — meaningless on a bare JSON API response,
    # so gated on an HTML content-type. Flagging them on e.g.
    # meniapp-api's /health would rebuild the noise problem bt-a2c2 was
    # careful to avoid: a real gap (no nosniff) buried under headers that
    # were never applicable there in the first place.
    if echo "$ctype" | grep -qi 'text/html'; then
      echo "$resp" | grep -qi '^content-security-policy:' \
        || echo "$resp" | grep -qi '^content-security-policy-report-only:' \
        || missing+=("content-security-policy")
      echo "$resp" | grep -qi '^x-frame-options:' || missing+=("x-frame-options")
      echo "$resp" | grep -qi '^referrer-policy:' || missing+=("referrer-policy")
    fi
    if [ "${#missing[@]}" -gt 0 ]; then
      local IFS=,
      echo "DRIFT  $label -> $code missing security headers: ${missing[*]}"
      FAIL=1
    else
      echo "OK     $label -> $code (security headers present)"
    fi
    return
  fi

  echo "CHECK  $label -> $code (unexpected status for a baselined non-Vercel path)"
  FAIL=1
}

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/domain-registry.sh
. "$HERE/lib/domain-registry.sh" || {
  echo "FATAL: cannot source lib/domain-registry.sh — refusing to run with no derived host list" >&2
  exit 2
}

OTHER_LIVE=()
if [ -n "${AUDIT_SUBS:-}" ]; then
  read -r -a SUBS <<<"$AUDIT_SUBS"
else
  DOMAIN_MD="${DOMAIN_MD:-$HOME/meni/DOMAIN.md}"
  [ -r "$DOMAIN_MD" ] || {
    echo "FATAL: cannot read $DOMAIN_MD — refusing to run an audit with no registry" >&2
    exit 2
  }
  mapfile -t SUBS < <(derive_registry_hosts "$DOMAIN_MD" vercel | sort -u)
  mapfile -t OTHER_LIVE < <(derive_registry_hosts "$DOMAIN_MD" non-vercel | sort -u)
fi

if [ "${#SUBS[@]}" -eq 0 ]; then
  echo "FATAL: derived zero Vercel-hosted live/alias subdomains — refusing to run an empty audit" >&2
  exit 2
fi

FAIL=0

for h in "${OTHER_LIVE[@]}"; do
  host="$h.omrihefez.com"
  if [ -n "${NONVERCEL_CHECK_PATHS[$h]:-}" ]; then
    echo "SKIP   $host -> live in the registry but not Vercel-hosted; Deployment-Protection drift does not apply (security-header baseline IS checked below, per path)"
    read -r -a paths <<<"${NONVERCEL_CHECK_PATHS[$h]}"
    for p in "${paths[@]}"; do
      check_nonvercel_path "$host" "$p"
    done
  else
    reason="${NONVERCEL_HEADER_SKIP_REASON[$h]:-security-header baseline not yet assessed for this host}"
    echo "SKIP   $host -> live in the registry but not Vercel-hosted; Deployment-Protection drift does not apply; security-header baseline also skipped: $reason"
  fi
done

for d in "${SUBS[@]}"; do
  host="$d.omrihefez.com"
  resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$host/")
  code=$(echo "$resp" | head -1 | awk '{print $2}')
  loc=$(echo "$resp" | grep -i '^location:' | tr -d '\r')

  if echo "$loc" | grep -qi 'vercel\.com'; then
    echo "DRIFT  $host -> $code $loc"
    FAIL=1
  elif [[ "$code" == "200" ]]; then
    missing="$(missing_security_headers "$resp")"
    if [ -n "$missing" ]; then
      echo "DRIFT  $host -> $code missing security headers: $missing"
      FAIL=1
    else
      echo "OK     $host -> $code (security headers present)"
    fi
  elif [[ "$code" == "307" || "$code" == "401" || "$code" == "308" ]]; then
    echo "OK     $host -> $code ${loc:+($loc)} (header baseline not applicable: no page served)"
  else
    echo "CHECK  $host -> $code ${loc:+($loc)}"
    FAIL=1
  fi
done

exit $FAIL
