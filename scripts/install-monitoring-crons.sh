#!/usr/bin/env bash
# Installs cron entries for check-fallback-cert.sh, audit-domains.sh
# (bt-a942), check-monitor-heartbeats.sh (bt-b542), and
# deploy/activation-probes/probe-bt-5fb7.sh (bt-4e2a). All existed but were
# scheduled nowhere -- referenced only as one-shot closing evidence for the
# tasks that wrote them (bt-2b10, bt-a740, bt-5fb7) -- so a real regression
# in any of them would sit unnoticed indefinitely, which is exactly how the
# wildcard fallback cert expired silently for over a month. All run through
# scripts/run-monitor.sh, which writes a dated ~/inbox file on any non-zero
# exit so the morning brief surfaces a failure.
#
# Idempotent: re-running replaces the managed block instead of duplicating it.
#
# This block is rewritten WHOLESALE from $CRON_LINES below, so $CRON_LINES is
# the single source of truth for everything between the markers: an entry that
# is live inside them but missing here is deleted on the next run. The
# heartbeat entry was exactly that (bt-34af) -- scheduled live by an installer
# run from an abandoned worktree, never landed in this file, so a single
# `bash scripts/install-monitoring-crons.sh` would have unscheduled the one
# monitor whose whole job is noticing that a monitor stopped running, and the
# only thing that would have reported it was the monitor being deleted.
# The DROPPED guard below now makes that failure loud instead of silent.
#
# Usage: install-monitoring-crons.sh [--dry-run] [--force]
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
    *) echo "usage: install-monitoring-crons.sh [--dry-run] [--force]" >&2; exit 2 ;;
  esac
done

# Hardcoded to the canonical checkout, not derived from this script's own
# location -- same rationale as install-cert-renewal-cron.sh: this installer
# must produce the same crontab lines regardless of whether it's run from the
# main checkout or a throwaway task worktree.
REPO="/home/omri/projects/bass-tuner"
RUNNER="$REPO/scripts/run-monitor.sh"
FALLBACK_CERT="$REPO/scripts/check-fallback-cert.sh"
DOMAIN_AUDIT="$REPO/scripts/audit-domains.sh"
HEARTBEAT="$REPO/scripts/check-monitor-heartbeats.sh"
STALE_DEPLOY="$REPO/deploy/activation-probes/probe-bt-5fb7.sh"

BEGIN_MARK="# BEGIN bass-tuner-monitoring (scripts/install-monitoring-crons.sh)"
END_MARK="# END bass-tuner-monitoring (scripts/install-monitoring-crons.sh)"

# 06:05/06:10 -- ahead of the 06:17 wildcard-cert-renewal run so all three
# TLS/domain checks land in the same pre-day-start window.
# 07:00 heartbeat -- deliberately AFTER all three (and after the Monday
# cert-renewal run), so it reads the logs the same morning's runs just wrote
# rather than alerting on a gap the 06:05-06:17 window was about to close.
# stale-deploy (bt-4e2a) -- probe-bt-5fb7.sh was only ever run as one-shot
# `--live` evidence when a task closed, so a deploy that silently failed or
# an edge cache serving a stale sw.js between closings would sit uncaught
# indefinitely, the same gap bt-a942 found for the TLS/domain checks. Run
# every 2h (offset :22 to dodge the 06:05-07:00 window and the top-of-hour
# rush of other boxes' crons) rather than daily -- it's cheap (one curl) and
# catching a stale deploy sooner narrows the window it ships broken to users.
CRON_LINES="5 6 * * * $RUNNER fallback-cert $FALLBACK_CERT
10 6 * * * $RUNNER domain-audit $DOMAIN_AUDIT
0 7 * * * $RUNNER heartbeat $HEARTBEAT
22 */2 * * * $RUNNER stale-deploy $STALE_DEPLOY"

# crontab log-dir lint (ma-0540): these lines run through run-monitor.sh,
# which does its own `mkdir -p ... && { ... } >> "$LOG"` INSIDE the already-
# running process (not a cron-level `>>` redirect), so ma-5896 doesn't apply
# to them today -- this is a regression guard against a future line that
# bypasses the wrapper and redirects directly.
if ! printf '%s\n' "$CRON_LINES" | bash "$SCRIPT_DIR/lint-crontab-logdirs.sh" -; then
  echo "[install-monitoring-crons] refusing to install: rendered lines failed the log-dir lint (see above)." >&2
  exit 1
fi

# Shared crontab lock (ma-09c1): every installer across the fleet that reads
# the whole user crontab, edits it, and writes it back — this one and its
# sibling install-cert-renewal-cron.sh in particular, since both run in this
# same repo — takes this same lock, so two installers running concurrently
# on this box serialize instead of one clobbering the other's freshly-written
# block. See meniapp/scripts/check-crontab-drift.sh's header.
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

# Guard (bt-34af): refuse to silently unschedule a monitor. The block is
# replaced wholesale, so anything live inside the markers but missing from
# $CRON_LINES just disappears -- and a monitor that never runs looks exactly
# like a monitor that passes. Compared by monitor NAME rather than whole line,
# so an ordinary schedule change is not flagged but an entry vanishing is.
OLD_BLOCK="$(printf '%s\n' "$CURRENT_CRON" | sed -n "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|p")"
DROPPED="$(comm -23 \
  <(printf '%s\n' "$OLD_BLOCK"  | monitor_names) \
  <(printf '%s\n' "$CRON_LINES" | monitor_names))"

if [ -n "$DROPPED" ]; then
  {
    echo "[install-monitoring-crons] these monitors are scheduled in the live managed"
    echo "  block but absent from this script's \$CRON_LINES, so installing would"
    echo "  silently unschedule them:"
    printf '%s\n' "$DROPPED" | sed 's/^/      /'
    echo "  Add them to \$CRON_LINES -- this file is the source of truth for the whole"
    echo "  block -- or re-run with --force if you really mean to unschedule them."
  } >&2
  if [ "$FORCE" != "1" ]; then
    echo "[install-monitoring-crons] refusing to install (no --force); crontab unchanged." >&2
    exit 1
  fi
  echo "[install-monitoring-crons] --force given: unscheduling the above." >&2
fi

STRIPPED_CRON="$(printf '%s\n' "$CURRENT_CRON" | sed "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|d")"
# Legacy cleanup pass, for a stray exact duplicate left behind by a corrupted
# or partial marker pair (the sed range-delete above can't find it if either
# marker is missing). Matched on a run-monitor.sh/monitor-name SUBSTRING
# before this (bt-d428), which struck ANY crontab line merely mentioning that
# monitor anywhere -- not just its own managed block -- including a
# hand-added line on a different schedule. Same defect shape as the raw-
# basename bug bt-b38f fixed in install-cert-renewal-cron.sh, just narrower.
# Matching the FULL line against $CRON_LINES verbatim instead still cleans up
# an exact stray duplicate but leaves anything that merely mentions the
# monitor name alone.
STRIPPED_CRON="$(printf '%s\n' "$STRIPPED_CRON" | grep -vFxf <(printf '%s\n' "$CRON_LINES") || true)"

NEW_CRON="$(printf '%s\n%s\n%s\n%s\n' "$STRIPPED_CRON" "$BEGIN_MARK" "$CRON_LINES" "$END_MARK")"

if [ "$DRY_RUN" = "1" ]; then
  echo "[install-monitoring-crons] dry-run: crontab would become:" >&2
  printf '%s\n' "$NEW_CRON" | sed 's/^/    /' >&2
else
  printf '%s\n' "$NEW_CRON" | crontab -
  echo "[install-monitoring-crons] installed crons: 06:05 fallback-cert, 06:10 domain-audit, 07:00 heartbeat (daily), :22/2h stale-deploy (see: crontab -l)"
fi
