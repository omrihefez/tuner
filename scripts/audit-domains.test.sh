#!/usr/bin/env bash
# Regression test for scripts/audit-domains.sh (ma-20c5). Asserts the SUBS
# array cannot silently drift from ~/meni/DOMAIN.md again — the array had
# fallen to 8 hosts against a registry of 11 live/alias rows, missing
# `meniapp` (a real Vercel+live gap) and (correctly, but silently) omitting
# the two Cloudflare-Tunnel hosts `meniapp-api`/`tik-api`. Hermetic — no
# real ~/meni/DOMAIN.md, no network (CURL_CMD stub).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/audit-domains.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/DOMAIN.md"
FIXTURE_MAP="$TMP/responses.tsv"   # host<TAB>code<TAB>location

cat >"$FIXTURE" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `omrihefez.com` (apex) | Personal hub | *(none)* | Vercel | explicit | 🟠 blank | 404 |
| ~~`oldapp`~~ | sunset | old-repo | Vercel | wildcard | 🔴 removed | must NOT be audited |
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `meniapp` | Meni app | meniapp | Vercel | wildcard | 🟢 live | the ma-20c5 gap: real Vercel host missing from the old array |
| `meniapp-api` | worker orchestration | meniapp | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, must SKIP not FAIL |
EOF

CURL_STUB="$TMP/curl-stub.sh"
cat >"$CURL_STUB" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
host="$(echo "$url" | sed -E 's#https?://([^/]+)/?#\1#')"
row="$(awk -F'\t' -v h="$host" '$1 == h {print; exit}' "$CURL_FIXTURE_MAP")"
if [ -z "$row" ]; then
  printf 'HTTP/1.1 599 Unknown\r\n\r\n'
  exit 0
fi
code="$(cut -f2 <<<"$row")"
loc="$(cut -f3 <<<"$row")"
printf 'HTTP/1.1 %s Status\r\n' "$code"
[ -n "$loc" ] && printf 'location: %s\r\n' "$loc"
printf '\r\n'
EOF
chmod +x "$CURL_STUB"

run() { CURL_FIXTURE_MAP="$FIXTURE_MAP" DOMAIN_MD="$FIXTURE" CURL_CMD="$CURL_STUB" bash "$SCRIPT"; }

echo "1. a Vercel+live host missing from a hand-copied array (the ma-20c5 gap) is now checked"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t200\t\n' >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t200\t\n' >>"$FIXTURE_MAP"
printf 'meniapp-api.omrihefez.com\t404\t\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0, got $rc: $out"
grep -q "OK     meniapp.omrihefez.com -> 200" <<<"$out" || fail "expected meniapp to be actively checked, got: $out"
ok "meniapp is derived and checked, not missing"

echo "2. a tombstoned row is never audited"
grep -q "oldapp" <<<"$out" && fail "a 🔴 removed row must not appear at all, got: $out"
ok "tombstoned row excluded"

echo "3. a non-Vercel live host (Cloudflare Tunnel) is SKIPped, not run through the Vercel-gate check, and not silently dropped"
grep -q "^SKIP   meniapp-api.omrihefez.com" <<<"$out" || fail "expected an explicit SKIP line for meniapp-api, got: $out"
grep -q "^OK     meniapp-api" <<<"$out" && fail "meniapp-api's bare 404 must not be run through the Vercel OK/CHECK logic, got: $out"
ok "Cloudflare-Tunnel host is named via SKIP, its normal 404 never fails the run"

echo "4. a genuine Vercel Deployment-Protection redirect still fails loudly (bt-417b class)"
: >"$FIXTURE_MAP"
printf 'bass.omrihefez.com\t200\t\n' >>"$FIXTURE_MAP"
printf 'meniapp.omrihefez.com\t307\thttps://vercel.com/login\n' >>"$FIXTURE_MAP"
printf 'meniapp-api.omrihefez.com\t404\t\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 on a vercel.com login redirect, got $rc: $out"
grep -q "^DRIFT  meniapp.omrihefez.com" <<<"$out" || fail "expected a DRIFT line for the gated host, got: $out"
ok "the original bt-417b drift detection still fires"

echo "5. AUDIT_SUBS overrides the DOMAIN.md derivation entirely (test-monitoring.sh's bt-a942 self-test relies on this to force a failure)"
: >"$FIXTURE_MAP"
printf 'nonexistent-bt-a942-selftest.omrihefez.com\t404\t\n' >>"$FIXTURE_MAP"
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

echo
echo "PASS ($pass assertions)"
