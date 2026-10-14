#!/usr/bin/env bash
# alert-latch-ci-fallback.test.sh — regression test for bt-7727.
#
# Both scripts/lib/alert-latch.sh and scripts/lib/alert-latch.test.sh used to
# resolve donefile's canonical copy by a hardcoded absolute path with no
# fallback and no existence check. On a hosted CI runner (ubuntu-latest)
# /home/omri/projects/donefile does not exist, so the shim's `source` failed
# -- which downstream looked like check-heartbeat-alert-dedup.test.sh
# reporting "expected 1 notify, got 0" (confirmed on run 38380100889) -- and
# the test shim's `exec bash "$ALERT_LATCH_TEST"` exited 127 with no
# explanation.
#
# THIS TEST FAILS AGAINST THE PARENT COMMIT. Verified by hand 2026-10-14:
# checking out scripts/lib/alert-latch.sh from HEAD~1 (no [ -f ... ] ||
# fallback, no vendored file) and sourcing it with ALERT_LATCH_CANONICAL
# pointed at a path that does not exist makes the shim try to `source` that
# nonexistent path directly and fail with "No such file or directory" --
# notify_and_latch is never defined. Likewise HEAD~1's alert-latch.test.sh
# with ALERT_LATCH_TEST pointed at a missing path `exec`s it unconditionally
# and the whole test process exits 127, which this suite also catches below
# (case 2).
#
# ALERT_LATCH_CANONICAL is a test-only override the fix added to
# alert-latch.sh specifically so this can simulate "the canonical path is
# absent" without touching the real file on Omri's box -- see that file's
# own comment. It is never set by any real caller.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHIM="$HERE/alert-latch.sh"
TEST_SHIM="$HERE/alert-latch.test.sh"
VENDORED="$HERE/alert-latch.vendored.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
MISSING="$TMP/no-such-donefile-checkout/alert-latch.sh"

echo "1. alert-latch.sh: canonical absent -> falls back to the vendored pin, library still loads"
out="$(ALERT_LATCH_CANONICAL="$MISSING" timeout 10 bash -c \
  'set -uo pipefail; . "$1" || exit $?; declare -F notify_and_latch >/dev/null || { echo "notify_and_latch not defined"; exit 9; }' \
  _ "$SHIM" 2>&1)"
rc=$?
[ "$rc" -eq 0 ] || fail "expected the shim to load via the vendored fallback, got rc=$rc: $out"
ok "missing canonical falls back to the vendored pin and defines notify_and_latch"

echo "2. alert-latch.sh: canonical present -> the real canonical is sourced, not the vendored pin"
# A canary function only the vendored copy would define if it were used by
# mistake proves which file actually got sourced.
STUBDIR="$TMP/stub-canonical"; mkdir -p "$STUBDIR"
cat >"$STUBDIR/alert-latch.sh" <<'EOF'
notify_and_latch() { :; }
ALERT_LATCH_SOURCE_CANARY=real-canonical
EOF
out="$(ALERT_LATCH_CANONICAL="$STUBDIR/alert-latch.sh" timeout 10 bash -c \
  'set -uo pipefail; . "$1"; [ "${ALERT_LATCH_SOURCE_CANARY:-}" = "real-canonical" ]' \
  _ "$SHIM" 2>&1)"
rc=$?
[ "$rc" -eq 0 ] || fail "a present canonical must still be sourced over the vendored pin: $out"
ok "present canonical is sourced; the vendored pin is a fallback, not a default"

echo "3. alert-latch.sh: the vendored pin itself defines every function the canonical does"
[ -f "$VENDORED" ] || fail "scripts/lib/alert-latch.vendored.sh does not exist"
for fn in alert_latch_log notify_and_latch notify_and_latch_with_age notify_now; do
  out="$(ALERT_LATCH_CANONICAL="$MISSING" timeout 10 bash -c \
    'set -uo pipefail; . "$1"; declare -F "$2" >/dev/null' _ "$SHIM" "$fn" 2>&1)"
  [ $? -eq 0 ] || fail "vendored pin does not define $fn: $out"
done
ok "vendored pin defines alert_latch_log / notify_and_latch / notify_and_latch_with_age / notify_now"

echo "4. alert-latch.test.sh: shared suite absent -> skips cleanly (exit 0, reason printed), never 127"
out="$(ALERT_LATCH_TEST="$MISSING" timeout 10 bash "$TEST_SHIM" 2>&1)"
rc=$?
[ "$rc" -eq 0 ] || fail "expected a clean skip (exit 0) with the shared suite missing, got rc=$rc: $out"
grep -qi "skipping" <<<"$out" || fail "a clean skip must say why: $out"
ok "missing shared suite skips with exit 0 and a printed reason"

echo "5. alert-latch.test.sh: shared suite present -> actually runs it (exec), not a silent skip"
FAKE_SUITE="$TMP/fake-suite.sh"
cat >"$FAKE_SUITE" <<'EOF'
#!/usr/bin/env bash
echo "FAKE-SUITE-RAN"
exit 0
EOF
chmod +x "$FAKE_SUITE"
out="$(ALERT_LATCH_TEST="$FAKE_SUITE" timeout 10 bash "$TEST_SHIM" 2>&1)"
rc=$?
[ "$rc" -eq 0 ] || fail "expected the fake suite's own exit code (0), got rc=$rc: $out"
grep -q "FAKE-SUITE-RAN" <<<"$out" || fail "the test shim did not actually run the suite it was pointed at: $out"
ok "a present shared suite is run, not skipped"

if [ "$pass" -ne 5 ]; then
  echo "alert-latch-ci-fallback: expected 5 passing checks, got $pass"
  exit 1
fi
echo "alert-latch-ci-fallback: all passed"
