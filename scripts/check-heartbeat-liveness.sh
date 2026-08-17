#!/usr/bin/env bash
# Watches check-monitor-heartbeats.sh's OWN liveness (bt-6492).
#
# check-monitor-heartbeats.sh (bt-b542) watches fallback-cert / domain-audit /
# cert-renewal, but nothing watched IT -- and it ran from the very managed
# cron block it watches (scripts/install-monitoring-crons.sh), so a watcher
# whose own execution silently stopped (cron entry edited away, exec bit
# lost, cron itself wedged) would look identical to "every check passed".
#
# DO NOT fold this into check-monitor-heartbeats.sh's MAX_AGE_HOURS map --
# that was tried and rejected: a self-referential entry only reports once the
# watcher itself has already run, so it can never report "the watcher didn't
# run at all". This has to be a SEPARATE script on a SEPARATE scheduler
# (systemd timer, not bass-tuner's cron -- see systemd/bass-tuner-heartbeat-
# watchdog.timer / scripts/install-heartbeat-watchdog.sh) so a bass-tuner-cron
# failure and this watchdog's failure can never share a root cause.
#
# Reads the same "=== heartbeat <ISO8601> ===" marker convention run-monitor.sh
# already writes to $HOME/.cache/bass-tuner-heartbeat.log on every invocation
# of check-monitor-heartbeats.sh, regardless of that script's own exit code.
#
# Usage: check-heartbeat-liveness.sh
#   MAX_AGE_HOURS env var overrides the default 30h threshold (sized like
#   fallback-cert/domain-audit: daily 07:00 run + slack for a late morning).
set -uo pipefail

MAX_AGE_HOURS="${MAX_AGE_HOURS:-30}"
LOG="$HOME/.cache/bass-tuner-heartbeat.log"
MENI_NOTIFY="$HOME/meni/bin/meni-notify"

alert() {
  local msg="$1"
  echo "STALE    $msg"
  bash "$MENI_NOTIFY" "$msg" >/dev/null 2>&1 || true
}

if [[ ! -f "$LOG" ]]; then
  alert "bass-tuner heartbeat-watchdog: the heartbeat monitor (check-monitor-heartbeats.sh) has NEVER logged a run (expected $LOG) -- its cron entry, exec bit, or crond itself may be broken"
  exit 1
fi

last_line="$(grep -E '^=== ' "$LOG" | tail -1)"
last_ts="$(awk '{print $3}' <<<"$last_line")"
if [[ -z "$last_ts" ]]; then
  alert "bass-tuner heartbeat-watchdog: heartbeat log has no parseable run marker ($LOG)"
  exit 1
fi

last_epoch="$(date -d "$last_ts" +%s 2>/dev/null || true)"
if [[ -z "$last_epoch" ]]; then
  alert "bass-tuner heartbeat-watchdog: heartbeat log's last timestamp '$last_ts' failed to parse ($LOG)"
  exit 1
fi

now_epoch="$(date +%s)"
age_hours=$(( (now_epoch - last_epoch) / 3600 ))

if (( age_hours > MAX_AGE_HOURS )); then
  alert "bass-tuner heartbeat-watchdog: the heartbeat monitor last ran ${age_hours}h ago (limit ${MAX_AGE_HOURS}h) -- $LOG -- its cron entry, exec bit, or crond itself may be broken"
  exit 1
fi

echo "OK       heartbeat monitor last ran ${age_hours}h ago (limit ${MAX_AGE_HOURS}h)"
exit 0
