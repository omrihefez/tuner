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
#
# COOP/CORP (bt-1176): same admission test as everything else in this file —
# measured live 2026-10-10, 7 of 9 Vercel hosts now send both
# Cross-Origin-Opener-Policy and Cross-Origin-Resource-Policy (bass, compose,
# meni, preview.meni, meniapp, kidai, tik — the last one only as of tkn-c2a6,
# which closed after this task was filed). That's the estate norm, so both
# join REQUIRED_HEADERS rather than getting a separate check. Checked for
# PRESENCE only, same as the other headers here — no value-level assertion.
# Remaining gap: trips (th-f5bc, open). planner is unaffected by this
# addition the same way it's unaffected by every other REQUIRED_HEADERS
# entry: it never serves a 200 page at its checked path, so the body-shaped
# baseline (this array) never applies to it.
REQUIRED_HEADERS=(x-frame-options x-content-type-options referrer-policy cross-origin-opener-policy cross-origin-resource-policy)

# PERMISSIONS-POLICY (bt-4164): added to the baseline on the same admission
# test bt-a2c2 set above — "what the siblings actually send, not an
# aspirational list". MEASURED LIVE 2026-10-01: 7 of 10 hosts now send it
# (bass, kidai, meniapp, planner, tik, trips, house); it is the estate norm.
# Checked for PRESENCE only, never an exact value — the seven senders
# legitimately disagree on the value itself (`microphone=(self)` on
# bass/meniapp because they use the mic, `geolocation=(self)` on trips,
# `interest-cohort=()` on kidai-only), so a single expected string would
# create false DRIFT on four compliant hosts. Per-host exact values are
# scripts/check-permissions-policy.sh's job, not this one.
#
# PERMISSIONS_POLICY_EXEMPT: the two hosts still measured absent today, each
# with the task that already tracks it and the date of this admission — a
# named, dated exemption, not a silent skip, so this baseline doesn't turn
# permanently red while those tasks are open. Remove the entry (not just
# flip it) once the sibling task lands and the host sends the header live;
# the host then falls through to the real check like everyone else.
declare -A PERMISSIONS_POLICY_EXEMPT=(
  [compose]="cp-8845 2026-10-01"
  [meni]="ar-3426 2026-10-01"
)
# arch-preview's entry removed here, not just left stale (bt-f55e): ar-1fde
# retired the host (vercel alias rm, 2026-10-09) and it now 404s by design,
# so it never reaches the 200 branch this map guards. See
# VERCEL_RETIRED_SKIP_REASON below for the exemption that actually applies
# to it now.

# missing_security_headers <raw response headers> <permissions-policy exemption, if any>
#   Prints a comma-separated list of missing baseline header names (empty if
#   none are missing). The second arg is the caller's
#   PERMISSIONS_POLICY_EXEMPT lookup result for this host (empty string =
#   not exempt) — kept out of this function's own host-lookup so it stays a
#   pure header-list check, same as before bt-4164.
missing_security_headers() {
  local resp="$1" pp_exempt="${2:-}" missing=()
  echo "$resp" | grep -qi '^content-security-policy:' \
    || echo "$resp" | grep -qi '^content-security-policy-report-only:' \
    || missing+=("content-security-policy")
  local h
  for h in "${REQUIRED_HEADERS[@]}"; do
    echo "$resp" | grep -qi "^${h}:" || missing+=("$h")
  done
  if [ -z "$pp_exempt" ]; then
    echo "$resp" | grep -qi '^permissions-policy:' || missing+=("permissions-policy")
  fi
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
# non-Vercel host" — the registry (~/meni/DOMAIN.md §1) has exactly one host
# whose CORRECT behaviour would misread as drift under this baseline:
# `brain` answers a bare 404 to every unauthenticated request by design
# (its auth wall).
#
# `oauth` (bt-0611, reviewed 2026-10-08): previously exempted on the same
# "no auth wall by design" reasoning as `brain`, which conflates "has no
# AUTH wall" with "serves no real app response" — those are not the same
# claim, and for `oauth` the second half is false.
# `smarthome/oauth-callback/server.py`'s `_html()` helper sets
# Content-Security-Policy / Referrer-Policy / X-Content-Type-Options on
# every response it renders, which is the host's own code disagreeing with
# the exemption that used to sit here. `/health` is its one documented,
# stable 200 (DOMAIN.md: "`/health` -> 200 `ok` is a liveness probe only"),
# so it moves into the opt-in list below like `tik-api`'s `/health` — the
# same class, not the `brain` class. (`/clips/<name>.mp3` is a second real
# response path on this host that bypasses `_html()` entirely and so ships
# no headers either, but it has no stable, registry-known path this script
# can pin without naming a specific clip file; tracked as a follow-up
# rather than guessed at here.)
#
# `tik-api`/`tik-api-vps` (bt-135b): assessed — both are the SAME FastAPI
# origin (tik-api-tunnel.service on the VPS answers both hostnames; the
# `-vps` name is the cutover/rollback pair for `tik-api`, not a separate
# app), a pure JSON API with no HTML page ever served (docs disabled in
# prod) and every route auth-gated except `/health`. That puts them in the
# SAME class as `meniapp-api`, not `brain`: nosniff still matters on
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
  [oauth]="/health"
)
declare -A NONVERCEL_HEADER_SKIP_REASON=(
  [brain]="by-design auth wall answers a bare 404 to every unauthenticated request; correct behaviour, not drift; reviewed bt-0611 2026-10-08 (oauth's identical-looking exemption did NOT hold up under the same review and was removed, so this one being a one-line reason is itself the decision, not an oversight)"
)

# STRICT-TRANSPORT-SECURITY (bt-b75b): the skip reason above is about BODY
# semantics (a 404 auth wall) — not a reason to also exempt HSTS, which is
# a transport-level header set (or not) regardless of what the body looks
# like. So the skip is narrowed rather than reused: `brain` stays OUT of
# NONVERCEL_CHECK_PATHS (its 404 body must never be scored against the
# CSP/XFO/nosniff/Cache-Control baseline meant for a real app response),
# but it still gets ONE unauthenticated path probed for HSTS alone, via
# check_hsts_at() below: `/`, its by-design 404, verified live 2026-08-23
# per DOMAIN.md. (`oauth` used to have an entry here too; bt-0611 moved it
# into NONVERCEL_CHECK_PATHS above instead, where it now gets the full
# baseline — including HSTS, via check_nonvercel_path() — rather than HSTS
# alone.)
declare -A NONVERCEL_HSTS_ONLY_PATH=(
  [brain]="/"
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
#   meni/trips/tik: "/" redirects (307) to /login, which serves a real 200
#     HTML page — checked there.
#   planner: "/" itself already returns 401 WITH the full header set (no
#     separate unauthenticated page exists to redirect to) — checked at "/"
#     again, this time through check_nonvercel_path()'s refusal-code branch
#     (Cache-Control: no-store + HSTS) rather than the bare root-level
#     check_hsts() every Vercel host already gets below.
#   arch-preview WAS here on this same 307->/login pattern, dropped by
#     bt-f55e (2026-10-10): ar-1fde retired the host (vercel alias rm,
#     2026-10-09) so "/" now answers 404, not 307 — see
#     VERCEL_RETIRED_SKIP_REASON below for the exemption that covers it now.
# A Vercel host that answers 307/308/401 with NO entry here is not silently
# OK — it fails loudly as UNPINNED instead (same idiom check-tunnel-
# liveness.sh uses for an unpinned non-Vercel host), so a new auth-gated
# Vercel host can't quietly repeat this gap.
declare -A VERCEL_CHECK_PATHS=(
  [meni]="/login"
  [trips]="/login"
  [tik]="/login"
  [planner]="/"
  # preview.meni is arch-preview's replacement and the real meni-arch staging
  # host (ar-111a). It took a DOMAIN.md §1 row on 2026-10-10 (ar-0058), having
  # had none since it went live, and the moment that row existed this audit
  # derived the host and reported UNPINNED — exit 1, so the 10 6 cron would
  # have gone red daily on an otherwise-correct registry fix. Pinned in the
  # same breath as the row. Same 307->/login shape as meni, which is not a
  # coincidence: it serves the same Next.js app, and its rpId is deliberately
  # pinned to meni.omrihefez.com (scripts/preview-passkey-env.ts) so Omri's
  # production passkey logs in here — the login page this baselines is a real
  # production auth surface, not a staging stub.
  [preview.meni]="/login"
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

# VERCEL_RETIRED_SKIP_REASON (bt-f55e): a host DOMAIN.md §1 still lists 🟢
# live — derive_registry_hosts() has no way to know otherwise, and that
# status lives in omrihefez/meni, which this repo may not commit to (same
# constraint the albumclub/apartments teardowns hit; those got fixed at the
# registry row instead, which this one cannot until a meni-side worker
# updates DOMAIN.md) — but that has been deliberately retired at the Vercel
# alias level and now 404s BY DESIGN, not by drift. Keyed and dated like the
# sibling exemption maps above. Only takes effect for a 404 response (see
# the SUBS loop below) — if the host ever serves anything else again,
# that's new, real signal and falls through to the ordinary CHECK branch
# rather than being swallowed by this exemption.
# Remove this entry once DOMAIN.md's own row moves off 🟢 live (then the
# host drops out of SUBS entirely and this map goes empty for it).
declare -A VERCEL_RETIRED_SKIP_REASON=(
  [arch-preview]="ar-1fde 2026-10-09: vercel alias rm retired this host (meni-arch's staging surface moved to preview.meni.omrihefez.com); now 404 by design"
)

# APEX_UNCLAIMED_SKIP_REASON (bt-820a): the apex has no Vercel project behind
# it at all — DOMAIN.md §1 row 23 🟠 blank, "404 DEPLOYMENT_NOT_FOUND — design
# in §6" — so there is no vercel.json/next.config/header array anywhere in
# this estate that could add includeSubDomains/preload to it. The
# max-age=63072000-only header check_apex_hsts() sees is Vercel's platform
# default for an unclaimed name, not a misconfiguration anyone here can fix,
# so asserting on it daily is noise, not signal (same reasoning as
# VERCEL_RETIRED_SKIP_REASON above, applied to "never claimed" instead of
# "claimed then retired"). Keyed and dated like the sibling exemption maps.
# Scoped to the EXACT measured signature (404 AND x-vercel-error:
# DEPLOYMENT_NOT_FOUND, checked at the call site below) so this stops
# applying the instant the apex serves anything else — a real 200 page per
# §6, or even a different 404 shape — which then falls through to the
# ordinary check_apex_hsts() assertion rather than being silently swallowed.
# Remove this entry once §6 ships and the apex serves a real page.
declare -A APEX_UNCLAIMED_SKIP_REASON=(
  [omrihefez.com]="bt-820a 2026-10-10: no Vercel project exists behind the apex (DOMAIN.md §1 row 23 🟠 blank, §6 design unbuilt); 404 DEPLOYMENT_NOT_FOUND is Vercel's platform default for an unclaimed name, not a configurable response"
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
#   preload is NOT asserted here (bt-e47e corrected the reasoning, not just
#   the behaviour): preload is not a per-host property to begin with.
#   hstspreload.org keys a submission on the REGISTRABLE DOMAIN alone —
#   qualifying requires includeSubDomains AND preload served AT THE APEX,
#   and the submission then covers the whole tree in one shot. A `preload`
#   token sent by a subdomain (kidai, meniapp, …) cannot add that host, or
#   anything, to the list; it is inert there regardless of which way it
#   goes, so there is no per-host human judgement being deferred by
#   skipping it — the judgement this comment used to describe doesn't
#   exist. The apex IS checked for `preload`, in check_apex_hsts() below,
#   because it is the one host where the directive is load-bearing and
#   submitting is a real, one-way decision (tracked as follow-up against
#   iac, not this audit's call to make silently).
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

# check_apex_hsts <label> <raw response headers> <status code>
#   Like check_hsts() above, but ALSO requires `preload` — the apex is the
#   one host where that directive is load-bearing (hstspreload.org keys
#   submission on the registrable domain: qualifying requires
#   includeSubDomains AND preload served at the apex, covering the whole
#   tree at once). A subdomain sending preload is inert either way (see
#   check_hsts()'s comment above), which is why that check never requires
#   it; the apex is the opposite case, so it gets its own, stricter check
#   rather than a flag threaded through the shared one — the apex is the
#   only call site that ever uses this (bt-e47e).
check_apex_hsts() {
  local label="$1" resp="$2" code="$3"
  check_hsts "$label" "$resp" "$code"

  local line value
  line=$(echo "$resp" | grep -i '^strict-transport-security:' | head -1)
  [ -n "$line" ] || return   # check_hsts() already reported the missing header

  value="${line#*:}"
  value="$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r$//')"
  if ! echo "$value" | grep -qi 'preload'; then
    echo "DRIFT  $label -> $code Strict-Transport-Security missing preload at the apex (bt-e47e: this is the one host where preload is load-bearing): $value"
    FAIL=1
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

# check_nonvercel_path <host incl. .omrihefez.com> <path> [vercel_pinned]
#   Fetches <host><path> and asserts the baseline appropriate to what came
#   back, updating the shared FAIL flag. Never touches missing_security_
#   headers()/REQUIRED_HEADERS — those stay scoped to the SUBS loop so its
#   existing behaviour and tests are untouched; its own inline
#   CSP/X-Frame-Options/Referrer-Policy/Permissions-Policy checks below are
#   the html-gated set for THIS loop, kept separate on purpose.
#
#   vercel_pinned (bt-1176): the third, optional arg. The SUBS loop's
#   307/308/401 branch routes a Vercel host through THIS function (via
#   VERCEL_CHECK_PATHS) to baseline its one real page — meni/login,
#   trips/login, tik/login, planner's own "/". Those hosts are part of the
#   same Vercel census that admitted COOP/CORP into REQUIRED_HEADERS above,
#   so they need the identical check — but the OTHER_LIVE loop also calls
#   this function (via NONVERCEL_CHECK_PATHS) for genuinely non-Vercel hosts
#   (house, oauth, tik-api, meniapp-api) that were never measured as part of
#   that census; house and oauth are confirmed NOT sending COOP/CORP live
#   today, and flagging them would be new, out-of-scope noise this task
#   never asked for. The flag is how one shared function serves both callers
#   without conflating them: non-empty only on the Vercel-loop call sites.
check_nonvercel_path() {
  local host="$1" path="$2" vercel_pinned="${3:-}"
  local resp code ctype label="$host$path"
  local pp_exempt="${PERMISSIONS_POLICY_EXEMPT[${host%.omrihefez.com}]:-}"
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
      if [ -n "$vercel_pinned" ]; then
        echo "$resp" | grep -qi '^cross-origin-opener-policy:' || missing+=("cross-origin-opener-policy")
        echo "$resp" | grep -qi '^cross-origin-resource-policy:' || missing+=("cross-origin-resource-policy")
      fi
      if echo "$resp" | grep -qi '^permissions-policy:'; then
        :
      elif [ -n "$pp_exempt" ]; then
        echo "SKIP   $label -> permissions-policy baseline not applicable: exempted per $pp_exempt (not a silent skip — tracked separately, bt-4164)"
      else
        missing+=("permissions-policy")
      fi
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
APEX_HOST=""
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
  # APEX (bt-e47e): the one row derive_registry_hosts() excludes BY
  # CONSTRUCTION — its name cell is dot-shaped, which that shared,
  # cross-repo-duplicated helper treats as "FQDN meant for a different
  # consumer", not a bare label to append .omrihefez.com onto (see that
  # file's own header). The apex needs the opposite treatment: it is the
  # one real, live host that IS legitimately dot-shaped, and it is the
  # only one, so rather than teach the shared helper a second exclusion
  # rule just for this row, pull it directly here. Not status-filtered
  # (🟢/🔵 only) like derive_registry_hosts() — the apex is audited
  # whatever its current registry status says, which is exactly how this
  # task found it still missing includeSubDomains/preload while sitting at
  # 🟠 blank.
  APEX_HOST="$(awk -F'|' '
    NF < 8 { next }
    { name = $2
      if (name !~ /`/) next
      if (!match(name, /`[^`]*`/)) next
      raw = substr(name, RSTART + 1, RLENGTH - 2)
      if (raw ~ /\./) { print raw; exit }
    }
  ' "$DOMAIN_MD")"
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
    pp_exempt="${PERMISSIONS_POLICY_EXEMPT[$d]:-}"
    missing="$(missing_security_headers "$resp" "$pp_exempt")"
    if [ -n "$pp_exempt" ] && ! echo "$resp" | grep -qi '^permissions-policy:'; then
      echo "SKIP   $host -> permissions-policy baseline not applicable: exempted per $pp_exempt (not a silent skip — tracked separately, bt-4164)"
    fi
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
        check_nonvercel_path "$host" "$vp" vercel
      done
    else
      echo "UNPINNED $host -> $code ${loc:+($loc)} registry lists this as live Vercel but no page is served at / and nobody pinned a VERCEL_CHECK_PATHS entry for it — add one" >&2
      FAIL=1
    fi
  elif [[ "$code" == "404" && -n "${VERCEL_RETIRED_SKIP_REASON[$d]:-}" ]]; then
    echo "SKIP   $host -> $code retired, not drift: ${VERCEL_RETIRED_SKIP_REASON[$d]}"
  else
    echo "CHECK  $host -> $code ${loc:+($loc)}"
    FAIL=1
    check_hsts "$host" "$resp" "$code"
  fi
done

# APEX (bt-e47e): not a member of SUBS/OTHER_LIVE — see where APEX_HOST is
# derived above for why — so it gets its own probe rather than being folded
# into either loop. Only present when the registry was actually read
# (AUDIT_SUBS overrides skip it entirely, same as every other DOMAIN.md
# derivation in this script).
if [ -n "$APEX_HOST" ]; then
  resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null --max-time 10 "https://$APEX_HOST/")
  code=$(echo "$resp" | head -1 | awk '{print $2}')
  if [[ "$code" == "404" ]] \
    && echo "$resp" | grep -qi '^x-vercel-error:[[:space:]]*DEPLOYMENT_NOT_FOUND' \
    && [ -n "${APEX_UNCLAIMED_SKIP_REASON[$APEX_HOST]:-}" ]; then
    echo "SKIP   $APEX_HOST -> $code apex unclaimed, not drift: ${APEX_UNCLAIMED_SKIP_REASON[$APEX_HOST]}"
  else
    check_apex_hsts "$APEX_HOST" "$resp" "$code"
  fi
fi

exit $FAIL
