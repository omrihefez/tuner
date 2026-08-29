#!/usr/bin/env bash
# Generic monitor wrapper (bt-a942): runs a monitor script, always logs its
# output, and on any non-zero exit ALSO writes a dated ~/inbox file so the
# morning brief surfaces the failure. Same principle as
# iac/scripts/drift-check.sh: "a silent monitor is a broken monitor" -- a
# script that only writes ~/.cache/*.log (like renew-wildcard-cert.sh did
# before this) can FATAL every run and nobody notices, which is exactly how
# the wildcard fallback cert expired silently for over a month.
#
# bt-7964: the inbox alert is now latched on a sha256 fingerprint of the
# failure output via lib/alert-latch.sh, so a PERSISTENT failure alerts once
# instead of once a day forever — bt-5149 was exactly that: the same
# albumclub.omrihefez.com 404 re-alarmed daily for over a week until someone
# edited the domain list. The latch is written only once the inbox file is
# actually on disk (ma-c1b2: never latch an alert that wasn't delivered) and
# is cleared the moment the monitor passes again, so a later NEW occurrence
# of the very same failure still alerts instead of staying silent forever.
#
# Usage: run-monitor.sh <name> <script-path> [args...]
#   <name> becomes the log filename stem ($HOME/.cache/bass-tuner-<name>.log,
#   appended forever), the inbox filename stem
#   ($HOME/inbox/bass-tuner-<name>-<date>.md, one per day like drift-check.sh
#   so a same-day rerun legitimately supersedes today's own alert but a
#   different day's run never clobbers an alert nobody has read yet), and the
#   latch filename stem ($HOME/.cache/bass-tuner-<name>.alert-latch).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/alert-latch.sh
# FAIL CLOSED: a wrapper that cannot latch correctly must not silently fall
# back to alerting on every run either — refuse rather than guess.
. "$HERE/lib/alert-latch.sh" || {
  echo "FATAL: cannot source lib/alert-latch.sh — refusing to run a guard that cannot report" >&2
  exit 2
}

if [[ $# -lt 2 ]]; then
  echo "usage: run-monitor.sh <name> <script-path> [args...]" >&2
  exit 2
fi

NAME="$1"; shift
SCRIPT="$1"; shift

LOG="$HOME/.cache/bass-tuner-${NAME}.log"
LATCH="$HOME/.cache/bass-tuner-${NAME}.alert-latch"
NOTIFY="${BASS_TUNER_MONITOR_NOTIFY:-$HERE/lib/write-inbox-alert.sh}"

mkdir -p "$HOME/.cache" "$HOME/inbox"

{
  echo "=== $NAME $(date -Is) ==="
  out=$("$SCRIPT" "$@" 2>&1)
  code=$?
  echo "$out"
  echo "exit $code"
  echo
} >> "$LOG"

if [[ "$code" -ne 0 ]]; then
  fingerprint="$(printf '%s' "$out" | sha256sum | cut -d' ' -f1)"
  if [[ "$(cat "$LATCH" 2>/dev/null || true)" == "$fingerprint" ]]; then
    alert_latch_log "$NAME: already alerted for this exact failure, not re-notifying (see $LOG)"
  else
    MSG="$(
      echo "# bass-tuner monitor failed — $NAME ($(date -I))"
      echo
      echo "\`$SCRIPT\` exited $code:"
      echo
      echo '```'
      echo "$out"
      echo '```'
      echo
      echo "Full log: $LOG"
    )"
    BT_MONITOR_NAME="$NAME" notify_and_latch "$NOTIFY" "$LATCH" "$fingerprint" "$MSG"
  fi
else
  rm -f "$LATCH" "${LATCH}.undelivered" 2>/dev/null || true
fi

exit "$code"
