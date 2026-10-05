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
# bt-47e9: that direct meni-notify call used to fire on EVERY run for as
# long as a monitor stayed stale/missing -- same class of bug as th-b15d
# (trips-hub's heal-dev-alias.sh), which re-sent one message 65 times in
# eight hours. Each condition now goes through lib/alert-latch.sh's
# notify_and_latch, keyed per monitor name + condition kind (never on the
# rendered message, since it embeds an ever-increasing age in hours and
# would look "new" on every tick). The latch is cleared the moment that
# monitor reports OK again, so a later recurrence still alerts.
#
# Usage: check-monitor-heartbeats.sh [monitor-name ...]
#   No args: checks every monitor install-monitoring-crons.sh --print-line
#   says is scheduled (minus "heartbeat" itself -- see MAX_AGE_HOURS below).
#   One or more names: checks only those. A name with no MAX_AGE_HOURS entry
#   -- whether it's a typo, a removed monitor, or a real one the installer
#   schedules but this map was never updated for -- is reported as UNKNOWN
#   (not silently skipped), the same way a stale log is.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/alert-latch.sh
. "$HERE/lib/alert-latch.sh" || {
  echo "FATAL: cannot source lib/alert-latch.sh -- refusing to run a guard that cannot report" >&2
  exit 2
}

# name -> max age in hours before its log is considered stale, sized to that
# monitor's own installed cron cadence (see install-monitoring-crons.sh /
# install-cert-renewal-cron.sh) plus slack for a late morning -- tight enough
# to catch a real gap within about a day, loose enough not to flap on
# ordinary cron jitter.
declare -A MAX_AGE_HOURS=(
  [fallback-cert]=30       # daily 06:05
  [domain-audit]=30        # daily 06:10
  [tunnel-liveness]=30     # daily 06:12 (bt-8818)
  [cert-renewal]=192       # weekly Mon 06:17 (7d + 1d slack)
  [stale-deploy]=6         # every 2h at :22 (bt-4e2a) -- 3x cadence for slack
  [model-ids]=30           # daily 06:14 (bt-5abe)
  [permissions-policy]=30  # daily 06:16 (bt-40c5/bt-b97b, bt-2604)
  # NOTE: does NOT include "heartbeat" itself (this script's own run) --
  # that was tried and rejected in bt-6492: a self-referential entry only
  # reports once the watcher has already run, so it can never catch "the
  # watcher didn't run at all". That case is covered by a SEPARATE script
  # on a SEPARATE scheduler instead: check-heartbeat-liveness.sh, run by
  # systemd/bass-tuner-heartbeat-watchdog.timer (install-heartbeat-watchdog.sh).
)

MENI_NOTIFY="$HOME/meni/bin/meni-notify"
ALERT_DIR="$HOME/.cache/bass-tuner-monitor-heartbeats-alerts"

# bt-2604: the DEFAULT monitor set (no CLI args) is derived from the
# installers' own --print-line output -- the same source check-crontab-drift.sh
# already reconciles against -- instead of restating it as a second,
# hand-maintained list. MAX_AGE_HOURS keys drifted from the installers' real
# monitor set already (tunnel-liveness/bt-0603, permissions-policy/bt-2604):
# each was added to an installer and started running on schedule while
# staying invisible to this watcher, because the watcher only ever checked
# its OWN list. TWO installers schedule monitors this script watches --
# install-monitoring-crons.sh for everything except cert-renewal, which
# install-cert-renewal-cron.sh schedules on its own separate weekly cadence --
# so both are queried and unioned. Parses the same way each installer's own
# monitor_names() parses the live crontab: the first argument after any
# run-monitor.sh invocation is the monitor name. "heartbeat" is excluded
# explicitly -- see the MAX_AGE_HOURS comment above, same reason.
INSTALLERS=("$HERE/install-monitoring-crons.sh" "$HERE/install-cert-renewal-cron.sh")
installed_monitor_names() {
  for installer in "${INSTALLERS[@]}"; do
    "$installer" --print-line 2>/dev/null
  done | awk '!/^[[:space:]]*#/ {
    for (i = 1; i < NF; i++)
      if ($i ~ /run-monitor\.sh$/) { print $(i + 1); break }
  }' | sed '/^$/d' | sort -u
}

if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  mapfile -t TARGETS < <(installed_monitor_names | grep -vFx "heartbeat" || true)
  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo "FATAL: '${INSTALLERS[*]} --print-line' produced no monitor names -- refusing to run with an empty target set" >&2
    exit 2
  fi
fi

FAIL=0

# alert <name> <condition> <message> -- <condition> is the latch VALUE: a
# stable label for the kind of failure (never-run / no-marker / bad-timestamp
# / stale), not the rendered message, so a ticking age doesn't defeat the
# dedup on every run. notify_and_latch only ever DELIVERS then latches -- it
# does not itself compare against what's already latched (same contract
# run-monitor.sh relies on), so the "is this the same condition as last time"
# check has to happen here, before calling it.
alert() {
  local name="$1" condition="$2" msg="$3"
  local latch="$ALERT_DIR/${name}.alert-latch"
  echo "STALE    $msg"
  if [[ "$(cat "$latch" 2>/dev/null || true)" == "$condition" ]]; then
    alert_latch_log "$name: already alerted for '$condition', not re-notifying"
  else
    notify_and_latch "$MENI_NOTIFY" "$latch" "$condition" "$msg" >/dev/null 2>&1 || true
  fi
  FAIL=1
}

clear_alert() {
  local name="$1"
  rm -f "$ALERT_DIR/${name}.alert-latch" "$ALERT_DIR/${name}.alert-latch.undelivered" 2>/dev/null || true
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
    alert "$name" "never-run" "bass-tuner heartbeat: $name has NEVER logged a run (expected $log)"
    continue
  fi

  last_line="$(grep -E '^=== ' "$log" | tail -1)"
  last_ts="$(awk '{print $3}' <<<"$last_line")"
  if [[ -z "$last_ts" ]]; then
    alert "$name" "no-marker" "bass-tuner heartbeat: $name's log has no parseable run marker ($log)"
    continue
  fi

  last_epoch="$(date -d "$last_ts" +%s 2>/dev/null || true)"
  if [[ -z "$last_epoch" ]]; then
    alert "$name" "bad-timestamp:$last_ts" "bass-tuner heartbeat: $name's last timestamp '$last_ts' failed to parse ($log)"
    continue
  fi

  now_epoch="$(date +%s)"
  age_hours=$(( (now_epoch - last_epoch) / 3600 ))

  if (( age_hours > max_age )); then
    alert "$name" "stale" "bass-tuner heartbeat: $name last ran ${age_hours}h ago (limit ${max_age}h) -- $log"
  else
    echo "OK       $name last ran ${age_hours}h ago (limit ${max_age}h)"
    clear_alert "$name"
  fi
done

exit "$FAIL"
