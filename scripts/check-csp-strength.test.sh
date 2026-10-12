#!/usr/bin/env bash
# Regression test for scripts/check-csp-strength.sh (bt-5059).
# Hermetic -- no real network, no real ~/meni/DOMAIN.md (CURL_CMD stub +
# DOMAIN_MD fixture, same pattern as check-permissions-policy.test.sh /
# audit-domains.test.sh).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/check-csp-strength.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/DOMAIN.md"
FIXTURE_MAP="$TMP/responses.tsv"  # host<TAB>csp value (empty = header absent)

cat >"$FIXTURE" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `clean` | clean app | fixture | Vercel | wildcard | 🟢 live | tight CSP, no issues |
| `brain` | API backend | fixture | Cloudflare Tunnel | explicit | 🟢 live | real NO_CSP_REASON entry in the script under test, reused here so the registry-derivation test doesn't need its own exemption entry |
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
  csp="$(cut -f2 <<<"$row")"
  [ -n "$csp" ] && printf 'content-security-policy: %s\r\n' "$csp"
fi
printf '\r\n'
EOF
chmod +x "$CURL_STUB"

run() { CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" DOMAIN_MD="$FIXTURE" bash "$SCRIPT"; }
run_hosts() { CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" CSP_HOSTS="$1" bash "$SCRIPT"; }

echo "1. the live finding this script exists to catch: script-src 'unsafe-inline' goes red"
: >"$FIXTURE_MAP"
printf 'trips-fixture.omrihefez.com\tdefault-src '"'"'self'"'"'; script-src '"'"'self'"'"' '"'"'unsafe-inline'"'"' https://challenges.cloudflare.com; style-src '"'"'self'"'"' '"'"'unsafe-inline'"'"'\n' >>"$FIXTURE_MAP"
out="$(run_hosts trips-fixture 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for script-src 'unsafe-inline', got $rc: $out"
grep -q "^DRIFT  trips-fixture.omrihefez.com -> script-src has 'unsafe-inline'" <<<"$out" || fail "expected a DRIFT line naming script-src unsafe-inline, got: $out"
ok "script-src 'unsafe-inline' (the real trips finding) goes red"

echo "2. script-src 'unsafe-eval' goes red"
: >"$FIXTURE_MAP"
printf 'evalhost.omrihefez.com\tdefault-src '"'"'self'"'"'; script-src '"'"'self'"'"' '"'"'unsafe-eval'"'"'\n' >>"$FIXTURE_MAP"
out="$(run_hosts evalhost 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for script-src 'unsafe-eval', got $rc: $out"
grep -q "unsafe-eval" <<<"$out" || fail "expected unsafe-eval to be named, got: $out"
ok "script-src 'unsafe-eval' goes red"

echo "3. a bare https: wildcard in img-src (the real tik finding) goes red -- a real origin like https://example.com in img-src does NOT trip it"
: >"$FIXTURE_MAP"
printf 'tik-fixture.omrihefez.com\tdefault-src '"'"'self'"'"'; script-src '"'"'self'"'"'; img-src '"'"'self'"'"' data: https:\n' >>"$FIXTURE_MAP"
out="$(run_hosts tik-fixture 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a bare https: wildcard in img-src, got $rc: $out"
grep -q "img-src has a bare wildcard origin" <<<"$out" || fail "expected img-src wildcard to be named, got: $out"
ok "bare https: wildcard in img-src (the real tik finding) goes red"

: >"$FIXTURE_MAP"
printf 'realorigin.omrihefez.com\tdefault-src '"'"'self'"'"'; script-src '"'"'self'"'"'; img-src '"'"'self'"'"' https://cdn.example.com; object-src '"'"'none'"'"'; base-uri '"'"'self'"'"'; frame-ancestors '"'"'none'"'"'\n' >>"$FIXTURE_MAP"
out="$(run_hosts realorigin 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "a real origin (https://cdn.example.com) in img-src must NOT be read as a bare wildcard, got $rc: $out"
ok "a real https:// origin in img-src is not a false positive"

echo "4. a bare * wildcard in script-src goes red too"
: >"$FIXTURE_MAP"
printf 'starhost.omrihefez.com\tdefault-src '"'"'self'"'"'; script-src *\n' >>"$FIXTURE_MAP"
out="$(run_hosts starhost 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a bare * in script-src, got $rc: $out"
grep -q "script-src has a bare wildcard origin" <<<"$out" || fail "expected script-src wildcard to be named, got: $out"
ok "bare * wildcard in script-src goes red"

echo "5. style-src 'unsafe-inline' is a DELIBERATE exemption -- must NOT fail on its own"
: >"$FIXTURE_MAP"
printf 'styleonly.omrihefez.com\tdefault-src '"'"'self'"'"'; script-src '"'"'self'"'"'; style-src '"'"'self'"'"' '"'"'unsafe-inline'"'"'; object-src '"'"'none'"'"'; base-uri '"'"'self'"'"'; frame-ancestors '"'"'none'"'"'\n' >>"$FIXTURE_MAP"
out="$(run_hosts styleonly 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "style-src 'unsafe-inline' alone must not fail (deliberate exemption), got $rc: $out"
grep -q "^OK     styleonly.omrihefez.com" <<<"$out" || fail "expected an OK line, got: $out"
ok "style-src 'unsafe-inline' alone passes clean (deliberate estate-wide exemption)"

echo "6. style-src 'unsafe-eval' is NOT exempt -- only 'unsafe-inline' is"
: >"$FIXTURE_MAP"
printf 'styleeval.omrihefez.com\tdefault-src '"'"'self'"'"'; script-src '"'"'self'"'"'; style-src '"'"'self'"'"' '"'"'unsafe-eval'"'"'\n' >>"$FIXTURE_MAP"
out="$(run_hosts styleeval 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for style-src 'unsafe-eval' (only unsafe-inline is exempt), got $rc: $out"
grep -q "style-src has 'unsafe-eval'" <<<"$out" || fail "expected style-src unsafe-eval to be named, got: $out"
ok "style-src 'unsafe-eval' still goes red -- only 'unsafe-inline' is exempt"

echo "7. a fully clean CSP passes, tombstoned row excluded"
: >"$FIXTURE_MAP"
printf "clean.omrihefez.com\\tdefault-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'\\n" >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 for a clean CSP, got $rc: $out"
grep -q "retired" <<<"$out" && fail "a tombstoned row must never appear, got: $out"
ok "a fully clean CSP passes, tombstoned row excluded"

echo "8. a missing CSP header on an UNEXEMPT host is a loud DRIFT"
: >"$FIXTURE_MAP"
printf 'noheader.omrihefez.com\t\n' >>"$FIXTURE_MAP"
out="$(run_hosts noheader 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a missing CSP header, got $rc: $out"
grep -q "^DRIFT  noheader.omrihefez.com -> no Content-Security-Policy header sent" <<<"$out" || fail "expected a DRIFT line naming the absence, got: $out"
ok "a missing CSP header on an unexempt host is a loud DRIFT"

echo "9. a missing CSP header on a DECLARED exemption (e.g. an API/tunnel backend) passes with a named reason, not a silent skip"
: >"$FIXTURE_MAP"
printf 'meniapp-api.omrihefez.com\t\n' >>"$FIXTURE_MAP"
out="$(run_hosts meniapp-api 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 for a declared exemption, got $rc: $out"
grep -q "^OK     meniapp-api.omrihefez.com -> no Content-Security-Policy header, exempt:" <<<"$out" || fail "expected a named-reason OK line, got: $out"
ok "a declared no-CSP exemption passes with its reason stated, not a silent skip"

echo "10. default-src fallback: a host with ONLY default-src 'unsafe-inline' (no explicit script-src) is still caught"
: >"$FIXTURE_MAP"
printf "fallback.omrihefez.com\\tdefault-src 'self' 'unsafe-inline'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts fallback 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 via the default-src fallback, got $rc: $out"
grep -q "script-src has 'unsafe-inline'" <<<"$out" || fail "expected the fallback to be read as script-src, got: $out"
ok "default-src fallback is used when script-src is absent (browser CSP fallback semantics)"

echo "11. default-src 'none' with no script-src/img-src/style-src at all (the real oauth.omrihefez.com shape) is clean, not a false positive -- including base-uri 'none' (not 'self') being accepted as the stricter, equally safe value"
: >"$FIXTURE_MAP"
printf "noneonly.omrihefez.com\\tdefault-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts noneonly 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 for a default-src 'none' policy (base-uri 'none', the real oauth.omrihefez.com shape), got $rc: $out"
ok "default-src 'none' with no further directives is clean, base-uri 'none' accepted"

echo "12. HOST LIST comes from the registry (derive_registry_hosts), not a hand-maintained list -- clean and brain both appear with no CSP_HOSTS override, the tombstoned row never does"
: >"$FIXTURE_MAP"
printf "clean.omrihefez.com\\tdefault-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'\\n" >>"$FIXTURE_MAP"
printf 'brain.omrihefez.com\t\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0, got $rc: $out"
grep -q "clean.omrihefez.com" <<<"$out" || fail "expected clean (a registry-derived host) to be checked, got: $out"
grep -q "brain.omrihefez.com" <<<"$out" || fail "expected brain (a registry-derived, NO_CSP_REASON-exempt host) to also be checked, got: $out"
ok "host list is derived from the registry in 'all' mode, covering a declared exemption too"

echo "13. object-src missing entirely (the real bass/planner/trips finding, bt-2c67) goes red via the default-src fallback"
: >"$FIXTURE_MAP"
printf "noobjsrc.omrihefez.com\\tdefault-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; base-uri 'self'; frame-ancestors 'none'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts noobjsrc 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a missing object-src, got $rc: $out"
grep -q "object-src missing 'none'" <<<"$out" || fail "expected object-src missing 'none' to be named, got: $out"
ok "object-src missing entirely goes red (the real bass/planner/trips finding)"

echo "14. object-src set but not 'none' (e.g. 'self') still goes red -- not just an absence check"
: >"$FIXTURE_MAP"
printf "objself.omrihefez.com\\tdefault-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; object-src 'self'; base-uri 'self'; frame-ancestors 'none'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts objself 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for object-src 'self' (not 'none'), got $rc: $out"
grep -q "object-src missing 'none'" <<<"$out" || fail "expected object-src missing 'none' to be named, got: $out"
ok "object-src 'self' (not 'none') still goes red"

echo "15. base-uri missing entirely goes red -- no default-src fallback covers it"
: >"$FIXTURE_MAP"
printf "nobaseuri.omrihefez.com\\tdefault-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; object-src 'none'; frame-ancestors 'none'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts nobaseuri 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a missing base-uri, got $rc: $out"
grep -q "base-uri missing 'self' or 'none'" <<<"$out" || fail "expected base-uri missing to be named, got: $out"
ok "base-uri missing entirely goes red"

echo "16. base-uri 'none' alone (distinct from 'self') passes -- both are accepted, isolated from the oauth-shape integration test above"
: >"$FIXTURE_MAP"
printf "basenone.omrihefez.com\\tdefault-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts basenone 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 for base-uri 'none', got $rc: $out"
ok "base-uri 'none' alone passes (both 'self' and 'none' are accepted)"

echo "17. frame-ancestors missing entirely goes red -- no default-src fallback covers it"
: >"$FIXTURE_MAP"
printf "noframeanc.omrihefez.com\\tdefault-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; object-src 'none'; base-uri 'self'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts noframeanc 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for a missing frame-ancestors, got $rc: $out"
grep -q "frame-ancestors missing 'none'" <<<"$out" || fail "expected frame-ancestors missing to be named, got: $out"
ok "frame-ancestors missing entirely goes red"

echo "18. frame-ancestors 'self' (present but wrong value) still goes red -- only 'none' is accepted"
: >"$FIXTURE_MAP"
printf "frameself.omrihefez.com\\tdefault-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'self'\\n" >>"$FIXTURE_MAP"
out="$(run_hosts frameself 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 for frame-ancestors 'self' (only 'none' accepted), got $rc: $out"
grep -q "frame-ancestors missing 'none'" <<<"$out" || fail "expected frame-ancestors missing 'none' to be named, got: $out"
ok "frame-ancestors 'self' (wrong value) still goes red"

echo "19. an unreadable DOMAIN.md (and no CSP_HOSTS override) refuses to run rather than silently checking nothing"
out="$(DOMAIN_MD="$TMP/does-not-exist.md" CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" bash "$SCRIPT" 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2 for a missing registry, got $rc: $out"
ok "missing DOMAIN.md refuses to run rather than silently checking nothing"

echo
echo "PASS ($pass assertions)"
