#!/usr/bin/env bash
# Regression test for scripts/audit-domains.sh (ma-20c5, bt-a2c2, bt-d173).
# Asserts the SUBS array cannot silently drift from ~/meni/DOMAIN.md again —
# the array had fallen to 8 hosts against a registry of 11 live/alias rows,
# missing `meniapp` (a real Vercel+live gap) and (correctly, but silently)
# omitting the two Cloudflare-Tunnel hosts `meniapp-api`/`tik-api`. Hermetic
# — no real ~/meni/DOMAIN.md, no network (CURL_CMD stub).
#
# bt-d173 added the second half: OTHER_LIVE (non-Vercel) hosts used to be a
# single SKIP echo with no header check of any kind behind it — the real
# reason hc-d30f (house-control shipping zero security headers on its
# auth-redirect) had no cross-repo coverage. NONVERCEL_CHECK_PATHS/
# NONVERCEL_HEADER_SKIP_REASON in audit-domains.sh are hardcoded to the real
# registry labels (`house`, `meniapp-api`, and — since bt-135b assessed them
# — `tik-api`/`tik-api-vps` all checked; `brain`/`oauth` explicitly exempt by
# design; anything else still defaults to "not yet assessed", exercised in
# test 13b below with a synthetic stand-in since no real host is left
# unclassified), so the fixtures below otherwise use those exact bare
# labels rather than test-only stand-ins.
#
# bt-b75b added Strict-Transport-Security, checked unconditionally on every
# baselined non-Vercel call (check_hsts(), inside check_nonvercel_path() —
# not gated on 200 or on text/html, because HSTS is a transport directive,
# not a document protection). `brain`/`oauth` are still exempt from the
# BODY-shaped baseline (CSP/XFO/referrer-policy/nosniff/Cache-Control) for
# the reasons already stated, but that exemption no longer covers HSTS: each
# now gets exactly one path curled via check_hsts_at() (NONVERCEL_HSTS_ONLY_PATH)
# for HSTS alone. FULL_HEADERS below carries a Strict-Transport-Security
# value so tests 1-8 and the "good" fixtures in 9-13 (which are about other
# headers) don't spuriously go DRIFT; tests 14/15 exercise the HSTS check
# itself failing-then-passing.
#
# bt-3ba1 closed the matching gap on the Vercel (SUBS) side: that loop never
# called check_hsts() at all, and a 307/308/401 Vercel host (no page served
# at "/") was asserted on nothing whatsoever. check_hsts() is now called
# unconditionally for every SUBS host (tests 18/19 below), and
# VERCEL_CHECK_PATHS pins a real page to probe on the five 307/401 hosts
# measured live (tests 20/21), with an UNPINNED failure (test 22) for any
# Vercel host that answers 307/308/401 with no pinned path — the SUBS-side
# mirror of check-tunnel-liveness.sh's UNPINNED idiom. The shared FIXTURE
# registry's old `authed` stand-in is renamed `planner` (a real registry
# label, now pinned at "/") so tests 1/4/7/8 exercise the real
# VERCEL_CHECK_PATHS entry rather than a path the script can never actually
# see.
#
# bt-4164 added Permissions-Policy to the baseline (7 of 10 live hosts send
# it as of 2026-10-01). FULL_HEADERS below now carries one so every existing
# "full baseline" fixture (tests 1-23) stays OK rather than spuriously
# DRIFTing on the new header — tests 27/28 exercise the check itself
# failing-then-passing, and tests 29/30 exercise the PERMISSIONS_POLICY_EXEMPT
# carve-out for the two hosts (compose/cp-8845, meni+arch-preview/ar-3426)
# still measured absent, on both the SUBS-loop and check_nonvercel_path sides.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/audit-domains.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/DOMAIN.md"
FIXTURE_MAP="$TMP/responses.tsv"   # host<TAB>path<TAB>code<TAB>location<TAB>extra-headers (| separated "name: value")
FULL_HEADERS="content-security-policy: default-src 'self'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer|permissions-policy: camera=(), microphone=(), geolocation=()|strict-transport-security: max-age=31536000; includeSubDomains"

cat >"$FIXTURE" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `omrihefez.com` (apex) | Personal hub | *(none)* | Vercel | explicit | 🟠 blank | 404 |
| ~~`oldapp`~~ | sunset | old-repo | Vercel | wildcard | 🔴 removed | must NOT be audited |
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `meniapp` | Meni app | meniapp | Vercel | wildcard | 🟢 live | the ma-20c5 gap: real Vercel host missing from the old array |
| `meniapp-api` | worker orchestration | meniapp | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, must SKIP the Vercel gate AND get its own per-path baseline (bt-d173) |
| `planner` | auth-gated app | some-repo | Vercel | wildcard | 🟢 live | 401 host, VERCEL_CHECK_PATHS pins "/" (bt-3ba1) |
EOF

CURL_STUB="$TMP/curl-stub.sh"
cat >"$CURL_STUB" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
host="$(echo "$url" | sed -E 's#^https?://([^/]+).*#\1#')"
path="$(echo "$url" | sed -E 's#^https?://[^/]+##')"
[ -z "$path" ] && path="/"
row="$(awk -F'\t' -v h="$host" -v p="$path" '$1 == h && $2 == p {print; exit}' "$CURL_FIXTURE_MAP")"
if [ -z "$row" ]; then
  printf 'HTTP/1.1 599 Unknown\r\n\r\n'
  exit 0
fi
code="$(cut -f3 <<<"$row")"
loc="$(cut -f4 <<<"$row")"
hdrs="$(cut -f5 <<<"$row")"
printf 'HTTP/1.1 %s Status\r\n' "$code"
[ -n "$loc" ] && printf 'location: %s\r\n' "$loc"
if [ -n "$hdrs" ]; then
  IFS='|' read -ra H <<<"$hdrs"
  for h in "${H[@]}"; do
    printf '%s\r\n' "$h"
  done
fi
printf '\r\n'
EOF
chmod +x "$CURL_STUB"

run() { CURL_FIXTURE_MAP="$FIXTURE_MAP" DOMAIN_MD="$FIXTURE" CURL_CMD="$CURL_STUB" bash "$SCRIPT"; }

# meniapp-api is now a NONVERCEL_CHECK_PATHS host (bt-d173): every scenario
# below that uses the shared $FIXTURE gets its /health curled for real, so
# give it a clean full-baseline row unless the test is specifically about
# that check.
MENIAPP_API_HEALTH_OK() { printf 'meniapp-api.omrihefez.com\t/health\t200\t\t%s\n' "$FULL_HEADERS"; }
# planner (bt-3ba1): a real VERCEL_CHECK_PATHS entry pinned at "/" itself —
# its 401 already carries the full header set live, so this fixture gives it
# just what check_nonvercel_path()'s refusal-code branch checks (Cache-
# Control: no-store + HSTS), matching the measured live shape.
PLANNER_OK() { printf 'planner.omrihefez.com\t/\t401\t\tcache-control: no-store|strict-transport-security: max-age=31536000; includeSubDomains\n'; }

echo "1. a Vercel+live host missing from a hand-copied array (the ma-20c5 gap) is now checked"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
MENIAPP_API_HEALTH_OK >>"$FIXTURE_MAP"
PLANNER_OK >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0, got $rc: $out"
grep -q "OK     meniapp.omrihefez.com -> 200" <<<"$out" || fail "expected meniapp to be actively checked, got: $out"
ok "meniapp is derived and checked, not missing"

echo "2. a tombstoned row is never audited"
grep -q "oldapp" <<<"$out" && fail "a 🔴 removed row must not appear at all, got: $out"
ok "tombstoned row excluded"

echo "3. a non-Vercel live host (Cloudflare Tunnel) is SKIPped from the Vercel Deployment-Protection gate, and separately gets its own per-path baseline (bt-d173), not the old bare-echo"
grep -q "^SKIP   meniapp-api.omrihefez.com -> live in the registry but not Vercel-hosted; Deployment-Protection drift does not apply (security-header baseline IS checked below, per path)" <<<"$out" \
  || fail "expected the Deployment-Protection SKIP line naming the baseline is checked separately, got: $out"
grep -q "^OK     meniapp-api.omrihefez.com/health -> 200" <<<"$out" \
  || fail "expected the layer-3 per-path baseline check to actually run (and pass, given full headers) for meniapp-api/health, got: $out"
ok "Cloudflare-Tunnel host is named via SKIP for the Vercel gate, and its own security-header baseline runs and reports separately"

echo "4. a genuine Vercel Deployment-Protection redirect still fails loudly (bt-417b class)"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t/\t307\thttps://vercel.com/login\n' >>"$FIXTURE_MAP"
MENIAPP_API_HEALTH_OK >>"$FIXTURE_MAP"
PLANNER_OK >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 on a vercel.com login redirect, got $rc: $out"
grep -q "^DRIFT  meniapp.omrihefez.com" <<<"$out" || fail "expected a DRIFT line for the gated host, got: $out"
ok "the original bt-417b drift detection still fires"

echo "5. AUDIT_SUBS overrides the DOMAIN.md derivation entirely (test-monitoring.sh's bt-a942 self-test relies on this to force a failure)"
: >"$FIXTURE_MAP"
printf 'nonexistent-bt-a942-selftest.omrihefez.com\t/\t404\t\n' >>"$FIXTURE_MAP"
out="$(AUDIT_SUBS="nonexistent-bt-a942-selftest" CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" DOMAIN_MD="$TMP/does-not-exist.md" bash "$SCRIPT")"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for the forced-failure host, got $rc: $out"
grep -q "^CHECK  nonexistent-bt-a942-selftest.omrihefez.com" <<<"$out" || fail "expected the override host to be checked and fail, got: $out"
ok "AUDIT_SUBS bypasses DOMAIN_MD entirely (even an unreadable one), so the self-test sabotage still works"

echo "6. an unreadable DOMAIN.md fails loudly instead of running an empty/stale audit"
: >"$FIXTURE_MAP"
DOMAIN_MD="$TMP/does-not-exist.md" CURL_CMD="$CURL_STUB" bash "$SCRIPT" >/tmp/audit-out-$$ 2>&1
rc=$?
rm -f /tmp/audit-out-$$
[ "$rc" -eq 2 ] || fail "expected exit 2 for a missing registry, got $rc"
ok "missing DOMAIN.md refuses to run rather than silently checking nothing"

echo "7. bt-a2c2: a 200 host with NO security headers at all (the compose.omrihefez.com shape) is reported as DRIFT, not OK"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t/\t200\t\n' >>"$FIXTURE_MAP"
MENIAPP_API_HEALTH_OK >>"$FIXTURE_MAP"
PLANNER_OK >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 when a 200 host is missing its whole security-header baseline, got $rc: $out"
grep -q "^DRIFT  meniapp.omrihefez.com -> 200 missing security headers:" <<<"$out" || fail "expected a DRIFT line naming the missing headers, got: $out"
grep -q "content-security-policy" <<<"$out" || fail "expected content-security-policy named as missing, got: $out"
grep -q "x-frame-options" <<<"$out" || fail "expected x-frame-options named as missing, got: $out"
grep -q "x-content-type-options" <<<"$out" || fail "expected x-content-type-options named as missing, got: $out"
grep -q "referrer-policy" <<<"$out" || fail "expected referrer-policy named as missing, got: $out"
grep -q "^OK     bass.omrihefez.com -> 200" <<<"$out" || fail "expected bass (full baseline) to stay OK, got: $out"
ok "a 200 response with zero security headers is DRIFT, and this is exactly the shape the discovery run measured live on compose.omrihefez.com"

echo "8. a report-only CSP still counts as present (the trips.omrihefez.com shape), and a 401/redirect host is exempt from the header baseline entirely"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t/\t200\t\tcontent-security-policy-report-only: default-src '"'"'self'"'"'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer|permissions-policy: camera=(), microphone=(self), geolocation=()|strict-transport-security: max-age=31536000; includeSubDomains\n' >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
MENIAPP_API_HEALTH_OK >>"$FIXTURE_MAP"
PLANNER_OK >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 (report-only CSP counts, 401 is exempt), got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> 200" <<<"$out" || fail "expected report-only CSP to satisfy the CSP check, got: $out"
grep -q "^OK     planner.omrihefez.com -> 401" <<<"$out" || fail "expected the 401 host to be OK given its pinned-path baseline, got: $out"
grep -q "^DRIFT  planner" <<<"$out" && fail "a 401 host with a satisfied pinned-path baseline must not be flagged, got: $out"
ok "report-only CSP satisfies the baseline and a 401 host is correctly exempt"

# --- bt-d173/bt-135b: layer-3 non-Vercel per-(host,path) baseline ---
# A dedicated small registry: one Vercel host (bass, so SUBS isn't empty)
# plus the full non-Vercel cast — the four checked hosts (house, meniapp-api,
# tik-api, tik-api-vps — bt-135b assessed the latter two as the same JSON-API
# class as meniapp-api, not a brain/oauth-style exemption) and the two that
# must stay SKIPped for stated, differing reasons (brain, oauth).
FIXTURE2="$TMP/DOMAIN2.md"
FIXTURE_MAP2="$TMP/responses2.tsv"
cat >"$FIXTURE2" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `house` | House control | house-control | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, per-path baseline checked (bt-d173) |
| `meniapp-api` | worker orchestration | meniapp | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, per-path baseline checked (bt-d173) |
| `brain` | Second Brain | second-brain | Cloudflare Tunnel | explicit | 🟢 live | by-design 404 auth wall — must stay SKIPped |
| `oauth` | OAuth catcher | apartment | Cloudflare Tunnel | explicit | 🟢 live | intentionally public — must stay SKIPped |
| `tik-api` | TIK API | tik | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, per-path baseline checked (bt-135b) |
| `tik-api-vps` | TIK API VPS origin | tik | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, per-path baseline checked (bt-135b) |
EOF
run2() { CURL_FIXTURE_MAP="$FIXTURE_MAP2" DOMAIN_MD="$FIXTURE2" CURL_CMD="$CURL_STUB" bash "$SCRIPT"; }
BASS_OK() { printf 'bass.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS"; }
HOUSE_LOGIN_OK() { printf 'house.omrihefez.com\t/login\t200\t\tcontent-type: text/html|%s\n' "$FULL_HEADERS"; }
TIK_API_HEALTH_OK() { printf 'tik-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000; includeSubDomains\n'; }
TIK_API_VPS_HEALTH_OK() { printf 'tik-api-vps.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000; includeSubDomains\n'; }
BRAIN_HSTS_OK() { printf 'brain.omrihefez.com\t/\t404\t\tstrict-transport-security: max-age=31536000; includeSubDomains\n'; }
OAUTH_HSTS_OK() { printf 'oauth.omrihefez.com\t/health\t200\t\tstrict-transport-security: max-age=31536000; includeSubDomains\n'; }

echo "9. bt-d173 (hc-d30f class, FAILING shape): house's refusal-redirect path missing Cache-Control: no-store is DRIFT, and brain/oauth never get the BODY-shaped baseline (bt-b75b: they DO now get their own HSTS-only check)"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"   # framing headers present, but NO cache-control — the hc-d30f shape
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (house's / is missing no-store), got $rc: $out"
grep -q "^DRIFT  house.omrihefez.com/ -> 307 missing Cache-Control: no-store" <<<"$out" || fail "expected the hc-d30f-class DRIFT line for house's /, got: $out"
grep -q "^OK     brain.omrihefez.com/ -> 404 (Strict-Transport-Security: max-age=31536000; includeSubDomains)" <<<"$out" || fail "expected brain's HSTS-only check to run and pass, got: $out"
grep -q "^OK     oauth.omrihefez.com/health -> 200 (Strict-Transport-Security: max-age=31536000; includeSubDomains)" <<<"$out" || fail "expected oauth's HSTS-only check to run and pass, got: $out"
grep -qE "brain\.omrihefez\.com.*(Cache-Control|security headers)" <<<"$out" && fail "brain must never get the body-shaped baseline (Cache-Control/CSP/XFO/nosniff/referrer-policy), got: $out"
grep -qE "oauth\.omrihefez\.com.*(Cache-Control|security headers)" <<<"$out" && fail "oauth must never get the body-shaped baseline, got: $out"
grep -q "^OK     tik-api.omrihefez.com/health -> 200" <<<"$out" || fail "expected tik-api/health to be curled and pass given full headers, got: $out"
grep -q "^OK     tik-api-vps.omrihefez.com/health -> 200" <<<"$out" || fail "expected tik-api-vps/health to be curled and pass given full headers, got: $out"
ok "the check FAILS on the exact pre-fix hc-d30f shape (framing headers present, cache header absent); brain/oauth are never curled for the body-shaped baseline but ARE curled for HSTS alone; tik-api/tik-api-vps ARE curled and pass"

echo "10. bt-d173: the SAME check PASSES once Cache-Control: no-store is added — proves this is a real fail/pass check, not a check that only ever passes"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000; includeSubDomains\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once no-store is present (the hc-d30f fix shape), got $rc: $out"
grep -q "^OK     house.omrihefez.com/ -> 307 (Cache-Control: no-store present" <<<"$out" || fail "expected house's / to read OK once fixed, got: $out"
grep -q "^OK     house.omrihefez.com/login -> 200" <<<"$out" || fail "expected house's /login (framing headers, html) to read OK, got: $out"
ok "the check flips to OK the moment the fix is present — this is the same probe, not a different one for each side"

echo "11. bt-d173: meniapp-api's /health (JSON) missing x-content-type-options is DRIFT — the exact live finding this task's own 'done when' names — and CSP/X-Frame-Options/Referrer-Policy are NOT required on it (content-type gate avoids the JSON-API noise problem)"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|strict-transport-security: max-age=31536000\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (meniapp-api missing nosniff), got $rc: $out"
grep -q "^DRIFT  meniapp-api.omrihefez.com/health -> 200 missing security headers: x-content-type-options$" <<<"$out" \
  || fail "expected DRIFT naming ONLY x-content-type-options as missing (no csp/x-frame-options/referrer-policy noise on a JSON API), got: $out"
ok "a JSON API missing nosniff is DRIFT, named precisely, with no false noise from framing headers that don't apply to it"

echo "11b. bt-135b: tik-api's /health (JSON) missing x-content-type-options is DRIFT — the exact live finding measured on tik-api.omrihefez.com before the fix in the tik-api repo — and tik-api-vps (same origin) is checked independently"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000\n' >>"$FIXTURE_MAP2"
printf 'tik-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|strict-transport-security: max-age=31536000\n' >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (tik-api missing nosniff), got $rc: $out"
grep -q "^DRIFT  tik-api.omrihefez.com/health -> 200 missing security headers: x-content-type-options$" <<<"$out" \
  || fail "expected DRIFT naming ONLY x-content-type-options as missing for tik-api, got: $out"
grep -q "^OK     tik-api-vps.omrihefez.com/health -> 200" <<<"$out" \
  || fail "expected tik-api-vps to still read OK independently of tik-api's drift, got: $out"
ok "tik-api missing nosniff is DRIFT (the pre-fix shape), and tik-api-vps is checked as its own row, not coupled to tik-api's result"

echo "12. bt-d173: a 401 on a checked non-Vercel host is exempt from framing headers but NOT from Cache-Control: no-store (mirrors the SUBS-loop 401 exemption, inverted for cache)"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t401\t\t\n' >>"$FIXTURE_MAP2"   # zero headers at all, including no-store
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1, got $rc: $out"
line="$(grep "^DRIFT  house.omrihefez.com/ " <<<"$out")"
[ -n "$line" ] || fail "expected a DRIFT line for house's 401 /, got: $out"
grep -q "missing Cache-Control: no-store" <<<"$line" || fail "expected a 401 missing no-store to be DRIFT, got: $line"
grep -qi "x-frame-options\|content-security-policy\|referrer-policy" <<<"$line" && fail "a 401 must never be checked for framing headers, got: $line"
ok "a 401 refusal is checked for Cache-Control: no-store and never for framing headers — matches the task's own done-when"

echo "13. bt-d173/bt-135b: SKIP text for an exempt host names its OWN reason, not a copy of another host's; a host with no stated reason falls through to the default (still-live code path — no real registry host currently exercises it, so this one row is a deliberate stand-in, not a real label)"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t401\t\tcache-control: no-store\n' >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
grep -q "^SKIP   brain.omrihefez.com.*by-design auth wall" <<<"$out" || fail "expected brain's SKIP reason to name its by-design 404 auth wall, got: $out"
grep -q "^SKIP   oauth.omrihefez.com.*intentionally public" <<<"$out" || fail "expected oauth's SKIP reason to name it as intentionally public, got: $out"
grep -q "^OK     tik-api.omrihefez.com/health -> 200" <<<"$out" || fail "expected tik-api to now be actively checked, not SKIPped, got: $out"
ok "each SKIPped host states its own actual reason — the SKIP text does not collapse two different causes into one line, and tik-api is no longer in the SKIP set at all"

echo "13b. the still-live default-reason fallback (no real registry host currently exercises it, since tik-api's assessment resolved the last unclassified one) fires for a host in neither dict"
: >"$TMP/DOMAIN3.md"
cat >"$TMP/DOMAIN3.md" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `not-yet-triaged` | stand-in for a future untriaged non-Vercel host | some-repo | Cloudflare Tunnel | explicit | 🟢 live | deliberately absent from both NONVERCEL_* dicts |
EOF
: >"$TMP/responses3.tsv"
printf 'bass.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$TMP/responses3.tsv"
out="$(CURL_FIXTURE_MAP="$TMP/responses3.tsv" DOMAIN_MD="$TMP/DOMAIN3.md" CURL_CMD="$CURL_STUB" bash "$SCRIPT")"
grep -q "^SKIP   not-yet-triaged.omrihefez.com.*not yet assessed" <<<"$out" || fail "expected the default fallback reason for an unclassified host, got: $out"
ok "a host in neither NONVERCEL_CHECK_PATHS nor NONVERCEL_HEADER_SKIP_REASON still gets the default not-yet-assessed reason, not a crash or a false OK"

# --- bt-b75b: Strict-Transport-Security itself, FAILING then PASSING ---
# bt-b75b's own gap: every check above already proves the OTHER headers
# fail-then-pass; none of them ever left out Strict-Transport-Security and
# then added it back in, so none of them actually exercise the new check.
# Run against the parent commit (pre-bt-b75b) this section reproduces the
# exact live finding: meniapp-api/health and brain/ both measured missing
# HSTS, and check_nonvercel_path()/check_hsts_at() never looked for it —
# both would have reported OK regardless. Confirmed red against the parent
# commit before this section was added.

echo "14. bt-b75b (FAILING shape, check_nonvercel_path/NONVERCEL_CHECK_PATHS side): meniapp-api's /health with every OTHER header present but NO Strict-Transport-Security is DRIFT on a 200 — not gated on content-type the way CSP/X-Frame-Options/Referrer-Policy are"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n' >>"$FIXTURE_MAP2"   # full baseline EXCEPT hsts
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (meniapp-api missing Strict-Transport-Security), got $rc: $out"
grep -q "^DRIFT  meniapp-api.omrihefez.com/health -> 200 missing Strict-Transport-Security$" <<<"$out" \
  || fail "expected a dedicated DRIFT line naming Strict-Transport-Security missing on the 200 JSON /health response, got: $out"
grep -qE "^DRIFT.*missing security headers:.*strict-transport-security" <<<"$out" \
  && fail "HSTS must be its own DRIFT line, not merged into the CSP/XFO/nosniff missing-headers list, got: $out"
ok "a 200 non-Vercel response missing ONLY Strict-Transport-Security is DRIFT — the check fires on the exact live shape this task measured, and fires on a bare JSON 200 with no text/html content-type"

echo "15. bt-b75b (PASSING shape, same probe): the SAME meniapp-api row flips to OK once Strict-Transport-Security is added back — proves this is a real fail/pass check, not one only ever seen passing"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000; includeSubDomains\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once Strict-Transport-Security is present, got $rc: $out"
grep -q "^OK     meniapp-api.omrihefez.com/health -> 200 (Strict-Transport-Security: max-age=31536000; includeSubDomains)" <<<"$out" \
  || fail "expected meniapp-api/health's dedicated HSTS line to flip to OK, got: $out"
ok "the same probe flips to OK the moment Strict-Transport-Security is added — this is the fail/pass pair for the check_nonvercel_path side of bt-b75b"

echo "16. bt-b75b (FAILING shape, NONVERCEL_HSTS_ONLY_PATH/brain-oauth side): brain's by-design 404 with NO Strict-Transport-Security is DRIFT — the exact live shape measured 2026-09-30 (brain.omrihefez.com 404, no HSTS) — even though brain is fully exempt from the body-shaped baseline"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
printf 'brain.omrihefez.com\t/\t404\t\t\n' >>"$FIXTURE_MAP2"   # the real measured shape: 404, zero headers
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (brain missing Strict-Transport-Security), got $rc: $out"
grep -q "^DRIFT  brain.omrihefez.com/ -> 404 missing Strict-Transport-Security$" <<<"$out" \
  || fail "expected a DRIFT line for brain's missing HSTS on its by-design 404, got: $out"
ok "an exempt-from-body-baseline host (brain) still goes DRIFT when it lacks Strict-Transport-Security — the by-design 404 exemption narrows to body-shaped headers only, per this task's done-when #2"

echo "17. bt-b75b: the SAME brain probe flips to OK once Strict-Transport-Security is present on its 404"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff|strict-transport-security: max-age=31536000; includeSubDomains\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
BRAIN_HSTS_OK >>"$FIXTURE_MAP2"
OAUTH_HSTS_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once brain sends Strict-Transport-Security, got $rc: $out"
grep -q "^OK     brain.omrihefez.com/ -> 404 (Strict-Transport-Security: max-age=31536000; includeSubDomains)" <<<"$out" \
  || fail "expected brain's HSTS line to flip to OK, got: $out"
ok "the brain/oauth-side probe is the same fail/pass pair, not a check only ever seen passing"

# --- bt-3ba1: the Vercel (SUBS) loop gets the same HSTS + per-path coverage
# the non-Vercel loop already has. Before this task the SUBS loop never
# called check_hsts() at all, and a 307/308/401 Vercel host (no page served
# at "/") was asserted on literally nothing — this is the exact live shape
# measured 2026-10-01 for meni/arch-preview/trips/tik (307 -> /login) and
# planner (401). A dedicated small registry: bass (vercel, 200, keeps SUBS
# non-empty) plus `meni` (vercel, 307 at "/" -> /login, VERCEL_CHECK_PATHS
# pins /login).
FIXTURE4="$TMP/DOMAIN4.md"
FIXTURE_MAP4="$TMP/responses4.tsv"
cat >"$FIXTURE4" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `meni` | Meni app | meniapp | Vercel | wildcard | 🟢 live | 307 at / -> /login, VERCEL_CHECK_PATHS pins /login (bt-3ba1) |
EOF
run4() { CURL_FIXTURE_MAP="$FIXTURE_MAP4" DOMAIN_MD="$FIXTURE4" CURL_CMD="$CURL_STUB" bash "$SCRIPT"; }
MENI_LOGIN() { printf 'meni.omrihefez.com\t/login\t200\t\t%s\n' "$1"; }

echo "18. bt-3ba1 (FAILING shape): meni's 307-redirect root is asserted on nothing by itself (header baseline not applicable at /), but its VERCEL_CHECK_PATHS-pinned /login path is now checked — missing x-frame-options there is DRIFT"
: >"$FIXTURE_MAP4"
BASS_OK >>"$FIXTURE_MAP4"
printf 'meni.omrihefez.com\t/\t307\t/login\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP4"
printf 'meni.omrihefez.com\t/login\t200\t\tcontent-type: text/html|content-security-policy: default-src '"'"'self'"'"'|x-content-type-options: nosniff|referrer-policy: no-referrer|strict-transport-security: max-age=31536000\n' >>"$FIXTURE_MAP4"
out="$(run4)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (meni's /login missing x-frame-options), got $rc: $out"
grep -q "^DRIFT  meni.omrihefez.com/login -> 200 missing security headers: x-frame-options$" <<<"$out" \
  || fail "expected the pinned /login path to be checked and DRIFT on a missing header, got: $out"
ok "a Vercel host's root redirect alone proves nothing — the pinned /login path is what actually catches the missing header"

echo "19. bt-3ba1 (PASSING shape, same probe): the SAME meni /login flips to OK once x-frame-options is present — proves the per-path check is a real fail/pass check, not one only ever seen passing"
: >"$FIXTURE_MAP4"
BASS_OK >>"$FIXTURE_MAP4"
printf 'meni.omrihefez.com\t/\t307\t/login\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP4"
MENI_LOGIN "$FULL_HEADERS" >>"$FIXTURE_MAP4"
out="$(run4)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once /login carries the full baseline, got $rc: $out"
grep -q "^OK     meni.omrihefez.com/login -> 200 (security headers present)" <<<"$out" \
  || fail "expected meni's /login to read OK once fixed, got: $out"
ok "the pinned-path check flips to OK the moment the fix is present"

echo "20. bt-3ba1 (FAILING shape, SUBS-root HSTS side): a Vercel host missing Strict-Transport-Security at the ROOT is now DRIFT — before this task check_hsts() was never called from the SUBS loop at all, so this was silently OK"
: >"$FIXTURE_MAP4"
printf 'bass.omrihefez.com\t/\t200\t\tcontent-security-policy: default-src '"'"'self'"'"'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer|permissions-policy: camera=(), microphone=(self), geolocation=()\n' >>"$FIXTURE_MAP4"
printf 'meni.omrihefez.com\t/\t307\t/login\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP4"
MENI_LOGIN "$FULL_HEADERS" >>"$FIXTURE_MAP4"
out="$(run4)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (bass missing Strict-Transport-Security at root), got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> 200 missing Strict-Transport-Security$" <<<"$out" \
  || fail "expected a dedicated DRIFT line for bass's missing HSTS, got: $out"
ok "the SUBS loop now calls check_hsts() unconditionally — a 200 Vercel host missing only HSTS is DRIFT where it used to be silently OK"

echo "21. bt-3ba1 (PASSING shape, same probe): the SAME bass row flips to OK once Strict-Transport-Security is present — proves this is a real fail/pass check"
: >"$FIXTURE_MAP4"
BASS_OK >>"$FIXTURE_MAP4"
printf 'meni.omrihefez.com\t/\t307\t/login\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP4"
MENI_LOGIN "$FULL_HEADERS" >>"$FIXTURE_MAP4"
out="$(run4)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once bass sends Strict-Transport-Security, got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> 200 (Strict-Transport-Security: max-age=31536000; includeSubDomains)" <<<"$out" \
  || fail "expected bass's HSTS line to flip to OK, got: $out"
ok "the SUBS-root HSTS probe is the same fail/pass pair, not a check only ever seen passing"

echo "22. bt-3ba1: a Vercel host answering 307/401/308 with NO VERCEL_CHECK_PATHS entry fails loudly as UNPINNED instead of printing a silent OK — same idiom check-tunnel-liveness.sh already uses for an unpinned non-Vercel host"
FIXTURE5="$TMP/DOMAIN5.md"
FIXTURE_MAP5="$TMP/responses5.tsv"
cat >"$FIXTURE5" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `newapp` | stand-in for a future unpinned auth-gated Vercel host | some-repo | Vercel | wildcard | 🟢 live | deliberately absent from VERCEL_CHECK_PATHS |
EOF
: >"$FIXTURE_MAP5"
BASS_OK >>"$FIXTURE_MAP5"
printf 'newapp.omrihefez.com\t/\t401\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP5"
out="$(CURL_FIXTURE_MAP="$FIXTURE_MAP5" DOMAIN_MD="$FIXTURE5" CURL_CMD="$CURL_STUB" bash "$SCRIPT" 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (newapp has no pinned path), got $rc: $out"
grep -q "^UNPINNED newapp.omrihefez.com -> 401" <<<"$out" \
  || fail "expected an UNPINNED line naming the unpinned 401 Vercel host, got: $out"
ok "an auth-gated Vercel host with no VERCEL_CHECK_PATHS entry fails loudly as UNPINNED rather than printing a silent OK"

echo "23. bt-3ba1: a reviewed cross-host alias redirect (the real tuner.omrihefez.com -> bass.omrihefez.com 308, measured live 2026-10-01 running this very fix) is SKIPped from the per-path pin requirement, not flagged UNPINNED — but still gets check_hsts() on its own root response"
: >"$FIXTURE_MAP5"
BASS_OK >>"$FIXTURE_MAP5"
printf 'tuner.omrihefez.com\t/\t308\thttps://bass.omrihefez.com/\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP5"
cat >"$TMP/DOMAIN5-tuner.md" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `tuner` | vanity alias of bass | bass-tuner | Vercel | wildcard | 🔵 alias | 308-redirects to bass, DOMAIN.md §2 rule 3 |
EOF
out="$(CURL_FIXTURE_MAP="$FIXTURE_MAP5" DOMAIN_MD="$TMP/DOMAIN5-tuner.md" CURL_CMD="$CURL_STUB" bash "$SCRIPT" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 (tuner is a reviewed alias, not an unpinned gap), got $rc: $out"
grep -q "^SKIP   tuner.omrihefez.com -> pinned-path baseline not applicable:" <<<"$out" \
  || fail "expected tuner's alias-skip reason, not a silent OK or an UNPINNED failure, got: $out"
grep -q "^UNPINNED tuner" <<<"$out" && fail "a reviewed alias must never be flagged UNPINNED, got: $out"
grep -q "^OK     tuner.omrihefez.com -> 308 (Strict-Transport-Security: max-age=31536000; includeSubDomains)" <<<"$out" \
  || fail "expected tuner's root response to still get check_hsts() despite the body-baseline skip, got: $out"
ok "a reviewed cross-host alias redirect is named via its own SKIP reason, never UNPINNED, and still gets the unconditional root HSTS check"

# --- bt-8c53: check_hsts() asserts the VALUE, not just presence ---
# Before this task, check_hsts() only tested that the header NAME was
# present — max-age=0 (which actively tells the browser to FORGET the HSTS
# pin) and a value missing includeSubDomains both printed OK. Confirmed
# against the parent commit (79a00b3, pre bt-8c53): test 24's exact fixture
# prints "OK bass.omrihefez.com -> 200 (Strict-Transport-Security present)"
# there, not DRIFT.
FIXTURE6="$TMP/DOMAIN6.md"
FIXTURE_MAP6="$TMP/responses6.tsv"
cat >"$FIXTURE6" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
EOF
run6() { CURL_FIXTURE_MAP="$FIXTURE_MAP6" DOMAIN_MD="$FIXTURE6" CURL_CMD="$CURL_STUB" bash "$SCRIPT"; }
BASS_HSTS() { printf 'bass.omrihefez.com\t/\t200\t\tcontent-security-policy: default-src '"'"'self'"'"'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer|permissions-policy: camera=(), microphone=(self), geolocation=()|strict-transport-security: %s\n' "$1"; }

echo "24. bt-8c53 (FAILING shape, pre-fix this was OK): max-age=0 actively instructs the browser to forget the HSTS pin — a presence-only check reported it OK regardless"
: >"$FIXTURE_MAP6"
BASS_HSTS "max-age=0" >>"$FIXTURE_MAP6"
out="$(run6)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (max-age=0 is below the floor), got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> 200 Strict-Transport-Security max-age=0 below floor 31536000" <<<"$out" \
  || fail "expected a DRIFT line naming the sub-floor max-age, got: $out"
ok "max-age=0 is DRIFT, not OK — the exact gap this task was filed over"

echo "25. bt-8c53 (companion shape): max-age clears the floor but includeSubDomains is absent — compose's exact live shape measured 2026-10-01"
: >"$FIXTURE_MAP6"
BASS_HSTS "max-age=63072000" >>"$FIXTURE_MAP6"
out="$(run6)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (missing includeSubDomains), got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> 200 Strict-Transport-Security missing includeSubDomains" <<<"$out" \
  || fail "expected a DRIFT line naming the missing includeSubDomains directive, got: $out"
ok "a high max-age with no includeSubDomains is still DRIFT — compose's own live gap, not a hypothetical"

echo "26. bt-8c53 (PASSING shape, same probe): max-age at the floor plus includeSubDomains together are OK"
: >"$FIXTURE_MAP6"
BASS_HSTS "max-age=31536000; includeSubDomains" >>"$FIXTURE_MAP6"
out="$(run6)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once max-age clears the floor and includeSubDomains is present, got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> 200 (Strict-Transport-Security: max-age=31536000; includeSubDomains)" <<<"$out" \
  || fail "expected bass's HSTS line to read OK with the full value shown, got: $out"
ok "the same probe flips to OK once both the floor and includeSubDomains are satisfied — not a check only ever seen failing"

# --- bt-4164: Permissions-Policy admitted to the baseline, presence only ---
# 7 of 10 live hosts send it as of 2026-10-01 (measured in the task body);
# it is now the estate norm per bt-a2c2's own admission test. Checked for
# PRESENCE, not an exact value, because the senders legitimately disagree on
# the value itself. The two hosts still measured absent (compose, meni +
# arch-preview) carry a named, dated exemption (PERMISSIONS_POLICY_EXEMPT)
# pointing at the task that already tracks each, not a silent skip.

echo "27. bt-4164 (FAILING shape, SUBS side): bass with the full baseline minus Permissions-Policy is DRIFT, naming permissions-policy precisely — confirmed red against the parent commit (pre-bt-4164), which has no such check at all"
: >"$FIXTURE_MAP6"
printf 'bass.omrihefez.com\t/\t200\t\tcontent-security-policy: default-src '"'"'self'"'"'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer|strict-transport-security: max-age=31536000; includeSubDomains\n' >>"$FIXTURE_MAP6"
out="$(run6)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (bass missing permissions-policy), got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> 200 missing security headers: permissions-policy$" <<<"$out" \
  || fail "expected a DRIFT line naming ONLY permissions-policy as missing, got: $out"
ok "a 200 Vercel host with every other header present but no Permissions-Policy is DRIFT — the exact bt-4164 gap, not a check only ever seen passing"

echo "28. bt-4164 (PASSING shape, same probe): the SAME bass row flips to OK once Permissions-Policy is added — proves this is a real fail/pass check"
: >"$FIXTURE_MAP6"
BASS_HSTS "max-age=31536000; includeSubDomains" >>"$FIXTURE_MAP6"
out="$(run6)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once permissions-policy is present, got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> 200 (security headers present)" <<<"$out" \
  || fail "expected bass to read OK once permissions-policy is present (BASS_HSTS already includes it), got: $out"
ok "the same probe flips to OK the moment Permissions-Policy is added back"

echo "29. bt-4164 (SUBS-side exemption): compose, PERMISSIONS_POLICY_EXEMPT'd per cp-8845, stays OK despite sending no Permissions-Policy — named via SKIP, not a silent pass"
FIXTURE7="$TMP/DOMAIN7.md"
FIXTURE_MAP7="$TMP/responses7.tsv"
cat >"$FIXTURE7" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `compose` | Compose | compose | Vercel | explicit | 🟢 live | sends no Permissions-Policy today, tracked on cp-8845 |
EOF
run7() { CURL_FIXTURE_MAP="$FIXTURE_MAP7" DOMAIN_MD="$FIXTURE7" CURL_CMD="$CURL_STUB" bash "$SCRIPT"; }
: >"$FIXTURE_MAP7"
BASS_OK >>"$FIXTURE_MAP7"
printf 'compose.omrihefez.com\t/\t200\t\tcontent-security-policy: default-src '"'"'self'"'"'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer|strict-transport-security: max-age=31536000; includeSubDomains\n' >>"$FIXTURE_MAP7"
out="$(run7)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 (compose is exempted, not DRIFT), got $rc: $out"
grep -q "^OK     compose.omrihefez.com -> 200 (security headers present)" <<<"$out" \
  || fail "expected compose to read OK despite missing permissions-policy, got: $out"
grep -q "^SKIP   compose.omrihefez.com -> permissions-policy baseline not applicable: exempted per cp-8845 2026-10-01" <<<"$out" \
  || fail "expected a SKIP line naming compose's exemption and the task that tracks it, got: $out"
ok "compose's exemption suppresses the DRIFT but is named via SKIP, not silently dropped — this would catch a dangling exemption the moment cp-8845 closes and nobody removed the entry, because the SKIP line would then say so loudly next to a host that actually sends the header"

echo "30. bt-4164 (check_nonvercel_path-side exemption): meni, PERMISSIONS_POLICY_EXEMPT'd per ar-3426, stays OK on its pinned /login path despite sending no Permissions-Policy"
: >"$FIXTURE_MAP4"
BASS_OK >>"$FIXTURE_MAP4"
printf 'meni.omrihefez.com\t/\t307\t/login\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP4"
printf 'meni.omrihefez.com\t/login\t200\t\tcontent-type: text/html|content-security-policy: default-src '"'"'self'"'"'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer|strict-transport-security: max-age=31536000; includeSubDomains\n' >>"$FIXTURE_MAP4"
out="$(run4)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 (meni/login is exempted, not DRIFT), got $rc: $out"
grep -q "^OK     meni.omrihefez.com/login -> 200 (security headers present)" <<<"$out" \
  || fail "expected meni/login to read OK despite missing permissions-policy, got: $out"
grep -q "^SKIP   meni.omrihefez.com/login -> permissions-policy baseline not applicable: exempted per ar-3426 2026-10-01" <<<"$out" \
  || fail "expected a SKIP line naming meni's exemption and the task that tracks it, got: $out"
ok "the same exemption works on the check_nonvercel_path side (meni's VERCEL_CHECK_PATHS-pinned /login), keyed off the same PERMISSIONS_POLICY_EXEMPT map — arch-preview shares meni's ar-3426 entry and is not re-tested separately, same map lookup"

echo
echo "PASS ($pass assertions)"
