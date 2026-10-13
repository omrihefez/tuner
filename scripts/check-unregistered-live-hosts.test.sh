#!/usr/bin/env bash
# Regression test for scripts/check-unregistered-live-hosts.sh (bt-1af4).
# Hermetic -- no real Vercel session, no real Cloudflare/Infisical
# credential, no dependence on which hosts actually exist on this box right
# now. Same VERCEL_ALIAS_CMD / CF_DNS_RECORDS_CMD full-bypass override
# convention as every other monitor's CURL_CMD stub in this repo.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/check-unregistered-live-hosts.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

DOMAIN_MD_FIXTURE="$TMP/DOMAIN.md"
cat >"$DOMAIN_MD_FIXTURE" <<'EOF'
# fixture registry

| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `house` | House control | house-control | Cloudflare Tunnel | explicit | 🟢 live | tunnel |
| ~~`arch-preview`~~ | retired staging alias | meni-arch | — | none | 🔴 removed | 404 by design, DNS record not yet cleaned up |
EOF

# --- Vercel alias fixture: a two-page response, so the test exercises the
# real pagination loop rather than only a single-page shortcut. Page 1
# names a REGISTERED host (bass); page 2 -- reachable only if the cursor is
# actually followed -- names an UNREGISTERED one (ghost-app). If pagination
# were broken (e.g. the cursor never advances), this test would see only
# page 1 and wrongly report a clean run.
VERCEL_FIXTURES="$TMP/vercel"
mkdir -p "$VERCEL_FIXTURES"
cat >"$VERCEL_FIXTURES/page-0.json" <<'EOF'
{"aliases":[{"alias":"bass.omrihefez.com","deploymentId":"dpl_1"},{"alias":"bass-tuner-git-pr-123.vercel.app","deploymentId":"dpl_2"}],"pagination":{"next":"c1"}}
EOF
cat >"$VERCEL_FIXTURES/page-c1.json" <<'EOF'
{"aliases":[{"alias":"ghost-app.omrihefez.com","deploymentId":"dpl_3"}],"pagination":{"next":null}}
EOF
VERCEL_STUB="$TMP/vercel-stub.sh"
cat >"$VERCEL_STUB" <<'EOF'
#!/usr/bin/env bash
cursor=""
if [ "${1:-}" = "--next" ]; then cursor="$2"; fi
if [ -z "$cursor" ]; then
  cat "$VERCEL_FIXTURE_DIR/page-0.json"
else
  cat "$VERCEL_FIXTURE_DIR/page-$cursor.json"
fi
EOF
chmod +x "$VERCEL_STUB"

# --- Cloudflare CNAME fixture: one registered tunnel host (house), one
# UNREGISTERED tunnel host (rogue-tunnel), one email-infra CNAME that must
# NOT be mistaken for a live app host (links -> Resend, not cfargotunnel),
# and the wildcard record itself (must never be reported as a "host").
CF_FIXTURE="$TMP/cf-cnames.json"
cat >"$CF_FIXTURE" <<'EOF'
{"success":true,"result":[
  {"type":"CNAME","name":"house.omrihefez.com","content":"b03113fc-live.cfargotunnel.com"},
  {"type":"CNAME","name":"rogue-tunnel.omrihefez.com","content":"deadbeef-rogue.cfargotunnel.com"},
  {"type":"CNAME","name":"links.omrihefez.com","content":"links1.resend-dns.com"},
  {"type":"CNAME","name":"*.omrihefez.com","content":"cname.vercel-dns-017.com"}
]}
EOF
CF_STUB="cat '$CF_FIXTURE'"

run() {
  VERCEL_FIXTURE_DIR="$VERCEL_FIXTURES" \
  VERCEL_ALIAS_CMD="$VERCEL_STUB" \
  CF_DNS_RECORDS_CMD="$CF_STUB" \
  DOMAIN_MD="$DOMAIN_MD_FIXTURE" \
  bash "$SCRIPT"
}

echo "1. DRIFT: an unregistered Vercel-aliased host AND an unregistered tunnel host are both caught, from different pages/sources"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (DRIFT) with two unregistered live hosts present, got $rc: $out"
grep -q "^DRIFT  ghost-app.omrihefez.com -> live via vercel-alias" <<<"$out" \
  || fail "expected a DRIFT line for ghost-app.omrihefez.com (page 2 of the Vercel alias pagination), got: $out"
grep -q "^DRIFT  rogue-tunnel.omrihefez.com -> live via cloudflare-tunnel" <<<"$out" \
  || fail "expected a DRIFT line for rogue-tunnel.omrihefez.com (Cloudflare CNAME to a live tunnel), got: $out"
ok "catches an unregistered host from page 2 of Vercel alias pagination and an unregistered Cloudflare tunnel CNAME"

echo "2. registered hosts from both sources report OK, not DRIFT"
grep -q "^OK     bass.omrihefez.com -> live via vercel-alias, registered" <<<"$out" \
  || fail "expected bass.omrihefez.com to report OK, got: $out"
grep -q "^OK     house.omrihefez.com -> live via cloudflare-tunnel, registered" <<<"$out" \
  || fail "expected house.omrihefez.com to report OK, got: $out"
ok "a registered host from either source is OK, never DRIFT"

echo "3. email-infra CNAME (not a cfargotunnel target) and the wildcard record itself are never reported as hosts at all"
if grep -q "links" <<<"$out"; then
  fail "links.omrihefez.com (Resend CNAME, not a tunnel) was reported as a host: $out"
fi
if grep -qE '^\S+\s+\*\.omrihefez|^\S+\s+\.omrihefez' <<<"$out"; then
  fail "the wildcard CNAME record itself was reported as a discovered host: $out"
fi
ok "non-tunnel CNAMEs (email infra, the wildcard record) are excluded from discovery entirely"

echo "4. AFTER: once ghost-app and rogue-tunnel are added to the registry, the exact same discovery clears to exit 0 — proves this is a real fail/pass probe"
cat >"$DOMAIN_MD_FIXTURE" <<'EOF'
# fixture registry

| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| `bass` | Bass tuner | bass-tuner | Vercel | wildcard | 🟢 live | canonical |
| `house` | House control | house-control | Cloudflare Tunnel | explicit | 🟢 live | tunnel |
| `ghost-app` | now registered | bass-tuner | Vercel | wildcard | 🟢 live | added |
| `rogue-tunnel` | now registered | house-control | Cloudflare Tunnel | explicit | 🟢 live | added |
EOF
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once both hosts are registered, got $rc: $out"
if grep -q "^DRIFT" <<<"$out"; then
  fail "expected zero DRIFT lines once both hosts are registered, got: $out"
fi
ok "the check clears to exit 0 once the missing registry rows are added — not a check that can only ever fail"

echo "5. a RETIRED host that still carries a stale non-tunnel CNAME (the real arch-preview shape) is never flagged as live"
# arch-preview is 🔴 removed in the fixture registry (not in REG_SET) but its
# DNS record was never in either discovery source to begin with (its CNAME
# targets cname.vercel-dns.com, not a cfargotunnel.com tunnel, and it has no
# Vercel alias in the fixture) -- so it must never appear in the output at
# all, confirming DNS presence alone is correctly never treated as liveness.
if grep -q "arch-preview" <<<"$out"; then
  fail "arch-preview (retired, stale generic-Vercel CNAME only) was reported as live: $out"
fi
ok "a retired host's stale non-tunnel DNS record is not mistaken for a live surface"

echo "6. CANNOT RUN (exit 2), never a false OK/DRIFT, when Vercel discovery itself fails"
BROKEN_STUB="$TMP/broken-vercel.sh"
cat >"$BROKEN_STUB" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$BROKEN_STUB"
out="$(VERCEL_FIXTURE_DIR="$VERCEL_FIXTURES" VERCEL_ALIAS_CMD="$BROKEN_STUB" CF_DNS_RECORDS_CMD="$CF_STUB" DOMAIN_MD="$DOMAIN_MD_FIXTURE" bash "$SCRIPT" 2>&1)"
rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2 (CANNOT RUN) when the Vercel alias fetch fails, got $rc: $out"
grep -q "^CANNOT RUN" <<<"$out" || fail "expected a CANNOT RUN line, got: $out"
ok "a failed Vercel discovery fails closed (exit 2), never read as a clean/empty result"

echo "7. CANNOT RUN (exit 2) when the registry itself derives zero live/alias hosts"
EMPTY_DOMAIN_MD="$TMP/empty-DOMAIN.md"
cat >"$EMPTY_DOMAIN_MD" <<'EOF'
# fixture registry, nothing live

| Subdomain | Purpose / app | Repo | Host | DNS | Status | Notes |
|---|---|---|---|---|---|---|
| ~~`gone`~~ | sunset | none | — | none | 🔴 removed | nothing live here |
EOF
out="$(VERCEL_FIXTURE_DIR="$VERCEL_FIXTURES" VERCEL_ALIAS_CMD="$VERCEL_STUB" CF_DNS_RECORDS_CMD="$CF_STUB" DOMAIN_MD="$EMPTY_DOMAIN_MD" bash "$SCRIPT" 2>&1)"
rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2 (CANNOT RUN) with an empty registry, got $rc: $out"
ok "an empty registry fails closed rather than reporting every live host as DRIFT or silently passing"

echo
echo "All $pass checks passed."
