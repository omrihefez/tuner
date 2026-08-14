#!/usr/bin/env bash
# The heartbeat monitor that watches the other monitors (bt-b542). The cron
# calling this script has existed since install-monitoring-crons.sh but the
# script itself never did -- exit 127 every morning at 07:00, silently, since
# installation. Its entire job: notice when fallback-cert / domain-audit /
# cert-renewal stop running, since a monitor that fails alerts via
# run-monitor.sh's own inbox note, but a monitor that never RUNS AT ALL
# (cron entry edited away, run-monitor.sh loses its exec bit, cron itself
# stops) looks identical to "every check passed" -- silence either way.
#
# Uses the SAME log convention run-monitor.sh already writes: each run
# appends a "=== <name> <ISO8601-timestamp> ===" marker to
# $HOME/.cache/bass-tuner-<name>.log before running the wrapped script, on
# every invocation regardless of the wrapped script's own exit code. This
# checks the age of the last such marker against each monitor's own cron
# cadence (+ grace for a slow morning) -- not just log presence, since a log
# that stopped growing 3 weeks ago still "exists".
#
# On top of exiting non-zero (which, run through run-monitor.sh like every
# other monitor here, produces its own ~/inbox note), this ALSO pushes
# through meni-notify directly: an inbox note nobody reads is exactly the
# failure mode that got this script written in the first place (the note
# for THIS gap sat unread in ~/inbox for a full day before Main found it).
#
# Usage: check-monitor-heartbeats.sh [monitor-name ...]
#   No args: checks every monitor in MAX_AGE_HOURS below.
#   One or more names: checks only those. An unknown name is reported as
#   UNKNOWN (not silently skipped) so pointing this at a typo'd or removed
#   monitor name is itself visible, the same way a stale log is.
set -uo pipefail

# name -> max age in hours before its log is considered stale, sized to that
# monitor's own installed cron cadence (see install-monitoring-crons.sh /
# install-cert-renewal-cron.sh) plus slack for a late morning -- tight enough
# to catch a real gap within about a day, loose enough not to flap on
# ordinary cron jitter.
declare -A MAX_AGE_HOURS=(
  [fallback-cert]=30    # daily 06:05
  [domain-audit]=30     # daily 06:10
  [cert-renewal]=192    # weekly Mon 06:17 (7d + 1d slack)
  [stale-deploy]=6      # every 2h at :22 (bt-4e2a) -- 3x cadence for slack
)

MENI_NOTIFY="$HOME/meni/bin/meni-notify"

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=("${!MAX_AGE_HOURS[@]}")
fi

FAIL=0

alert() {
  local msg="$1"
  echo "STALE    $msg"
  bash "$MENI_NOTIFY" "$msg" >/dev/null 2>&1 || true
  FAIL=1
}

for name in "${TARGETS[@]}"; do
  if [[ -z "${MAX_AGE_HOURS[$name]+x}" ]]; then
    echo "UNKNOWN  $name is not a registered monitor (known: ${!MAX_AGE_HOURS[*]})"
    FAIL=1
    continue
  fi

  max_age="${MAX_AGE_HOURS[$name]}"
  log="$HOME/.cache/bass-tuner-${name}.log"

  if [[ ! -f "$log" ]]; then
    alert "bass-tuner heartbeat: $name has NEVER logged a run (expected $log)"
    continue
  fi

  last_line="$(grep -E '^=== ' "$log" | tail -1)"
  last_ts="$(awk '{print $3}' <<<"$last_line")"
  if [[ -z "$last_ts" ]]; then
    alert "bass-tuner heartbeat: $name's log has no parseable run marker ($log)"
    continue
  fi

  last_epoch="$(date -d "$last_ts" +%s 2>/dev/null || true)"
  if [[ -z "$last_epoch" ]]; then
    alert "bass-tuner heartbeat: $name's last timestamp '$last_ts' failed to parse ($log)"
    continue
  fi

  now_epoch="$(date +%s)"
  age_hours=$(( (now_epoch - last_epoch) / 3600 ))

  if (( age_hours > max_age )); then
    alert "bass-tuner heartbeat: $name last ran ${age_hours}h ago (limit ${max_age}h) -- $log"
  else
    echo "OK       $name last ran ${age_hours}h ago (limit ${max_age}h)"
  fi
done

exit "$FAIL"
