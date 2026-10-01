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

# STRICT-TRANSPORT-SECURITY (bt-b75b): both skip reasons above are about
# BODY semantics (a 404 auth wall, a public-by-design page) — neither is a
# reason to also exempt HSTS, which is a transport-level header set (or not)
# regardless of what the body looks like. So the skip is narrowed rather
# than reused: `brain`/`oauth` stay OUT of NONVERCEL_CHECK_PATHS (their
# 404/public bodies must never be scored against the CSP/XFO/nosniff/
# Cache-Control baseline meant for a real app response), but each still
# gets ONE unauthenticated path probed for HSTS alone, via check_hsts_at()
# below. `brain`: `/` (its by-design 404, verified live 2026-08-23 per
# DOMAIN.md). `oauth`: `/health`, its one real 200 (DOMAIN.md: "`/health`
# -> 200 `ok` is a liveness probe only").
declare -A NONVERCEL_HSTS_ONLY_PATH=(
  [brain]="/"
  [oauth]="/health"
)

# VERCEL PER-PATH BASELINE (bt-3ba1): same shape and spirit as
# NONVERCEL_CHECK_PATHS above, but for the Vercel (SUBS) loop below. A
# 307/308 (auth redirect) or 401 (auth refusal) Vercel host serves no page at
# "/" — the SUBS loop used to treat that as reason to assert NOTHING at all,
# which is the exact root-only-probing mistake bt-d173 already rejected for
# the non-Vercel side (house-control's own "/" WAS the redirect that skipped
# its headers before that fix). This map pins ONE path per such host that
# actually serves a real response worth baselining, reusing
# check_nonvercel_path() — host-type-agnostic despite the name, it dispatches
# purely on status code/content-type — to run the same
# CSP/X-Frame-Options/nosniff/Referrer-Policy/Cache-Control/HSTS checks used
# on the non-Vercel side.
#   meni/arch-preview/trips/tik: "/" redirects (307) to /login, which serves
#     a real 200 HTML page — checked there.
#   planner: "/" itself already returns 401 WITH the full header set (no
#     separate unauthenticated page exists to redirect to) — checked at "/"
#     again, this time through check_nonvercel_path()'s refusal-code branch
#     (Cache-Control: no-store + HSTS) rather than the bare root-level
#     check_hsts() every Vercel host already gets below.
# A Vercel host that answers 307/308/401 with NO entry here is not silently
# OK — it fails loudly as UNPINNED instead (same idiom check-tunnel-
# liveness.sh uses for an unpinned non-Vercel host), so a new auth-gated
# Vercel host can't quietly repeat this gap.
declare -A VERCEL_CHECK_PATHS=(
  [meni]="/login"
  [arch-preview]="/login"
  [trips]="/login"
  [tik]="/login"
  [planner]="/"
)

# VERCEL_ALIAS_SKIP_REASON: the UNPINNED fallback above assumes a 307/308/401
# host has its OWN unauthenticated page sitting one hop away. `tuner` does
# not — DOMAIN.md §2 rule 3 has it 308-redirecting to `bass`'s own canonical
# registry row on a DIFFERENT host, which the SUBS loop already baselines in
# full under its own name. A VERCEL_CHECK_PATHS entry would just re-curl
# `tuner` and follow nothing (check_nonvercel_path() operates on one host, it
# does not follow a redirect to a different hostname), so this is a real,
# reviewed exemption, not a forgotten pin — named here by hand, same idiom as
# NONVERCEL_HEADER_SKIP_REASON above, rather than inferred from the redirect
# target at runtime. check_hsts() on the root response above still runs
# regardless — this only exempts the pinned-path BODY baseline.
declare -A VERCEL_ALIAS_SKIP_REASON=(
  [tuner]="308-redirects to bass (bass's own canonical registry row is baselined separately); DOMAIN.md §2 rule 3 alias, no separate page exists here"
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

# check_hsts <label> <raw response headers> <status code>
#   Asserts Strict-Transport-Security alone, as its OWN DRIFT/OK line,
#   independent of every other header check (bt-b75b). Deliberately NOT
#   folded into missing_security_headers()/the 200-branch `missing` array
#   below or the refusal/redirect Cache-Control check above: those are
#   gated on status code (200) or content-type (text/html) for reasons that
#   are real for CSP/X-Frame-Options/Referrer-Policy (nothing to frame or
#   leak on a bare JSON/401/404 body) but do NOT apply to HSTS — it is a
#   transport directive the browser must honour for the ORIGIN regardless
#   of what any single response's body or status is, so it is asserted on
#   every baselined call site unconditionally.
#
#   bt-8c53: presence alone used to be enough, so `max-age=0` — which
#   actively tells the browser to forget the pin — and a header missing
#   includeSubDomains both read as OK. Now the VALUE is asserted:
#     - max-age must parse and be >= 31536000 (one year). That floor is the
#       LOWEST value any live host sends today (bass/meni/house); two hosts
#       run 63072000 but that's not made the floor, since raising it later
#       is free while a host that needs to run lower would have to fight
#       this check to even deploy.
#     - includeSubDomains must be present.
#   preload is deliberately NOT asserted: six live hosts send it and three
#   don't, and adding it to a host is a one-way trip onto the browser
#   preload list — that's a call for a human to make per host, not a
#   default this audit should silently require or silently ignore.
check_hsts() {
  local label="$1" resp="$2" code="$3"
  local hsts_max_age_floor=31536000
  local line value max_age

  line=$(echo "$resp" | grep -i '^strict-transport-security:' | head -1)
  if [ -z "$line" ]; then
    echo "DRIFT  $label -> $code missing Strict-Transport-Security"
    FAIL=1
    return
  fi

  value="${line#*:}"
  value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r$//')"
  max_age=$(echo "$value" | grep -oi 'max-age=[0-9]*' | head -1 | cut -d= -f2)

  if [ -z "$max_age" ]; then
    echo "DRIFT  $label -> $code Strict-Transport-Security has no max-age: $value"
    FAIL=1
  elif [ "$max_age" -lt "$hsts_max_age_floor" ]; then
    echo "DRIFT  $label -> $code Strict-Transport-Security max-age=$max_age below floor $hsts_max_age_floor: $value"
    FAIL=1
  elif ! echo "$value" | grep -qi 'includesubdomains'; then
    echo "DRIFT  $label -> $code Strict-Transport-Security missing includeSubDomains: $value"
    FAIL=1
  else
    echo "OK     $label -> $code (Strict-Transport-Security: $value)"
  fi
}

# check_hsts_at <host incl. .omrihefez.com> <path>
#   Curls <host><path> for the sole purpose of feeding check_hsts() — used
#   for NONVERCEL_HSTS_ONLY_PATH hosts (bt-b75b) that are otherwise exempt
#   from the full non-Vercel baseline for reasons that don't apply to HSTS.
check_hsts_at() {
  local host="$1" path="$2"
  local resp code label="$host$path"
  resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$host$path")
  code=$(echo "$resp" | head -1 | awk '{print $2}')
  check_hsts "$label" "$resp" "$code"
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
    check_hsts "$label" "$resp" "$code"
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
    check_hsts "$label" "$resp" "$code"
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
    if [ -n "${NONVERCEL_HSTS_ONLY_PATH[$h]:-}" ]; then
      echo "SKIP   $host -> live in the registry but not Vercel-hosted; Deployment-Protection drift does not apply; body-shaped security-header baseline skipped: $reason (Strict-Transport-Security IS still checked below — transport-level, not body-shaped)"
      check_hsts_at "$host" "${NONVERCEL_HSTS_ONLY_PATH[$h]}"
    else
      echo "SKIP   $host -> live in the registry but not Vercel-hosted; Deployment-Protection drift does not apply; security-header baseline also skipped: $reason"
    fi
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
    check_hsts "$host" "$resp" "$code"
  elif [[ "$code" == "200" ]]; then
    missing="$(missing_security_headers "$resp")"
    if [ -n "$missing" ]; then
      echo "DRIFT  $host -> $code missing security headers: $missing"
      FAIL=1
    else
      echo "OK     $host -> $code (security headers present)"
    fi
    check_hsts "$host" "$resp" "$code"
  elif [[ "$code" == "307" || "$code" == "401" || "$code" == "308" ]]; then
    echo "OK     $host -> $code ${loc:+($loc)} (header baseline not applicable at /: no page served)"
    check_hsts "$host" "$resp" "$code"
    if [ -n "${VERCEL_ALIAS_SKIP_REASON[$d]:-}" ]; then
      echo "SKIP   $host -> pinned-path baseline not applicable: ${VERCEL_ALIAS_SKIP_REASON[$d]}"
    elif [ -n "${VERCEL_CHECK_PATHS[$d]:-}" ]; then
      read -r -a vpaths <<<"${VERCEL_CHECK_PATHS[$d]}"
      for vp in "${vpaths[@]}"; do
        check_nonvercel_path "$host" "$vp"
      done
    else
      echo "UNPINNED $host -> $code ${loc:+($loc)} registry lists this as live Vercel but no page is served at / and nobody pinned a VERCEL_CHECK_PATHS entry for it — add one" >&2
      FAIL=1
    fi
  else
    echo "CHECK  $host -> $code ${loc:+($loc)}"
    FAIL=1
    check_hsts "$host" "$resp" "$code"
  fi
done

exit $FAIL
