#!/usr/bin/env bash
# Install (or refresh) the ff-sync cron (bt-31a9) that fast-forwards this
# shared maintainer checkout onto origin/main every 3 minutes — without it,
# the monitoring crons (scripts/run-monitor.sh fallback-cert/domain-audit/
# heartbeat/stale-deploy/cert-renewal) all run whatever this checkout
# happened to have checked out, not what is actually merged. Mirrors
# house-control's, donefile's and tik-api's ff-sync-main-checkout.sh cadence
# and cron shape.
#
# Marker-delimited and idempotent, matching the other installers in this
# directory: re-running replaces the block rather than appending a second
# copy.
#
#   bash scripts/install-ff-sync-cron.sh          # install / update
#   bash scripts/install-ff-sync-cron.sh --remove
#   bash scripts/install-ff-sync-cron.sh --print-line   # rendered lines only, no markers (used by check-crontab-drift.sh)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$HOME/.local/share/meni-hub/ff-sync-bass-tuner-main-checkout"

BEGIN="# BEGIN bass-tuner-ff-sync (scripts/install-ff-sync-cron.sh)"
END="# END bass-tuner-ff-sync (scripts/install-ff-sync-cron.sh)"
LINE="*/3 * * * * mkdir -p $STATE_DIR && $REPO_ROOT/scripts/ff-sync-main-checkout.sh >> $STATE_DIR/cron.log 2>&1"

# Recurring drift check (ma-707b, mirrors tik-api's ff-sync installer) —
# shared implementation in meniapp (ma-c616), called by absolute path since
# this entry runs on the meni VPS, same box meniapp lives on.
DRIFT_CHECK="/home/omri/projects/meniapp/scripts/check-crontab-drift.sh"
DRIFT_STATE_DIR="$HOME/.local/share/meni-hub/bass-tuner-ff-sync-crontab-drift"
DRIFT_LINE="52 * * * * mkdir -p $DRIFT_STATE_DIR && BLOCK_LABEL=bass-tuner-ff-sync BEGIN_MARK=\"$BEGIN\" END_MARK=\"$END\" EXPECTED_CONTENT_CMD=\"$REPO_ROOT/scripts/install-ff-sync-cron.sh --print-line\" INSTALLER_HINT=\"scripts/install-ff-sync-cron.sh\" $DRIFT_CHECK >> $DRIFT_STATE_DIR/cron.log 2>&1"

LINES="$LINE
$DRIFT_LINE"

if [ "${1:-}" = "--print-line" ]; then
  printf '%s\n' "$LINES"
  exit 0
fi

# Shared crontab lock (ma-09c1) — same lock every fleet crontab installer
# takes, so two installers running concurrently serialize instead of one
# clobbering the other's freshly-written block.
. "$(dirname "${BASH_SOURCE[0]}")/lib/crontab-install-lock.sh" || {
  echo "FATAL: cannot source lib/crontab-install-lock.sh -- refusing to modify the crontab without the shared lock" >&2
  exit 1
}
crontab_install_take_lock

current="$(crontab -l 2>/dev/null || true)"
stripped="$(printf '%s\n' "$current" | awk -v b="$BEGIN" -v e="$END" '
  $0 == b {skip=1} skip==0 {print} $0 == e {skip=0}')"

if [ "${1:-}" = "--remove" ]; then
  printf '%s\n' "$stripped" | crontab -
  echo "removed"
  exit 0
fi

{ printf '%s\n' "$stripped"; echo "$BEGIN"; printf '%s\n' "$LINES"; echo "$END"; } | crontab -
echo "installed:"
crontab -l | grep -A2 "$BEGIN"
