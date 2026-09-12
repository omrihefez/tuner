#!/usr/bin/env bash
# Regression test for bt-47e9: check-monitor-heartbeats.sh and
# check-heartbeat-liveness.sh used to call meni-notify unconditionally on
# every tick for as long as a monitor stayed stale/missing -- same class of
# bug as th-b15d (trips-hub's heal-dev-alias.sh re-sent one message 65 times
# in eight hours). Deliberately hermetic like run-monitor-latch.test.sh:
# a stub meni-notify under a fake $HOME just counts calls, no real hub/
# Telegram traffic and no live crontab.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HB="$HERE/check-monitor-heartbeats.sh"
LIVENESS="$HERE/check-heartbeat-liveness.sh"

pass=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "  ok — $*"; pass=$((pass + 1)); }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME/.cache" "$FAKE_HOME/meni/bin"
COUNT_FILE="$TMP/notify-count"
: > "$COUNT_FILE"

cat > "$FAKE_HOME/meni/bin/meni-notify" <<EOF
#!/usr/bin/env bash
echo call >> "$COUNT_FILE"
exit 0
EOF
chmod +x "$FAKE_HOME/meni/bin/meni-notify"

count() { wc -l < "$COUNT_FILE" | tr -d ' '; }

stale_log() {
  cat > "$FAKE_HOME/.cache/bass-tuner-fallback-cert.log" <<EOF
=== fallback-cert $(date -d '40 days ago' -Is) ===
exit 0
EOF
}
fresh_log() {
  cat > "$FAKE_HOME/.cache/bass-tuner-fallback-cert.log" <<EOF
=== fallback-cert $(date -Is) ===
exit 0
EOF
}

echo "--- check-monitor-heartbeats.sh (per-monitor dedup) ---"

echo "1. first tick of a stale monitor alerts"
stale_log
env HOME="$FAKE_HOME" "$HB" fallback-cert >/dev/null 2>&1
[ "$(count)" = "1" ] || fail "expected 1 notify after first stale tick, got $(count)"
ok "first stale tick alerts"

echo "2. three more ticks of the SAME staleness do not re-alert"
for _ in 1 2 3; do
  env HOME="$FAKE_HOME" "$HB" fallback-cert >/dev/null 2>&1
done
[ "$(count)" = "1" ] || fail "persistent staleness re-alerted (bt-47e9's bug) -- notify count is $(count), expected 1"
ok "persistent staleness alerts once, not once per tick"

echo "3. recovering clears the latch"
fresh_log
out="$(env HOME="$FAKE_HOME" "$HB" fallback-cert 2>&1)"
grep -q "^OK" <<<"$out" || fail "recovered monitor not reported OK: $out"
[ "$(count)" = "1" ] || fail "recovery itself alerted -- notify count is $(count), expected 1"
ok "recovery reports OK and does not alert"

echo "4. a later recurrence of the same staleness alerts again (never permanent silence)"
stale_log
env HOME="$FAKE_HOME" "$HB" fallback-cert >/dev/null 2>&1
[ "$(count)" = "2" ] || fail "recurrence after recovery did not re-alert -- notify count is $(count), expected 2"
ok "recurrence after recovery re-alerts"

echo "5. a monitor that has NEVER logged also dedups across ticks"
: > "$COUNT_FILE"
rm -f "$FAKE_HOME/.cache/bass-tuner-cert-renewal.log"
for _ in 1 2 3; do
  env HOME="$FAKE_HOME" "$HB" cert-renewal >/dev/null 2>&1
done
[ "$(count)" = "1" ] || fail "never-logged monitor re-alerted every tick -- notify count is $(count), expected 1"
ok "never-logged monitor alerts once across repeated ticks"

echo
echo "--- check-heartbeat-liveness.sh (own dedup) ---"

stale_hb_log() {
  cat > "$FAKE_HOME/.cache/bass-tuner-heartbeat.log" <<EOF
=== heartbeat $(date -d '40 hours ago' -Is) ===
exit 0
EOF
}
fresh_hb_log() {
  cat > "$FAKE_HOME/.cache/bass-tuner-heartbeat.log" <<EOF
=== heartbeat $(date -Is) ===
exit 0
EOF
}

: > "$COUNT_FILE"

echo "6. first tick of a stale heartbeat log alerts"
stale_hb_log
env HOME="$FAKE_HOME" MAX_AGE_HOURS=30 "$LIVENESS" >/dev/null 2>&1
[ "$(count)" = "1" ] || fail "expected 1 notify after first stale liveness tick, got $(count)"
ok "first stale liveness tick alerts"

echo "7. repeated ticks of the same staleness do not re-alert"
for _ in 1 2 3; do
  env HOME="$FAKE_HOME" MAX_AGE_HOURS=30 "$LIVENESS" >/dev/null 2>&1
done
[ "$(count)" = "1" ] || fail "persistent liveness staleness re-alerted -- notify count is $(count), expected 1"
ok "persistent liveness staleness alerts once, not once per tick"

echo "8. recovering clears the latch, and a later recurrence re-alerts"
fresh_hb_log
env HOME="$FAKE_HOME" MAX_AGE_HOURS=30 "$LIVENESS" >/dev/null 2>&1
[ "$(count)" = "1" ] || fail "liveness recovery itself alerted -- notify count is $(count), expected 1"
stale_hb_log
env HOME="$FAKE_HOME" MAX_AGE_HOURS=30 "$LIVENESS" >/dev/null 2>&1
[ "$(count)" = "2" ] || fail "liveness recurrence after recovery did not re-alert -- notify count is $(count), expected 2"
ok "liveness recovery clears the latch and a later recurrence re-alerts"

echo
echo "PASS ($pass assertions)"
