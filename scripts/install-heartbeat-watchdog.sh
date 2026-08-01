#!/usr/bin/env bash
# Installs the bass-tuner heartbeat-liveness watchdog as a systemd --user
# timer (bt-6492) -- deliberately NOT crontab, and deliberately NOT part of
# scripts/install-monitoring-crons.sh's managed block. That block is the
# thing the watchdog exists to watch over: if cron itself stops firing, if
# the managed block's next wholesale rewrite drops an entry, or if
# run-monitor.sh loses its exec bit, a checker living in that same block or
# scheduler would go silent for the exact same reason it needs to report.
# A systemd timer is a different scheduler entirely, so none of those
# failure modes can take it down too.
#
# Symlinks this repo's systemd/ unit files into ~/.config/systemd/user (same
# pattern as second-brain-digest.timer), so `systemctl --user status` always
# reflects the tracked source of truth -- no drift between what's installed
# and what's in the repo.
#
# Idempotent: safe to re-run (relinks, reloads, re-enables).
#
# Usage: install-heartbeat-watchdog.sh [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
UNIT_DIR="$HOME/.config/systemd/user"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

SERVICE_SRC="$REPO/systemd/bass-tuner-heartbeat-watchdog.service"
TIMER_SRC="$REPO/systemd/bass-tuner-heartbeat-watchdog.timer"

for f in "$SERVICE_SRC" "$TIMER_SRC"; do
  [ -f "$f" ] || { echo "[install-heartbeat-watchdog] missing unit file: $f" >&2; exit 1; }
done

if [ "$DRY_RUN" = "1" ]; then
  echo "[install-heartbeat-watchdog] dry-run: would link"
  echo "  $SERVICE_SRC -> $UNIT_DIR/bass-tuner-heartbeat-watchdog.service"
  echo "  $TIMER_SRC -> $UNIT_DIR/bass-tuner-heartbeat-watchdog.timer"
  echo "[install-heartbeat-watchdog] dry-run: would run: systemctl --user daemon-reload && systemctl --user enable --now bass-tuner-heartbeat-watchdog.timer"
  exit 0
fi

mkdir -p "$UNIT_DIR"
ln -sf "$SERVICE_SRC" "$UNIT_DIR/bass-tuner-heartbeat-watchdog.service"
ln -sf "$TIMER_SRC" "$UNIT_DIR/bass-tuner-heartbeat-watchdog.timer"

systemctl --user daemon-reload
systemctl --user enable --now bass-tuner-heartbeat-watchdog.timer

echo "[install-heartbeat-watchdog] installed and enabled bass-tuner-heartbeat-watchdog.timer (see: systemctl --user list-timers bass-tuner-heartbeat-watchdog.timer)"
