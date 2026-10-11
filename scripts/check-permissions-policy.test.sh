#!/usr/bin/env bash
# Regression test for scripts/check-permissions-policy.sh (bt-40c5 / bt-5c8e).
# Hermetic -- no real network, no real ~/meni/DOMAIN.md (CURL_CMD stub +
# DOMAIN_MD fixture, same pattern as audit-domains.test.sh /
# check-tunnel-liveness.test.sh).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/check-permissions-policy.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/DOMAIN.md"
FIXTURE_MAP="$TMP/responses.tsv"  # host<TAB>permissions-policy value (empty = header absent)

cat >"$FIXTURE" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | mic-using, value-checked |
| `house` | House control | house-control | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, still sends the header |
| ~~`retired`~~ | gone | none | Cloudflare Tunnel | none | 🔴 removed | tombstoned, must NOT appear |
EOF

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

run() { CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" DOMAIN_MD="$FIXTURE" bash "$SCRIPT"; }
run_hosts() { CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" PP_HOSTS="$1" bash "$SCRIPT"; }

echo "1. BEFORE (the live pre-bt-5c8e shape): bass with NO Permissions-Policy header fails loudly"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t\n' >>"$FIXTURE_MAP"
printf 'house.omrihefez.com\tcamera=(), microphone=(), geolocation=()\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 when a tracked host's header is absent, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> no Permissions-Policy header sent (expected:" <<<"$out" || fail "expected a DRIFT line naming the absence, got: $out"
ok "a tracked host (bass) losing its header entirely is a loud DRIFT, not a silent skip"

echo "2. AFTER: bass and house both send their correct recorded value -> exit 0, tombstoned row excluded"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tcamera=(), microphone=(self), geolocation=()\n' >>"$FIXTURE_MAP"
printf 'house.omrihefez.com\tcamera=(), microphone=(), geolocation=()\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 with correct values, got $rc: $out"
grep -q "^OK     bass.omrihefez.com -> Permissions-Policy: camera=(), microphone=(self), geolocation=()" <<<"$out" || fail "expected an OK line for bass, got: $out"
grep -q "^OK     house.omrihefez.com -> Permissions-Policy: camera=(), microphone=(), geolocation=()" <<<"$out" || fail "expected an OK line for house, got: $out"
grep -q "retired" <<<"$out" && fail "a tombstoned row must never appear, got: $out"
ok "both hosts match their recorded value: exit 0, tombstoned row excluded"

echo "3. a wrong/widened value (geolocation=* widened from geolocation=()) is DRIFT, not a false pass -- demonstrated red here, then proven red against the parent commit below"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tcamera=(), microphone=(self), geolocation=()\n' >>"$FIXTURE_MAP"
printf 'house.omrihefez.com\tcamera=(), microphone=(), geolocation=*\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a widened value, got $rc: $out"
grep -q "^DRIFT  house.omrihefez.com -> Permissions-Policy: camera=(), microphone=(), geolocation=\* (expected:" <<<"$out" || fail "expected a DRIFT line naming the widened value, got: $out"
ok "a widened value (geolocation=* instead of geolocation=()) is caught, not silently accepted"

echo "4. the empty-microphone-allowlist mistake (the original mic-breaking bug) is still caught for bass"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tcamera=(), microphone=(), geolocation=()\n' >>"$FIXTURE_MAP"
out="$(run_hosts bass 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for an empty microphone allowlist, got $rc: $out"
grep -q "^DRIFT  bass.omrihefez.com -> Permissions-Policy: camera=(), microphone=(), geolocation=() (expected:" <<<"$out" || fail "expected a DRIFT line naming the wrong value, got: $out"
ok "an empty microphone allowlist (the failure mode that breaks getUserMedia) is still caught"

echo "5. a host sending the header with NO recorded expected value fails loudly as UNPINNED, not a silent OK -- bt-5c8e's actual point: a new header-sending host does not get silent presence-only coverage"
: >"$FIXTURE_MAP"
printf 'newhost.omrihefez.com\tcamera=(), microphone=(), geolocation=()\n' >>"$FIXTURE_MAP"
out="$(run_hosts newhost 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for an unpinned header-sending host, got $rc: $out"
grep -q "^UNPINNED newhost.omrihefez.com -> sends Permissions-Policy:" <<<"$out" || fail "expected an UNPINNED line, got: $out"
ok "an unrecorded host that starts sending the header is a loud UNPINNED failure, not a silent gap"

echo "6. an untracked host sending NO header at all is silently skipped (presence-only coverage is audit-domains.sh's job, not this script's)"
: >"$FIXTURE_MAP"
printf 'untracked.omrihefez.com\t\n' >>"$FIXTURE_MAP"
out="$(run_hosts untracked)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 -- an untracked, header-silent host is not this script's concern, got $rc: $out"
grep -q "untracked" <<<"$out" && fail "an untracked host with no header should not be mentioned at all, got: $out"
ok "an untracked host sending no header is silently skipped -- not this script's job"

echo "7. HOST LIST comes from the registry (derive_registry_hosts), not a hand-maintained list -- bass and house both appear with no PP_HOSTS override, the tombstoned row never does"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\tcamera=(), microphone=(self), geolocation=()\n' >>"$FIXTURE_MAP"
printf 'house.omrihefez.com\tcamera=(), microphone=(), geolocation=()\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0, got $rc: $out"
grep -q "bass.omrihefez.com" <<<"$out" || fail "expected bass (a registry-derived Vercel host) to be checked, got: $out"
grep -q "house.omrihefez.com" <<<"$out" || fail "expected house (a registry-derived non-Vercel host) to also be checked -- mode must be 'all', not 'vercel', got: $out"
ok "hosts are derived from the registry in 'all' mode, covering non-Vercel senders like house too"

echo "8. an unreadable DOMAIN.md (and no PP_HOSTS override) refuses to run rather than silently checking nothing"
: >"$FIXTURE_MAP"
out="$(DOMAIN_MD="$TMP/does-not-exist.md" CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" bash "$SCRIPT" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2 for a missing registry, got $rc: $out"
ok "missing DOMAIN.md refuses to run rather than silently checking nothing"

echo
echo "PASS ($pass assertions)"
