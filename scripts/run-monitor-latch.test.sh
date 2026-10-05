#!/usr/bin/env bash
# Regression test for bt-7964: run-monitor.sh latches a failure alert on a
# sha256 fingerprint of the monitor's output via lib/alert-latch.sh, so a
# PERSISTENT failure alerts once instead of once a day forever. bt-5149 is
# the observed instance of the bug this closes: the same
# albumclub.omrihefez.com 404 re-alarmed daily for over a week with nothing
# changed. Deliberately hermetic and deterministic -- unlike
# test-monitoring.sh's crontab-presence checks, nothing here depends on the
# live crontab, so it carries none of that suite's documented
# concurrent-rewrite race (bt-d30a).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$HERE/run-monitor.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# bt-0803: run-monitor.sh appends to $HOME/.cache/bass-tuner-<name>.log
# forever by design for a REAL monitor with a stable name, but this test
# mints a fresh name every run ($$), so that log is a throwaway fixture, not
# a real monitor's history -- it must not accumulate. Sweep dead runs' leftover
# fixtures from $HOME/.cache first: a SIGKILL or a bare `exec` runs no EXIT
# trap, so cleanup-on-exit can never be complete on its own, and these are the
# strays that already built up. Keyed on PID so a concurrent run's still-live
# fixture is never swept out from under it.
sweep_stale_latch_fixtures() {
  local f pid
  for f in "$HOME"/.cache/bass-tuner-latch-test-bt7964-*.log \
           "$HOME"/.cache/bass-tuner-latch-test-bt7964-*.alert-latch \
           "$HOME"/.cache/bass-tuner-latch-test-bt7964-*.alert-latch.undelivered; do
    [ -e "$f" ] || continue
    pid="$(basename "$f")"
    pid="${pid#bass-tuner-latch-test-bt7964-}"
    pid="${pid%%.*}"
    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    [[ "$pid" == "$$" ]] && continue
    kill -0 "$pid" 2>/dev/null && continue
    rm -f "$f"
  done
}
sweep_stale_latch_fixtures

NAME="latch-test-bt7964-$$"
FLAKY="$TMP/flaky.sh"
OUTPUT_FILE="$TMP/output.txt"
LOG="$HOME/.cache/bass-tuner-${NAME}.log"
LATCH="$HOME/.cache/bass-tuner-${NAME}.alert-latch"
inbox() { echo "$HOME/inbox/bass-tuner-${NAME}-$(date -I).md"; }
rm -f "$(inbox)" "$LATCH" "${LATCH}.undelivered" "$LOG"
cleanup() { rm -f "$(inbox)" "$LATCH" "${LATCH}.undelivered" "$LOG"; }
trap 'cleanup; rm -rf "$TMP"' EXIT

fails() {
  cat > "$FLAKY" <<'EOF'
#!/usr/bin/env bash
cat "$OUTPUT_FILE"
exit 1
EOF
  chmod +x "$FLAKY"
}
passes() {
  cat > "$FLAKY" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod +x "$FLAKY"
}

echo "1. first occurrence of a failure alerts"
fails
echo "same failure every time" > "$OUTPUT_FILE"
env OUTPUT_FILE="$OUTPUT_FILE" "$RUNNER" "$NAME" "$FLAKY" >/dev/null 2>&1
[ -f "$(inbox)" ] || fail "first occurrence did not write an inbox alert"
ok "first occurrence of a failure alerts"
rm -f "$(inbox)"

echo "2. a byte-identical repeat failure does NOT re-alert (the bt-5149 bug)"
env OUTPUT_FILE="$OUTPUT_FILE" "$RUNNER" "$NAME" "$FLAKY" >/dev/null 2>&1
[ -f "$(inbox)" ] && fail "identical repeat failure re-alerted (bt-5149's daily-nag bug)"
ok "identical repeat failure does not re-alert"

echo "3. a genuinely different failure fingerprint alerts again"
echo "different failure now" > "$OUTPUT_FILE"
env OUTPUT_FILE="$OUTPUT_FILE" "$RUNNER" "$NAME" "$FLAKY" >/dev/null 2>&1
[ -f "$(inbox)" ] || fail "a changed failure fingerprint did not re-alert"
ok "a changed failure fingerprint alerts again"
rm -f "$(inbox)"

echo "4. a resolve-then-regress cycle re-alerts even with the same fingerprint as before"
passes
env OUTPUT_FILE="$OUTPUT_FILE" "$RUNNER" "$NAME" "$FLAKY" >/dev/null 2>&1
fails
env OUTPUT_FILE="$OUTPUT_FILE" "$RUNNER" "$NAME" "$FLAKY" >/dev/null 2>&1
[ -f "$(inbox)" ] || fail "same failure did not re-alert after an intervening pass"
ok "resolve-then-regress re-alerts (ma-c1b2: never permanent silence)"

echo
echo "PASS ($pass assertions)"
