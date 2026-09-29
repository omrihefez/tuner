#!/usr/bin/env bash
# Regression test for scripts/check-model-ids-resolve.sh (bt-5abe). Hermetic
# -- no real network, no real API key, no dependence on which repos or model
# strings actually exist on this box right now. Same CURL_CMD-stub
# convention as check-permissions-policy.test.sh / audit-domains.test.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/check-model-ids-resolve.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FIXTURE_MAP="$TMP/model-codes.tsv"   # model-id<TAB>http-code

CURL_STUB="$TMP/curl-stub.sh"
cat >"$CURL_STUB" <<'EOF'
#!/usr/bin/env bash
url="${@: -1}"
model="${url##*/models/}"
row="$(awk -F'\t' -v m="$model" '$1 == m {print; exit}' "$CURL_FIXTURE_MAP")"
code="$(cut -f2 <<<"$row")"
[ -z "$code" ] && code=000
printf '%s' "$code"
EOF
chmod +x "$CURL_STUB"

SCAN_DIR="$TMP/scan-root"
mkdir -p "$SCAN_DIR/repo-a/scripts" "$SCAN_DIR/repo-b/src"

run() {
  MODEL_SCAN_ROOTS="$SCAN_DIR/repo-a/ $SCAN_DIR/repo-b/" \
  CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" \
  GEMINI_API_KEY="fake-key-for-test" \
  bash "$SCRIPT"
}

echo "1. DISCOVERY SHAPE: a real model-ID-shaped string is found, but a GCP project id and a service-account name that merely start with 'gemini-' are not"
cat >"$SCAN_DIR/repo-a/scripts/ai.py" <<'EOF'
MODEL = "gemini-9.9-flash-doesnotexist"
PROJECT = "gemini-free-tier-2026"
SA = "gemini-key-mgr@gemini-free-tier-2026.iam.gserviceaccount.com"
EOF
: >"$SCAN_DIR/repo-b/src/empty.ts"
: >"$FIXTURE_MAP"
printf 'gemini-9.9-flash-doesnotexist\t404\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (DRIFT) for the one real model-shaped string, got $rc: $out"
grep -q "gemini-9.9-flash-doesnotexist:404" <<<"$out" || fail "expected the DRIFT line to name the model, got: $out"
if grep -qE "gemini-free-tier-2026:|gemini-key-mgr:" <<<"$out"; then
  fail "the GCP project id / service-account name were treated as model IDs and checked against the API: $out"
fi
ok "the shape regex discovers a real model ID and skips the project-id/service-account lookalikes"

echo "2. BEFORE: a model ID that 404s against the provider is real DRIFT, not a clean pass"
: >"$SCAN_DIR/repo-a/scripts/ai.py"
echo 'MODEL = "gemini-9.9-flash-doesnotexist"' >"$SCAN_DIR/repo-a/scripts/ai.py"
: >"$FIXTURE_MAP"
printf 'gemini-9.9-flash-doesnotexist\t404\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 when the model 404s, got $rc: $out"
grep -q "^DRIFT" <<<"$out" || fail "expected a DRIFT line, got: $out"
ok "a retired/nonexistent model ID is caught as DRIFT (exit 1)"

echo "3. AFTER: the same check against the same model ID once it resolves clears — proves this is a real fail/pass probe, not a check that can only ever fail"
: >"$FIXTURE_MAP"
printf 'gemini-9.9-flash-doesnotexist\t200\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "expected exit 0 once the model resolves, got $rc: $out"
grep -q "^OK" <<<"$out" || fail "expected an OK line, got: $out"
ok "the check flips to OK once the provider actually answers 200"

echo "4. an invalid/rejected API key (401/403) is CANNOT RUN, never read as 'every model resolves'"
: >"$FIXTURE_MAP"
printf 'gemini-9.9-flash-doesnotexist\t403\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2 (CANNOT RUN) for a rejected key, got $rc: $out"
grep -q "^CANNOT RUN: Gemini API key rejected" <<<"$out" || fail "expected a CANNOT RUN / key-rejected line, got: $out"
ok "an invalid API key exits 2 (CANNOT RUN), distinct from both OK (0) and DRIFT (1)"

echo "5. no API key at all (and no readable vault auth file) is also CANNOT RUN, not a silent pass"
: >"$FIXTURE_MAP"
printf 'gemini-9.9-flash-doesnotexist\t200\n' >>"$FIXTURE_MAP"
out="$(
  MODEL_SCAN_ROOTS="$SCAN_DIR/repo-a/ $SCAN_DIR/repo-b/" \
  CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" \
  MENI_AUTH_ENV="$TMP/does-not-exist.env" \
  bash "$SCRIPT" 2>&1
)"; rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2 (CANNOT RUN) with no key and no vault access, got $rc: $out"
grep -q "^CANNOT RUN: no GEMINI_API_KEY set" <<<"$out" || fail "expected the no-key CANNOT RUN line, got: $out"
ok "a missing API key with no vault fallback exits 2 (CANNOT RUN), not 0"

echo "6. zero discovered model IDs is CANNOT RUN — a monitor that silently checks nothing must not read as a clean pass"
EMPTY_DIR="$TMP/empty-scan"
mkdir -p "$EMPTY_DIR/repo/src"
: >"$EMPTY_DIR/repo/src/nothing.ts"
out="$(
  MODEL_SCAN_ROOTS="$EMPTY_DIR/repo/" \
  CURL_FIXTURE_MAP="$FIXTURE_MAP" CURL_CMD="$CURL_STUB" \
  GEMINI_API_KEY="fake-key-for-test" \
  bash "$SCRIPT" 2>&1
)"; rc=$?
[ "$rc" -eq 2 ] || fail "expected exit 2 (CANNOT RUN) with 0 discovered model IDs, got $rc: $out"
grep -q "^CANNOT RUN: discovered 0 model IDs" <<<"$out" || fail "expected the 0-discovered CANNOT RUN line, got: $out"
ok "discovering 0 model IDs exits 2 rather than trivially passing"

echo "7. two discovered model IDs, one healthy and one retired — reported per-model, not all-or-nothing"
: >"$SCAN_DIR/repo-a/scripts/ai.py"
printf 'A = "gemini-2.5-flash"\nB = "gemini-9.9-flash-doesnotexist"\n' >"$SCAN_DIR/repo-a/scripts/ai.py"
: >"$FIXTURE_MAP"
printf 'gemini-2.5-flash\t200\n' >>"$FIXTURE_MAP"
printf 'gemini-9.9-flash-doesnotexist\t404\n' >>"$FIXTURE_MAP"
out="$(run 2>&1)"; rc=$?
[ "$rc" -eq 1 ] || fail "expected exit 1 (one of two is DRIFT), got $rc: $out"
grep -q "gemini-9.9-flash-doesnotexist:404" <<<"$out" || fail "expected the retired model named in the DRIFT line, got: $out"
if grep -q "gemini-2.5-flash:" <<<"$out"; then
  fail "the healthy model was also listed as DRIFT, discrimination is not per-model: $out"
fi
ok "a healthy model and a retired model discovered together are reported separately, not lumped as one verdict"

echo
echo "PASS ($pass assertions)"
