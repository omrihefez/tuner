#!/usr/bin/env bash
# Regression test for scripts/check-permissions-policy.sh (bt-40c5). Hermetic
# — no real network, same CURL_CMD-stub pattern as audit-domains.test.sh /
# check-tunnel-liveness.test.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/check-permissions-policy.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE_MAP="$TMP/responses.tsv"  # host<TAB>permissions-policy value (empty = header absent)

CURL_STUB="$TMP/curl-stub.sh"
cat >"$CURL_STUB" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
host="$(echo "$url" | sed -E 's#^https?://([^/]+).*#\1#')"
row="$(awk -F'\t' -v h="$host" '$1 == h {print; exit}' "$CURL_FIXTURE_MAP")"
printf 'HTTP/1.1 200 OK\r\n'
if [ -n "$row" ]; then
  pp="$(cut -f2 <<<"$row")"
  [ -n "$pp" ] && printf 'permissions-policy: %s\r\n' "$pp"
fi
printf '\r\n'
EOF
chmod +x "$CURL_STUB"

run() { CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" CHECK_HOST=bass.omrihefez.com bash "$SCRIPT"; }

echo "1. BEFORE: no Permissions-Policy header at all (the live bt-40c5 shape) fails loudly"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 when the header is absent, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> no Permissions-Policy header sent" <<<"$out" || fail "expected a DRIFT line naming the absence, got: $out"
ok "the check fails on the exact pre-fix shape (no header at all)"

echo "2. AFTER: the correct value passes — same check, proves this is a real fail/pass probe"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tcamera=(), microphone=(self), geolocation=()\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 with the correct value, got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> Permissions-Policy: camera=(), microphone=(self), geolocation=()" <<<"$out" || fail "expected an OK line echoing the value, got: $out"
ok "the check flips to OK once the correct header is present"

echo "3. a wrong value (e.g. microphone=() — the mic-breaking mistake) is DRIFT, not a false pass"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tcamera=(), microphone=(), geolocation=()\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for an empty microphone allowlist, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> Permissions-Policy: camera=(), microphone=(), geolocation=() (expected:" <<<"$out" || fail "expected a DRIFT line naming the wrong value, got: $out"
ok "an empty microphone allowlist (the failure mode that breaks getUserMedia) is caught, not silently accepted"

echo "4. a value with extra/reordered directives is DRIFT — exact match, not a substring/contains check"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tmicrophone=(self), camera=(), geolocation=(), fullscreen=(self)\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a reordered/extended value, got $rc: $out"
grep -q "^DRIFT" <<<"$out" || fail "expected a DRIFT line, got: $out"
ok "an unexpected extra directive or reordering is caught, not accepted as close enough"

echo
echo "PASS ($pass assertions)"
