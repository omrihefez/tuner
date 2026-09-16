#!/usr/bin/env bash
# Regression test for scripts/check-tunnel-liveness.sh (bt-8818). Hermetic —
# no real network, no real ~/meni/DOMAIN.md (CURL_CMD stub + DOMAIN_MD
# fixture, same pattern as audit-domains.test.sh).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/check-tunnel-liveness.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE="$TMP/DOMAIN.md"
FIXTURE_MAP="$TMP/responses.tsv"  # host+path<TAB>code

cat >"$FIXTURE" <<'EOF'
| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass Tuner | bass-tuner | Vercel | wildcard | 🟢 live | must NOT appear — Vercel-hosted |
| `oauth` | OAuth catcher | apartment | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, pinned |
| `house` | House control | house-control | Cloudflare Tunnel | explicit | 🟢 live | non-Vercel, pinned |
| ~~`retired`~~ | gone | none | Cloudflare Tunnel | none | 🔴 removed | tombstoned, must NOT appear |
EOF

CURL_STUB="$TMP/curl-stub.sh"
cat >"$CURL_STUB" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
row="$(awk -F'\t' -v u="$url" '$1 == u {print; exit}' "$CURL_FIXTURE_MAP")"
if [ -z "$row" ]; then
  echo "000"
  exit 0
fi
cut -f2 <<<"$row"
EOF
chmod +x "$CURL_STUB"

run() { CURL_FIXTURE_MAP="$FIXTURE_MAP" DOMAIN_MD="$FIXTURE" CURL_CMD="$CURL_STUB" bash "$SCRIPT"; }

echo "1. all pinned hosts answering as expected -> exit 0, Vercel host and tombstoned row excluded"
: >"$FIXTURE_MAP"
printf 'https://oauth.omrihefez.com/health\t200\n' >>"$FIXTURE_MAP"
printf 'https://house.omrihefez.com/\t307\n' >>"$FIXTURE_MAP"
out="$(run)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 on a clean pass, got $rc: $out"
grep -q "^ok       oauth.omrihefez.com/health -- HTTP 200" <<<"$out" && fail "unexpected format"
grep -q "ok       oauth.omrihefez.com/health" <<<"$out" || fail "expected oauth to be checked and OK, got: $out"
grep -q "ok       house.omrihefez.com/" <<<"$out" || fail "expected house to be checked and OK, got: $out"
grep -q "bass" <<<"$out" && fail "a Vercel-hosted host must never appear here (that's audit-domains.sh's job), got: $out"
grep -q "retired" <<<"$out" && fail "a tombstoned row must never appear, got: $out"
ok "clean pass: exit 0, only non-Vercel live hosts checked"

echo "2. a host that does not resolve (curl -> 000) fails the run — BEFORE: passes cleanly when it resolves"
: >"$FIXTURE_MAP"
printf 'https://oauth.omrihefez.com/health\t200\n' >>"$FIXTURE_MAP"
baseline_out="$(TUNNEL_HOSTS=oauth run)"; baseline_rc=$?
[ "$baseline_rc" -eq 0 ] || fail "baseline: oauth resolving with the pinned status should pass, got rc=$baseline_rc: $baseline_out"
ok "BEFORE: oauth resolving with its pinned status passes (rc=0)"

: >"$FIXTURE_MAP"
# no row for oauth -> stub returns 000, simulating DNS/TLS/connection failure
down_out="$(TUNNEL_HOSTS=oauth run 2>&1)"; down_rc=$?
[ "$down_rc" -ne 0 ] || fail "AFTER: expected non-zero exit when oauth does not resolve, got 0: $down_out"
grep -q "^DOWN" <<<"$down_out" || fail "expected a DOWN line for the unresolving host, got: $down_out"
ok "AFTER: a host that stops resolving fails the run (exit $down_rc), DOWN line names it"

echo "3. a host answering the WRONG pinned status fails the run — BEFORE: matching status passes"
: >"$FIXTURE_MAP"
printf 'https://house.omrihefez.com/\t307\n' >>"$FIXTURE_MAP"
match_out="$(TUNNEL_HOSTS=house run)"; match_rc=$?
[ "$match_rc" -eq 0 ] || fail "baseline: house answering its pinned 307 should pass, got rc=$match_rc: $match_out"
ok "BEFORE: house answering its pinned status (307) passes (rc=0)"

: >"$FIXTURE_MAP"
printf 'https://house.omrihefez.com/\t200\n' >>"$FIXTURE_MAP"
drift_out="$(TUNNEL_HOSTS=house run 2>&1)"; drift_rc=$?
[ "$drift_rc" -ne 0 ] || fail "AFTER: expected non-zero exit when house answers 200 instead of the pinned 307, got 0: $drift_out"
grep -q "^CHANGED.*expected 307" <<<"$drift_out" || fail "expected a CHANGED line naming the pinned status, got: $drift_out"
ok "AFTER: a host drifting off its pinned status fails the run (exit $drift_rc), CHANGED line names expected vs actual"

echo "4. a registry host with no pinned EXPECT_PATH/EXPECT_STATUS entry fails loudly instead of being silently skipped"
out="$(TUNNEL_HOSTS=nonexistent-bt-8818-selftest run 2>&1)"; rc=$?
[ "$rc" -ne 0 ] || fail "expected non-zero exit for an unpinned host, got 0: $out"
grep -q "^UNPINNED" <<<"$out" || fail "expected an UNPINNED line, got: $out"
ok "an unpinned host is a loud failure, not a silent gap"

echo "5. an unreadable DOMAIN.md fails loudly instead of running an empty check"
DOMAIN_MD="$TMP/does-not-exist.md" CURL_CMD="$CURL_STUB" CURL_FIXTURE_MAP="$FIXTURE_MAP" bash "$SCRIPT" >/tmp/tunnel-liveness-out-$$ 2>&1
rc=$?
rm -f /tmp/tunnel-liveness-out-$$
[ "$rc" -eq 2 ] || fail "expected exit 2 for a missing registry, got $rc"
ok "missing DOMAIN.md refuses to run rather than silently checking nothing"

echo
echo "PASS ($pass assertions)"
