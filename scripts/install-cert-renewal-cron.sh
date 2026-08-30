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
# This block is rewritten WHOLESALE from $CRON_LINES below, so $CRON_LINES is
# the single source of truth for everything between the markers: an entry
# that is live inside them but missing here is deleted on the next run
# (same defect class as install-monitoring-crons.sh before bt-34af). The
# DROPPED guard below makes that failure loud instead of silent.
#
# $CRON_LINES also carries this block's own drift check (ma-09c1): rather
# than a second tracked data file (which could itself drift from this
# script), scripts/check-crontab-drift.sh gets its "expected content" by
# running this installer with --print-line, so there is exactly one source
# of truth for the block, this file.
#
# Usage: install-cert-renewal-cron.sh [--dry-run] [--force] [--print-line]
#   --dry-run    print the resulting crontab instead of installing it
#   --force      install even if the guard reports a monitor would be dropped
#                (i.e. you are deliberately unscheduling one)
#   --print-line print the rendered block content, install nothing (used by
#                scripts/check-crontab-drift.sh as its source of truth)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
FORCE=0
PRINT_LINE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)    DRY_RUN=1 ;;
    --force)      FORCE=1 ;;
    --print-line) PRINT_LINE=1 ;;
    *) echo "usage: install-cert-renewal-cron.sh [--dry-run] [--force] [--print-line]" >&2; exit 2 ;;
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

# crontab drift check (ma-09c1) — hourly: warns via meni-notify if the live
# wildcard-cert-renewal block has drifted from this installer. Lives inside
# the very block it guards, same convention as meniapp/deploy/crontab.meniapp.
# Calls the single shared implementation in meniapp (ma-c616 — no more
# per-repo vendored copies) by absolute path — this entry runs on the meni
# VPS, same box as meniapp, so the absolute path always resolves. Its
# BLOCK_LABEL/BEGIN_MARK/END_MARK/EXPECTED_CONTENT_CMD/INSTALLER_HINT are now
# passed explicitly rather than relying on the script's own defaults — those
# defaults derive from the script's OWN location (meniapp), not this repo's,
# once it's no longer a local vendored copy.
DRIFT_CHECK="/home/omri/projects/meniapp/scripts/check-crontab-drift.sh"
# Same consolidation for the log-dir lint (ma-b531): shared implementation
LINT_LOGDIRS="/home/omri/projects/meniapp/scripts/lint-crontab-logdirs.sh"
DRIFT_STATE_DIR="/home/omri/.local/share/meni-hub/bass-tuner-crontab-drift"
DRIFT_LINE="47 * * * * mkdir -p $DRIFT_STATE_DIR && BLOCK_LABEL=wildcard-cert-renewal BEGIN_MARK=\"$BEGIN_MARK\" END_MARK=\"$END_MARK\" EXPECTED_CONTENT_CMD=\"/home/omri/projects/bass-tuner/scripts/install-cert-renewal-cron.sh --print-line\" INSTALLER_HINT=\"scripts/install-cert-renewal-cron.sh\" $DRIFT_CHECK >> $DRIFT_STATE_DIR/cron.log 2>&1"

CRON_LINES="$CRON_LINE
$DRIFT_LINE"

if [ "$PRINT_LINE" = "1" ]; then
  printf '%s\n' "$CRON_LINES"
  exit 0
fi

# crontab log-dir lint (ma-0540): the cert-renewal line runs through
# run-monitor.sh, which does its own `mkdir -p ... && { ... } >> "$LOG"`
# INSIDE the already-running process (not a cron-level `>>` redirect), so
# ma-5896 doesn't apply to it today -- this is a regression guard against a
# future line that bypasses the wrapper and redirects directly. The drift
# check line above is a real cron-level redirect and IS subject to ma-5896,
# hence its own `mkdir -p ... &&` prefix.
if ! printf '%s\n' "$CRON_LINES" | bash "$LINT_LOGDIRS" -; then
  echo "[install-cert-renewal-cron] refusing to install: rendered lines failed the log-dir lint (see above)." >&2
  exit 1
fi

# Shared crontab lock (ma-09c1): every installer across the fleet that reads
# the whole user crontab, edits it, and writes it back takes this same lock,
# so two installers running concurrently on this box serialize instead of
# one clobbering the other's freshly-written block.
CRONTAB_LOCK="$HOME/.local/share/meni-hub/crontab-install.lock"
mkdir -p "$(dirname "$CRONTAB_LOCK")"
exec 200>"$CRONTAB_LOCK"
flock -x 200

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
# unschedule a monitor. The block is replaced wholesale from $CRON_LINES, so
# anything live inside the markers but missing from $CRON_LINES just
# disappears -- and a monitor that never runs looks exactly like a monitor
# that passes. Compared by monitor NAME rather than whole line, so an
# ordinary schedule change is not flagged but an entry vanishing is. The
# drift-check line never registers as a "monitor" here (it isn't a
# run-monitor.sh invocation), so it never trips or is protected by this guard.
OLD_BLOCK="$(printf '%s\n' "$CURRENT_CRON" | sed -n "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|p")"
DROPPED="$(comm -23 \
  <(printf '%s\n' "$OLD_BLOCK"  | monitor_names) \
  <(printf '%s\n' "$CRON_LINES" | monitor_names))"

if [ -n "$DROPPED" ]; then
  {
    echo "[install-cert-renewal-cron] these monitors are scheduled in the live managed"
    echo "  block but absent from this script's \$CRON_LINES, so installing would"
    echo "  silently unschedule them:"
    printf '%s\n' "$DROPPED" | sed 's/^/      /'
    echo "  Add them to \$CRON_LINES -- this file is the source of truth for the whole"
    echo "  block -- or re-run with --force if you really mean to unschedule them."
  } >&2
  if [ "$FORCE" != "1" ]; then
    echo "[install-cert-renewal-cron] refusing to install (no --force); crontab unchanged." >&2
    exit 1
  fi
  echo "[install-cert-renewal-cron] --force given: unscheduling the above." >&2
fi

STRIPPED_CRON="$(printf '%s\n' "$CURRENT_CRON" | sed "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|d")"
# Legacy cleanup pass, for a stray exact duplicate left behind by a corrupted
# or partial marker pair (the sed range-delete above can't find it if either
# marker is missing). Matched on a "run-monitor.sh cert-renewal " SUBSTRING
# before this (bt-9777), which struck ANY crontab line merely mentioning that
# monitor invocation -- not just its own managed block -- including a
# hand-added line on a different schedule. Same defect shape as the raw-
# basename bug bt-b38f fixed just above, and the one bt-d428 fixed in
# install-monitoring-crons.sh's own legacy pass. Matching the FULL line
# against $CRON_LINES verbatim instead still cleans up an exact stray
# duplicate but leaves anything that merely mentions the monitor alone.
STRIPPED_CRON="$(printf '%s\n' "$STRIPPED_CRON" | grep -vFxf <(printf '%s\n' "$CRON_LINES") || true)"

NEW_CRON="$(printf '%s\n%s\n%s\n%s\n' "$STRIPPED_CRON" "$BEGIN_MARK" "$CRON_LINES" "$END_MARK")"

if [ "$DRY_RUN" = "1" ]; then
  echo "[install-cert-renewal-cron] dry-run: crontab would become:" >&2
  printf '%s\n' "$NEW_CRON" | sed 's/^/    /' >&2
else
  printf '%s\n' "$NEW_CRON" | crontab -
  echo "[install-cert-renewal-cron] installed Monday 06:17 cron for $SCRIPT (see: crontab -l)"
fi
