#!/usr/bin/env bash
# Installs the weekly renew-wildcard-cert.sh cron entry into the interactive
# user's crontab (bt-03ea). The script itself is idempotent -- it only acts
# once the cert is within RENEW_THRESHOLD_DAYS of expiry -- so a weekly cadence
# is enough to always catch the renewal window with margin to spare.
# Idempotent: re-running replaces the managed block instead of duplicating it.
#
# Runs through scripts/run-monitor.sh (bt-a942), not a bare `>> log 2>&1`
# redirect -- the raw log at $HOME/.cache/bass-tuner-cert-renewal.log was
# never read by anything, so every FATAL path (expired Cloudflare token,
# `vercel certs ls` format change, TXT propagation timeout, ...) failed
# invisibly; that's exactly how the wildcard cert expired silently for over
# a month. run-monitor.sh still writes that same log AND, on any non-zero
# exit, a dated ~/inbox file so the morning brief surfaces the failure.
#
# This block is rewritten WHOLESALE from $CRON_LINE below, so $CRON_LINE is
# the single source of truth for everything between the markers: an entry
# that is live inside them but missing here is deleted on the next run
# (same defect class as install-monitoring-crons.sh before bt-34af). The
# DROPPED guard below makes that failure loud instead of silent.
#
# Usage: install-cert-renewal-cron.sh [--dry-run] [--force]
#   --dry-run  print the resulting crontab instead of installing it
#   --force    install even if the guard reports a monitor would be dropped
#              (i.e. you are deliberately unscheduling one)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    *) echo "usage: install-cert-renewal-cron.sh [--dry-run] [--force]" >&2; exit 2 ;;
  esac
done

# Hardcoded to the canonical checkout, not derived from this script's own
# location -- this installer must produce the same crontab line regardless of
# whether it's run from the main checkout or a throwaway task worktree.
SCRIPT="/home/omri/projects/bass-tuner/scripts/renew-wildcard-cert.sh"
RUNNER="/home/omri/projects/bass-tuner/scripts/run-monitor.sh"

BEGIN_MARK="# BEGIN wildcard-cert-renewal (scripts/install-cert-renewal-cron.sh)"
END_MARK="# END wildcard-cert-renewal (scripts/install-cert-renewal-cron.sh)"

CRON_LINE="17 6 * * 1 $RUNNER cert-renewal $SCRIPT"

# crontab log-dir lint (ma-0540): this line runs through run-monitor.sh,
# which does its own `mkdir -p ... && { ... } >> "$LOG"` INSIDE the already-
# running process (not a cron-level `>>` redirect), so ma-5896 doesn't apply
# to it today -- this is a regression guard against a future line that
# bypasses the wrapper and redirects directly.
if ! printf '%s\n' "$CRON_LINE" | bash "$SCRIPT_DIR/lint-crontab-logdirs.sh" -; then
  echo "[install-cert-renewal-cron] refusing to install: rendered line failed the log-dir lint (see above)." >&2
  exit 1
fi

CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

# Monitor names (run-monitor.sh's first argument) on stdin's cron lines.
# Comment lines are skipped so the BEGIN/END markers never register as entries.
monitor_names() {
  awk '!/^[[:space:]]*#/ {
         for (i = 1; i < NF; i++)
           if ($i ~ /run-monitor\.sh$/) { print $(i + 1); break }
       }' | sed '/^$/d' | sort -u
}

# Guard (bt-3f5a, same defect class as bt-34af): refuse to silently
# unschedule a monitor. The block is replaced wholesale from $CRON_LINE, so
# anything live inside the markers but missing from $CRON_LINE just
# disappears -- and a monitor that never runs looks exactly like a monitor
# that passes. Compared by monitor NAME rather than whole line, so an
# ordinary schedule change is not flagged but an entry vanishing is.
OLD_BLOCK="$(printf '%s\n' "$CURRENT_CRON" | sed -n "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|p")"
DROPPED="$(comm -23 \
  <(printf '%s\n' "$OLD_BLOCK"  | monitor_names) \
  <(printf '%s\n' "$CRON_LINE"  | monitor_names))"

if [ -n "$DROPPED" ]; then
  {
    echo "[install-cert-renewal-cron] these monitors are scheduled in the live managed"
    echo "  block but absent from this script's \$CRON_LINE, so installing would"
    echo "  silently unschedule them:"
    printf '%s\n' "$DROPPED" | sed 's/^/      /'
    echo "  Add them to \$CRON_LINE -- this file is the source of truth for the whole"
    echo "  block -- or re-run with --force if you really mean to unschedule them."
  } >&2
  if [ "$FORCE" != "1" ]; then
    echo "[install-cert-renewal-cron] refusing to install (no --force); crontab unchanged." >&2
    exit 1
  fi
  echo "[install-cert-renewal-cron] --force given: unscheduling the above." >&2
fi

STRIPPED_CRON="$(printf '%s\n' "$CURRENT_CRON" | sed "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|d")"
# Scoped to this monitor's run-monitor.sh invocation (bt-b38f), not the raw
# script basename -- the basename matched (and deleted) ANY crontab line
# mentioning renew-wildcard-cert.sh anywhere, managed or not, including a
# hand-written or differently-scheduled renewal someone added deliberately.
STRIPPED_CRON="$(printf '%s\n' "$STRIPPED_CRON" | grep -vF "run-monitor.sh cert-renewal " || true)"

NEW_CRON="$(printf '%s\n%s\n%s\n%s\n' "$STRIPPED_CRON" "$BEGIN_MARK" "$CRON_LINE" "$END_MARK")"

if [ "$DRY_RUN" = "1" ]; then
  echo "[install-cert-renewal-cron] dry-run: crontab would become:" >&2
  printf '%s\n' "$NEW_CRON" | sed 's/^/    /' >&2
else
  printf '%s\n' "$NEW_CRON" | crontab -
  echo "[install-cert-renewal-cron] installed Monday 06:17 cron for $SCRIPT (see: crontab -l)"
fi
