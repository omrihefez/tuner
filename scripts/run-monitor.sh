#!/usr/bin/env bash
# Generic monitor wrapper (bt-a942): runs a monitor script, always logs its
# output, and on any non-zero exit ALSO writes a dated ~/inbox file so the
# morning brief surfaces the failure. Same principle as
# iac/scripts/drift-check.sh: "a silent monitor is a broken monitor" -- a
# script that only writes ~/.cache/*.log (like renew-wildcard-cert.sh did
# before this) can FATAL every run and nobody notices, which is exactly how
# the wildcard fallback cert expired silently for over a month.
#
# Usage: run-monitor.sh <name> <script-path> [args...]
#   <name> becomes the log filename stem ($HOME/.cache/bass-tuner-<name>.log,
#   appended forever) and the inbox filename stem
#   ($HOME/inbox/bass-tuner-<name>-<date>.md, one per day like drift-check.sh
#   so a same-day rerun legitimately supersedes today's own alert but a
#   different day's run never clobbers an alert nobody has read yet).
set -uo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: run-monitor.sh <name> <script-path> [args...]" >&2
  exit 2
fi

NAME="$1"; shift
SCRIPT="$1"; shift

LOG="$HOME/.cache/bass-tuner-${NAME}.log"
INBOX="$HOME/inbox/bass-tuner-${NAME}-$(date -I).md"

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
  {
    echo "# bass-tuner monitor failed — $NAME ($(date -I))"
    echo
    echo "\`$SCRIPT\` exited $code:"
    echo
    echo '```'
    echo "$out"
    echo '```'
    echo
    echo "Full log: $LOG"
  } > "$INBOX"
fi

exit "$code"
