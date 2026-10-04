#!/usr/bin/env bash
# Regression test for scripts/check-cors-corp-consistency.sh (bt-bfee).
# Hermetic — no real network, same CURL_CMD-stub pattern as
# check-permissions-policy.test.sh / audit-domains.test.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/check-cors-corp-consistency.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE_MAP="$TMP/responses.tsv"  # host<TAB>corp<TAB>acao (empty = header absent)

CURL_STUB="$TMP/curl-stub.sh"
cat >"$CURL_STUB" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
host="$(echo "$url" | sed -E 's#^https?://([^/]+).*#\1#')"
row="$(awk -F'\t' -v h="$host" '$1 == h {print; exit}' "$CURL_FIXTURE_MAP")"
printf 'HTTP/1.1 200 OK\r\n'
if [ -n "$row" ]; then
  corp="$(cut -f2 <<<"$row")"
  acao="$(cut -f3 <<<"$row")"
  [ -n "$corp" ] && printf 'cross-origin-resource-policy: %s\r\n' "$corp"
  [ -n "$acao" ] && printf 'access-control-allow-origin: %s\r\n' "$acao"
fi
printf '\r\n'
EOF
chmod +x "$CURL_STUB"

run() { CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" CHECK_HOST=bass.omrihefez.com bash "$SCRIPT"; }

echo "1. BEFORE: ACAO:* alongside CORP:same-origin (the live pre-fix bt-bfee shape) fails loudly"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tsame-origin\t*\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for ACAO:* alongside CORP:same-origin, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> Access-Control-Allow-Origin: \* contradicts Cross-Origin-Resource-Policy: same-origin" <<<"$out" \
  || fail "expected a DRIFT line naming the contradiction, got: $out"
ok "the check fails on the exact pre-fix shape (ACAO:* + CORP:same-origin)"

echo "2. AFTER: ACAO scoped to the site's own origin passes — same check, proves this is a real fail/pass probe"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tsame-origin\thttps://bass.omrihefez.com\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 with ACAO scoped to the site's own origin, got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> Cross-Origin-Resource-Policy: same-origin, Access-Control-Allow-Origin: https://bass.omrihefez.com" <<<"$out" \
  || fail "expected an OK line echoing both values, got: $out"
ok "the check flips to OK once ACAO is scoped to the site's own origin"

echo "3. ACAO missing entirely is DRIFT, not a silent pass"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tsame-origin\t\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 when ACAO is absent, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> no Access-Control-Allow-Origin header sent" <<<"$out" || fail "expected a DRIFT line naming the absence, got: $out"
ok "a missing Access-Control-Allow-Origin header is caught, not silently accepted"

echo "4. CORP missing entirely is DRIFT — this check also guards the posture it depends on"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t\thttps://bass.omrihefez.com\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 when CORP is absent, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> no Cross-Origin-Resource-Policy header sent" <<<"$out" || fail "expected a DRIFT line naming the absence, got: $out"
ok "a missing Cross-Origin-Resource-Policy header is caught too"

echo "5. a different wrong ACAO value (e.g. a different origin, not *) is still DRIFT, not a near-miss pass"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tsame-origin\thttps://evil.example\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a wrong non-wildcard origin, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> Access-Control-Allow-Origin: https://evil.example (expected: https://bass.omrihefez.com)" <<<"$out" \
  || fail "expected a DRIFT line naming the wrong value, got: $out"
ok "a wrong non-wildcard origin is caught, not accepted just for not being *"

echo
echo "PASS ($pass assertions)"
