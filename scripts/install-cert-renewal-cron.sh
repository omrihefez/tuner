#!/usr/bin/env bash
# Installs the weekly renew-wildcard-cert.sh cron entry into the interactive
# user's crontab (bt-03ea). The script itself is idempotent -- it only acts
# once the cert is within RENEW_THRESHOLD_DAYS of expiry -- so a weekly cadence
# is enough to always catch the renewal window with margin to spare.
# Idempotent: re-running replaces the managed block instead of duplicating it.
#
# Usage: install-cert-renewal-cron.sh [--dry-run]
set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# Hardcoded to the canonical checkout, not derived from this script's own
# location -- this installer must produce the same crontab line regardless of
# whether it's run from the main checkout or a throwaway task worktree.
SCRIPT="/home/omri/projects/bass-tuner/scripts/renew-wildcard-cert.sh"
LOG_FILE="$HOME/.cache/bass-tuner-cert-renewal.log"

BEGIN_MARK="# BEGIN wildcard-cert-renewal (scripts/install-cert-renewal-cron.sh)"
END_MARK="# END wildcard-cert-renewal (scripts/install-cert-renewal-cron.sh)"

CRON_LINE="17 6 * * 1 $SCRIPT >> $LOG_FILE 2>&1"

CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

STRIPPED_CRON="$(printf '%s\n' "$CURRENT_CRON" | sed "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|d")"
STRIPPED_CRON="$(printf '%s\n' "$STRIPPED_CRON" | grep -vF "$(basename "$SCRIPT")" || true)"

NEW_CRON="$(printf '%s\n%s\n%s\n%s\n' "$STRIPPED_CRON" "$BEGIN_MARK" "$CRON_LINE" "$END_MARK")"

if [ "$DRY_RUN" = "1" ]; then
  echo "[install-cert-renewal-cron] dry-run: crontab would become:" >&2
  printf '%s\n' "$NEW_CRON" | sed 's/^/    /' >&2
else
  printf '%s\n' "$NEW_CRON" | crontab -
  echo "[install-cert-renewal-cron] installed Monday 06:17 cron for $SCRIPT (see: crontab -l)"
fi
