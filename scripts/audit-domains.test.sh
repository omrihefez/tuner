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
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/audit-domains.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/DOMAIN.md"
FIXTURE_MAP="$TMP/responses.tsv"   # host<TAB>path<TAB>code<TAB>location<TAB>extra-headers (| separated "name: value")
FULL_HEADERS="content-security-policy: default-src 'self'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer"

cat >"$FIXTURE" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `omrihefez.com` (apex) | Personal hub | *(none)* | Vercel | explicit | 🟠 blank | 404 |
| ~~`oldapp`~~ | sunset | old-repo | Vercel | wildcard | 🔴 removed | must NOT be audited |
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `meniapp` | Meni app | meniapp | Vercel | wildcard | 🟢 live | the ma-20c5 gap: real Vercel host missing from the old array |
| `meniapp-api` | worker orchestration | meniapp | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, must SKIP the Vercel gate AND get its own per-path baseline (bt-d173) |
| `authed` | auth-gated app | some-repo | Vercel | wildcard | 🟢 live | 401 host, header baseline exempt |
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

echo "1. a Vercel+live host missing from a hand-copied array (the ma-20c5 gap) is now checked"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
MENIAPP_API_HEALTH_OK >>"$FIXTURE_MAP"
printf 'authed.omrihefez.com\t/\t401\t\n' >>"$FIXTURE_MAP"
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
printf 'authed.omrihefez.com\t/\t401\t\n' >>"$FIXTURE_MAP"
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
printf 'authed.omrihefez.com\t/\t401\t\n' >>"$FIXTURE_MAP"
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
printf 'bass.omrihefez.com\t/\t200\t\tcontent-security-policy-report-only: default-src '"'"'self'"'"'|x-frame-options: DENY|x-content-type-options: nosniff|referrer-policy: no-referrer\n' >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t/\t200\t\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP"
MENIAPP_API_HEALTH_OK >>"$FIXTURE_MAP"
printf 'authed.omrihefez.com\t/\t401\t\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 (report-only CSP counts, 401 is exempt), got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> 200" <<<"$out" || fail "expected report-only CSP to satisfy the CSP check, got: $out"
grep -q "^OK     authed.omrihefez.com -> 401" <<<"$out" || fail "expected the 401 host to be OK despite carrying zero security headers, got: $out"
grep -q "^DRIFT  authed" <<<"$out" && fail "a 401 host must never be flagged for missing security headers, got: $out"
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
TIK_API_HEALTH_OK() { printf 'tik-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n'; }
TIK_API_VPS_HEALTH_OK() { printf 'tik-api-vps.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n'; }

echo "9. bt-d173 (hc-d30f class, FAILING shape): house's refusal-redirect path missing Cache-Control: no-store is DRIFT, and brain/oauth never get curled at all"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\t%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"   # framing headers present, but NO cache-control — the hc-d30f shape
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
out="$(run2)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (house's / is missing no-store), got $rc: $out"
grep -q "^DRIFT  house.omrihefez.com/ -> 307 missing Cache-Control: no-store" <<<"$out" || fail "expected the hc-d30f-class DRIFT line for house's /, got: $out"
grep -qE "^(OK|DRIFT|CHECK) +brain" <<<"$out" && fail "brain must never be curled/checked, got: $out"
grep -qE "^(OK|DRIFT|CHECK) +oauth" <<<"$out" && fail "oauth must never be curled/checked, got: $out"
grep -q "^OK     tik-api.omrihefez.com/health -> 200" <<<"$out" || fail "expected tik-api/health to be curled and pass given full headers, got: $out"
grep -q "^OK     tik-api-vps.omrihefez.com/health -> 200" <<<"$out" || fail "expected tik-api-vps/health to be curled and pass given full headers, got: $out"
ok "the check FAILS on the exact pre-fix hc-d30f shape (framing headers present, cache header absent), brain/oauth are never curled, and tik-api/tik-api-vps ARE curled and pass"

echo "10. bt-d173: the SAME check PASSES once Cache-Control: no-store is added — proves this is a real fail/pass check, not a check that only ever passes"
: >"$FIXTURE_MAP2"
BASS_OK >>"$FIXTURE_MAP2"
printf 'house.omrihefez.com\t/\t307\t/login\tcache-control: no-store|%s\n' "$FULL_HEADERS" >>"$FIXTURE_MAP2"
HOUSE_LOGIN_OK >>"$FIXTURE_MAP2"
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
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
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
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
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n' >>"$FIXTURE_MAP2"
printf 'tik-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json\n' >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
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
printf 'meniapp-api.omrihefez.com\t/health\t200\t\tcontent-type: application/json|x-content-type-options: nosniff\n' >>"$FIXTURE_MAP2"
TIK_API_HEALTH_OK >>"$FIXTURE_MAP2"
TIK_API_VPS_HEALTH_OK >>"$FIXTURE_MAP2"
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

echo
echo "PASS ($pass assertions)"
