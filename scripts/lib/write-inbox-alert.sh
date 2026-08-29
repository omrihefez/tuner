#!/usr/bin/env bash
# write-inbox-alert.sh — bt-7964. The "notifier" run-monitor.sh hands to
# alert-latch.sh's notify_and_latch, so a monitor's fingerprint latch is only
# written once the alert has actually landed where the morning brief reads
# it ($HOME/inbox), never just because the monitor failed again.
#
# notify_and_latch calls its notifier with exactly one argument (the
# message), so there is no positional slot for the monitor name — read it
# from $BT_MONITOR_NAME instead, set by run-monitor.sh before the call.
set -uo pipefail

msg="${1:-}"
name="${BT_MONITOR_NAME:-}"

if [[ -z "$name" || -z "$msg" ]]; then
  echo "write-inbox-alert.sh: need \$BT_MONITOR_NAME set and a message argument" >&2
  exit 2
fi

inbox_dir="$HOME/inbox"
mkdir -p "$inbox_dir" || exit 1
printf '%s\n' "$msg" > "$inbox_dir/bass-tuner-${name}-$(date -I).md"
