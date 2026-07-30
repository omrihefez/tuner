#!/usr/bin/env bash
# Installs daily cron entries for check-fallback-cert.sh and audit-domains.sh
# (bt-a942). Both existed but were scheduled nowhere -- referenced only as
# one-shot closing evidence for the tasks that wrote them (bt-2b10, bt-a740)
# -- so a real regression in either would sit unnoticed indefinitely, which
# is exactly how the wildcard fallback cert expired silently for over a
# month. Both run through scripts/run-monitor.sh, which writes a dated
# ~/inbox file on any non-zero exit so the morning brief surfaces a failure.
#
# Idempotent: re-running replaces the managed block instead of duplicating it.
#
# Usage: install-monitoring-crons.sh [--dry-run]
set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# Hardcoded to the canonical checkout, not derived from this script's own
# location -- same rationale as install-cert-renewal-cron.sh: this installer
# must produce the same crontab lines regardless of whether it's run from the
# main checkout or a throwaway task worktree.
REPO="/home/omri/projects/bass-tuner"
RUNNER="$REPO/scripts/run-monitor.sh"
FALLBACK_CERT="$REPO/scripts/check-fallback-cert.sh"
DOMAIN_AUDIT="$REPO/scripts/audit-domains.sh"

BEGIN_MARK="# BEGIN bass-tuner-monitoring (scripts/install-monitoring-crons.sh)"
END_MARK="# END bass-tuner-monitoring (scripts/install-monitoring-crons.sh)"

# 06:05/06:10 -- ahead of the 06:17 wildcard-cert-renewal run so all three
# TLS/domain checks land in the same pre-day-start window.
CRON_LINES="5 6 * * * $RUNNER fallback-cert $FALLBACK_CERT
10 6 * * * $RUNNER domain-audit $DOMAIN_AUDIT"

CURRENT_CRON="$(crontab -l 2>/dev/null || true)"

STRIPPED_CRON="$(printf '%s\n' "$CURRENT_CRON" | sed "\\|^$BEGIN_MARK\$|,\\|^$END_MARK\$|d")"
STRIPPED_CRON="$(printf '%s\n' "$STRIPPED_CRON" | grep -vF "run-monitor.sh fallback-cert " | grep -vF "run-monitor.sh domain-audit " || true)"

NEW_CRON="$(printf '%s\n%s\n%s\n%s\n' "$STRIPPED_CRON" "$BEGIN_MARK" "$CRON_LINES" "$END_MARK")"

if [ "$DRY_RUN" = "1" ]; then
  echo "[install-monitoring-crons] dry-run: crontab would become:" >&2
  printf '%s\n' "$NEW_CRON" | sed 's/^/    /' >&2
else
  printf '%s\n' "$NEW_CRON" | crontab -
  echo "[install-monitoring-crons] installed daily 06:05/06:10 crons for fallback-cert / domain-audit checks (see: crontab -l)"
fi
